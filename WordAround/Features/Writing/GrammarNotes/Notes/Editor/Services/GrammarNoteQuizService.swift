import Foundation
import FirebaseFirestore

// MARK: - Protocol

protocol GrammarNoteQuizServicing {
    func fetchQuizzes(ownerUID: String, topicId: String, noteId: String) async throws -> [GrammarNoteQuiz]
    func createQuiz(_ quiz: GrammarNoteQuiz) async throws
    func updateQuiz(_ quiz: GrammarNoteQuiz) async throws
    func deleteQuiz(id: String, ownerUID: String, topicId: String, noteId: String) async throws
}

// MARK: - Live implementation

final class GrammarNoteQuizService: GrammarNoteQuizServicing {

    private let db = Firestore.firestore()

    func fetchQuizzes(ownerUID: String, topicId: String, noteId: String) async throws -> [GrammarNoteQuiz] {
        let snapshot = try await quizzesCollection(ownerUID: ownerUID, topicId: topicId, noteId: noteId)
            .getDocuments()
        return snapshot.documents
            .compactMap { makeQuiz(from: $0.data(), id: $0.documentID) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func createQuiz(_ quiz: GrammarNoteQuiz) async throws {
        try await quizzesCollection(ownerUID: quiz.ownerUID, topicId: quiz.topicId, noteId: quiz.noteId)
            .document(quiz.id)
            .setData(dictionary(from: quiz))
        try await noteDocument(ownerUID: quiz.ownerUID, topicId: quiz.topicId, noteId: quiz.noteId)
            .updateData([
                "hasQuiz": true,
                "updatedAt": Timestamp(date: Date())
            ])
    }

    func updateQuiz(_ quiz: GrammarNoteQuiz) async throws {
        var data = dictionary(from: quiz)
        data["updatedAt"] = Timestamp(date: Date())
        try await quizzesCollection(ownerUID: quiz.ownerUID, topicId: quiz.topicId, noteId: quiz.noteId)
            .document(quiz.id)
            .setData(data, merge: true)
    }

    func deleteQuiz(id: String, ownerUID: String, topicId: String, noteId: String) async throws {
        try await quizzesCollection(ownerUID: ownerUID, topicId: topicId, noteId: noteId)
            .document(id).delete()
        let remaining = try await quizzesCollection(ownerUID: ownerUID, topicId: topicId, noteId: noteId)
            .getDocuments()
        if remaining.documents.isEmpty {
            try await noteDocument(ownerUID: ownerUID, topicId: topicId, noteId: noteId)
                .updateData([
                    "hasQuiz": false,
                    "updatedAt": Timestamp(date: Date())
                ])
        }
    }

    // MARK: - Firestore paths

    private func quizzesCollection(ownerUID: String, topicId: String, noteId: String) -> CollectionReference {
        db.collection("users").document(ownerUID)
            .collection("grammarNoteTopics").document(topicId)
            .collection("notes").document(noteId)
            .collection("quizzes")
    }

    private func noteDocument(ownerUID: String, topicId: String, noteId: String) -> DocumentReference {
        db.collection("users").document(ownerUID)
            .collection("grammarNoteTopics").document(topicId)
            .collection("notes").document(noteId)
    }

    // MARK: - Mapping

    private func makeQuiz(from data: [String: Any], id: String) -> GrammarNoteQuiz? {
        guard
            let ownerUID = data["ownerUID"] as? String,
            let topicId  = data["topicId"]  as? String,
            let noteId   = data["noteId"]   as? String,
            let title    = data["title"]    as? String
        else { return nil }
        return GrammarNoteQuiz(
            id:              id,
            ownerUID:        ownerUID,
            topicId:         topicId,
            noteId:          noteId,
            title:           title,
            sourceNoteTitle: data["sourceNoteTitle"] as? String ?? "",
            questions:       decodeQuestions(from: data["questions"]),
            createdAt:       dateValue(data["createdAt"]) ?? Date(),
            updatedAt:       dateValue(data["updatedAt"]) ?? Date()
        )
    }

    private func dictionary(from quiz: GrammarNoteQuiz) -> [String: Any] {
        [
            "ownerUID":        quiz.ownerUID,
            "topicId":         quiz.topicId,
            "noteId":          quiz.noteId,
            "title":           quiz.title,
            "sourceNoteTitle": quiz.sourceNoteTitle,
            "questions":       quiz.questions.map { dictionary(from: $0) },
            "createdAt":       Timestamp(date: quiz.createdAt),
            "updatedAt":       Timestamp(date: quiz.updatedAt)
        ]
    }

    private func dictionary(from q: GrammarQuizQuestion) -> [String: Any] {
        var data: [String: Any] = [
            "id":            q.id,
            "type":          q.type.rawValue,
            "questionText":  q.questionText,
            "options":       q.options,
            "correctAnswer": q.correctAnswer,
            "order":         q.order
        ]
        if let e = q.explanation { data["explanation"] = e }
        return data
    }

    private func decodeQuestions(from value: Any?) -> [GrammarQuizQuestion] {
        guard let raw = value as? [[String: Any]] else { return [] }
        return raw.compactMap { data -> GrammarQuizQuestion? in
            guard
                let id            = data["id"]            as? String,
                let typeRaw       = data["type"]          as? String,
                let type          = GrammarQuizQuestionType(rawValue: typeRaw),
                let questionText  = data["questionText"]  as? String,
                let correctAnswer = data["correctAnswer"] as? String
            else { return nil }
            return GrammarQuizQuestion(
                id:            id,
                type:          type,
                questionText:  questionText,
                options:       data["options"]     as? [String] ?? [],
                correctAnswer: correctAnswer,
                explanation:   data["explanation"] as? String,
                order:         data["order"]       as? Int ?? 0
            )
        }.sorted { $0.order < $1.order }
    }

    private func dateValue(_ value: Any?) -> Date? {
        if let ts = value as? Timestamp { return ts.dateValue() }
        return value as? Date
    }
}

// MARK: - Mock

struct MockGrammarNoteQuizService: GrammarNoteQuizServicing {
    var quizzes: [GrammarNoteQuiz] = []
    func fetchQuizzes(ownerUID: String, topicId: String, noteId: String) async throws -> [GrammarNoteQuiz] { quizzes }
    func createQuiz(_ quiz: GrammarNoteQuiz) async throws {}
    func updateQuiz(_ quiz: GrammarNoteQuiz) async throws {}
    func deleteQuiz(id: String, ownerUID: String, topicId: String, noteId: String) async throws {}
}
