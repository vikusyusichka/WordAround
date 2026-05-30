import Foundation

final class SpeakingFeedbackService {

    private let client: SpeakingFeedbackAIClient

    init(client: SpeakingFeedbackAIClient = GeminiSpeakingFeedbackAIClient()) {
        self.client = client
    }

    /// Generates speaking feedback. Returns the feedback along with an
    /// optional human-readable fallback reason. When `fallbackReason` is
    /// non-nil the feedback is the local fallback. The reason is intended
    /// for surfacing in a result-screen banner (e.g. "AI feedback
    /// unavailable (decode error). Showing basic feedback.").
    func generateFeedback(
        language: GrammarLanguage,
        level: EssayDifficulty,
        context: SpeakingConversationContext?,
        messages: [SpeakingConversationMessage],
        includeDebateMetrics: Bool = false
    ) async -> (feedback: SpeakingConversationFeedback, fallbackReason: String?) {
        let transcript = Self.buildTranscript(messages)
        let userMessages = messages.filter { $0.role == .user }
        let userChars = userMessages.reduce(0) { $0 + $1.text.count }

        #if DEBUG
        let host = (GrammarQuizAIConfiguration.endpointURL?.host) ?? "<none>"
        let path = GrammarQuizAIConfiguration.endpointURL?.path ?? ""
        print("[FeedbackService] start userMessages=\(userMessages.count) transcriptChars=\(userChars) endpointHost=\(host) path='\(path.isEmpty ? "/" : path)' lang=\(language.title) level=\(level.rawValue)")
        #endif

        if userMessages.isEmpty {
            #if DEBUG
            print("[FeedbackService] fallback reason=noUserMessages — skipping AI call")
            #endif
            let fb = Self.localFallback(
                language: language,
                level: level,
                messages: messages,
                transcript: transcript,
                reason: .noUserMessages,
                includeDebateMetrics: includeDebateMetrics
            )
            return (fb, "No speaking answers were recorded.")
        }

        let request = SpeakingFeedbackRequest(
            language: language,
            level: level,
            scenarioOrTopicTitle: context?.title ?? "Open conversation",
            scenarioOrTopicContext: context?.promptContext ?? "Generic conversation practice.",
            messages: messages,
            includeDebateMetrics: includeDebateMetrics
        )

        var lastError: String = "unknown error"
        for attempt in 1...2 {
            #if DEBUG
            print("[FeedbackService] AI attempt \(attempt) — request started")
            #endif
            do {
                let dto = try await client.generateFeedback(request)
                #if DEBUG
                print("[FeedbackService] AI attempt \(attempt) — request finished OK")
                #endif
                return (Self.makeFeedback(from: dto, transcript: transcript, isFallback: false), nil)
            } catch let error as SpeakingFeedbackAIClientError {
                lastError = Self.shortDescription(for: error)
                #if DEBUG
                print("[FeedbackService] AI attempt \(attempt) failed: \(error.errorDescription ?? lastError)")
                #endif
            } catch {
                lastError = error.localizedDescription
                #if DEBUG
                print("[FeedbackService] AI attempt \(attempt) failed (unknown): \(error.localizedDescription)")
                #endif
            }
        }

        #if DEBUG
        print("[FeedbackService] fallback reason=aiFailed lastError='\(lastError)'")
        #endif
        let fb = Self.localFallback(
            language: language,
            level: level,
            messages: messages,
            transcript: transcript,
            reason: .aiFailed,
            includeDebateMetrics: includeDebateMetrics
        )
        return (fb, "AI feedback unavailable (\(lastError)). Showing basic feedback.")
    }

    private static func shortDescription(for error: SpeakingFeedbackAIClientError) -> String {
        switch error {
        case .notConfigured:                return "not configured"
        case .invalidResponse:              return "invalid response"
        case .serverError(let code, _):     return "server \(code)"
        case .validationFailed(let reason): return "validation: \(reason)"
        case .network:                      return "network error"
        }
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
            extraMetrics: Self.debateMetrics(from: dto),
            transcript: transcript,
            isFallback: isFallback
        )
    }

    /// Maps the optional debate score blocks (if the AI returned them) into
    /// extra metrics shown after the four core ones.
    private static func debateMetrics(from dto: SpeakingFeedbackAIResponseDTO) -> [SpeakingFeedbackMetric] {
        var result: [SpeakingFeedbackMetric] = []
        if let argument = dto.argumentQuality {
            result.append(metric(title: "Argument Quality", icon: "scalemass.fill", from: argument))
        }
        if let persuasiveness = dto.persuasiveness {
            result.append(metric(title: "Persuasiveness", icon: "megaphone.fill", from: persuasiveness))
        }
        if let structure = dto.structure {
            result.append(metric(title: "Structure", icon: "list.bullet.rectangle.fill", from: structure))
        }
        return result
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
        reason: FallbackReason,
        includeDebateMetrics: Bool = false
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

        let extraMetrics: [SpeakingFeedbackMetric] = includeDebateMetrics
            ? debateFallbackMetrics(
                userMessageCount: userMessages.count,
                totalWords: totalWords,
                hasUserMessages: !userMessages.isEmpty
            )
            : []

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
            extraMetrics: extraMetrics,
            transcript: transcript,
            isFallback: true
        )
    }

    private static func debateFallbackMetrics(
        userMessageCount: Int,
        totalWords: Int,
        hasUserMessages: Bool
    ) -> [SpeakingFeedbackMetric] {
        guard hasUserMessages else {
            return [
                SpeakingFeedbackMetric(title: "Argument Quality", rating: "—", score: 0, explanation: "No arguments to evaluate.", iconName: "scalemass.fill"),
                SpeakingFeedbackMetric(title: "Persuasiveness", rating: "—", score: 0, explanation: "No arguments to evaluate.", iconName: "megaphone.fill"),
                SpeakingFeedbackMetric(title: "Structure", rating: "—", score: 0, explanation: "No arguments to evaluate.", iconName: "list.bullet.rectangle.fill")
            ]
        }

        let argumentScore = min(95, 30 + totalWords * 2)
        let persuasivenessScore = min(95, 25 + userMessageCount * 8 + totalWords)
        let structureScore = min(95, 35 + userMessageCount * 6)

        return [
            SpeakingFeedbackMetric(
                title: "Argument Quality",
                rating: ratingForScore(argumentScore, allowsZero: true),
                score: argumentScore,
                explanation: "Estimated from how much reasoning you gave. Full AI review needed.",
                iconName: "scalemass.fill"
            ),
            SpeakingFeedbackMetric(
                title: "Persuasiveness",
                rating: ratingForScore(persuasivenessScore, allowsZero: true),
                score: persuasivenessScore,
                explanation: "Estimated from how actively you argued your case.",
                iconName: "megaphone.fill"
            ),
            SpeakingFeedbackMetric(
                title: "Structure",
                rating: ratingForScore(structureScore, allowsZero: true),
                score: structureScore,
                explanation: "Estimated from how many turns you organised your points across.",
                iconName: "list.bullet.rectangle.fill"
            )
        ]
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
