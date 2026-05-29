/**
 * WordAround — Gemini proxy Worker.
 *
 * Wire contract with the iOS app (`GrammarQuizAIHTTPClient`):
 *   POST  /
 *   body: { "prompt": "<full prompt>" }
 *   resp: { "text": "<model output>" }
 *   err:  { "error": "<message>" }   (HTTP 4xx/5xx)
 *
 * The Gemini API key lives ONLY as the Cloudflare Worker secret
 * `GEMINI_API_KEY`. Set it once with:
 *   wrangler secret put GEMINI_API_KEY
 *
 * The iOS app never sees the key — it only knows this Worker's URL.
 *
 * Additional path-routed endpoints:
 *   POST /api/describe-picture/random-image  → Unsplash proxy
 *   POST /api/shadowing/phrases              → Gemini phrase generation (JSON)
 *   POST /api/pronunciation/content          → Gemini pronunciation items (JSON)
 *   POST /api/speech/azure-token             → short-lived Azure Speech token
 *
 * Extra secrets (set once, never committed):
 *   wrangler secret put UNSPLASH_ACCESS_KEY
 *   wrangler secret put AZURE_SPEECH_KEY
 *   wrangler secret put AZURE_SPEECH_REGION
 */

const GEMINI_MODEL = "gemini-2.5-flash";
const GEMINI_ENDPOINT = (model) =>
  `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;

const JSON_HEADERS = {
  "Content-Type": "application/json",
  // Permissive CORS so the same Worker can be hit from a future web client.
  // The iOS URLSession path is unaffected.
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

const DESCRIBE_PICTURE_PATH = "/api/describe-picture/random-image";
const UNSPLASH_RANDOM_ENDPOINT =
  "https://api.unsplash.com/photos/random?orientation=landscape&content_filter=high";

const SHADOWING_PHRASES_PATH = "/api/shadowing/phrases";
const PRONUNCIATION_CONTENT_PATH = "/api/pronunciation/content";
const AZURE_TOKEN_PATH = "/api/speech/azure-token";

export default {
  async fetch(request, env) {
    // CORS preflight — harmless for iOS, required if you ever hit this
    // Worker from a browser.
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: JSON_HEADERS });
    }

    if (request.method !== "POST") {
      return jsonError("Only POST is supported.", 405);
    }

    // Path-routed endpoints. Anything else falls through to the default
    // Gemini prompt proxy below, preserving the existing `POST /` contract
    // used by feedback/topic generation.
    const pathname = new URL(request.url).pathname;

    if (pathname === DESCRIBE_PICTURE_PATH) {
      return handleDescribePictureRandomImage(env);
    }

    if (pathname === AZURE_TOKEN_PATH) {
      return handleAzureSpeechToken(env);
    }

    if (pathname === SHADOWING_PHRASES_PATH) {
      return handleShadowingPhrases(request, env);
    }

    if (pathname === PRONUNCIATION_CONTENT_PATH) {
      return handlePronunciationContent(request, env);
    }

    if (!env.GEMINI_API_KEY) {
      // Misconfiguration — secret was never set. Surface a clear error
      // rather than leaking that the key is missing to the LLM provider.
      return jsonError("Worker is missing GEMINI_API_KEY secret.", 500);
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return jsonError("Request body must be valid JSON.", 400);
    }

    const prompt = typeof body?.prompt === "string" ? body.prompt.trim() : "";
    if (!prompt) {
      return jsonError("Missing or empty 'prompt' field.", 400);
    }

    // Optional `responseMimeType` from the caller. When the iOS app asks
    // for `application/json`, Gemini will return a JSON-shaped string —
    // useful for quiz / topic generation. When unset, free-form text is
    // returned (used for plain-text hints and smoke tests).
    const requestedMime =
      typeof body?.responseMimeType === "string"
        ? body.responseMimeType.trim()
        : "";

    const generationConfig = {
      temperature: 0.4,
      maxOutputTokens: 2048,
    };
    if (requestedMime === "application/json") {
      generationConfig.responseMimeType = "application/json";
    }

    // Forward to Gemini server-side. The key is appended as the standard
    // `?key=` query parameter — Google's recommended auth for the
    // `generativelanguage` REST API. The key never appears in any iOS
    // bundle, log, or stack trace.
    let geminiResp;
    try {
      geminiResp = await fetch(
        `${GEMINI_ENDPOINT(GEMINI_MODEL)}?key=${encodeURIComponent(env.GEMINI_API_KEY)}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            contents: [
              {
                role: "user",
                parts: [{ text: prompt }],
              },
            ],
            generationConfig,
          }),
        }
      );
    } catch (e) {
      return jsonError(`Upstream network error: ${String(e)}`, 502);
    }

    if (!geminiResp.ok) {
      // Avoid leaking provider-specific 4xx/5xx detail to the client.
      const status = geminiResp.status >= 500 ? 502 : 502;
      return jsonError(`Gemini error (${geminiResp.status}).`, status);
    }

    let geminiJson;
    try {
      geminiJson = await geminiResp.json();
    } catch {
      return jsonError("Gemini returned a non-JSON response.", 502);
    }

    // Pull the first candidate's first text part. Gemini's structure is
    // candidates[0].content.parts[0].text — null-safe at every step.
    const text =
      geminiJson?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

    if (typeof text !== "string" || text.trim().length === 0) {
      return jsonError("Gemini returned empty text.", 502);
    }

    return new Response(JSON.stringify({ text }), {
      status: 200,
      headers: JSON_HEADERS,
    });
  },
};

