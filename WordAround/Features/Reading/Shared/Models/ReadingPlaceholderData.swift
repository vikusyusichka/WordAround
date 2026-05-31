import SwiftUI

enum ReadingPlaceholderData {

    // MARK: - Article

    static let articleTitle = "A Morning in the City"
    static let articleBody = """
    Every morning, Maria walks through the bustling streets of Barcelona. The aroma of fresh bread fills the air as cafés open their doors. She passes colourful markets where vendors arrange ripe tomatoes and fragrant herbs.

    Today she has an important meeting downtown. Although the city can feel overwhelming, Maria enjoys observing the rhythm of daily life — cyclists weaving through traffic, children laughing in the park, and musicians playing on street corners.

    She stops at her favourite bakery and buys a warm croissant. As she eats, she reads the headlines on a nearby newsstand. The world feels both vast and intimate from this small corner of the city.
    """

    static let highlightedWords = ["bustling", "fragrant", "overwhelming", "intimate"]

    // MARK: - Questions

    struct Question: Identifiable {
        let id: String
        let title: String
        let prompt: String
        let options: [String]
        let correctIndex: Int
        var showsFindInText: Bool = false
    }

    static let comprehensionQuestions: [Question] = [
        Question(
            id: "q1",
            title: "Question 1",
            prompt: "What is the main idea of the text?",
            options: [
                "Maria dislikes city life.",
                "Maria enjoys her morning routine in the city.",
                "Maria is moving to Barcelona.",
                "Maria works at a bakery."
            ],
            correctIndex: 1
        ),
        Question(
            id: "q2",
            title: "Question 2",
            prompt: "What does Maria buy at the bakery?",
            options: ["A sandwich", "A croissant", "Coffee", "Newspaper"],
            correctIndex: 1
        ),
        Question(
            id: "q3",
            title: "Question 3",
            prompt: "Which word best describes the city streets?",
            options: ["Empty", "Bustling", "Silent", "Dark"],
            correctIndex: 1
        ),
        Question(
            id: "q4",
            title: "Question 4",
            prompt: "What does Maria read at the newsstand?",
            options: ["A novel", "Headlines", "A map", "Her email"],
            correctIndex: 1
        ),
        Question(
            id: "q5",
            title: "Question 5",
            prompt: "Where do children laugh in the text?",
            options: ["At school", "In the park", "On the bus", "At home"],
            correctIndex: 1
        ),
        Question(
            id: "q6",
            title: "Question 6",
            prompt: "Why does Maria stop at the bakery?",
            options: [
                "To meet a friend",
                "To buy breakfast",
                "To apply for a job",
                "To use the restroom"
            ],
            correctIndex: 1
        ),
        Question(
            id: "q7",
            title: "Question 7",
            prompt: "What feeling does the last sentence suggest?",
            options: ["Fear", "Boredom", "Connection", "Anger"],
            correctIndex: 2
        ),
        Question(
            id: "q8",
            title: "Question 8",
            prompt: "Which detail supports that the city is lively?",
            options: [
                "Empty streets",
                "Musicians on street corners",
                "Closed cafés",
                "Rainy weather"
            ],
            correctIndex: 1
        )
    ]

    static let myTextsQuestions: [Question] = [
        Question(
            id: "mt1",
            title: "Comprehension",
            prompt: "What is Maria doing each morning?",
            options: ["Sleeping late", "Walking through the city", "Flying abroad", "Studying at home"],
            correctIndex: 1
        ),
        Question(
            id: "mt2",
            title: "Vocabulary",
            prompt: "What does \"fragrant\" most likely mean?",
            options: ["Silent", "Pleasant smell", "Broken", "Expensive"],
            correctIndex: 1
        ),
        Question(
            id: "mt3",
            title: "Find evidence",
            prompt: "Which sentence shows Maria has a routine?",
            options: [
                "Every morning, Maria walks…",
                "The world feels vast…",
                "Children laughing in the park",
                "Musicians playing"
            ],
            correctIndex: 0,
            showsFindInText: true
        ),
        Question(
            id: "mt4",
            title: "Comprehension",
            prompt: "What is Maria's destination today?",
            options: ["The park", "A meeting downtown", "The airport", "The beach"],
            correctIndex: 1
        ),
        Question(
            id: "mt5",
            title: "Vocabulary",
            prompt: "\"Bustling\" is closest in meaning to:",
            options: ["Busy", "Quiet", "Cold", "Empty"],
            correctIndex: 0
        ),
        Question(
            id: "mt6",
            title: "Find evidence",
            prompt: "Where does the text mention food?",
            options: [
                "Fresh bread and croissant",
                "Street musicians",
                "Traffic lights",
                "Office buildings"
            ],
            correctIndex: 0,
            showsFindInText: true
        ),
        Question(
            id: "mt7",
            title: "Comprehension",
            prompt: "How does Maria feel about the city?",
            options: ["She hates it", "She enjoys observing it", "She ignores it", "She fears it"],
            correctIndex: 1
        )
    ]

    // MARK: - Vocabulary

    struct VocabularyItem: Identifiable {
        let id: String
        let word: String
        let translation: String
        let example: String
        var status: String? = nil
    }

