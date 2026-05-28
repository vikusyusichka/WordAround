import Foundation

final class SpeakingFeedbackService {

    private let client: SpeakingFeedbackAIClient

    init(client: SpeakingFeedbackAIClient = GeminiSpeakingFeedbackAIClient()) {
        self.client = client
    }

    func generateFeedback(
        language: GrammarLanguage,
        level: EssayDifficulty,
        context: SpeakingConversationContext?,
        messages: [SpeakingConversationMessage]
    ) async -> SpeakingConversationFeedback {
        let transcript = Self.buildTranscript(messages)
        let userMessages = messages.filter { $0.role == .user }

        if userMessages.isEmpty {
            #if DEBUG
            print("[FeedbackService] no user messages — skipping AI call")
            #endif
            return Self.localFallback(
                language: language,
                level: level,
                messages: messages,
                transcript: transcript,
                reason: .noUserMessages
            )
        }

        let request = SpeakingFeedbackRequest(
            language: language,
            level: level,
            scenarioOrTopicTitle: context?.title ?? "Open conversation",
            scenarioOrTopicContext: context?.promptContext ?? "Generic conversation practice.",
            messages: messages
        )

        for attempt in 1...2 {
            do {
                let dto = try await client.generateFeedback(request)
                #if DEBUG
                print("[FeedbackService] AI feedback succeeded on attempt \(attempt)")
                #endif
                return Self.makeFeedback(from: dto, transcript: transcript, isFallback: false)
            } catch {
                #if DEBUG
                print("[FeedbackService] attempt \(attempt) failed: \(error.localizedDescription)")
                #endif
                if attempt == 2 {
                    return Self.localFallback(
                        language: language,
                        level: level,
                        messages: messages,
                        transcript: transcript,
                        reason: .aiFailed
                    )
                }
            }
        }

        return Self.localFallback(
            language: language,
            level: level,
            messages: messages,
            transcript: transcript,
            reason: .aiFailed
        )
    }

