import Foundation

#if canImport(MicrosoftCognitiveServicesSpeech)
import MicrosoftCognitiveServicesSpeech
#endif

enum PronunciationAudioInput {
    case audioFile(URL)
    case recognizedText(String)
}

enum PronunciationAssessmentError: LocalizedError {
    case notImplemented(String)
    case unavailable(String)
    case invalidInput

    var errorDescription: String? {
        switch self {
        case .notImplemented(let m): return m
        case .unavailable(let m):    return "Pronunciation assessment unavailable: \(m)"
        case .invalidInput:          return "Pronunciation assessment received invalid input."
        }
    }
}

protocol PronunciationAssessing {
    func assessPronunciation(
        audioInput: PronunciationAudioInput,
        referenceText: String,
        languageCode: String
    ) async throws -> PronunciationAssessmentResult
}

final class AzurePronunciationAssessmentService: PronunciationAssessing {

    private let tokenProvider: AzureSpeechTokenProviding

    init(tokenProvider: AzureSpeechTokenProviding = AzureSpeechTokenService()) {
        self.tokenProvider = tokenProvider
    }

    func assessPronunciation(
        audioInput: PronunciationAudioInput,
        referenceText: String,
        languageCode: String
    ) async throws -> PronunciationAssessmentResult {
        #if canImport(MicrosoftCognitiveServicesSpeech)
        guard case let .audioFile(audioURL) = audioInput else {
            throw PronunciationAssessmentError.notImplemented(
                "Azure assessment needs an audio file. Wire WAV capture for Shadowing."
            )
        }

        let azure = try await tokenProvider.fetchToken()
        #if DEBUG
        print("[Pronunciation] Azure token acquired region=\(azure.region) — audio=\(audioURL.lastPathComponent)")
        #endif

        _ = (referenceText, languageCode)
        throw PronunciationAssessmentError.notImplemented(
            "Azure Speech SDK present, but audio-stream wiring is not finished yet."
        )
        #else
        _ = (audioInput, referenceText, languageCode, tokenProvider)
        throw PronunciationAssessmentError.notImplemented(
            "Azure Speech SDK is not installed."
        )
        #endif
    }
}

struct TranscriptSimilarityPronunciationAssessor: PronunciationAssessing {

    func assessPronunciation(
        audioInput: PronunciationAudioInput,
        referenceText: String,
        languageCode: String
    ) async throws -> PronunciationAssessmentResult {
        let recognized: String
        switch audioInput {
        case .recognizedText(let t): recognized = t
        case .audioFile:             throw PronunciationAssessmentError.invalidInput
        }

        let phrase = ShadowingPhrase(
            text: referenceText,
            languageCode: languageCode,
            level: .b1,
            category: .daily
        )
        let attempt = ShadowingComparison.evaluate(phrase: phrase, userTranscript: recognized)

        let targetTokens = ShadowingComparison.tokenize(referenceText)
        let completeness = targetTokens.isEmpty
            ? 0
            : Double(attempt.matchedWords.count) / Double(targetTokens.count) * 100

        let matchedSet = Set(attempt.matchedWords.map { $0.lowercased() })
        var words: [PronunciationWordResult] = targetTokens.map { token in
            let isMatched = matchedSet.contains(token.lowercased())
            return PronunciationWordResult(
                word: token,
                accuracyScore: isMatched ? Double(attempt.accuracy) : 0,
                errorType: isMatched ? "None" : "Omission"
            )
        }
        for extra in attempt.extraWords {
            words.append(PronunciationWordResult(word: extra, accuracyScore: 0, errorType: "Insertion"))
        }

        return PronunciationAssessmentResult(
            pronunciationScore: Double(attempt.accuracy),
            accuracyScore: Double(attempt.accuracy),
            fluencyScore: Double(attempt.accuracy),
            completenessScore: completeness.rounded(),
            recognizedText: recognized,
            wordResults: words,
            isEstimate: true
        )
    }
}

enum PronunciationAssessmentConfiguration {
    static func makeAzureAssessor() -> PronunciationAssessing {
        AzurePronunciationAssessmentService()
    }

    static func makeFallbackAssessor() -> PronunciationAssessing {
        TranscriptSimilarityPronunciationAssessor()
    }
}
