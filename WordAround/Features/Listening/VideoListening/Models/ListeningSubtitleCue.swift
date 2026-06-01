import Foundation

/// A single timed subtitle line. Timing may be estimated when a real timed
/// track (e.g. WebVTT) isn't available — see `ListeningSubtitleBuilder`.
struct ListeningSubtitleCue: Identifiable, Equatable, Hashable {
    let id: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let text: String
    var translation: String?

    func contains(time: TimeInterval) -> Bool {
        time >= startTime && time < endTime
    }

    var timecodeText: String {
        let minutes = Int(startTime) / 60
        let seconds = Int(startTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// Loading lifecycle for a video's subtitle track.
enum ListeningSubtitleLoadState: Equatable {
    case idle
    case loading
    case loaded
    case unavailable
    case failed(String)
}

/// Builds subtitle cues for the placeholder subtitle architecture. Until a real
/// timed-subtitle source is wired in, cues are estimated by evenly distributing
/// transcript sentences across the known video duration. The timing is
/// approximate; the model/UI are ready for accurate cues later.
enum ListeningSubtitleBuilder {
    static func estimatedCues(transcript: String?, totalDuration: TimeInterval) -> [ListeningSubtitleCue] {
        guard let transcript,
              !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }

        let sentences = splitSentences(transcript)
        guard !sentences.isEmpty else { return [] }

        // Fall back to ~4 s per line when duration is unknown.
        let duration = totalDuration > 0 ? totalDuration : Double(sentences.count) * 4
        let perCue = duration / Double(sentences.count)

        return sentences.enumerated().map { index, text in
            ListeningSubtitleCue(
                id: "cue-\(index)",
                startTime: Double(index) * perCue,
                endTime: Double(index + 1) * perCue,
                text: text
            )
        }
    }

    private static func splitSentences(_ text: String) -> [String] {
        var result: [String] = []
        text.enumerateSubstrings(in: text.startIndex..., options: .bySentences) { substring, _, _, _ in
            if let sentence = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !sentence.isEmpty {
                result.append(sentence)
            }
        }
        if result.isEmpty {
            result = text
                .split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        return result
    }
}
