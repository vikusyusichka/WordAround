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
    if (new URL(request.url).pathname === DESCRIBE_PICTURE_PATH) {
      return handleDescribePictureRandomImage(env);
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
