import Foundation

struct ListeningSubtitleCue: Identifiable, Equatable, Hashable, Codable {
    let id: String
    let startTime: TimeInterval
    let endTime: TimeInterval
    let text: String
    var order: Int = 0
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

enum ListeningSubtitleBuilder {
    static func estimatedCues(transcript: String?, totalDuration: TimeInterval) -> [ListeningSubtitleCue] {
        guard let transcript,
              !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }

        let sentences = splitSentences(transcript)
        guard !sentences.isEmpty else { return [] }

        let duration = totalDuration > 0 ? totalDuration : Double(sentences.count) * 4
        let perCue = duration / Double(sentences.count)

        return sentences.enumerated().map { index, text in
            ListeningSubtitleCue(
                id: "cue-\(index)",
                startTime: Double(index) * perCue,
                endTime: Double(index + 1) * perCue,
                text: text,
                order: index
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

    static func sentenceCues(from cues: [ListeningSubtitleCue]) -> [ListeningSubtitleCue] {
        guard shouldMergeIntoSentences(cues) else { return cues }
        return mergeIntoSentences(cues)
    }

    private static func shouldMergeIntoSentences(_ cues: [ListeningSubtitleCue]) -> Bool {
        guard cues.count > 1 else { return false }
        let totalWords = cues.reduce(0) { $0 + wordCount(in: $1.text) }
        return Double(totalWords) / Double(cues.count) < 3
    }

    private static func mergeIntoSentences(_ cues: [ListeningSubtitleCue]) -> [ListeningSubtitleCue] {
        let maxWords = 14
        let maxDuration: TimeInterval = 8
        var merged: [ListeningSubtitleCue] = []
        var index = 0

        while index < cues.count {
            var texts = [cues[index].text.trimmingCharacters(in: .whitespacesAndNewlines)]
            var startTime = cues[index].startTime
            var endTime = cues[index].endTime
            var next = index + 1

            while next < cues.count {
                let previous = texts[texts.count - 1]
                if endsSentence(previous) { break }

                let candidate = cues[next].text.trimmingCharacters(in: .whitespacesAndNewlines)
                let combinedCount = wordCount(in: texts.joined(separator: " ")) + wordCount(in: candidate)
                let duration = cues[next].endTime - startTime
                if combinedCount > maxWords || duration > maxDuration { break }

                texts.append(candidate)
                endTime = cues[next].endTime
                next += 1
            }

            let text = texts.joined(separator: " ")
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !text.isEmpty {
                merged.append(ListeningSubtitleCue(
                    id: "cue-\(merged.count)",
                    startTime: startTime,
                    endTime: endTime,
                    text: text,
                    order: merged.count
                ))
            }

            index = next > index + 1 ? next : index + 1
        }

        return merged
    }

    private static func wordCount(in text: String) -> Int {
        text.split(whereSeparator: \.isWhitespace).filter { !$0.isEmpty }.count
    }

    private static func endsSentence(_ text: String) -> Bool {
        text.range(of: #"[.!?]["']?\s*$"#, options: .regularExpression) != nil
    }
}
