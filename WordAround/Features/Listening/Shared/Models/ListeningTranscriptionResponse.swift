import Foundation

struct ListeningTranscriptionResponse: Equatable, Codable {
    let transcriptText: String
    let subtitles: [ListeningSubtitleCue]
    var vttText: String?
    var detectedLanguage: String?
    var durationSeconds: Double?

    var hasUsableTranscript: Bool {
        !transcriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var orderedCues: [ListeningSubtitleCue] {
        subtitles.sorted { $0.startTime < $1.startTime }
    }
}
