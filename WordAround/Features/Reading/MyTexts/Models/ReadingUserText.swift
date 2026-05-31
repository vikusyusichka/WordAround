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
    var readingFocus: ReadingFocus
    var enabledQuestionTypes: Set<ReadingQuestionType>
    var assistance: ReadingAssistanceOptions
    var sourceType: ReadingSourceType
    var detectedLevel: EssayDifficulty?
    var characterCount: Int
    var status: ReadingLibraryItemStatus
    var readingTimeSeconds: Int?

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
        averageScore: Double? = nil,
        readingFocus: ReadingFocus = .mainIdea,
        enabledQuestionTypes: Set<ReadingQuestionType> = ReadingQuestionType.defaultEnabled,
        assistance: ReadingAssistanceOptions = .default,
        sourceType: ReadingSourceType = .pastedText,
        detectedLevel: EssayDifficulty? = nil,
        characterCount: Int = 0,
        status: ReadingLibraryItemStatus = .new,
        readingTimeSeconds: Int? = nil
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
        self.readingFocus = readingFocus
        self.enabledQuestionTypes = enabledQuestionTypes
        self.assistance = assistance
        self.sourceType = sourceType
        self.detectedLevel = detectedLevel
        self.characterCount = characterCount > 0 ? characterCount : content.count
        self.status = status
        self.readingTimeSeconds = readingTimeSeconds
        if progress >= 1 || isCompleted {
            self.status = .completed
        } else if progress > 0 {
            self.status = .inProgress
        }
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
        case id, title, content, languageCode, level
        case detectedLevel
        case wordCount, estimatedReadingMinutes, preview
        case createdAt, updatedAt, lastOpenedAt
        case progress, lastReadCharacterIndex, isCompleted
        case completedSessionsCount, averageScore
        case readingFocus, enabledQuestionTypes, assistance, sourceType
        case characterCount, status, readingTimeSeconds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        languageCode = try container.decode(String.self, forKey: .languageCode)
        let legacyLevel = try container.decodeIfPresent(EssayDifficulty.self, forKey: .detectedLevel)
        if let decodedLevel = try container.decodeIfPresent(EssayDifficulty.self, forKey: .level) {
            level = decodedLevel
            detectedLevel = legacyLevel
        } else {
            level = legacyLevel ?? .b1
            detectedLevel = legacyLevel
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
        readingFocus = try container.decodeIfPresent(ReadingFocus.self, forKey: .readingFocus) ?? .mainIdea
        if let types = try container.decodeIfPresent([String].self, forKey: .enabledQuestionTypes) {
            enabledQuestionTypes = ReadingQuestionType.from(rawValues: types)
        } else {
            enabledQuestionTypes = ReadingQuestionType.defaultEnabled
        }
        assistance = try container.decodeIfPresent(ReadingAssistanceOptions.self, forKey: .assistance) ?? .default
        sourceType = try container.decodeIfPresent(ReadingSourceType.self, forKey: .sourceType) ?? .pastedText
        characterCount = try container.decodeIfPresent(Int.self, forKey: .characterCount) ?? content.count
        status = try container.decodeIfPresent(ReadingLibraryItemStatus.self, forKey: .status) ?? .new
        readingTimeSeconds = try container.decodeIfPresent(Int.self, forKey: .readingTimeSeconds)
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
        try container.encode(readingFocus, forKey: .readingFocus)
        try container.encode(enabledQuestionTypes.map(\.rawValue).sorted(), forKey: .enabledQuestionTypes)
        try container.encode(assistance, forKey: .assistance)
        try container.encode(sourceType, forKey: .sourceType)
        try container.encodeIfPresent(detectedLevel, forKey: .detectedLevel)
        try container.encode(characterCount, forKey: .characterCount)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(readingTimeSeconds, forKey: .readingTimeSeconds)
    }
}

// MARK: - Display helpers

extension ReadingUserText {
    var languageTitle: String { language.title }
    var levelTitle: String { level.title }
    var statusLabel: String { status.label }
    var focusTitle: String { readingFocus.title }

    var isUnfinished: Bool {
        (status == .inProgress || (progress > 0 && progress < 1)) && !isCompleted
    }

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
