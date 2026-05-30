/**
 * Provider adapters for the AI Provider Router.
 *
 * Each adapter exposes:
 *   - name:            stable provider id used by the priority matrix
 *   - isConfigured(env): true when the provider's secret is present
 *   - async generate(request, env): returns the raw model text, or throws
 *                                    a `ProviderError` describing the failure
 *
 * A normalized request looks like:
 *   { task, prompt, responseFormat: "text"|"json", temperature, maxTokens }
 *
 * Adapters hide every provider-specific request/response shape. They NEVER
 * expose API keys — keys come from `env` (Cloudflare Worker secrets) and are
 * only ever placed in outbound provider headers / query strings.
 */

import { logDebug } from "./log.js";

// Per-provider request timeout. A hung provider must fail over quickly so the
// next provider in the chain gets a chance.
const PROVIDER_TIMEOUT_MS = 25_000;

// Default models. Each can be overridden by an optional Worker var/secret of
// the same name (e.g. `GROQ_MODEL`) without touching code.
const DEFAULT_MODELS = {
  gemini: "gemini-2.5-flash", // keep the exact model the Worker already used
  groq: "llama-3.1-8b-instant",
  cerebras: "llama3.1-8b",
  cohere: "command-r-plus",
  deepseek: "deepseek-chat",
};

const GEMINI_ENDPOINT = (model) =>
  `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;

/**
 * Error type that tells the router HOW to react to a provider failure.
 *
 *   reason   — short machine-ish string for logs/attempts ("rate_limit", ...)
 *   status   — upstream HTTP status when known (else 0)
 *   cooldown — when true, the router parks this provider for a cooldown window
 *
 * Every ProviderError is treated as "try the next provider" — adapters only
 * throw these for genuine provider-side failures (never for a bad client
 * request, which the router rejects before any provider is called).
 */
export class ProviderError extends Error {
  constructor(reason, { status = 0, cooldown = false } = {}) {
    super(reason);
    this.name = "ProviderError";
    this.reason = reason;
    this.status = status;
    this.cooldown = cooldown;
  }
}

function modelFor(provider, env) {
  const override = env?.[`${provider.toUpperCase()}_MODEL`];
  if (typeof override === "string" && override.trim().length > 0) {
    return override.trim();
  }
  return DEFAULT_MODELS[provider];
}

/**
 * Classifies an upstream HTTP status into a ProviderError. Centralised so all
 * adapters agree on what counts as "rate limited" vs "server error" vs
 * "skip this provider".
 */
function errorForStatus(status, providerName) {
  // Quota / rate limit → fail over AND cool the provider down.
  if (status === 429) {
    return new ProviderError("rate_limit", { status, cooldown: true });
  }
  // Auth / forbidden → bad or missing-scope key. Skip & cool down so we stop
  // hammering a misconfigured provider, but keep serving from the others.
  if (status === 401 || status === 403) {
    return new ProviderError("auth_error", { status, cooldown: true });
  }
  // Transient upstream failures → fail over without cooldown.
  if (status === 500 || status === 502 || status === 503 || status === 504) {
    return new ProviderError("server_error", { status });
  }
  // Anything else non-2xx (incl. 400/422 from a provider rejecting our
  // response_format) → still just skip to the next provider. Our own request
  // validation already happened upstream, so this is a provider-side quirk.
  return new ProviderError(`http_${status}`, { status });
}

async function fetchWithTimeout(url, init) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), PROVIDER_TIMEOUT_MS);
  try {
    return await fetch(url, { ...init, signal: controller.signal });
  } catch (e) {
    const reason = e?.name === "AbortError" ? "timeout" : "network";
    throw new ProviderError(reason);
  } finally {
    clearTimeout(timer);
  }
}

function ensureNonEmpty(text) {
  if (typeof text !== "string" || text.trim().length === 0) {
    throw new ProviderError("empty_response");
  }
  return text;
}

// ---------------------------------------------------------------------------
// OpenAI-compatible chat adapter (Groq, Cerebras, DeepSeek)
// ---------------------------------------------------------------------------

async function callOpenAICompatible({ providerName, baseURL, apiKey, model, request }) {
  const body = {
    model,
    messages: [{ role: "user", content: request.prompt }],
    temperature: request.temperature ?? 0.4,
    max_tokens: request.maxTokens ?? 2048,
  };
  if (request.responseFormat === "json") {
    body.response_format = { type: "json_object" };
  }

  const resp = await fetchWithTimeout(baseURL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify(body),
  });

  if (!resp.ok) {
    throw errorForStatus(resp.status, providerName);
  }

  let json;
  try {
    json = await resp.json();
  } catch {
    throw new ProviderError("non_json_response");
  }

  const text = json?.choices?.[0]?.message?.content ?? "";
  return ensureNonEmpty(text);
}

// ---------------------------------------------------------------------------
// Gemini (generativelanguage REST API)
// ---------------------------------------------------------------------------

async function callGemini(request, env) {
  const model = modelFor("gemini", env);
  const generationConfig = {
    temperature: request.temperature ?? 0.4,
    maxOutputTokens: request.maxTokens ?? 2048,
  };
  if (request.responseFormat === "json") {
    generationConfig.responseMimeType = "application/json";
  }

  const resp = await fetchWithTimeout(
    `${GEMINI_ENDPOINT(model)}?key=${encodeURIComponent(env.GEMINI_API_KEY)}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ role: "user", parts: [{ text: request.prompt }] }],
        generationConfig,
      }),
    }
  );

  if (!resp.ok) {
    throw errorForStatus(resp.status, "gemini");
  }

  let json;
  try {
    json = await resp.json();
  } catch {
    throw new ProviderError("non_json_response");
  }

  const text = json?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
  return ensureNonEmpty(text);
}