    static let vocabularyItems: [VocabularyItem] = [
        VocabularyItem(id: "v1", word: "bustling", translation: "оживлённый", example: "The bustling streets were full of energy."),
        VocabularyItem(id: "v2", word: "fragrant", translation: "ароматный", example: "Fragrant herbs filled the market air."),
        VocabularyItem(id: "v3", word: "intimate", translation: "уютный, близкий", example: "The corner felt intimate and personal.")
    ]

    // MARK: - Mistakes

    struct Mistake: Identifiable {
        let id: String
        let question: String
        let yourAnswer: String
        let correctAnswer: String
    }

    static let mistakes: [Mistake] = [
        Mistake(
            id: "m1",
            question: "What feeling does the last sentence suggest?",
            yourAnswer: "Fear",
            correctAnswer: "Connection"
        ),
        Mistake(
            id: "m2",
            question: "Which detail supports that the city is lively?",
            yourAnswer: "Empty streets",
            correctAnswer: "Musicians on street corners"
        )
    ]

    // MARK: - Set words

    static let setName = "Travel Vocabulary"
    static let setWordCount = 55
    static let setWordsIncluded = 28

    static let setWords: [VocabularyItem] = [
        VocabularyItem(id: "s1", word: "luggage", translation: "багаж", example: "She packed her luggage carefully.", status: "Known"),
        VocabularyItem(id: "s2", word: "departure", translation: "отправление", example: "The departure gate opens at nine.", status: "Needs review"),
        VocabularyItem(id: "s3", word: "itinerary", translation: "маршрут", example: "Our itinerary includes three cities.", status: "Known"),
        VocabularyItem(id: "s4", word: "passport", translation: "паспорт", example: "Don't forget your passport.", status: "Known")
    ]

    static let setPreviewText = """
    At the airport, travelers checked their luggage and reviewed the departure board. Sofia confirmed her itinerary and kept her passport ready. The gate opened early, and the journey began with quiet excitement.
    """

    static let setHighlightedWords = ["luggage", "departure", "itinerary", "passport"]

    // MARK: - Story

    static let storyChapterTitle = "The Hidden Map"
    static let storyText = """
    The old map was folded inside a leather journal Elena found in the attic. Its edges were worn, but the ink still traced a path through mountains no one in her village remembered.

    At dawn she packed bread, water, and the map. The forest whispered as she crossed the first ridge. By midday, a stranger appeared on the trail — eyes sharp, smile uncertain.

    "That map leads to trouble," he said. Elena tightened her grip on the journal. Trouble, she thought, might also lead to answers.
    """

    static let storyChoices: [(icon: String, title: String, hint: String)] = [
        ("map.fill", "Follow the map", "Venture deeper into unknown trails."),
        ("person.fill.questionmark", "Ask the stranger", "Learn what he knows about the path."),
        ("house.fill", "Go back home", "Return safely and rethink the plan.")
    ]

    static let storyRecap = "Elena found a mysterious map and met a stranger on a forest trail who warned her about the path ahead."

    // MARK: - Speed reading

    static let speedChunks: [String] = [
        "Every morning, Maria walks through the bustling streets of Barcelona. The aroma of fresh bread fills the air as cafés open their doors.",
        "She passes colourful markets where vendors arrange ripe tomatoes and fragrant herbs. Today she has an important meeting downtown.",
        "Although the city can feel overwhelming, Maria enjoys observing the rhythm of daily life — cyclists, children, and musicians everywhere.",
        "She stops at her favourite bakery and buys a warm croissant. As she eats, she reads the headlines on a nearby newsstand."
    ]

    static let speedComprehensionResults: [(question: String, correct: Bool)] = [
        ("Where does Maria walk each morning?", true),
        ("What does she buy at the bakery?", true),
        ("Does Maria dislike the city?", false)
    ]

    static let pacingFeedback: [String] = [
        "You slowed down near long sentences",
        "Good consistency overall",
        "Try shorter sessions for accuracy"
    ]

    // MARK: - Interactive

    static let interactiveParagraph = """
    The scientist worked quickly in the laboratory. Each experiment required careful attention, but she moved with confident precision. Nearby, a colleague watched the results appear on the screen.
    """

    static let tappableWords = ["quickly", "careful", "precision", "results"]

    static let interactiveTasks: [(title: String, prompt: String, options: [String])] = [
        ("Choose the best next sentence", "Which sentence fits best after the paragraph?", ["She smiled at the success.", "The door was blue.", "Birds sang loudly."]),
        ("Tap the word", "Tap the word that means \"quickly\".", ["quickly", "careful", "laboratory"]),
        ("Order events", "Put the events in order.", ["Experiment runs", "Results appear", "Colleague watches"])
    ]

    // MARK: - Result metrics

    struct ResultMetrics {
        let primaryValue: String
        let primaryLabel: String
        let secondary: [(value: String, label: String)]
    }

    static let generatedResult = ResultMetrics(
        primaryValue: "82%",
        primaryLabel: "Comprehension",
        secondary: [
            ("6 / 8", "Correct"),
            ("5 min", "Time spent"),
            ("420", "Words read")
        ]
    )

    static let myTextsInsights: [(title: String, detail: String)] = [
        ("Estimated level", "B1"),
        ("Long sentences", "3 found"),
        ("Repeated words", "city, Maria"),
        ("Useful phrases", "fills the air, daily life")
    ]
}
