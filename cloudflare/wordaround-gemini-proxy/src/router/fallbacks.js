/**
 * Local fallbacks for the AI Provider Router.
 *
 * Used ONLY when every configured provider in a task's chain has failed.
 * The result is marked `fallbackUsed: true` by the router.
 *
 * Design choice:
 *   - For the dedicated structured endpoints (speaking topic, shadowing,
 *     pronunciation) we return safe curated content so the endpoint can still
 *     answer 200. The iOS app ALSO keeps its own richer local fallbacks as a
 *     deeper safety net (used when the Worker itself is unreachable).
 *   - For the generic `/` analysis tasks (essay, grammar quiz, speaking
 *     feedback, conversation/debate replies) we DO NOT fabricate detailed
 *     answers — `localFallback` returns `null`, the router surfaces an error,
 *     and the existing iOS-side fallback / error handling takes over. This
 *     preserves current behavior and avoids inventing fake corrections.
 *
 * The shapes returned here match the *raw* JSON the endpoint handlers expect
 * BEFORE enrichment (e.g. shadowing returns { phrases:[{text,translation,tip}] }),
 * so the same mapping code runs for AI output and fallback output alike.
 */

function pick(arr, seedStr) {
  if (!arr || arr.length === 0) return null;
  // Deterministic-ish rotation from the seed so repeated fallbacks vary.
  let h = 0;
  const s = String(seedStr ?? Math.random());
  for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) >>> 0;
  return arr[h % arr.length];
}

// --- Speaking topic --------------------------------------------------------

const TOPIC_FALLBACKS = {
  en: {
    title: "Daily conversation",
    description: "Talk about your day and ask the tutor questions.",
    openingQuestion: "Hi! How is your day going? Tell me one thing you did today.",
    promptContext:
      "Have a friendly daily-life conversation. Encourage the learner to share short personal stories.",
    category: "Daily life",
  },
  es: {
    title: "Conversación diaria",
    description: "Habla de tu día y hazle preguntas al tutor.",
    openingQuestion: "¡Hola! ¿Qué tal tu día? Cuéntame algo que hiciste hoy.",
    promptContext:
      "Mantén una conversación amistosa sobre la vida diaria. Anima al estudiante a contar historias breves.",
    category: "Daily life",
  },
  fr: {
    title: "Conversation quotidienne",
    description: "Parle de ta journée et pose des questions au tuteur.",
    openingQuestion: "Bonjour ! Comment se passe ta journée ? Raconte-moi une chose que tu as faite aujourd'hui.",
    promptContext:
      "Aie une conversation amicale sur la vie quotidienne. Encourage l'apprenant à partager de courtes histoires.",
    category: "Daily life",
  },
  de: {
    title: "Alltagsgespräch",
    description: "Sprich über deinen Tag und stelle dem Tutor Fragen.",
    openingQuestion: "Hallo! Wie läuft dein Tag? Erzähl mir eine Sache, die du heute gemacht hast.",
    promptContext:
      "Führe ein freundliches Alltagsgespräch. Ermutige den Lernenden, kurze persönliche Geschichten zu teilen.",
    category: "Daily life",
  },
};

function topicFallback(meta) {
  const code = (meta?.languageCode || "en").slice(0, 2).toLowerCase();
  return TOPIC_FALLBACKS[code] || TOPIC_FALLBACKS.en;
}

// --- Shadowing phrases -----------------------------------------------------

const SHADOWING_FALLBACKS = {
  en: [
    { text: "Could you say that again, please?", translation: "Could you say that again, please?", tip: "Stress 'again'." },
    { text: "I'm really looking forward to the weekend.", translation: "I'm really looking forward to the weekend.", tip: "Link 'looking forward'." },
    { text: "Let's meet at the usual place.", translation: "Let's meet at the usual place.", tip: "Keep it smooth and quick." },
  ],
  es: [
    { text: "¿Puedes repetirlo, por favor?", translation: "Can you repeat that, please?", tip: "Roll the soft 'r'." },
    { text: "Tengo muchas ganas de que llegue el fin de semana.", translation: "I'm really looking forward to the weekend.", tip: "Keep the rhythm even." },
    { text: "Quedamos en el sitio de siempre.", translation: "Let's meet at the usual place.", tip: "Stress 'siempre'." },
  ],
  fr: [
    { text: "Pouvez-vous répéter, s'il vous plaît ?", translation: "Can you repeat, please?", tip: "Nasal 'en'." },
    { text: "J'ai hâte d'être au week-end.", translation: "I can't wait for the weekend.", tip: "Liaison 'd'être'." },
    { text: "On se retrouve à l'endroit habituel.", translation: "Let's meet at the usual place.", tip: "Soft 'r'." },
  ],
  de: [
    { text: "Können Sie das bitte wiederholen?", translation: "Can you repeat that, please?", tip: "Crisp 'ch' is not needed here." },
    { text: "Ich freue mich schon auf das Wochenende.", translation: "I'm looking forward to the weekend.", tip: "Stress 'Wochen'." },
    { text: "Wir treffen uns am üblichen Ort.", translation: "Let's meet at the usual place.", tip: "Round the 'ü'." },
  ],
};

