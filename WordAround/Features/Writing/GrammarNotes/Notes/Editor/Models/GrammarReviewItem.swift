import Foundation

struct GrammarReviewItem: Identifiable, Codable, Equatable {
    let id: String
    let ownerUID: String
    let sourceType: GrammarReviewSourceType
    let topicId: String
    let noteId: String?
    let quizId: String?
    var title: String
    var previewText: String
    var languageCode: String
    var languageName: String
    var priority: GrammarReviewPriority
    var dueAt: Date
    var lastReviewedAt: Date?
    var nextReviewAt: Date?
    var reviewCount: Int
    var correctStreak: Int
    var incorrectStreak: Int
    var mistakeCount: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String,
        ownerUID: String,
        sourceType: GrammarReviewSourceType,
        topicId: String,
        noteId: String? = nil,
        quizId: String? = nil,
        title: String,
        previewText: String,
        languageCode: String,
        languageName: String,
        priority: GrammarReviewPriority = .normal,
        dueAt: Date = Date(),
        lastReviewedAt: Date? = nil,
        nextReviewAt: Date? = nil,
        reviewCount: Int = 0,
        correctStreak: Int = 0,
        incorrectStreak: Int = 0,
        mistakeCount: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.ownerUID = ownerUID
        self.sourceType = sourceType
        self.topicId = topicId
        self.noteId = noteId
        self.quizId = quizId
        self.title = title
        self.previewText = previewText
        self.languageCode = languageCode
        self.languageName = languageName
        self.priority = priority
        self.dueAt = dueAt
        self.lastReviewedAt = lastReviewedAt
        self.nextReviewAt = nextReviewAt
        self.reviewCount = reviewCount
        self.correctStreak = correctStreak
        self.incorrectStreak = incorrectStreak
        self.mistakeCount = mistakeCount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension GrammarReviewItem {

    static func id(forNoteTopicId topicId: String, noteId: String) -> String {
        "note_\(topicId)_\(noteId)"
    }

    static func id(forMistakeTopicId topicId: String, noteId: String) -> String {
        "mistake_\(topicId)_\(noteId)"
    }

    static func id(forQuizTopicId topicId: String, noteId: String, quizId: String) -> String {
        "quiz_\(topicId)_\(noteId)_\(quizId)"
    }

    func applying(result: GrammarReviewResult, at now: Date = Date()) -> GrammarReviewItem {
        var copy = self
        copy.lastReviewedAt = now
        copy.updatedAt = now
        copy.reviewCount += 1
        let nextAt = now.addingTimeInterval(result.nextInterval)
        copy.nextReviewAt = nextAt
        copy.dueAt = nextAt

        switch result {
        case .easy, .good:
            copy.correctStreak += 1
            copy.incorrectStreak = 0
        case .hard:
            copy.incorrectStreak += 1
        case .forgot:
            copy.incorrectStreak += 1
            copy.correctStreak = 0
            copy.mistakeCount += 1
        }

        return copy
    }
}

extension GrammarReviewItem {

    static func preview(
        id: String = UUID().uuidString,
        sourceType: GrammarReviewSourceType = .note,
        title: String = "Ser vs Estar",
        priority: GrammarReviewPriority = .normal,
        dueAt: Date = Date()
    ) -> GrammarReviewItem {
        GrammarReviewItem(
            id: id,
            ownerUID: "preview-user",
            sourceType: sourceType,
            topicId: "preview-topic",
            noteId: "preview-note",
            quizId: sourceType == .quiz ? "preview-quiz" : nil,
            title: title,
            previewText: "Use ser for identity and permanent traits. Use estar for state, location and temporary conditions.",
            languageCode: "es",
            languageName: "Spanish",
            priority: priority,
            dueAt: dueAt,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