    private static func makeFeedback(
        from dto: SpeakingFeedbackAIResponseDTO,
        transcript: String,
        isFallback: Bool
    ) -> SpeakingConversationFeedback {
        SpeakingConversationFeedback(
            overallScore: clampScore(dto.overallScore),
            summary: dto.summary.trimmingCharacters(in: .whitespacesAndNewlines),
            grammar: metric(
                title: "Grammar",
                icon: "checkmark.circle.fill",
                from: dto.grammar
            ),
            pronunciation: metric(
                title: "Pronunciation",
                icon: "mic.fill",
                from: dto.pronunciation
            ),
            vocabulary: metric(
                title: "Vocabulary",
                icon: "text.book.closed.fill",
                from: dto.vocabulary
            ),
            fluency: metric(
                title: "Fluency",
                icon: "waveform",
                from: dto.fluency
            ),
            corrections: dto.corrections.map { c in
                SpeakingCorrection(
                    originalText: c.originalText.trimmingCharacters(in: .whitespacesAndNewlines),
                    correctedText: c.correctedText.trimmingCharacters(in: .whitespacesAndNewlines),
                    explanation: c.explanation.trimmingCharacters(in: .whitespacesAndNewlines),
                    category: (c.category ?? "grammar").trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
            .filter { !$0.originalText.isEmpty && !$0.correctedText.isEmpty },
            transcript: transcript,
            isFallback: isFallback
        )
    }

    private static func metric(
        title: String,
        icon: String,
        from dto: SpeakingFeedbackAIResponseDTO.MetricDTO
    ) -> SpeakingFeedbackMetric {
        SpeakingFeedbackMetric(
            title: title,
            rating: dto.rating.trimmingCharacters(in: .whitespacesAndNewlines),
            score: clampScore(dto.score),
            explanation: dto.explanation.trimmingCharacters(in: .whitespacesAndNewlines),
            iconName: icon
        )
    }

    private static func clampScore(_ s: Int) -> Int {
        max(0, min(100, s))
    }

    static func buildTranscript(_ messages: [SpeakingConversationMessage]) -> String {
        messages
            .map { msg in
                let speaker = msg.role == .ai ? "Tutor" : "You"
                return "\(speaker): \(msg.text)"
            }
            .joined(separator: "\n")
    }

    private enum FallbackReason {
        case noUserMessages
        case aiFailed
    }

    private static func localFallback(
        language: GrammarLanguage,
        level: EssayDifficulty,
        messages: [SpeakingConversationMessage],
        transcript: String,
        reason: FallbackReason
    ) -> SpeakingConversationFeedback {
        let userMessages = messages.filter { $0.role == .user }
        let totalWords = userMessages.reduce(0) { $0 + Self.wordCount($1.text) }
        let uniqueWords = Self.uniqueWordCount(in: userMessages)

        let summary: String
        switch reason {
        case .noUserMessages:
            summary = "No speaking answers were recorded."
        case .aiFailed:
            if userMessages.isEmpty {
                summary = "No speaking answers were recorded."
            } else if totalWords < 12 {
                summary = "You answered briefly. Try giving longer answers next time."
            } else {
                summary = "Good practice. You kept the conversation going."
            }
        }

        let fluencyScore: Int = {
            if userMessages.isEmpty { return 0 }
            let lengthFactor = min(60, totalWords * 3)
            let turnFactor = min(30, userMessages.count * 6)
            return min(95, 10 + lengthFactor + turnFactor)
        }()

        let vocabularyScore: Int = {
            if userMessages.isEmpty { return 0 }
            return min(95, 30 + uniqueWords * 2)
        }()

        let grammarScore: Int = userMessages.isEmpty ? 0 : 70

        let pronunciationScore: Int = userMessages.isEmpty ? 0 : 65

        let overall: Int = {
            if userMessages.isEmpty { return 0 }
            let avg = (grammarScore + pronunciationScore + vocabularyScore + fluencyScore) / 4
            return min(95, avg)
        }()

        return SpeakingConversationFeedback(
            overallScore: overall,
            summary: summary,
            grammar: SpeakingFeedbackMetric(
                title: "Grammar",
                rating: ratingForScore(grammarScore, allowsZero: !userMessages.isEmpty),
                score: grammarScore,
                explanation: userMessages.isEmpty
                    ? "No user messages to evaluate."
                    : "Grammar needs full AI review. This is a neutral estimate.",
                iconName: "checkmark.circle.fill"
            ),
            pronunciation: SpeakingFeedbackMetric(
                title: "Pronunciation",
                rating: userMessages.isEmpty ? "—" : "Estimated",
                score: pronunciationScore,
                explanation: "Pronunciation needs audio analysis. This score is estimated.",
                iconName: "mic.fill"
            ),
            vocabulary: SpeakingFeedbackMetric(
                title: "Vocabulary",
                rating: ratingForScore(vocabularyScore, allowsZero: !userMessages.isEmpty),
                score: vocabularyScore,
                explanation: userMessages.isEmpty
                    ? "No user messages to evaluate."
                    : "Based on the variety of words you used.",
                iconName: "text.book.closed.fill"
            ),
            fluency: SpeakingFeedbackMetric(
                title: "Fluency",
                rating: ratingForScore(fluencyScore, allowsZero: !userMessages.isEmpty),
                score: fluencyScore,
                explanation: userMessages.isEmpty
                    ? "No user messages to evaluate."
                    : "Based on how many turns and words you produced.",
                iconName: "waveform"
            ),
            corrections: [],
            transcript: transcript,
            isFallback: true
        )
    }

    private static func ratingForScore(_ score: Int, allowsZero: Bool) -> String {
        if !allowsZero && score == 0 { return "—" }
        switch score {
        case 0..<40:    return "Needs practice"
        case 40..<65:   return "Fair"
        case 65..<80:   return "Good"
        default:        return "Great"
        }
    }

    private static func wordCount(_ text: String) -> Int {
        text
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .count
    }

    private static func uniqueWordCount(in messages: [SpeakingConversationMessage]) -> Int {
        var seen = Set<String>()
        for msg in messages {
            for token in msg.text.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber }) {
                if token.count >= 2 { seen.insert(String(token)) }
            }
        }
        return seen.count
    }
}