function jsonError(message, status) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: JSON_HEADERS,
  });
}

/**
 * Shadowing — generates a set of fresh target phrases in the learner's
 * target language via Gemini and returns strict JSON:
 *   { phrases: [ { id, text, translation, languageCode, level, category, tip } ] }
 *
 * Request body (from iOS `CloudflareShadowingPhraseClient`):
 *   { language, languageCode, level, category, count, avoidPhrases, seed }
 *
 * The Gemini key never leaves the Worker. On any upstream/parse failure we
 * return an error and the iOS app falls back to local phrase sets.
 */
async function handleShadowingPhrases(request, env) {
  if (!env.GEMINI_API_KEY) {
    return jsonError("Worker is missing GEMINI_API_KEY secret.", 500);
  }

  let body;
  try {
    body = await request.json();
  } catch {
    return jsonError("Request body must be valid JSON.", 400);
  }

  const language = typeof body?.language === "string" ? body.language.trim() : "";
  const languageCode =
    typeof body?.languageCode === "string" ? body.languageCode.trim() : "";
  const level = typeof body?.level === "string" ? body.level.trim() : "B1";
  const category =
    typeof body?.category === "string" ? body.category.trim() : "Daily phrases";
  const count = Math.min(Math.max(Number(body?.count) || 5, 1), 10);
  const avoidPhrases = Array.isArray(body?.avoidPhrases)
    ? body.avoidPhrases.filter((p) => typeof p === "string").slice(-30)
    : [];
  const seed =
    typeof body?.seed === "string" || typeof body?.seed === "number"
      ? String(body.seed)
      : String(Math.random());

  if (!language) {
    return jsonError("Missing 'language' field.", 400);
  }

  const avoidBlock =
    avoidPhrases.length > 0
      ? `\nDo NOT reuse or closely paraphrase any of these recent phrases:\n- ${avoidPhrases.join(
          "\n- "
        )}\n`
      : "\n";

  const prompt = `You are generating short speaking-practice phrases for a language learner to shadow (listen and repeat).

Target language: ${language}
CEFR level: ${level}
Category / theme: ${category}
Generate exactly ${count} phrases.
Variety seed: ${seed} (use it to make this set different from previous sets).
${avoidBlock}
Rules:
- Every "text" MUST be written in ${language} only. Never put English in "text" unless the target language is English.
- "translation" MUST be a natural English translation, for display only.
- Keep phrases natural, idiomatic and appropriate for ${level}.
- Each phrase is one sentence the learner can comfortably repeat aloud.
- "tip" is one short pronunciation/rhythm tip in English.
- Make the ${count} phrases distinct from each other.

Return ONLY strict minified JSON in exactly this shape, with no markdown:
{"phrases":[{"text":"...","translation":"...","tip":"..."}]}`;

  let geminiResp;
  try {
    geminiResp = await fetch(
      `${GEMINI_ENDPOINT(GEMINI_MODEL)}?key=${encodeURIComponent(env.GEMINI_API_KEY)}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ role: "user", parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 1.0,
            maxOutputTokens: 2048,
            responseMimeType: "application/json",
          },
        }),
      }
    );
  } catch (e) {
    return jsonError(`Upstream network error: ${String(e)}`, 502);
  }

  if (!geminiResp.ok) {
    return jsonError(`Gemini error (${geminiResp.status}).`, 502);
  }

  let geminiJson;
  try {
    geminiJson = await geminiResp.json();
  } catch {
    return jsonError("Gemini returned a non-JSON response.", 502);
  }

  const raw = geminiJson?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return jsonError("Gemini returned malformed phrase JSON.", 502);
  }

  const sourcePhrases = Array.isArray(parsed?.phrases) ? parsed.phrases : [];
  const phrases = sourcePhrases
    .map((p) => ({
      id: crypto.randomUUID(),
      text: typeof p?.text === "string" ? p.text.trim() : "",
      translation: typeof p?.translation === "string" ? p.translation.trim() : "",
      languageCode,
      level,
      category,
      tip: typeof p?.tip === "string" ? p.tip.trim() : "",
    }))
    .filter((p) => p.text.length > 0)
    .slice(0, count);

  if (phrases.length === 0) {
    return jsonError("Gemini returned no usable phrases.", 502);
  }

  return new Response(JSON.stringify({ phrases }), {
    status: 200,
    headers: JSON_HEADERS,
  });
}

/**
 * Pronunciation Trainer — generates focused pronunciation practice items
 * (single words, minimal pairs, short sound-focused phrases) in the target
 * language via Gemini. Returns strict JSON:
 *   { items: [ { id, type, text, translation, languageCode, level,
 *               difficulty, focusSound, tip, example } ] }
 *
 * Request body (from iOS `CloudflarePronunciationContentClient`):
 *   { language, languageCode, level, difficulty, focus, count, avoidItems, seed }
 *
 * The Gemini key never leaves the Worker. On any failure the iOS app falls
 * back to local pronunciation items.
 */
async function handlePronunciationContent(request, env) {
  if (!env.GEMINI_API_KEY) {
    return jsonError("Worker is missing GEMINI_API_KEY secret.", 500);
  }

  let body;
  try {
    body = await request.json();
  } catch {
    return jsonError("Request body must be valid JSON.", 400);
  }

  const language = typeof body?.language === "string" ? body.language.trim() : "";
  const languageCode =
    typeof body?.languageCode === "string" ? body.languageCode.trim() : "";
  const level = typeof body?.level === "string" ? body.level.trim() : "A2";
  const difficulty =
    typeof body?.difficulty === "string" ? body.difficulty.trim() : "balanced";
  const focus = typeof body?.focus === "string" ? body.focus.trim() : "mixed";
  const count = Math.min(Math.max(Number(body?.count) || 10, 1), 15);
  const avoidItems = Array.isArray(body?.avoidItems)
    ? body.avoidItems.filter((p) => typeof p === "string").slice(-40)
    : [];
  const seed =
    typeof body?.seed === "string" || typeof body?.seed === "number"
      ? String(body.seed)
      : String(Math.random());

  if (!language) {
    return jsonError("Missing 'language' field.", 400);
  }

  const avoidBlock =
    avoidItems.length > 0
      ? `\nDo NOT reuse any of these recent items:\n- ${avoidItems.join("\n- ")}\n`
      : "\n";

  const prompt = `You are generating focused PRONUNCIATION practice items for a language learner.
These are NOT full conversational sentences — they target specific sounds, difficult words, and minimal pairs.

Target language: ${language}
CEFR level: ${level}
Difficulty: ${difficulty}
Focus area: ${focus}
Generate exactly ${count} items.
Variety seed: ${seed} (use it to make this set different from previous sets).
${avoidBlock}
Each item has a "type", one of: "word", "minimalPair", "phrase", "sound".
- "word": a single difficult word.
- "minimalPair": two contrasting words separated by " / " (e.g. "ship / sheep").
- "phrase": a SHORT sound-focused phrase (max 5 words).
- "sound": an isolated sound or letter combination.

Rules:
- Every "text" MUST be written in ${language} only (never English unless the target language is English).
- Bias the set toward the focus area "${focus}".
- "translation" is a short natural English gloss, for display only (may be empty for pure "sound" items).
- "focusSound" names the specific sound/letters being trained (e.g. "rr", "th", "ü").
- "tip" is one short English tip on how to produce the sound.
- "example" is ONE short natural sentence in ${language} using the item (for an optional example playback).
- Make all ${count} items distinct.

Return ONLY strict minified JSON in exactly this shape, no markdown:
{"items":[{"type":"word","text":"...","translation":"...","focusSound":"...","tip":"...","example":"..."}]}`;

  let geminiResp;
  try {
    geminiResp = await fetch(
      `${GEMINI_ENDPOINT(GEMINI_MODEL)}?key=${encodeURIComponent(env.GEMINI_API_KEY)}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ role: "user", parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 1.0,
            maxOutputTokens: 2048,
            responseMimeType: "application/json",
          },
        }),
      }
    );
  } catch (e) {
    return jsonError(`Upstream network error: ${String(e)}`, 502);
  }

  if (!geminiResp.ok) {
    return jsonError(`Gemini error (${geminiResp.status}).`, 502);
  }

  let geminiJson;
  try {
    geminiJson = await geminiResp.json();
  } catch {
    return jsonError("Gemini returned a non-JSON response.", 502);
  }

  const raw = geminiJson?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return jsonError("Gemini returned malformed item JSON.", 502);
  }

  const allowedTypes = new Set(["word", "minimalPair", "phrase", "sound"]);
  const sourceItems = Array.isArray(parsed?.items) ? parsed.items : [];
  const items = sourceItems
    .map((it) => ({
      id: crypto.randomUUID(),
      type: allowedTypes.has(it?.type) ? it.type : "word",
      text: typeof it?.text === "string" ? it.text.trim() : "",
      translation: typeof it?.translation === "string" ? it.translation.trim() : "",
      languageCode,
      level,
      difficulty,
      focusSound: typeof it?.focusSound === "string" ? it.focusSound.trim() : "",
      tip: typeof it?.tip === "string" ? it.tip.trim() : "",
      example: typeof it?.example === "string" ? it.example.trim() : "",
    }))
    .filter((it) => it.text.length > 0)
    .slice(0, count);

  if (items.length === 0) {
    return jsonError("Gemini returned no usable items.", 502);
  }

  return new Response(JSON.stringify({ items }), {
    status: 200,
    headers: JSON_HEADERS,
  });
}

