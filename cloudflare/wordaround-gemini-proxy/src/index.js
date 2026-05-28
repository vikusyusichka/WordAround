/**
 * WordAround — Cloudflare Worker.
 *
 * Two routes are served from the same Worker so the iOS app needs only
 * one base URL:
 *
 *   1. POST /                     — Gemini text proxy (legacy wire contract
 *                                   used by GrammarQuizAIHTTPClient, the
 *                                   Essay AI client and similar).
 *
 *   2. POST /api/speaking/topic   — Groq-backed speaking-topic generator
 *                                   called by the iOS Speaking feature.
 *
 * Secrets (set once per environment with Wrangler):
 *   wrangler secret put GEMINI_API_KEY
 *   wrangler secret put GROQ_API_KEY
 *
 * The iOS app never sees either key — it only knows this Worker's URL.
 */

// ----- Gemini config -----
const GEMINI_MODEL = "gemini-2.5-flash";
const GEMINI_ENDPOINT = (model) =>
  `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;

// ----- Groq config -----
const GROQ_MODEL = "llama-3.1-8b-instant";
const GROQ_ENDPOINT = "https://api.groq.com/openai/v1/chat/completions";

const JSON_HEADERS = {
  "Content-Type": "application/json",
  // Permissive CORS so the same Worker can be hit from a future web client.
  // The iOS URLSession path is unaffected.
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

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

    const url = new URL(request.url);

    // Path-based dispatch. New routes go through the switch below;
    // anything else falls through to the legacy Gemini handler so
    // existing clients (which POST to "/") keep working unchanged.
    if (url.pathname === "/api/speaking/topic") {
      return handleSpeakingTopic(request, env);
    }

    return handleGeminiText(request, env);
  },
};

// =====================================================================
// Legacy Gemini text proxy (unchanged behaviour)
// =====================================================================

async function handleGeminiText(request, env) {
  if (!env.GEMINI_API_KEY) {
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
    return jsonError(`Gemini error (${geminiResp.status}).`, 502);
  }

  let geminiJson;
  try {
    geminiJson = await geminiResp.json();
  } catch {
    return jsonError("Gemini returned a non-JSON response.", 502);
  }

  const text =
    geminiJson?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

  if (typeof text !== "string" || text.trim().length === 0) {
    return jsonError("Gemini returned empty text.", 502);
  }

  return new Response(JSON.stringify({ text }), {
    status: 200,
    headers: JSON_HEADERS,
  });
}

// =====================================================================
// POST /api/speaking/topic — Groq-backed topic generator
//
// Request body from iOS:
//   {
//     "language":      "English",      // required
//     "level":         "A2",           // required CEFR level or "Native"
//     "lengthMinutes": 5               // required positive integer
//   }
//
// Response on success (current contract):
//   {
//     "title":            "<short topic title in selected language>",
//     "description":      "<one-sentence description in selected language>",
//     "openingQuestion":  "<the tutor's opening question in selected language>",
//     "promptContext":    "<English-language hint for the tutor prompt>",
//     "category":         "<one-or-two-word category in English>",
//     "level":            "<echo of requested level>",
//     "estimatedMinutes": <echo of requested lengthMinutes>,
//
//     // Legacy aliases — kept for older iOS builds, drop in a future
//     // release once everyone is on the new names.
//     "prompt":           "<same as description>",
//     "firstAIMessage":   "<same as openingQuestion>",
//     "context":          "<same as promptContext>",
//     "difficulty":       "<same as level>"
//   }
//
// All error responses use { "error": "<safe message>" } so the iOS app
// can surface them without leaking the Groq key or upstream stack traces.
// =====================================================================

async function handleSpeakingTopic(request, env) {
  if (!env.GROQ_API_KEY) {
    return jsonError("Worker is missing GROQ_API_KEY secret.", 500);
  }

  let body;
  try {
    body = await request.json();
  } catch {
    return jsonError("Request body must be valid JSON.", 400);
  }

  const language = typeof body?.language === "string" ? body.language.trim() : "";
  const level = typeof body?.level === "string" ? body.level.trim() : "";
  const lengthMinutes = Number(body?.lengthMinutes);

  // Optional anti-repeat list. Trimmed to 12 entries on the iOS side
  // already; we clamp again here to be safe.
  const rawAvoid = Array.isArray(body?.avoidTitles) ? body.avoidTitles : [];
  const avoidTitles = rawAvoid
    .filter((t) => typeof t === "string" && t.trim().length > 0)
    .map((t) => t.trim())
    .slice(-12);

  if (!language) {
    return jsonError("Missing or empty 'language' field.", 400);
  }
  if (!level) {
    return jsonError("Missing or empty 'level' field.", 400);
  }
  if (!Number.isFinite(lengthMinutes) || lengthMinutes <= 0 || lengthMinutes > 120) {
    return jsonError("Invalid 'lengthMinutes' field.", 400);
  }

  const prompt = buildTopicPrompt(language, level, lengthMinutes, avoidTitles);

  let groqResp;
  try {
    groqResp = await fetch(GROQ_ENDPOINT, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${env.GROQ_API_KEY}`,
      },
      body: JSON.stringify({
        model: GROQ_MODEL,
        messages: [
          {
            role: "system",
            content: "You output only JSON. No markdown, no prose, no commentary.",
          },
          { role: "user", content: prompt },
        ],
        // High temperature so successive calls drift into different
        // categories rather than locking onto common defaults
        // ("Morning routine", "Cafe", etc.).
        temperature: 1.0,
        top_p: 0.95,
        max_tokens: 400,
        response_format: { type: "json_object" },
      }),
    });
  } catch (e) {
    return jsonError(`Upstream network error: ${String(e)}`, 502);
  }

  // Surface rate-limits to the client without leaking provider detail.
  if (groqResp.status === 429) {
    return jsonError("Topic AI rate limit. Try again shortly.", 429);
  }

  if (!groqResp.ok) {
    return jsonError(`Topic AI error (${groqResp.status}).`, 502);
  }

  let groqJson;
  try {
    groqJson = await groqResp.json();
  } catch {
    return jsonError("Topic AI returned a non-JSON response.", 502);
  }

  const rawContent = groqJson?.choices?.[0]?.message?.content;
  if (typeof rawContent !== "string" || rawContent.trim().length === 0) {
    return jsonError("Topic AI returned empty content.", 502);
  }

  let parsed;
  try {
    parsed = JSON.parse(rawContent);
  } catch {
    return jsonError("Topic AI returned malformed JSON.", 502);
  }

  // Required visible fields. Model may emit either old (`prompt` /
  // `firstAIMessage` / `context` / `difficulty`) or new
  // (`description` / `openingQuestion` / `promptContext` / `level`)
  // key names — accept either and normalise.
  const title = stringField(parsed?.title);
  const description = stringField(parsed?.description ?? parsed?.prompt);
  const promptContext = stringField(parsed?.promptContext ?? parsed?.context);
  const openingQuestion = stringField(
    parsed?.openingQuestion ?? parsed?.firstAIMessage
  );

  if (!title || !description || !promptContext || !openingQuestion) {
    return jsonError("Topic AI returned an incomplete topic.", 502);
  }

  const category = stringField(parsed?.category) || "Conversation";

  // Emit BOTH new and legacy keys so an iOS rollout doesn't have to be
  // perfectly synchronised with the Worker rollout. The current iOS
  // client reads the new names; older builds still work via the legacy
  // aliases.
  return new Response(
    JSON.stringify({
      title,
      description,
      openingQuestion,
      promptContext,
      category,
      level,
      estimatedMinutes: lengthMinutes,

      // Legacy aliases — safe to drop once every shipped client is on
      // the new names.
      prompt: description,
      firstAIMessage: openingQuestion,
      context: promptContext,
      difficulty: level,
    }),
    { status: 200, headers: JSON_HEADERS }
  );
}

