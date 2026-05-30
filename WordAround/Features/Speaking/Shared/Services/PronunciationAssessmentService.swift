import Foundation

#if canImport(MicrosoftCognitiveServicesSpeech)
import MicrosoftCognitiveServicesSpeech
#endif

// MARK: - Input

/// What the assessor is given. A real acoustic engine needs the recorded
/// audio; the transcript-similarity fallback only needs the recognized text.
enum PronunciationAudioInput {
    case audioFile(URL)
    case recognizedText(String)
}

// MARK: - Errors

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

// MARK: - Protocol

/// Abstraction over a pronunciation-assessment engine so Azure can be plugged
/// in cleanly without touching call sites.
protocol PronunciationAssessing {
    func assessPronunciation(
        audioInput: PronunciationAudioInput,
        referenceText: String,
        languageCode: String
    ) async throws -> PronunciationAssessmentResult
}

// MARK: - Azure (skeleton)

/// Real pronunciation assessment via Azure Speech.
///
/// Secure token flow (no key in the app):
///   iOS → `AzureSpeechTokenService` → Worker `/api/speech/azure-token` → Azure STS
///
/// The Microsoft Cognitive Services Speech SDK is NOT yet added to the
/// project, so the acoustic path is gated behind `#if canImport(...)`. When
/// the SDK is added (see integration notes below) the TODO block wires the
/// recorded audio + reference text into `SPXPronunciationAssessmentConfig`.
///
/// INTEGRATION NOTES (to enable real assessment):
///   1. Add the Swift package / xcframework `MicrosoftCognitiveServicesSpeech`.
///   2. Capture the user's repetition to a WAV file (the current
///      `SpeechRecognitionService` streams the mic but does not persist audio;
///      add an `AVAudioFile` tap or `AVAudioRecorder` for Shadowing only).
///   3. Pass `.audioFile(url)` here. The token + region come from the Worker.
///   4. Map `SPXPronunciationAssessmentResult` → `PronunciationAssessmentResult`.
/// Until then this throws `.notImplemented` and the caller uses the
/// transcript-similarity fallback (clearly marked as an estimate).
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

        // Secure token (region included). Proves the token flow end-to-end.
        let azure = try await tokenProvider.fetchToken()
        #if DEBUG
        print("[Pronunciation] Azure token acquired region=\(azure.region) — audio=\(audioURL.lastPathComponent)")
        #endif

        // TODO: Wire the Azure Speech SDK once the package is added:
        //   let speechConfig = try SPXSpeechConfiguration(authorizationToken: azure.token, region: azure.region)
        //   speechConfig.speechRecognitionLanguage = languageCode
        //   let audioConfig = SPXAudioConfiguration(wavFileInput: audioURL.path)
        //   let paConfig = try SPXPronunciationAssessmentConfiguration(
        //       referenceText, gradingSystem: .hundredMark, granularity: .phoneme, enableMiscue: true)
        //   let recognizer = try SPXSpeechRecognizer(speechConfiguration: speechConfig, audioConfiguration: audioConfig)
        //   try paConfig.apply(to: recognizer)
        //   let spxResult = try recognizer.recognizeOnce()
        //   let pa = SPXPronunciationAssessmentResult(spxResult)
        //   return map(pa, recognizedText: spxResult.text)
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

// MARK: - Transcript-similarity fallback

/// Honest fallback when no real acoustic engine is available. Produces a
/// `PronunciationAssessmentResult` with `isEstimate = true` so the UI clearly
/// states this is NOT real pronunciation analysis.
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

// MARK: - Factory

enum PronunciationAssessmentConfiguration {
    /// The real engine attempted first.
    static func makeAzureAssessor() -> PronunciationAssessing {
        AzurePronunciationAssessmentService()
    }

    /// The honest fallback used when the real engine is unavailable.
    static func makeFallbackAssessor() -> PronunciationAssessing {
        TranscriptSimilarityPronunciationAssessor()
    }
}
