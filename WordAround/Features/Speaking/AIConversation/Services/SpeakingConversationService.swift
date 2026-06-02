import Foundation

final class SpeakingConversationService {

    private let client: SpeakingAIClient

    private let recentHistoryLimit: Int

    init(client: SpeakingAIClient, recentHistoryLimit: Int = 4) {
        self.client = client
        self.recentHistoryLimit = recentHistoryLimit
    }

    func requestReply(
        language: GrammarLanguage,
        level: EssayDifficulty,
        context: SpeakingConversationContext,
        history: [SpeakingConversationMessage],
        userMessage: String
    ) async throws -> String {
        let recent = Array(history.suffix(recentHistoryLimit))
        let prompt = Self.buildPrompt(
            language: language,
            level: level,
            context: context,
            recentMessages: recent,
            latestUserMessage: userMessage
        )
        return try await client.generateReply(prompt: prompt)
    }

    static func buildPrompt(
        language: GrammarLanguage,
        level: EssayDifficulty,
        context: SpeakingConversationContext,
        recentMessages: [SpeakingConversationMessage],
        latestUserMessage: String
    ) -> String {
        let recentLines: String
        if recentMessages.isEmpty {
            recentLines = "(no prior turns)"
        } else {
            recentLines = recentMessages
                .map { message in
                    let speaker = message.role == .ai ? "Tutor" : "Learner"
                    return "\(speaker): \(message.text)"
                }
                .joined(separator: "\n")
        }

        return """
        You are a language tutor.

        Language: \(language.title)
        Level: \(level.rawValue)
        Scenario/Topic: \(context.title) — \(context.promptContext)

        Reply naturally.
        Correct only one important mistake briefly.
        Ask one follow-up question.
        Keep reply short (1-2 sentences).
        Reply in \(language.title). Do not output JSON or markdown.

        Recent conversation:
        \(recentLines)

        Learner said:
        \(latestUserMessage)

        Return only the tutor reply.
        """
    }

