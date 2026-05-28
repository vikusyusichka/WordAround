import Foundation

struct GeneratedEssayTask: Codable, Equatable, Identifiable {
    let id: UUID
    let title: String
    let task: String
    let detectedLevel: EssayDifficulty
    let estimatedTimeMinutes: Int
    let wordLimitMin: Int
    let wordLimitMax: Int
    let quickTips: [String]

    init(
        id: UUID = UUID(),
        title: String,
        task: String,
        detectedLevel: EssayDifficulty,
        estimatedTimeMinutes: Int,
        wordLimitMin: Int,
        wordLimitMax: Int,
        quickTips: [String]
    ) {
        self.id = id
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.task = task.trimmingCharacters(in: .whitespacesAndNewlines)
        self.detectedLevel = detectedLevel
        self.estimatedTimeMinutes = estimatedTimeMinutes
        self.wordLimitMin = wordLimitMin
        self.wordLimitMax = wordLimitMax

        let cleanedTips = quickTips
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let fallbackTips = ["Plan your ideas", "Use clear examples", "Check verb forms"]
        self.quickTips = Array((cleanedTips + fallbackTips).prefix(3))
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case task
        case detectedLevel
        case estimatedTimeMinutes
        case wordLimitMin
        case wordLimitMax
        case quickTips
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        let title = (try? container.decode(String.self, forKey: .title)) ?? "Essay practice task"
        let task = (try? container.decode(String.self, forKey: .task)) ?? "Write a short essay about this topic."
        let levelString = (try? container.decode(String.self, forKey: .detectedLevel)) ?? EssayDifficulty.b1.rawValue
        let level = EssayDifficulty(rawValue: levelString)
            ?? EssayDifficulty(rawValue: levelString.uppercased())
            ?? EssayDifficulty(rawValue: levelString.capitalized)
            ?? .b1
        let estimatedTime = Self.decodeInt(from: container, key: .estimatedTimeMinutes) ?? 12
        let minWords = Self.decodeInt(from: container, key: .wordLimitMin) ?? 90
        let maxWords = Self.decodeInt(from: container, key: .wordLimitMax) ?? 150
        let tips = Self.decodeStringArray(from: container, key: .quickTips)

        self.init(
            id: id,
            title: title,
            task: task,
            detectedLevel: level,
            estimatedTimeMinutes: estimatedTime,
            wordLimitMin: minWords,
            wordLimitMax: maxWords,
            quickTips: tips
        )
    }

    /// Accepts the integer either as a JSON number (`12`) or as a JSON
    /// string (`"12"`). Gemini in `responseMimeType: application/json`
    /// mode occasionally emits numeric fields as strings (especially in
    /// non-English target languages), and the default
    /// `decodeIfPresent(Int.self, ...)` rejects that with a typeMismatch
    /// error that bubbles up and fails the entire decode.
    private static func decodeInt(
        from container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> Int? {
        if let int = try? container.decode(Int.self, forKey: key) {
            return int
        }
        if let double = try? container.decode(Double.self, forKey: key) {
            return Int(double)
        }
        if let raw = try? container.decode(String.self, forKey: key) {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            return Int(trimmed) ?? Double(trimmed).map(Int.init)
        }
        return nil
    }

    /// Accepts the tips either as a JSON array of strings or as a single
    /// comma- / semicolon- / newline-separated string. Same robustness
    /// goal as `decodeInt(from:key:)`.
    private static func decodeStringArray(
        from container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> [String] {
        if let array = try? container.decode([String].self, forKey: key) {
            return array
        }
        if let joined = try? container.decode(String.self, forKey: key) {
            return joined
                .split(whereSeparator: { $0 == "," || $0 == "\n" || $0 == ";" })
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        return []
    }

    var wordRange: ClosedRange<Int> {
        wordLimitMin...wordLimitMax
    }

    var wordRangeText: String {
        "\(wordLimitMin)-\(wordLimitMax) words"
    }
}