/**
 * Azure Speech — issues a short-lived (~10 min) auth token so the iOS app
 * can call Azure Pronunciation Assessment WITHOUT ever embedding the
 * subscription key. Returns: { token, region }.
 *
 * Secrets (set once, never committed):
 *   wrangler secret put AZURE_SPEECH_KEY
 *   wrangler secret put AZURE_SPEECH_REGION
 */
async function handleAzureSpeechToken(env) {
  const key = env.AZURE_SPEECH_KEY;
  const region = env.AZURE_SPEECH_REGION;

  if (!key || !region) {
    return jsonError(
      "Worker is missing AZURE_SPEECH_KEY or AZURE_SPEECH_REGION secret.",
      500
    );
  }

  const issueURL = `https://${region}.api.cognitive.microsoft.com/sts/v1.0/issueToken`;

  let azureResp;
  try {
    azureResp = await fetch(issueURL, {
      method: "POST",
      headers: {
        "Ocp-Apim-Subscription-Key": key,
        "Content-Type": "application/x-www-form-urlencoded",
        "Content-Length": "0",
      },
    });
  } catch (e) {
    return jsonError(`Azure token network error: ${String(e)}`, 502);
  }

  if (azureResp.status === 401 || azureResp.status === 403) {
    return jsonError("Azure rejected the speech credentials.", 502);
  }
  if (!azureResp.ok) {
    return jsonError(`Azure token error (${azureResp.status}).`, 502);
  }

  let token;
  try {
    token = await azureResp.text();
  } catch {
    return jsonError("Azure returned an unreadable token.", 502);
  }

  if (!token || token.trim().length === 0) {
    return jsonError("Azure returned an empty token.", 502);
  }

  return new Response(JSON.stringify({ token, region }), {
    status: 200,
    headers: JSON_HEADERS,
  });
}