function buildTopicPrompt(language, level, lengthMinutes, avoidTitles) {
  const levelHint = levelHintFor(level);
  // Small randomness anchor so the model has at least one freely-varying
  // signal between calls (in addition to its temperature). Helps avoid
  // "always returns the same topic" when the cache is forced-refresh.
  const seed = Math.floor(Math.random() * 1_000_000);

  // The single most important steering signal. Without this line the
  // model overwhelmingly defaults to the same 3-4 topics per level.
  const avoidBlock =
    avoidTitles && avoidTitles.length > 0
      ? [
          `Do NOT reuse or rephrase any of these recent titles: ${avoidTitles
            .map((t) => `"${t}"`)
            .join(", ")}.`,
          "Pick a clearly different scenario, category and vocabulary set.",
        ]
      : [];

  // A wider palette than "cafe / morning routine / family". Listed so
  // the model treats them as the *space* it can draw from, not a list
  // to copy verbatim.
  const inspirationPool = [
    "asking a neighbour to borrow something",
    "returning a damaged purchase",
    "describing a strange dream",
    "small talk at a bus stop",
    "calling a doctor for an appointment",
    "ordering food at a market stall",
    "discussing a movie you just watched",
    "explaining a recipe to a friend",
    "negotiating a price at a flea market",
    "lost in a museum, asking for help",
    "phone call to fix a broken appliance",
    "interviewing a grandparent about their childhood",
    "talking to a cashier about a discount",
    "describing your favourite season",
    "settling into a hotel room with a problem",
    "comparing two phones in a store",
    "explaining why you're late",
    "discussing weekend plans with a colleague",
    "renting a bicycle on holiday",
    "complaining politely about loud neighbours",
  ];
  // Sample a small subset so each call sees a different rotation.
  const sample = inspirationPool
    .map((value) => ({ value, sort: Math.random() }))
    .sort((a, b) => a.sort - b.sort)
    .slice(0, 6)
    .map((entry) => `- ${entry.value}`)
    .join("\n");

  const lines = [
    "You are creating a speaking practice topic for a language learner.",
    "Your job is to invent something fresh — not to fall back on the same default topic every time.",
    "",
    `Selected language: ${language}`,
    `Learner level: ${level}`,
    `Conversation length: ${lengthMinutes} minutes`,
    `Variety seed: ${seed}`,
    "",
    `Level guidance: ${levelHint}`,
  ];

  if (avoidBlock.length > 0) {
    lines.push("");
    lines.push(...avoidBlock);
  }

  lines.push("");
  lines.push("Inspiration (pick a different angle each call — do NOT copy these verbatim):");
  lines.push(sample);
  lines.push("");
  lines.push("Return ONLY a JSON object that matches this shape:");
  lines.push("{");
  lines.push(`  "title": "<short topic title in ${language}>",`);
  lines.push(`  "description": "<one short sentence in ${language} describing what the learner will practice>",`);
  lines.push(`  "category": "<one or two word category in English (e.g. Daily life, Travel, Professional, Social, Health, Hobbies, Shopping, Family, Tech, Food)>",`);
  lines.push(`  "level": "${level}",`);
  lines.push(`  "estimatedMinutes": ${lengthMinutes},`);
  lines.push(`  "openingQuestion": "<the tutor's opening question in ${language}>",`);
  lines.push(`  "promptContext": "<one short paragraph in English describing what the tutor should do during the roleplay>"`);
  lines.push("}");
  lines.push("");
  lines.push("Rules:");
  lines.push(`- title, description, openingQuestion MUST be written in ${language}.`);
  lines.push("- category and promptContext MUST be in English.");
  lines.push(`- The vocabulary and grammar MUST match level ${level}.`);
  lines.push(`- The openingQuestion MUST be a single sentence aimed at level ${level}.`);
  lines.push("- Pick something specific and conversational — concrete situations beat generic categories. Prefer titles like 'Asking a neighbour for help' over just 'Family'.");
  lines.push("- Vary the category from call to call when possible.");
  lines.push("- Do not output markdown, prose, or commentary. JSON only.");

  return lines.join("\n");
}

function levelHintFor(level) {
  switch ((level || "").toUpperCase()) {
    case "A1":
      return "Use very simple words, short sentences (max 8 words), present tense, no abstract topics.";
    case "A2":
      return "Use simple practical situations: travel, shopping, cafe, daily life. Short sentences.";
    case "B1":
      return "Use everyday opinions, experiences, plans. Vocabulary moderate.";
    case "B2":
      return "Allow comparisons, deeper discussion, some abstract ideas.";
    case "C1":
      return "Use abstract topics and nuanced opinions. Allow complex vocabulary.";
    default:
      return "Natural fluent conversation. Any topic.";
  }
}

function stringField(value) {
  if (typeof value !== "string") return "";
  return value.trim();
}

function jsonError(message, status) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: JSON_HEADERS,
  });
}
