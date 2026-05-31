import Foundation

struct ReadingUserText: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var title: String
    var content: String
    var languageCode: String
    var level: EssayDifficulty
    var wordCount: Int
    var estimatedReadingMinutes: Int
    var preview: String
    var createdAt: Date
    var updatedAt: Date
    var lastOpenedAt: Date?
    var progress: Double
    var lastReadCharacterIndex: Int
    var isCompleted: Bool
    var completedSessionsCount: Int
    var averageScore: Double?

    var language: GrammarLanguage {
        get { GrammarLanguage(rawValue: languageCode) ?? .english }
        set { languageCode = newValue.rawValue }
    }

    init(
        id: String = UUID().uuidString,
        title: String,
        content: String,
        language: GrammarLanguage,
        level: EssayDifficulty,
        wordCount: Int,
        estimatedReadingMinutes: Int,
        preview: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastOpenedAt: Date? = nil,
        progress: Double = 0,
        lastReadCharacterIndex: Int = 0,
        isCompleted: Bool = false,
        completedSessionsCount: Int = 0,
        averageScore: Double? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.languageCode = language.rawValue
        self.level = level
        self.wordCount = wordCount
        self.estimatedReadingMinutes = estimatedReadingMinutes
        self.preview = preview
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastOpenedAt = lastOpenedAt
        self.progress = min(max(progress, 0), 1)
        self.lastReadCharacterIndex = lastReadCharacterIndex
        self.isCompleted = isCompleted || progress >= 1
        self.completedSessionsCount = completedSessionsCount
        self.averageScore = averageScore
    }

    mutating func clampProgress() {
        progress = min(max(progress, 0), 1)
        if progress >= 1 {
            isCompleted = true
            progress = 1
        }
    }

    // MARK: - Codable (legacy field support)

    enum CodingKeys: String, CodingKey {
        case id, title, content, languageCode, level, detectedLevel
        case wordCount, estimatedReadingMinutes, preview
        case createdAt, updatedAt, lastOpenedAt
        case progress, lastReadCharacterIndex, isCompleted
        case completedSessionsCount, averageScore
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        languageCode = try container.decode(String.self, forKey: .languageCode)
        if let decodedLevel = try container.decodeIfPresent(EssayDifficulty.self, forKey: .level) {
            level = decodedLevel
        } else {
            level = try container.decodeIfPresent(EssayDifficulty.self, forKey: .detectedLevel) ?? .b1
        }
        wordCount = try container.decodeIfPresent(Int.self, forKey: .wordCount) ?? 0
        estimatedReadingMinutes = try container.decodeIfPresent(Int.self, forKey: .estimatedReadingMinutes) ?? 1
        preview = try container.decodeIfPresent(String.self, forKey: .preview) ?? ""
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        lastOpenedAt = try container.decodeIfPresent(Date.self, forKey: .lastOpenedAt)
        progress = try container.decodeIfPresent(Double.self, forKey: .progress) ?? 0
        lastReadCharacterIndex = try container.decodeIfPresent(Int.self, forKey: .lastReadCharacterIndex) ?? 0
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        completedSessionsCount = try container.decodeIfPresent(Int.self, forKey: .completedSessionsCount) ?? 0
        averageScore = try container.decodeIfPresent(Double.self, forKey: .averageScore)
        clampProgress()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(content, forKey: .content)
        try container.encode(languageCode, forKey: .languageCode)
        try container.encode(level, forKey: .level)
        try container.encode(wordCount, forKey: .wordCount)
        try container.encode(estimatedReadingMinutes, forKey: .estimatedReadingMinutes)
        try container.encode(preview, forKey: .preview)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(lastOpenedAt, forKey: .lastOpenedAt)
        try container.encode(progress, forKey: .progress)
        try container.encode(lastReadCharacterIndex, forKey: .lastReadCharacterIndex)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encode(completedSessionsCount, forKey: .completedSessionsCount)
        try container.encodeIfPresent(averageScore, forKey: .averageScore)
    }
}

// MARK: - Display helpers

extension ReadingUserText {
    var languageTitle: String { language.title }
    var levelTitle: String { level.title }

    var isUnfinished: Bool { progress > 0 && progress < 1 && !isCompleted }

    var actionTitle: String {
        if isCompleted { return "Read again" }
        return progress > 0 ? "Continue" : "Start"
    }

    var dateText: String {
        if let lastOpenedAt, progress > 0 {
            return "Opened \(Self.relativeDate(lastOpenedAt))"
        }
        return "Added \(Self.relativeDate(createdAt))"
    }

    var lastOpenedText: String {
        guard let lastOpenedAt else { return "Never" }
        return Self.relativeDate(lastOpenedAt)
    }

    var createdAtText: String { Self.relativeDate(createdAt) }

    private static func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
