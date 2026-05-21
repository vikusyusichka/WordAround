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
        let id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        let title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Essay practice task"
        let task = try container.decodeIfPresent(String.self, forKey: .task) ?? "Write a short essay about this topic."
        let levelString = try container.decodeIfPresent(String.self, forKey: .detectedLevel) ?? EssayDifficulty.b1.rawValue
        let level = EssayDifficulty(rawValue: levelString) ?? EssayDifficulty(rawValue: levelString.uppercased()) ?? .b1
        let estimatedTime = try container.decodeIfPresent(Int.self, forKey: .estimatedTimeMinutes) ?? 12
        let minWords = try container.decodeIfPresent(Int.self, forKey: .wordLimitMin) ?? 90
        let maxWords = try container.decodeIfPresent(Int.self, forKey: .wordLimitMax) ?? 150
        let tips = try container.decodeIfPresent([String].self, forKey: .quickTips) ?? []

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

    var wordRange: ClosedRange<Int> {
        wordLimitMin...wordLimitMax
    }

    var wordRangeText: String {
        "\(wordLimitMin)-\(wordLimitMax) words"
    }
}
