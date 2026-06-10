import Foundation

enum ReadingLibraryItemStatus: String, Codable, CaseIterable {
    case new
    case inProgress
    case completed

    var label: String {
        switch self {
        case .new:        return L10n.string("readingStatusNew")
        case .inProgress: return L10n.string("readingStatusInProgress")
        case .completed:  return L10n.string("readingStatusCompleted")
        }
    }
}

enum ReadingSourceType: String, Codable, CaseIterable {
    case generated
    case pastedText
    case photoImport
    case pdfImport
    case flashcardSet
    case story
    case speedPractice
    case interactive
    case aiGenerated
    case exploredArticle

    static func forMode(_ modeID: String) -> ReadingSourceType {
        switch modeID {
        case "my-texts":            return .pastedText
        case "reading-from-sets":   return .flashcardSet
        case "story-mode":          return .story
        case "speed-reading":       return .speedPractice
        case "generated-reading":   return .aiGenerated
        case "interactive-reading": return .story
        default:                    return .pastedText
        }
    }
}

struct ReadingLibraryItem: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var userId: String
    var modeID: String
    var title: String
    var preview: String
    var fullText: String
    var difficulty: String
    var estimatedMinutes: Int
    var createdAt: Date
    var updatedAt: Date
    var lastOpenedAt: Date?
    var progress: Double
    var comprehensionScore: Double?
    var tags: [String]
    var sourceType: ReadingSourceType
    var sourceId: String?
    var status: ReadingLibraryItemStatus
    var selections: [String: String]
    var toggles: [String: Bool]
    var languageCode: String
    var wordCount: Int
    var characterCount: Int
    var detectedDifficulty: String
    var readingFocus: String
    var enabledQuestionTypes: [String]
    var readingTimeSeconds: Int?
    var lastReadCharacterIndex: Int

    init(
        id: String = UUID().uuidString,
        userId: String,
        modeID: String,
        title: String,
        preview: String,
        fullText: String = "",
        difficulty: String = "",
        estimatedMinutes: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastOpenedAt: Date? = nil,
        progress: Double = 0,
        comprehensionScore: Double? = nil,
        tags: [String] = [],
        sourceType: ReadingSourceType? = nil,
        sourceId: String? = nil,
        status: ReadingLibraryItemStatus = .new,
        selections: [String: String] = [:],
        toggles: [String: Bool] = [:],
        languageCode: String = GrammarLanguage.english.rawValue,
        wordCount: Int = 0,
        characterCount: Int = 0,
        detectedDifficulty: String = "",
        readingFocus: String = ReadingFocus.mainIdea.rawValue,
        enabledQuestionTypes: [String] = ReadingQuestionType.defaultEnabledRawValues,
        readingTimeSeconds: Int? = nil,
        lastReadCharacterIndex: Int = 0
    ) {
        self.id = id
        self.userId = userId
        self.modeID = modeID
        self.title = title
        self.preview = preview
        self.fullText = fullText
        self.difficulty = difficulty
        self.estimatedMinutes = estimatedMinutes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastOpenedAt = lastOpenedAt
        self.progress = min(max(progress, 0), 1)
        self.comprehensionScore = comprehensionScore
        self.tags = tags
        self.sourceType = sourceType ?? .forMode(modeID)
        self.sourceId = sourceId
        self.status = status
        self.selections = selections
        self.toggles = toggles
        self.languageCode = languageCode
        self.wordCount = wordCount
        self.characterCount = characterCount
        self.detectedDifficulty = detectedDifficulty
        self.readingFocus = readingFocus
        self.enabledQuestionTypes = enabledQuestionTypes
        self.readingTimeSeconds = readingTimeSeconds
        self.lastReadCharacterIndex = lastReadCharacterIndex
    }
}

extension ReadingLibraryItem {
    var isCompleted: Bool { status == .completed || progress >= 1 }
    var progressPercent: Int { Int((min(max(progress, 0), 1) * 100).rounded()) }
    var minutesText: String { "\(max(estimatedMinutes, 1)) min" }

    var language: GrammarLanguage { GrammarLanguage(rawValue: languageCode) ?? .english }

    var actionTitle: String {
        switch status {
        case .completed: return L10n.string("readingActionReadAgain")
        case .inProgress: return L10n.string("commonContinue")
        case .new: return progress > 0 ? L10n.string("commonContinue") : L10n.string("readingActionStart")
        }
    }

    var dateText: String {
        if let lastOpenedAt, progress > 0 {
            return String(format: L10n.string("readingOpenedFormat"), Self.relativeDate(lastOpenedAt))
        }
        return String(format: L10n.string("readingAddedFormat"), Self.relativeDate(createdAt))
    }

    var lastOpenedText: String {
        guard let lastOpenedAt else { return L10n.string("readingNever") }
        return Self.relativeDate(lastOpenedAt)
    }

    var scoreText: String? {
        guard let comprehensionScore else { return nil }
        return "\(Int((min(max(comprehensionScore, 0), 1) * 100).rounded()))% score"
    }

    static func status(forProgress progress: Double) -> ReadingLibraryItemStatus {
        if progress >= 1 { return .completed }
        if progress > 0 { return .inProgress }
        return .new
    }

    private static func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
