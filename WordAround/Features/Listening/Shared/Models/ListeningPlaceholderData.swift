import Foundation

enum ListeningPlaceholderData {
    static let sampleText = """
    Every morning, Maria walks through the bustling streets of Barcelona. The aroma of fresh bread fills the air as cafés open their doors. She passes colourful markets where vendors arrange ripe tomatoes and fragrant herbs.

    Today she has an important meeting downtown. Although the city can feel overwhelming, Maria enjoys observing the rhythm of daily life. She listens carefully to conversations around her, picking up new phrases and expressions.
    """

    static let sampleTitle = "A Morning in the City"

    static let sampleQuestions: [ListeningQuestion] = [
        ListeningQuestion(
            id: "q1",
            prompt: "What does Maria do every morning?",
            options: ["She stays at home", "She walks through the city", "She takes the subway", "She goes to the beach"],
            correctIndex: 1
        ),
        ListeningQuestion(
            id: "q2",
            prompt: "What fills the air near the cafés?",
            options: ["Music", "Fresh bread aroma", "Rain", "Car exhaust"],
            correctIndex: 1
        ),
        ListeningQuestion(
            id: "q3",
            prompt: "Maria has an important meeting today.",
            options: ["True", "False"],
            correctIndex: 0
        )
    ]

    static let sampleResult = ListeningResult(
        id: "result-1",
        comprehensionPercent: 83,
        correctAnswers: 5,
        totalQuestions: 6,
        listeningTimeSeconds: 160,
        speedLabel: "1.0x",
        mistakes: [
            ListeningMistake(
                id: "m1",
                prompt: "What does Maria do every morning?",
                selectedAnswer: "She takes the subway",
                correctAnswer: "She walks through the city",
                explanation: "The text says Maria walks through the bustling streets every morning."
            )
        ]
    )
}