// ---------------------------------------------------------------------------
// Cohere (v2 chat)
// ---------------------------------------------------------------------------

async function callCohere(request, env) {
  const model = modelFor("cohere", env);
  const body = {
    model,
    messages: [{ role: "user", content: request.prompt }],
    temperature: request.temperature ?? 0.4,
  };
  if (request.responseFormat === "json") {
    body.response_format = { type: "json_object" };
  }

  const resp = await fetchWithTimeout("https://api.cohere.com/v2/chat", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${env.COHERE_API_KEY}`,
    },
    body: JSON.stringify(body),
  });

  if (!resp.ok) {
    throw errorForStatus(resp.status, "cohere");
  }

  let json;
  try {
    json = await resp.json();
  } catch {
    throw new ProviderError("non_json_response");
  }

  // Cohere v2: { message: { content: [ { type:"text", text:"..." } ] } }
  const parts = json?.message?.content;
  const text = Array.isArray(parts)
    ? parts.map((p) => (typeof p?.text === "string" ? p.text : "")).join("")
    : "";
  return ensureNonEmpty(text);
}

// ---------------------------------------------------------------------------
// Adapter registry
// ---------------------------------------------------------------------------

export const PROVIDERS = {
  gemini: {
    name: "gemini",
    isConfigured: (env) => Boolean(env.GEMINI_API_KEY),
    generate: (request, env) => callGemini(request, env),
  },
  groq: {
    name: "groq",
    isConfigured: (env) => Boolean(env.GROQ_API_KEY),
    generate: (request, env) =>
      callOpenAICompatible({
        providerName: "groq",
        baseURL: "https://api.groq.com/openai/v1/chat/completions",
        apiKey: env.GROQ_API_KEY,
        model: modelFor("groq", env),
        request,
      }),
  },
  cerebras: {
    name: "cerebras",
    isConfigured: (env) => Boolean(env.CEREBRAS_API_KEY),
    generate: (request, env) =>
      callOpenAICompatible({
        providerName: "cerebras",
        baseURL: "https://api.cerebras.ai/v1/chat/completions",
        apiKey: env.CEREBRAS_API_KEY,
        model: modelFor("cerebras", env),
        request,
      }),
  },
  cohere: {
    name: "cohere",
    isConfigured: (env) => Boolean(env.COHERE_API_KEY),
    generate: (request, env) => callCohere(request, env),
  },
  deepseek: {
    name: "deepseek",
    isConfigured: (env) => Boolean(env.DEEPSEEK_API_KEY),
    generate: (request, env) =>
      callOpenAICompatible({
        providerName: "deepseek",
        baseURL: "https://api.deepseek.com/chat/completions",
        apiKey: env.DEEPSEEK_API_KEY,
        model: modelFor("deepseek", env),
        request,
      }),
  },
};

export function describeModels(env) {
  return Object.fromEntries(
    Object.keys(PROVIDERS).map((p) => [p, modelFor(p, env)])
  );
}

// Re-exported only so callers can log a friendly note if they want.
export { logDebug };
