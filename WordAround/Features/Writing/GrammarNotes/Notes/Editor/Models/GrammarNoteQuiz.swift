import Foundation

struct GrammarNoteQuiz: Identifiable, Codable, Equatable {
    let id: String
    let ownerUID: String
    let topicId: String
    let noteId: String
    var title: String
    var sourceNoteTitle: String
    var questions: [GrammarQuizQuestion]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        ownerUID: String,
        topicId: String,
        noteId: String,
        title: String,
        sourceNoteTitle: String = "",
        questions: [GrammarQuizQuestion] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.ownerUID = ownerUID
        self.topicId = topicId
        self.noteId = noteId
        self.title = title
        self.sourceNoteTitle = sourceNoteTitle
        self.questions = questions
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension GrammarNoteQuiz {
    static func preview(questionCount: Int = 3) -> GrammarNoteQuiz {
        let now = Date()
        var questions: [GrammarQuizQuestion] = []
        if questionCount >= 1 {
            questions.append(GrammarQuizQuestion(
                id: "pq0", type: .multipleChoice,
                questionText: "Which verb describes a permanent state or identity?",
                options: ["estar", "haber", "ser", "tener"],
                correctAnswer: "ser",
                explanation: "Ser is used for permanent or long-lasting attributes.",
                order: 0
            ))
        }
        if questionCount >= 2 {
            questions.append(GrammarQuizQuestion(
                id: "pq1", type: .trueFalse,
                questionText: "True or False: Estar is used for temporary conditions and location.",
                options: ["True", "False"],
                correctAnswer: "True",
                order: 1
            ))
        }
        if questionCount >= 3 {
            questions.append(GrammarQuizQuestion(
                id: "pq2", type: .fillGap,
                questionText: "Fill in the gap: Ella _____ en casa.",
                correctAnswer: "está",
                explanation: "Location uses estar.",
                order: 2
            ))
        }
        return GrammarNoteQuiz(
            id: "preview-quiz",
            ownerUID: "preview-user",
            topicId: "preview-topic",
            noteId: "preview-note",
            title: "Quick Quiz: Ser vs Estar",
            sourceNoteTitle: "Ser vs Estar",
            questions: Array(questions.prefix(questionCount)),
            createdAt: now.addingTimeInterval(-3600),
            updatedAt: now
        )
    }
}
