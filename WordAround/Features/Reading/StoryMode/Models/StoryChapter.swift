import Foundation

struct StoryChapter: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var chapterIndex: Int
    var title: String
    var text: String
    var choices: [StoryChoice]
    var madeChoice: StoryChoice?
    var isCompleted: Bool
    var completedAt: Date?
    var scorePercent: Double?
    var readingTimeSeconds: Int?

    init(
        id: String = UUID().uuidString,
        chapterIndex: Int,
        title: String = "",
        text: String = "",
        choices: [StoryChoice] = [],
        madeChoice: StoryChoice? = nil,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        scorePercent: Double? = nil,
        readingTimeSeconds: Int? = nil
    ) {
        self.id = id
        self.chapterIndex = chapterIndex
        self.title = title.isEmpty ? "Chapter \(chapterIndex)" : title
        self.text = text
        self.choices = choices
        self.madeChoice = madeChoice
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.scorePercent = scorePercent
        self.readingTimeSeconds = readingTimeSeconds
    }

    // MARK: - Codable (additive fields decode safely from older payloads)

    enum CodingKeys: String, CodingKey {
        case id, chapterIndex, title, text, choices, madeChoice
        case isCompleted, completedAt, scorePercent, readingTimeSeconds
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        chapterIndex = try c.decodeIfPresent(Int.self, forKey: .chapterIndex) ?? 1
        let decodedTitle = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        title = decodedTitle.isEmpty ? "Chapter \(chapterIndex)" : decodedTitle
        text = try c.decodeIfPresent(String.self, forKey: .text) ?? ""
        choices = try c.decodeIfPresent([StoryChoice].self, forKey: .choices) ?? []
        madeChoice = try c.decodeIfPresent(StoryChoice.self, forKey: .madeChoice)
        isCompleted = try c.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        completedAt = try c.decodeIfPresent(Date.self, forKey: .completedAt)
        scorePercent = try c.decodeIfPresent(Double.self, forKey: .scorePercent)
        readingTimeSeconds = try c.decodeIfPresent(Int.self, forKey: .readingTimeSeconds)
    }

    // MARK: - Display helpers

    var displayTitle: String { "Chapter \(chapterIndex)" }

    var summary: String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 200 else { return trimmed }
        return String(trimmed.prefix(200)) + "…"
    }
}

// MARK: - Shared reading adapter

extension StoryChapter {
    func toReadingSessionInput(storySession: StorySession) -> ReadingSessionInput {
        ReadingSessionInput(
            id: "\(storySession.id)#\(chapterIndex)",
            modeID: "story-mode",
            title: "\(storySession.title) — \(displayTitle)",
            fullText: text,
            language: storySession.configuration.language,
            difficulty: EssayDifficulty(rawValue: storySession.configuration.difficultyTitle) ?? .b1,
            readingFocus: .mainIdea,
            questionTypes: ReadingQuestionType.defaultEnabled,
            assistance: .default,
            sourceType: .story,
            sourceId: storySession.id
        )
    }
}

