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