/**
 * Describe Picture — fetches a random landscape photo from Unsplash and
 * returns a simplified shape the iOS app can decode directly:
 *   { id, imageURL, authorName, authorURL }
 *
 * The Unsplash access key lives ONLY as the Worker secret
 * `UNSPLASH_ACCESS_KEY`. Set it once with:
 *   wrangler secret put UNSPLASH_ACCESS_KEY
 * The iOS app never sees the key — it only knows this Worker's URL.
 */
async function handleDescribePictureRandomImage(env) {
  if (!env.UNSPLASH_ACCESS_KEY) {
    return jsonError("Worker is missing UNSPLASH_ACCESS_KEY secret.", 500);
  }

  let unsplashResp;
  try {
    unsplashResp = await fetch(UNSPLASH_RANDOM_ENDPOINT, {
      headers: {
        Authorization: `Client-ID ${env.UNSPLASH_ACCESS_KEY}`,
        "Accept-Version": "v1",
      },
    });
  } catch (e) {
    return jsonError(`Upstream network error: ${String(e)}`, 502);
  }

  if (unsplashResp.status === 401 || unsplashResp.status === 403) {
    // Auth/quota problem — never echo the provider's body (may hint at key).
    return jsonError("Image provider rejected the request.", 502);
  }
  if (unsplashResp.status === 429) {
    return jsonError("Image provider rate limit reached.", 429);
  }
  if (!unsplashResp.ok) {
    return jsonError(`Image provider error (${unsplashResp.status}).`, 502);
  }

  let photo;
  try {
    photo = await unsplashResp.json();
  } catch {
    return jsonError("Image provider returned a non-JSON response.", 502);
  }

  const imageURL =
    photo?.urls?.regular ?? photo?.urls?.full ?? photo?.urls?.raw ?? "";
  const id = typeof photo?.id === "string" ? photo.id : "";

  if (!id || typeof imageURL !== "string" || imageURL.length === 0) {
    return jsonError("Image provider returned no usable image.", 502);
  }

  const authorName =
    typeof photo?.user?.name === "string" && photo.user.name.trim().length > 0
      ? photo.user.name.trim()
      : "Unknown";
  const authorURL =
    typeof photo?.user?.links?.html === "string"
      ? photo.user.links.html
      : "https://unsplash.com";

  return new Response(
    JSON.stringify({ id, imageURL, authorName, authorURL }),
    { status: 200, headers: JSON_HEADERS }
  );
}