function shadowingFallback(meta) {
  const code = (meta?.languageCode || "en").slice(0, 2).toLowerCase();
  const set = SHADOWING_FALLBACKS[code] || SHADOWING_FALLBACKS.en;
  return { phrases: set };
}

// --- Pronunciation items ---------------------------------------------------

const PRONUNCIATION_FALLBACKS = {
  en: [
    { type: "minimalPair", text: "ship / sheep", translation: "ship / sheep", focusSound: "i vs iː", tip: "Short vs long 'ee'.", example: "The sheep is on the ship." },
    { type: "word", text: "thirty", translation: "thirty", focusSound: "th", tip: "Tongue between teeth.", example: "She is thirty years old." },
    { type: "minimalPair", text: "bat / bet", translation: "bat / bet", focusSound: "æ vs e", tip: "Open the mouth for 'bat'.", example: "I bet that's a bat." },
  ],
  es: [
    { type: "word", text: "perro", translation: "dog", focusSound: "rr", tip: "Trill the double 'r'.", example: "El perro corre." },
    { type: "minimalPair", text: "pero / perro", translation: "but / dog", focusSound: "r vs rr", tip: "Single tap vs trill.", example: "Pero el perro ladra." },
    { type: "word", text: "gente", translation: "people", focusSound: "g+e", tip: "Soft 'h' sound for 'ge'.", example: "Hay mucha gente." },
  ],
  fr: [
    { type: "word", text: "rue", translation: "street", focusSound: "u", tip: "Round the lips tightly.", example: "La rue est longue." },
    { type: "minimalPair", text: "dessus / dessous", translation: "above / below", focusSound: "u vs ou", tip: "Front vs back vowel.", example: "C'est dessus, pas dessous." },
    { type: "sound", text: "an", translation: "", focusSound: "nasal an", tip: "Let air pass through the nose.", example: "Un grand enfant." },
  ],
  de: [
    { type: "word", text: "Brötchen", translation: "bread roll", focusSound: "ö + ch", tip: "Round lips, soft 'ch'.", example: "Ich kaufe ein Brötchen." },
    { type: "minimalPair", text: "Mütter / Mutter", translation: "mothers / mother", focusSound: "ü vs u", tip: "Front vs back vowel.", example: "Die Mütter und die Mutter." },
    { type: "word", text: "ich", translation: "I", focusSound: "ich-Laut", tip: "Soft hiss, tongue high.", example: "Ich bin hier." },
  ],
};

function pronunciationFallback(meta) {
  const code = (meta?.languageCode || "en").slice(0, 2).toLowerCase();
  const set = PRONUNCIATION_FALLBACKS[code] || PRONUNCIATION_FALLBACKS.en;
  return { items: set };
}

// --- Debate / conversation text fallbacks ----------------------------------

const DEBATE_REPLY_FALLBACKS = {
  en: "I see your point, but it doesn't fully convince me. Why do you think that?",
  es: "Entiendo tu punto, pero no me convence del todo. ¿Por qué crees eso?",
  fr: "Je comprends ton point, mais ça ne me convainc pas. Pourquoi penses-tu cela ?",
  de: "Ich verstehe dein Argument, aber es überzeugt mich nicht ganz. Warum denkst du das?",
};

/**
 * Returns the local fallback payload for a task, or `null` when the task has
 * no safe local fallback (the router then returns an error so the caller's own
 * fallback/error path runs).
 *
 *   meta: { languageCode?, language?, level?, seed? }
 *
 * Returns one of:
 *   { json: <object> }   — for JSON tasks
 *   { text: <string> }   — for text tasks
 *   null                 — no fallback; surface an error instead
 */
export function localFallback(task, meta = {}) {
  switch (task) {
    case "speaking_topic_generation":
    case "debate_topic_generation":
      return { json: topicFallback(meta) };

    case "shadowing_phrase_generation":
      return { json: shadowingFallback(meta) };

    case "pronunciation_content_generation":
      return { json: pronunciationFallback(meta) };

    case "debate_ai_response":
    case "speaking_conversation": {
      const code = (meta?.languageCode || "en").slice(0, 2).toLowerCase();
      return { text: DEBATE_REPLY_FALLBACKS[code] || DEBATE_REPLY_FALLBACKS.en };
    }

    // Analysis tasks: do NOT fabricate. Let the existing iOS fallback/error
    // handling take over.
    default:
      return null;
  }
}

export { pick };
