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
        case .generatedTopic:
            return genericTopicHint(for: language)
        }
    }
}
