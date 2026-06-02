import Foundation

final class DebateConversationService {

    private let client: SpeakingAIClient
    private let recentHistoryLimit: Int

    init(client: SpeakingAIClient, recentHistoryLimit: Int = 4) {
        self.client = client
        self.recentHistoryLimit = recentHistoryLimit
    }


    func requestOpening(
        language: GrammarLanguage,
        level: EssayDifficulty,
        topic: GeneratedConversationTopic,
        learnerSide: DebateSide,
        aiSide: DebateSide
    ) async throws -> String {
        let prompt = Self.buildOpeningPrompt(
            language: language,
            level: level,
            topic: topic,
            learnerSide: learnerSide,
            aiSide: aiSide
        )
        return try await client.generateReply(prompt: prompt)
    }

    func requestReply(
        language: GrammarLanguage,
        level: EssayDifficulty,
        topic: GeneratedConversationTopic,
        learnerSide: DebateSide,
        aiSide: DebateSide,
        round: DebateRound,
        history: [SpeakingConversationMessage],
        userMessage: String
    ) async throws -> String {
        let recent = Array(history.suffix(recentHistoryLimit))
        let prompt = Self.buildReplyPrompt(
            language: language,
            level: level,
            topic: topic,
            learnerSide: learnerSide,
            aiSide: aiSide,
            round: round,
            recentMessages: recent,
            latestUserMessage: userMessage
        )
        return try await client.generateReply(prompt: prompt)
    }


    static func buildOpeningPrompt(
        language: GrammarLanguage,
        level: EssayDifficulty,
        topic: GeneratedConversationTopic,
        learnerSide: DebateSide,
        aiSide: DebateSide
    ) -> String {
        """
        You are a friendly but sharp debate opponent in a language learning app.

        Language: \(language.title)
        Learner level: \(level.rawValue)
        Debate topic: \(topic.title)
        Topic context: \(topic.promptContext)

        The learner will argue to \(stanceVerb(for: learnerSide)) the statement.
        You argue the opposite: you \(stanceVerb(for: aiSide)) the statement.

        Open the debate:
        - Briefly state your position on the topic.
        - Give ONE clear, level-appropriate argument for your side.
        - Invite the learner to share their opening opinion.

        Style rules:
        - Be respectful and encouraging. Never insult or attack the person.
        - Keep it short (2-3 sentences).
        - Match level \(level.rawValue) vocabulary.
        - Reply in \(language.title). Do not output JSON or markdown.

        Return only your opening statement.
        """
    }

    static func buildReplyPrompt(
        language: GrammarLanguage,
        level: EssayDifficulty,
        topic: GeneratedConversationTopic,
        learnerSide: DebateSide,
        aiSide: DebateSide,
        round: DebateRound,
        recentMessages: [SpeakingConversationMessage],
        latestUserMessage: String
    ) -> String {
        let recentLines: String
        if recentMessages.isEmpty {
            recentLines = "(no prior turns)"
        } else {
            recentLines = recentMessages
                .map { message in
                    let speaker = message.role == .ai ? "Opponent" : "Learner"
                    return "\(speaker): \(message.text)"
                }
                .joined(separator: "\n")
        }

        return """
        You are a friendly but sharp debate opponent in a language learning app.

        Language: \(language.title)
        Learner level: \(level.rawValue)
        Debate topic: \(topic.title)
        Topic context: \(topic.promptContext)

        The learner argues to \(stanceVerb(for: learnerSide)) the statement.
        You argue the opposite: you \(stanceVerb(for: aiSide)) the statement.

        Current round: \(round.title)
        This round, you should: \(round.aiInstruction)

        Style rules:
        - Stay on your side and push back on the learner's reasoning.
        - Be respectful and constructive — challenge ideas, never the person.
        - Keep it short (1-2 sentences).
        - Match level \(level.rawValue) vocabulary.
        - Reply in \(language.title). Do not output JSON or markdown.

        Recent exchange:
        \(recentLines)

        Learner just said:
        \(latestUserMessage)

        Return only your reply.
        """
    }

    private static func stanceVerb(for side: DebateSide) -> String {
        switch side {
        case .agree:      return "support"
        case .disagree:   return "oppose"
        case .surpriseMe: return "take a side on"
        }
    }


    static func fallbackOpening(for language: GrammarLanguage, topicTitle: String) -> String {
        switch language {
        case .spanish:    return "Empecemos a debatir sobre \(topicTitle). Yo no estoy de acuerdo. ¿Cuál es tu opinión?"
        case .french:     return "Commençons à débattre de \(topicTitle). Je ne suis pas d'accord. Quel est ton avis ?"
        case .german:     return "Lass uns über \(topicTitle) debattieren. Ich bin anderer Meinung. Was denkst du?"
        case .italian:    return "Iniziamo a dibattere su \(topicTitle). Io non sono d'accordo. Qual è la tua opinione?"
        case .portuguese: return "Vamos debater sobre \(topicTitle). Eu discordo. Qual é a sua opinião?"
        default:          return "Let's debate \(topicTitle). I disagree. What's your opinion?"
        }
    }

    static func fallbackReply(for language: GrammarLanguage) -> String {
        switch language {
        case .spanish:    return "Entiendo tu punto, pero no me convence del todo. ¿Por qué crees eso?"
        case .french:     return "Je comprends ton point, mais ça ne me convainc pas. Pourquoi penses-tu cela ?"
        case .german:     return "Ich verstehe dein Argument, aber es überzeugt mich nicht ganz. Warum denkst du das?"
        case .italian:    return "Capisco il tuo punto, ma non mi convince del tutto. Perché lo pensi?"
        case .portuguese: return "Entendo o seu ponto, mas não me convence totalmente. Por que você pensa assim?"
        default:          return "I see your point, but it doesn't fully convince me. Why do you think that?"
        }
    }

    static func fallbackBannerText(for language: GrammarLanguage) -> String {
        "AI limit reached. Using fallback."
    }

    /// Local-only hints; never sent to the AI or added to the transcript.
    static func localHints(for language: GrammarLanguage) -> [String] {
        switch language {
        case .spanish:
            return ["Creo que…", "Una razón es…", "En mi opinión…", "Por otro lado…", "Estoy de acuerdo porque…"]
        case .french:
            return ["Je pense que…", "Une raison est…", "À mon avis…", "D'un autre côté…", "Je suis d'accord parce que…"]
        case .german:
            return ["Ich denke, dass…", "Ein Grund ist…", "Meiner Meinung nach…", "Andererseits…", "Ich stimme zu, weil…"]
        case .italian:
            return ["Penso che…", "Una ragione è…", "Secondo me…", "D'altra parte…", "Sono d'accordo perché…"]
        case .portuguese:
            return ["Eu acho que…", "Uma razão é…", "Na minha opinião…", "Por outro lado…", "Concordo porque…"]
        default:
            return ["I think that…", "One reason is…", "In my opinion…", "On the other hand…", "I agree because…"]
        }
    }
}
