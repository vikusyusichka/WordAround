import Foundation

struct ConversationScenario: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let systemImage: String
    let category: String
    let promptContext: String
    private let firstMessages: [String: String]

    var icon: String { systemImage }
    var tags: [String] { [category] }

    func suggestedFirstMessage(for language: GrammarLanguage) -> String {
        firstMessages[language.rawValue] ?? firstMessages["english"] ?? ""
    }

    static let allScenarios: [ConversationScenario] = [
        ConversationScenario(
            id: "cafe",
            title: "Cafe",
            description: "Order a drink and ask about desserts.",
            systemImage: "cup.and.saucer.fill",
            category: "Daily life",
            promptContext: "The learner is a customer at a cosy cafe. You play the barista. Greet warmly, take their order, suggest desserts and snacks, and help them practice ordering, asking prices, and choosing items.",
            firstMessages: [
                "english":    "Hi there! Welcome to the cafe. What would you like to order today?",
                "spanish":    "¡Hola! Bienvenido al café. ¿Qué te gustaría pedir hoy?",
                "french":     "Bonjour ! Bienvenue au café. Que voulez-vous commander aujourd'hui ?",
                "german":     "Hallo! Willkommen im Café. Was möchten Sie heute bestellen?",
                "italian":    "Ciao! Benvenuto al caffè. Cosa vorresti ordinare oggi?",
                "portuguese": "Olá! Bem-vindo ao café. O que gostaria de pedir hoje?",
            ]
        ),
        ConversationScenario(
            id: "travel",
            title: "Travel",
            description: "Ask for directions and talk about your trip.",
            systemImage: "airplane",
            category: "Travel",
            promptContext: "The learner is travelling abroad. You play a friendly local. Help them ask for directions, recommend places to visit, talk about transport, and practice talking about their trip.",
            firstMessages: [
                "english":    "Hi! Are you visiting? Where are you headed today?",
                "spanish":    "¡Hola! ¿Estás de visita? ¿A dónde vas hoy?",
                "french":     "Bonjour ! Vous êtes en visite ? Où allez-vous aujourd'hui ?",
                "german":     "Hallo! Sind Sie zu Besuch? Wohin gehen Sie heute?",
                "italian":    "Ciao! Sei in visita? Dove stai andando oggi?",
                "portuguese": "Olá! Está de visita? Para onde vai hoje?",
            ]
        ),
        ConversationScenario(
            id: "daily-life",
            title: "Daily life",
            description: "Talk about your routine and hobbies.",
            systemImage: "sun.max.fill",
            category: "Daily life",
            promptContext: "Have a casual chat about everyday life. Ask the learner about their daily routine, weekend plans, hobbies, family, food they like. Keep it relaxed and friendly.",
            firstMessages: [
                "english":    "Hey! How was your day so far?",
                "spanish":    "¡Hola! ¿Cómo va tu día?",
                "french":     "Salut ! Comment se passe ta journée ?",
                "german":     "Hallo! Wie war dein Tag bisher?",
                "italian":    "Ciao! Com'è andata la tua giornata?",
                "portuguese": "Oi! Como foi o seu dia até agora?",
            ]
        ),
        ConversationScenario(
            id: "shopping",
            title: "Shopping",
            description: "Ask about prices, sizes and payment.",
            systemImage: "bag.fill",
            category: "Daily life",
            promptContext: "The learner is shopping in a store. You play the shop assistant. Help them ask about prices, sizes, colors, payment methods, and try on items.",
            firstMessages: [
                "english":    "Hi! Welcome in. Can I help you find anything?",
                "spanish":    "¡Hola! Bienvenido. ¿Te ayudo a encontrar algo?",
                "french":     "Bonjour ! Bienvenue. Je peux vous aider à trouver quelque chose ?",
                "german":     "Hallo! Willkommen. Kann ich Ihnen helfen, etwas zu finden?",
                "italian":    "Ciao! Benvenuto. Posso aiutarti a trovare qualcosa?",
                "portuguese": "Olá! Bem-vindo. Posso ajudar a encontrar algo?",
            ]
        ),
        ConversationScenario(
            id: "job-interview",
            title: "Job interview",
            description: "Answer simple interview questions.",
            systemImage: "briefcase.fill",
            category: "Professional",
            promptContext: "You are interviewing the learner for a job. Ask simple interview questions about their experience, skills, motivation, and availability. Be encouraging but realistic.",
            firstMessages: [
                "english":    "Hello, thanks for coming in today. Could you start by telling me a little about yourself?",
                "spanish":    "Hola, gracias por venir hoy. ¿Podrías empezar contándome un poco sobre ti?",
                "french":     "Bonjour, merci d'être venu aujourd'hui. Pouvez-vous commencer par me parler un peu de vous ?",
                "german":     "Hallo, danke, dass Sie heute gekommen sind. Können Sie mir etwas über sich erzählen?",
                "italian":    "Ciao, grazie per essere venuto oggi. Puoi iniziare raccontandomi un po' di te?",
                "portuguese": "Olá, obrigado por vir hoje. Pode começar me contando um pouco sobre você?",
            ]
        ),
        ConversationScenario(
            id: "airport",
            title: "Airport",
            description: "Check in, ask about luggage and boarding.",
            systemImage: "airplane.departure",
            category: "Travel",
            promptContext: "The learner is at the airport. You play a check-in agent or gate agent. Help them check in, ask about luggage, seat preferences, boarding times, and gate locations.",
            firstMessages: [
                "english":    "Hello! May I see your passport and ticket, please?",
                "spanish":    "¡Hola! ¿Me muestras tu pasaporte y tu billete, por favor?",
                "french":     "Bonjour ! Puis-je voir votre passeport et votre billet, s'il vous plaît ?",
                "german":     "Hallo! Darf ich Ihren Reisepass und Ihr Ticket sehen, bitte?",
                "italian":    "Salve! Posso vedere il suo passaporto e il biglietto, per favore?",
                "portuguese": "Olá! Posso ver o seu passaporte e bilhete, por favor?",
            ]
        ),
    ]

    static func == (lhs: ConversationScenario, rhs: ConversationScenario) -> Bool {
        lhs.id == rhs.id
    }
}