    func requestHint(
        mode: SpeakingHintMode,
        language: GrammarLanguage,
        level: EssayDifficulty,
        context: SpeakingConversationContext,
        history: [SpeakingConversationMessage],
        lastUserMessage: String?
    ) async throws -> String {
        let recent = Array(history.suffix(recentHistoryLimit))
        let prompt = Self.buildHintPrompt(
            mode: mode,
            language: language,
            level: level,
            context: context,
            recentMessages: recent,
            lastUserMessage: lastUserMessage
        )
        let reply = try await client.generateReply(prompt: prompt)
        return reply.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func buildHintPrompt(
        mode: SpeakingHintMode,
        language: GrammarLanguage,
        level: EssayDifficulty,
        context: SpeakingConversationContext,
        recentMessages: [SpeakingConversationMessage],
        lastUserMessage: String?
    ) -> String {
        let lastAIQuestion = recentMessages.last(where: { $0.role == .ai })?.text
        let lastAnswer = lastUserMessage?.trimmingCharacters(in: .whitespacesAndNewlines)

        let transcript: String
        if recentMessages.isEmpty {
            transcript = "(conversation has not started yet)"
        } else {
            transcript = recentMessages
                .map { msg in "\(msg.role == .ai ? "Tutor" : "Learner"): \(msg.text)" }
                .joined(separator: "\n")
        }

        let questionLine = (lastAIQuestion?.isEmpty == false)
            ? "Tutor's last question: \(lastAIQuestion!)"
            : "There is no tutor question yet — suggest a natural way to start talking about the topic."
        let answerLine = (lastAnswer?.isEmpty == false)
            ? "Learner's last answer: \(lastAnswer!)"
            : "The learner has not answered yet."

        let levelGuidance: String
        switch level {
        case .a1, .a2:
            levelGuidance = "The learner is a beginner (\(level.rawValue)). Keep it ONE very simple, natural short sentence with basic, common words."
        default:
            levelGuidance = "Match CEFR level \(level.rawValue): natural and fluent, but still ONE short sentence the learner can comfortably say aloud."
        }

        return """
        You help a language learner by suggesting ONE example answer they could say out loud next.

        Practice mode: \(mode.promptLabel)
        Language: \(language.title)
        Level: \(level.rawValue)
        Topic: \(context.title) — \(context.description)
        Topic context: \(context.promptContext)
        \(questionLine)
        \(answerLine)

        Recent conversation:
        \(transcript)

        Write ONE example answer the learner could say next.
        Rules:
        - If there is a tutor question, the answer MUST directly and relevantly respond to it.
        - \(levelGuidance)
        - Write it in \(language.title), in the learner's own first-person voice.
        - Output ONLY the sentence itself — no translation, no quotes, no label, no explanation, no markdown.
        """
    }

    static func fallbackReply(for language: GrammarLanguage) -> String {
        switch language {
        case .spanish:    return "Te escuché. Continuemos. ¿Qué más te gustaría?"
        case .french:     return "Je t'ai entendu. Continuons. Que voudrais-tu d'autre ?"
        case .german:     return "Ich habe dich gehört. Machen wir weiter. Was möchtest du noch?"
        case .italian:    return "Ti ho sentito. Continuiamo. Cos'altro vorresti?"
        case .portuguese: return "Eu ouvi você. Vamos continuar. O que mais gostaria?"
        default:          return "I heard you. Let's continue. What else would you like?"
        }
    }

    static func fallbackBannerText(for language: GrammarLanguage) -> String {
        "AI limit reached. Using fallback."
    }

    static func hintMessage(language: GrammarLanguage, scenario: ConversationScenario) -> String {
        switch (language, scenario.id) {
        case (.english,    "cafe"):         return "Try saying: I would like a coffee, please."
        case (.spanish,    "cafe"):         return "Try saying: Quisiera un café, por favor."
        case (.french,     "cafe"):         return "Try saying: Je voudrais un café, s'il vous plaît."
        case (.german,     "cafe"):         return "Try saying: Ich hätte gern einen Kaffee, bitte."

        case (.english,    "travel"):       return "Try saying: Excuse me, how do I get to the station?"
        case (.spanish,    "travel"):       return "Try saying: Disculpa, ¿cómo llego a la estación?"
        case (.french,     "travel"):       return "Try saying: Excusez-moi, comment aller à la gare ?"
        case (.german,     "travel"):       return "Try saying: Entschuldigung, wie komme ich zum Bahnhof?"

        case (.english,    "daily-life"):   return "Try saying: I usually wake up at seven and have coffee."
        case (.spanish,    "daily-life"):   return "Try saying: Normalmente me despierto a las siete y tomo café."
        case (.french,     "daily-life"):   return "Try saying: Je me réveille à sept heures et je prends un café."
        case (.german,     "daily-life"):   return "Try saying: Ich stehe um sieben auf und trinke Kaffee."

        case (.english,    "shopping"):     return "Try saying: How much does this cost?"
        case (.spanish,    "shopping"):     return "Try saying: ¿Cuánto cuesta esto?"
        case (.french,     "shopping"):     return "Try saying: Combien ça coûte ?"
        case (.german,     "shopping"):     return "Try saying: Wie viel kostet das?"

        case (.english,    "job-interview"): return "Try saying: I have three years of experience in this field."
        case (.spanish,    "job-interview"): return "Try saying: Tengo tres años de experiencia en este campo."
        case (.french,     "job-interview"): return "Try saying: J'ai trois ans d'expérience dans ce domaine."
        case (.german,     "job-interview"): return "Try saying: Ich habe drei Jahre Erfahrung in diesem Bereich."

        case (.english,    "airport"):       return "Try saying: I'd like to check in for my flight to Paris."
        case (.spanish,    "airport"):       return "Try saying: Quisiera facturar para mi vuelo a París."
        case (.french,     "airport"):       return "Try saying: Je voudrais enregistrer mes bagages pour Paris."
        case (.german,     "airport"):       return "Try saying: Ich möchte für meinen Flug nach Paris einchecken."

        default:
            return "Try saying one short sentence about \(scenario.title.lowercased())."
        }
    }

    static func genericTopicHint(for language: GrammarLanguage) -> String {
        switch language {
        case .spanish:    return "Intenta decir una frase sencilla sobre este tema."
        case .french:     return "Essaie de dire une phrase simple sur ce sujet."
        case .german:     return "Versuch, einen einfachen Satz zu diesem Thema zu sagen."
        case .italian:    return "Prova a dire una frase semplice su questo argomento."
        case .portuguese: return "Tente dizer uma frase simples sobre este tema."
        default:          return "Try saying one simple sentence about this topic."
        }
    }

    static func localHint(for language: GrammarLanguage, context: SpeakingConversationContext) -> String {
        switch context {
        case .scenario(let scenario):
            return hintMessage(language: language, scenario: scenario)
        case .generatedTopic(let topic):
            return topicAwareLocalHint(for: language, topicTitle: topic.title)
        }
    }

    static func topicAwareLocalHint(for language: GrammarLanguage, topicTitle: String) -> String {
        let title = topicTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return genericTopicHint(for: language) }

        switch language {
        case .spanish:    return "Intenta decir qué piensas o qué te gusta sobre «\(title)»."
        case .french:     return "Essaie de dire ce que tu penses ou ce que tu aimes à propos de « \(title) »."
        case .german:     return "Sag, was du über „\(title)“ denkst oder was dir daran gefällt."
        case .italian:    return "Prova a dire cosa pensi o cosa ti piace di «\(title)»."
        case .portuguese: return "Tente dizer o que você pensa ou do que gosta sobre «\(title)»."
        default:          return "Try saying what you think or like about “\(title).”"
        }
    }
}

enum SpeakingHintMode {
    case aiConversation
    case freeSpeaking

    var promptLabel: String {
        switch self {
        case .aiConversation: return "AI Conversation (back-and-forth dialogue with a tutor)"
        case .freeSpeaking:   return "Free Speaking (the learner speaks freely about a topic, no tutor replies)"
        }
    }
}
