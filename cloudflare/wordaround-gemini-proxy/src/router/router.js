/**
 * AIProviderRouter — the heart of the multi-provider failover system.
 *
 * Responsibilities:
 *   - pick the provider priority chain for a task type,
 *   - skip providers whose secret is missing,
 *   - skip providers currently in cooldown,
 *   - call providers in order, validating each output,
 *   - fail over to the next provider on any provider-side failure,
 *   - return a normalized response, or a local fallback when all fail.
 *
 * Cooldown is in-memory, per Worker instance (no Durable Objects / KV / DB).
 *
 * Normalized request (built by the endpoint handlers, never by iOS):
 *   { task, prompt, responseFormat:"text"|"json", temperature, maxTokens, meta }
 *
 * Normalized response:
 *   { text, json?, providerUsed, fallbackUsed, attempts }
 *   …or { error:true, reason, attempts } when nothing could serve the request.
 */

import { PROVIDERS, ProviderError } from "./providers.js";
import { validateOutput } from "./validators.js";
import { localFallback } from "./fallbacks.js";
import { logDebug, logWarn } from "./log.js";

// --- Provider priority matrix ----------------------------------------------

// Fast, latency-sensitive generation.
const FAST_CHAIN = ["groq", "cerebras", "gemini"];

// Quality / structured-reasoning tasks.
const ANALYSIS_CHAIN = ["gemini", "cohere", "deepseek", "groq"];

const TASK_KIND = {
  // FAST
  speaking_topic_generation: "fast",
  debate_topic_generation: "fast",
  debate_ai_response: "fast",
  speaking_conversation: "fast",
  shadowing_phrase_generation: "fast",
  pronunciation_content_generation: "fast",
  quick_hints: "fast",
  synonym_generation: "fast",
  translation_short: "fast",

  // ANALYSIS
  essay_generation: "analysis",
  essay_scoring: "analysis",
  essay_hints: "analysis",
  essay_assistance: "analysis",
  speaking_feedback: "analysis",
  free_speaking_feedback: "analysis",
  describe_picture_feedback: "analysis",
  debate_feedback: "analysis",
  grammar_quiz_generation: "analysis",
};

/**
 * Returns the ordered provider-name chain for a task. Unknown tasks default to
 * the ANALYSIS chain (Gemini first) — this preserves the original Worker
 * behavior for any `/` request that does not declare a task.
 */
export function chainForTask(task) {
  const kind = TASK_KIND[task] || "analysis";
  return kind === "fast" ? FAST_CHAIN : ANALYSIS_CHAIN;
}

// --- Cooldown (in-memory, per instance) ------------------------------------

const COOLDOWN_MS = 60_000;
const providerCooldowns = new Map(); // providerName -> epoch ms when it expires

export function isProviderOnCooldown(providerName) {
  const until = providerCooldowns.get(providerName);
  if (!until) return false;
  if (Date.now() >= until) {
    providerCooldowns.delete(providerName);
    return false;
  }
  return true;
}

export function markProviderCooldown(providerName, reason) {
  providerCooldowns.set(providerName, Date.now() + COOLDOWN_MS);
  logWarn(
    `cooldown set provider=${providerName} reason=${reason} for ${COOLDOWN_MS / 1000}s`
  );
}

// --- Router -----------------------------------------------------------------

/**
 * Routes a normalized AI request through the task's provider chain.
 * `request.meta` (optional) carries language/level/seed for local fallbacks.
 */
export async function routeAIRequest(request, env) {
  const chain = chainForTask(request.task);
  const attempts = [];

  logDebug(
    `task=${request.task} format=${request.responseFormat} promptChars=${
      request.prompt?.length ?? 0
    } chain=[${chain.join(" > ")}]`
  );

  for (const name of chain) {
    const provider = PROVIDERS[name];
    if (!provider) continue;

    if (!provider.isConfigured(env)) {
      logDebug(`skip provider=${name} reason=missing_key`);
      attempts.push({ provider: name, skipped: "missing_key" });
      continue;
    }

    if (isProviderOnCooldown(name)) {
      logDebug(`skip provider=${name} reason=cooldown`);
      attempts.push({ provider: name, skipped: "cooldown" });
      continue;
    }

    try {
      const rawText = await provider.generate(request, env);
      const validation = validateOutput(request, rawText);

      if (!validation.ok) {
        logWarn(`validation_failed provider=${name} reason=${validation.reason}`);
        attempts.push({ provider: name, status: "invalid", reason: validation.reason });
        continue; // fail over
      }

      logDebug(`success provider=${name}`);
      attempts.push({ provider: name, status: "ok" });
      return {
        text: validation.text,
        json: validation.json,
        providerUsed: name,
        fallbackUsed: false,
        attempts,
      };
    } catch (err) {
      const pe =
        err instanceof ProviderError
          ? err
          : new ProviderError(String(err?.message || err));
      if (pe.cooldown) {
        markProviderCooldown(name, pe.reason);
      }
      logWarn(
        `provider_failed provider=${name} reason=${pe.reason} status=${pe.status}`
      );
      attempts.push({
        provider: name,
        status: "error",
        reason: pe.reason,
        code: pe.status || undefined,
      });
      continue; // fail over to the next provider
    }
  }

  // Every provider in the chain failed / was skipped.
  const fb = localFallback(request.task, request.meta);
  if (fb) {
    logWarn(`all_providers_failed task=${request.task} → local fallback`);
    return {
      text: fb.text ?? (fb.json ? JSON.stringify(fb.json) : ""),
      json: fb.json,
      providerUsed: "local",
      fallbackUsed: true,
      attempts,
    };
  }

  logWarn(`all_providers_failed task=${request.task} → no local fallback (error)`);
  return { error: true, reason: "all_providers_failed", attempts };
}
