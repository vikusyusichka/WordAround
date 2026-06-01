import Foundation

struct ReadingSession: Identifiable, Codable, Equatable {
    let id: String
    let textId: String
    let title: String
    let content: String
    var languageCode: String
    var level: EssayDifficulty
    var wordCount: Int
    let startedAt: Date
    var completedAt: Date?
    var readingTimeSeconds: Int
    var questions: [ReadingQuestion]
    var answers: [ReadingAnswer]
    var result: ReadingResult?
    var focus: ReadingFocus?

    var language: GrammarLanguage {
        get { GrammarLanguage(rawValue: languageCode) ?? .english }
        set { languageCode = newValue.rawValue }
    }

    init(
        id: String = UUID().uuidString,
        textId: String,
        title: String,
        content: String,
        language: GrammarLanguage,
        level: EssayDifficulty,
        wordCount: Int,
        startedAt: Date = Date(),
        completedAt: Date? = nil,
        readingTimeSeconds: Int = 0,
        questions: [ReadingQuestion] = [],
        answers: [ReadingAnswer] = [],
        result: ReadingResult? = nil,
        focus: ReadingFocus? = nil
    ) {
        self.id = id
        self.textId = textId
        self.title = title
        self.content = content
        self.languageCode = language.rawValue
        self.level = level
        self.wordCount = wordCount
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.readingTimeSeconds = readingTimeSeconds
        self.questions = questions
        self.answers = answers
        self.result = result
        self.focus = focus
    }
}
