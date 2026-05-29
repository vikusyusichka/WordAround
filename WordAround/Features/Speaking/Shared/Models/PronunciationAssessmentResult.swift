import Foundation

/// Result of a real pronunciation assessment (e.g. Azure Pronunciation
/// Assessment). All scores are 0...100.
///
/// `isEstimate` distinguishes a genuine acoustic assessment from a
/// transcript-similarity fallback so the UI can be honest about it.
struct PronunciationAssessmentResult: Equatable {
    let pronunciationScore: Double
    let accuracyScore: Double
    let fluencyScore: Double
    let completenessScore: Double
    let recognizedText: String
    let wordResults: [PronunciationWordResult]

    /// True when these numbers came from transcript similarity rather than a
    /// real acoustic engine. The UI must surface an honest warning.
    let isEstimate: Bool

    init(
        pronunciationScore: Double,
        accuracyScore: Double,
        fluencyScore: Double,
        completenessScore: Double,
        recognizedText: String,
        wordResults: [PronunciationWordResult],
        isEstimate: Bool = false
    ) {
        self.pronunciationScore = pronunciationScore
        self.accuracyScore = accuracyScore
        self.fluencyScore = fluencyScore
        self.completenessScore = completenessScore
        self.recognizedText = recognizedText
        self.wordResults = wordResults
        self.isEstimate = isEstimate
    }

    /// Words the engine flagged as mispronounced, omitted or otherwise weak.
    var weakWords: [PronunciationWordResult] {
        wordResults.filter { $0.isWeak }
    }
}

/// Per-word breakdown from the assessment engine.
struct PronunciationWordResult: Identifiable, Equatable {
    let id: UUID
    let word: String
    let accuracyScore: Double
    /// Azure error types: "None", "Mispronunciation", "Omission", "Insertion".
    let errorType: String
    let phonemeResults: [PronunciationPhonemeResult]?

    init(
        id: UUID = UUID(),
        word: String,
        accuracyScore: Double,
        errorType: String = "None",
        phonemeResults: [PronunciationPhonemeResult]? = nil
    ) {
        self.id = id
        self.word = word
        self.accuracyScore = accuracyScore
        self.errorType = errorType
        self.phonemeResults = phonemeResults
    }

    var isWeak: Bool {
        let normalized = errorType.lowercased()
        return (normalized != "none" && !normalized.isEmpty) || accuracyScore < 60
    }
}

/// Optional phoneme-level detail when the engine provides it.
struct PronunciationPhonemeResult: Identifiable, Equatable {
    let id: UUID
    let phoneme: String
    let accuracyScore: Double

    init(id: UUID = UUID(), phoneme: String, accuracyScore: Double) {
        self.id = id
        self.phoneme = phoneme
        self.accuracyScore = accuracyScore
    }
}
