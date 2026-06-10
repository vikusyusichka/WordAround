import Foundation

struct GrammarQuizAIRequest: Codable, Equatable {
    let noteTitle: String
    let noteLanguageCode: String?
    let noteLanguageName: String?
    let noteType: String?
    let blocks: [Block]
    let questionCount: Int
    let allowedTypes: [String]
    let focusInstructions: String?

    struct Block: Codable, Equatable {
        let type: String
        let text: String
        let secondaryText: String?
        let items: [String]
    }
}

struct GrammarQuizAIResponseDTO: Codable, Equatable {
    let questions: [Question]

    struct Question: Codable, Equatable {
        let type: String
        let questionText: String
        let options: [String]?
        let correctAnswer: String
        let explanation: String?
    }
}
