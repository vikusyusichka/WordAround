import Foundation

struct ReadingSessionInput: Equatable {
    let id: String
    let modeID: String
    let title: String
    let fullText: String
    let language: GrammarLanguage
    let difficulty: EssayDifficulty
    let readingFocus: ReadingFocus
    let questionTypes: Set<ReadingQuestionType>
    let assistance: ReadingAssistanceOptions
    let sourceType: ReadingSourceType
    let sourceId: String?
    var metadata: [String: String]

    init(
        id: String = UUID().uuidString,
        modeID: String,
        title: String,
        fullText: String,
        language: GrammarLanguage,
        difficulty: EssayDifficulty,
        readingFocus: ReadingFocus = .mainIdea,
        questionTypes: Set<ReadingQuestionType> = ReadingQuestionType.defaultEnabled,
        assistance: ReadingAssistanceOptions = .default,
        sourceType: ReadingSourceType = .generated,
        sourceId: String? = nil,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.modeID = modeID
        self.title = title
        self.fullText = fullText
        self.language = language
        self.difficulty = difficulty
        self.readingFocus = readingFocus
        self.questionTypes = questionTypes
        self.assistance = assistance
        self.sourceType = sourceType
        self.sourceId = sourceId
        self.metadata = metadata
    }
}

extension ReadingSessionInput {
    func asUserText(analyzer: ReadingTextAnalyzing = ReadingTextAnalyzerService.shared) -> ReadingUserText {
        let wordCount = analyzer.wordCount(for: fullText)
        return ReadingUserText(
            id: id,
            title: title,
            content: fullText,
            language: language,
            level: difficulty,
            wordCount: wordCount,
            estimatedReadingMinutes: analyzer.estimatedReadingMinutes(wordCount: wordCount),
            preview: analyzer.preview(for: fullText, maxLength: 160),
            readingFocus: readingFocus,
            enabledQuestionTypes: questionTypes,
            assistance: assistance,
            sourceType: sourceType,
            status: .inProgress
        )
    }

    func makeReadingSession(
        questions: [ReadingQuestion],
        analyzer: ReadingTextAnalyzing = ReadingTextAnalyzerService.shared
    ) -> ReadingSession {
        ReadingSession(
            textId: id,
            title: title,
            content: fullText,
            language: language,
            level: difficulty,
            wordCount: analyzer.wordCount(for: fullText),
            questions: questions,
            focus: readingFocus
        )
    }

    var wordCount: Int { ReadingTextAnalyzerService.shared.wordCount(for: fullText) }
}
