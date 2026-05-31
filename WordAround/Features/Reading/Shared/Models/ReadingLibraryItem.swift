import Foundation

/// Lifecycle status of a saved reading item.
enum ReadingLibraryItemStatus: String, Codable, CaseIterable {
    case new
    case inProgress
    case completed

    var label: String {
        switch self {
        case .new:        return "New"
        case .inProgress: return "In Progress"
        case .completed:  return "Completed"
        }
    }
}

/// Where a saved reading item came from.
enum ReadingSourceType: String, Codable, CaseIterable {
    case generated
    case pastedText
    case flashcardSet
    case story
    case speedPractice
    case interactive

    /// Default source type for a Reading mode id (matches `ReadingMode.id`).
    static func forMode(_ modeID: String) -> ReadingSourceType {
        switch modeID {
        case "generated-reading":   return .generated
        case "my-texts":            return .pastedText
        case "reading-from-sets":   return .flashcardSet
        case "story-mode":          return .story
        case "speed-reading":       return .speedPractice
        case "interactive-reading": return .interactive
        default:                    return .generated
        }
    }
}

/// One saved item in a Reading mode library — a generated reading, story,
/// speed session, interactive scenario or set-based reading.
///
/// Persisted in Firestore at `users/{userId}/readingItems/{id}`. `ReadingMode`
/// itself is a presentation type (holds `Color`) and is not `Codable`, so the
/// owning mode is stored as `modeID` (matches `ReadingMode.id`). Items are
/// always queried by `modeID`, so one mode's library never shows another's.
struct ReadingLibraryItem: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var userId: String
    /// Owning mode — matches `ReadingMode.id`.
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
    /// Setup selections/toggles captured at creation, so the saved item can
    /// re-open its session without showing setup again.
    var selections: [String: String]
    var toggles: [String: Bool]
    var languageCode: String

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
        languageCode: String = GrammarLanguage.english.rawValue
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
    }
}

// MARK: - Display helpers

extension ReadingLibraryItem {
    var isCompleted: Bool { status == .completed || progress >= 1 }
    var progressPercent: Int { Int((min(max(progress, 0), 1) * 100).rounded()) }
    var minutesText: String { "\(max(estimatedMinutes, 1)) min" }

    var language: GrammarLanguage { GrammarLanguage(rawValue: languageCode) ?? .english }

    var actionTitle: String {
        switch status {
        case .completed: return "Read again"
        case .inProgress: return "Continue"
        case .new: return progress > 0 ? "Continue" : "Start"
        }
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

    var scoreText: String? {
        guard let comprehensionScore else { return nil }
        return "\(Int((min(max(comprehensionScore, 0), 1) * 100).rounded()))% score"
    }

    /// Recomputes `status` from progress (used when persisting progress updates).
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
