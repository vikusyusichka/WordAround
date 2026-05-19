import Foundation

struct EssayTopic: Identifiable, Equatable {
    let id = UUID()
    let level: String
    let title: String
    let estimatedMinutes: Int
    let taskDescription: String
    let wordRange: ClosedRange<Int>
    let tips: [String]

    var wordRangeText: String {
        "\(wordRange.lowerBound)-\(wordRange.upperBound) words"
    }
}

extension EssayTopic {
    static let predefined: [EssayTopic] = [
        EssayTopic(
            level: "A2-B1",
            title: "Describing a place",
            estimatedMinutes: 10,
            taskDescription: "You are visiting a new city. Write a short paragraph describing a place you like there.",
            wordRange: 70...120,
            tips: ["Use adjectives", "Describe what you see", "Talk about feelings"]
        ),
        EssayTopic(
            level: "A2",
            title: "My daily routine",
            estimatedMinutes: 8,
            taskDescription: "Write about your typical day. Mention what you do in the morning, afternoon and evening.",
            wordRange: 60...100,
            tips: ["Use present simple", "Add time phrases", "Keep sentences clear"]
        ),
        EssayTopic(
            level: "B1",
            title: "A memorable trip",
            estimatedMinutes: 12,
            taskDescription: "Describe a trip you remember well. Explain where you went, what happened and why it was special.",
            wordRange: 90...150,
            tips: ["Use past simple", "Add details", "Explain your opinion"]
        ),
        EssayTopic(
            level: "A2-B1",
            title: "My favorite season",
            estimatedMinutes: 10,
            taskDescription: "Write about your favorite season. Describe the weather, activities and why you like it.",
            wordRange: 70...120,
            tips: ["Use weather words", "Compare seasons", "Use because"]
        ),
        EssayTopic(
            level: "B1",
            title: "A person I admire",
            estimatedMinutes: 12,
            taskDescription: "Write about a person you admire. Describe their personality, actions and why they inspire you.",
            wordRange: 90...160,
            tips: ["Use personality adjectives", "Give examples", "Use linking words"]
        )
    ]

    static var fallback: EssayTopic {
        predefined[0]
    }
}
