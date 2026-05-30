/**
 * Output validation for the AI Provider Router.
 *
 * For `responseFormat === "text"` we only require non-empty trimmed text.
 *
 * For `responseFormat === "json"` we:
 *   1. strip Markdown ```json fences a provider may wrap the JSON in,
 *   2. parse the JSON (reject malformed),
 *   3. validate the required fields for the task type.
 *
 * A failed validation makes the router fail over to the next provider, exactly
 * like an HTTP error would. The returned `text` for JSON tasks is the
 * re-minified JSON string so the iOS clients (which parse the `text` field
 * and run their OWN decoders) keep working unchanged.
 */

/** Strips ```json … ``` / ``` … ``` fences and surrounding prose. */
export function stripJSONFences(raw) {
  let s = String(raw ?? "").trim();

  if (s.startsWith("```")) {
    const firstNewline = s.indexOf("\n");
    if (firstNewline !== -1) {
      s = s.slice(firstNewline + 1);
    }
    if (s.endsWith("```")) {
      s = s.slice(0, -3);
    }
    s = s.trim();
  }

  // If there is stray prose around the JSON, grab the first balanced object
  // or array. Cheap heuristic: from first { or [ to the matching last } or ].
  const firstBrace = s.indexOf("{");
  const firstBracket = s.indexOf("[");
  let start = -1;
  let open = "{";
  let close = "}";
  if (firstBrace !== -1 && (firstBracket === -1 || firstBrace < firstBracket)) {
    start = firstBrace;
  } else if (firstBracket !== -1) {
    start = firstBracket;
    open = "[";
    close = "]";
  }
  if (start > 0) {
    const lastClose = s.lastIndexOf(close);
    if (lastClose > start) {
      s = s.slice(start, lastClose + 1);
    }
  }

  return s.trim();
}

function isNonEmptyString(v) {
  return typeof v === "string" && v.trim().length > 0;
}

function hasScoreBlock(block) {
  return (
    block &&
    typeof block === "object" &&
    "score" in block &&
    "rating" in block
  );
}

/**
 * Per-task required-field checks. Returns `null` when valid, or a short reason
 * string when invalid. Kept deliberately loose: it mirrors what the iOS
 * decoders truly need so a perfectly good Gemini response is never rejected.
 */
function validateJSONForTask(task, data) {
  switch (task) {
    case "speaking_topic_generation":
    case "debate_topic_generation": {
      // Accept either canonical or legacy field names (the iOS client maps
      // description<-prompt, openingQuestion<-firstAIMessage, etc.).
      const title = data?.title;
      const description = data?.description ?? data?.prompt;
      const opening = data?.openingQuestion ?? data?.firstAIMessage;
      if (!isNonEmptyString(title)) return "missing_title";
      if (!isNonEmptyString(description)) return "missing_description";
      if (!isNonEmptyString(opening)) return "missing_openingQuestion";
      return null;
    }

    case "speaking_feedback":
    case "free_speaking_feedback":
    case "describe_picture_feedback":
    case "debate_feedback": {
      if (typeof data?.overallScore !== "number") return "missing_overallScore";
      if (!isNonEmptyString(data?.summary)) return "missing_summary";
      if (!hasScoreBlock(data?.grammar)) return "missing_grammar";
      if (!hasScoreBlock(data?.pronunciation)) return "missing_pronunciation";
      if (!hasScoreBlock(data?.vocabulary)) return "missing_vocabulary";
      if (!hasScoreBlock(data?.fluency)) return "missing_fluency";
      if (!Array.isArray(data?.corrections)) return "missing_corrections";
      return null;
    }

    case "shadowing_phrase_generation": {
      if (!Array.isArray(data?.phrases) || data.phrases.length === 0) {
        return "missing_phrases";
      }
      const ok = data.phrases.some((p) => isNonEmptyString(p?.text));
      return ok ? null : "phrases_without_text";
    }

    case "pronunciation_content_generation": {
      if (!Array.isArray(data?.items) || data.items.length === 0) {
        return "missing_items";
      }
      const ok = data.items.some((it) => isNonEmptyString(it?.text));
      return ok ? null : "items_without_text";
    }

    case "grammar_quiz_generation": {
      if (!Array.isArray(data?.questions) || data.questions.length === 0) {
        return "missing_questions";
      }
      return null;
    }

    // Essay tasks intentionally use lenient validation: the iOS app decodes
    // several different shapes (task, hint, scoring) and runs its own checks.
    // We only guard against "not a JSON object".
    case "essay_generation":
    case "essay_scoring":
    case "essay_hints":
    case "essay_assistance":
    default: {
      if (data && typeof data === "object") return null;
      return "not_an_object";
    }
  }
}

/**
 * Validates a provider's raw text against the request.
 * Returns { ok: true, text, json? } or { ok: false, reason }.
 */
export function validateOutput(request, rawText) {
  if (request.responseFormat === "json") {
    const cleaned = stripJSONFences(rawText);
    let parsed;
    try {
      parsed = JSON.parse(cleaned);
    } catch {
      return { ok: false, reason: "invalid_json" };
    }
    const fieldReason = validateJSONForTask(request.task, parsed);
    if (fieldReason) {
      return { ok: false, reason: `schema:${fieldReason}` };
    }
    // Hand back a clean minified JSON string so `{ text }` consumers keep
    // working, plus the parsed object for structured endpoints.
    return { ok: true, json: parsed, text: JSON.stringify(parsed) };
  }

  // Plain text.
  const text = String(rawText ?? "").trim();
  if (text.length === 0) {
    return { ok: false, reason: "empty_text" };
  }
  return { ok: true, text };
}
