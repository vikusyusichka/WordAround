import Foundation

final class LocalFallbackSpeakingTopicAIClient: SpeakingTopicAIClient {

    func generateTopic(
        language: GrammarLanguage,
        level: EssayDifficulty,
        length: ConversationLength,
        avoidTitles: [String]
    ) async throws -> GeneratedConversationTopic {
        #if DEBUG
        print("[TopicAI] using LOCAL fallback for \(language.title)/\(level.rawValue) avoid=\(avoidTitles.count)")
        #endif
        return Self.pickTopic(language: language, level: level, avoidTitles: avoidTitles)
    }

    static func pickTopic(
        language: GrammarLanguage,
        level: EssayDifficulty,
        avoidTitles: [String] = []
    ) -> GeneratedConversationTopic {
        let full = Self.pool(for: level, language: language)
        guard !full.isEmpty else { return Self.universalFallback(language: language) }

        let avoid = Set(avoidTitles)
        let filtered = full.filter { !avoid.contains($0.title) }

        let pool = filtered.isEmpty ? full : filtered
        return pool.randomElement() ?? Self.universalFallback(language: language)
    }

    private static func pool(for level: EssayDifficulty, language: GrammarLanguage) -> [GeneratedConversationTopic] {
        switch (language, level) {
        case (.english, .a1), (.english, .a2):
            return [
                topic(.english, title: "Morning routine",        desc: "Talk about what you do every morning.", first: "Hi! What do you do in the morning?",                category: "Daily life", context: "Help the learner describe their morning routine with simple verbs. Ask short follow-up questions."),
                topic(.english, title: "Favourite food",         desc: "Talk about food you like.",             first: "Hi! What food do you like?",                       category: "Daily life", context: "Discuss favourite foods, meals, and simple cooking. Keep vocabulary basic."),
                topic(.english, title: "Family",                 desc: "Talk about your family.",               first: "Hi! Can you tell me about your family?",           category: "Social",     context: "Ask about family members, ages, and what they do. Keep sentences short."),
            ]
        case (.english, .b1), (.english, .b2):
            return [
                topic(.english, title: "Weekend plans",          desc: "Discuss what you want to do this weekend.", first: "What are your plans for the weekend?",        category: "Social",     context: "Ask about plans, preferences and reasons. Encourage opinions."),
                topic(.english, title: "A memorable trip",       desc: "Talk about a trip you remember.",          first: "Tell me about a trip you remember well.",       category: "Travel",     context: "Encourage the learner to share past experiences using past tense and descriptive vocabulary."),
                topic(.english, title: "Work or studies",        desc: "Talk about your job or what you study.",  first: "What do you do for work or study?",             category: "Professional", context: "Discuss work, studies, daily tasks and ambitions."),
            ]
        case (.english, .c1), (.english, .native):
            return [
                topic(.english, title: "Technology and society", desc: "Discuss how technology shapes society.", first: "How do you think technology is changing the way we live?", category: "Discussion", context: "Encourage abstract arguments, examples, and nuanced opinions. Push back politely on weak points."),
                topic(.english, title: "Travel vs. settling",    desc: "Compare travelling and settling in one place.", first: "Would you rather travel a lot or live in one place forever?", category: "Discussion", context: "Compare lifestyles, pros and cons. Encourage extended speech."),
            ]

        case (.spanish, .a1), (.spanish, .a2):
            return [
                topic(.spanish, title: "Mi rutina",     desc: "Habla de tu rutina diaria.",    first: "Hola, ¿qué haces por la mañana?",         category: "Daily life", context: "Help the learner describe their daily routine with simple present-tense verbs."),
                topic(.spanish, title: "Comida favorita", desc: "Habla de la comida que te gusta.", first: "Hola, ¿qué comida te gusta?",       category: "Daily life", context: "Discuss favourite foods in Spanish using basic vocabulary."),
            ]
        case (.spanish, .b1), (.spanish, .b2):
            return [
                topic(.spanish, title: "Planes de fin de semana", desc: "Habla de tus planes para el fin de semana.", first: "¿Qué planes tienes para el fin de semana?", category: "Social", context: "Talk about weekend plans, preferences and reasons in Spanish."),
                topic(.spanish, title: "Un viaje memorable",       desc: "Cuenta un viaje que recuerdas.",              first: "Cuéntame un viaje que recuerdas.",          category: "Travel", context: "Encourage past-tense narration of a memorable trip."),
            ]
        case (.spanish, .c1), (.spanish, .native):
            return [
                topic(.spanish, title: "Tecnología y sociedad",    desc: "Cómo la tecnología cambia la sociedad.",       first: "¿Cómo crees que la tecnología cambia la forma de vivir?", category: "Discussion", context: "Encourage nuanced arguments in Spanish."),
            ]

        case (.french, .a1), (.french, .a2):
            return [
                topic(.french, title: "Ma routine",       desc: "Parle de ta routine du matin.",  first: "Bonjour ! Que fais-tu le matin ?",   category: "Daily life", context: "Help the learner describe their morning routine in simple French."),
                topic(.french, title: "Plats préférés",   desc: "Parle des plats que tu aimes.",  first: "Bonjour ! Quel est ton plat préféré ?", category: "Daily life", context: "Discuss favourite foods in French."),
            ]
        case (.french, .b1), (.french, .b2):
            return [
                topic(.french, title: "Projets du week-end", desc: "Parle de tes projets pour le week-end.", first: "Quels sont tes projets pour le week-end ?", category: "Social", context: "Discuss weekend plans and preferences in French."),
            ]
        case (.french, .c1), (.french, .native):
            return [
                topic(.french, title: "Technologie et société", desc: "Comment la technologie change la société.", first: "Comment penses-tu que la technologie change notre vie ?", category: "Discussion", context: "Encourage nuanced arguments in French."),
            ]

        case (.german, .a1), (.german, .a2):
            return [
                topic(.german, title: "Mein Morgen",   desc: "Sprich über deine Morgenroutine.", first: "Hallo! Was machst du am Morgen?",       category: "Daily life", context: "Help the learner describe their morning routine in simple German."),
                topic(.german, title: "Lieblingsessen", desc: "Sprich über dein Lieblingsessen.", first: "Hallo! Was ist dein Lieblingsessen?", category: "Daily life", context: "Discuss favourite foods in German."),
            ]
        case (.german, .b1), (.german, .b2):
            return [
                topic(.german, title: "Wochenendpläne", desc: "Sprich über deine Pläne für das Wochenende.", first: "Was sind deine Pläne für das Wochenende?", category: "Social", context: "Discuss weekend plans and reasons in German."),
            ]
        case (.german, .c1), (.german, .native):
            return [
                topic(.german, title: "Technologie und Gesellschaft", desc: "Wie verändert die Technologie die Gesellschaft?", first: "Wie verändert deiner Meinung nach die Technologie unser Leben?", category: "Discussion", context: "Encourage nuanced arguments in German."),
            ]

        default:
            return [Self.universalFallback(language: language)]
        }
    }

    private static func topic(
        _: GrammarLanguage,
        title: String,
        desc: String,
        first: String,
        category: String,
        context: String
    ) -> GeneratedConversationTopic {
        GeneratedConversationTopic(
            title: title,
            description: desc,
            firstAIMessage: first,
            promptContext: context,
            category: category
        )
    }

    private static func universalFallback(language: GrammarLanguage) -> GeneratedConversationTopic {

        GeneratedConversationTopic(
            title: "Daily conversation",
            description: "Talk about your day and ask the tutor questions.",
            firstAIMessage: "Hi! How is your day going? Tell me one thing you did today.",
            promptContext: "Have a friendly daily-life conversation. Encourage the learner to share short personal stories.",
            category: "Daily life"
        )
    }
}
