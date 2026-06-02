import Foundation

enum ShadowingPhraseError: LocalizedError {
    case noPhrases
    case notConfigured
    case network(String)
    case serverError(Int, String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noPhrases:            return "No phrases are available for this selection."
        case .notConfigured:        return "Phrase generation is not configured."
        case .network(let m):       return "Network error: \(m)"
        case .serverError(let c, let m): return m.isEmpty ? "Phrase service error (\(c))." : "Phrase service error (\(c)): \(m)"
        case .invalidResponse:      return "The phrase service returned an unexpected response."
        }
    }
}

struct ShadowingPhraseBatch {
    let phrases: [ShadowingPhrase]
    let usedFallback: Bool
    let fallbackReason: String?
}

protocol ShadowingPhraseProviding {
    func phrases(
        for language: GrammarLanguage,
        level: EssayDifficulty,
        category: ShadowingCategory,
        count: Int,
        avoidPhrases: [String]
    ) async throws -> ShadowingPhraseBatch
}

extension ShadowingPhraseProviding {
    func phrases(
        for language: GrammarLanguage,
        level: EssayDifficulty,
        category: ShadowingCategory
    ) async throws -> ShadowingPhraseBatch {
        try await phrases(for: language, level: level, category: category, count: 5, avoidPhrases: [])
    }
}

enum ShadowingPhraseAIConfiguration {
    static let workerPath = "/api/shadowing/phrases"

    static var endpointURL: URL? {
        guard
            let base = GrammarQuizAIConfiguration.endpointURL,
            var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        else { return nil }
        components.path = workerPath
        return components.url
    }
}

final class ShadowingPhraseService: ShadowingPhraseProviding {

    private let aiClient: CloudflareShadowingPhraseClient?
    private let recentStore: ShadowingRecentPhraseStore

    init(
        aiClient: CloudflareShadowingPhraseClient? = nil,
        recentStore: ShadowingRecentPhraseStore = .shared
    ) {
        if let aiClient {
            self.aiClient = aiClient
        } else if let url = ShadowingPhraseAIConfiguration.endpointURL {
            self.aiClient = CloudflareShadowingPhraseClient(endpointURL: url)
        } else {
            self.aiClient = nil
        }
        self.recentStore = recentStore
    }

    func phrases(
        for language: GrammarLanguage,
        level: EssayDifficulty,
        category: ShadowingCategory,
        count: Int,
        avoidPhrases: [String]
    ) async throws -> ShadowingPhraseBatch {
        let remembered = recentStore.recentPhrases(language: language, level: level, category: category)
        let avoid = Array((avoidPhrases + remembered).suffix(30))

        #if DEBUG
        print("[ShadowingPhraseService] request lang=\(language.title) level=\(level.rawValue) category=\(category.rawValue) count=\(count) avoidCount=\(avoid.count) aiConfigured=\(aiClient != nil)")
        #endif

        if let aiClient {
            do {
                let generated = try await aiClient.generatePhrases(
                    language: language,
                    level: level,
                    category: category,
                    count: count,
                    avoidPhrases: avoid
                )
                if !generated.isEmpty {
                    recentStore.remember(texts: generated.map(\.text), language: language, level: level, category: category)
                    #if DEBUG
                    print("[ShadowingPhraseService] AI success count=\(generated.count) fallback=false")
                    #endif
                    return ShadowingPhraseBatch(phrases: generated, usedFallback: false, fallbackReason: nil)
                }
                #if DEBUG
                print("[ShadowingPhraseService] AI returned empty — falling back")
                #endif
            } catch {
                #if DEBUG
                print("[ShadowingPhraseService] AI failed: \((error as? LocalizedError)?.errorDescription ?? error.localizedDescription) — falling back")
                #endif
            }
        }

        let fallback = Self.localFallback(
            language: language, level: level, category: category, count: count, avoid: avoid
        )
        guard !fallback.isEmpty else { throw ShadowingPhraseError.noPhrases }
        recentStore.remember(texts: fallback.map(\.text), language: language, level: level, category: category)

        let reason = aiClient == nil
            ? "Phrase generation isn't configured. Showing local phrases."
            : "Couldn't generate phrases. Showing local phrases."
        #if DEBUG
        print("[ShadowingPhraseService] fallback used count=\(fallback.count) reason='\(reason)'")
        #endif
        return ShadowingPhraseBatch(phrases: fallback, usedFallback: true, fallbackReason: reason)
    }

    private struct Entry { let text: String; let translation: String? }

    private static func localFallback(
        language: GrammarLanguage,
        level: EssayDifficulty,
        category: ShadowingCategory,
        count: Int,
        avoid: [String]
    ) -> [ShadowingPhrase] {
        let pool = localPhraseTexts(language: language, category: category).shuffled()
        let avoidSet = Set(avoid.map { $0.lowercased() })

        var chosen = pool.filter { !avoidSet.contains($0.text.lowercased()) }
        if chosen.count < count { chosen += pool.filter { e in !chosen.contains { $0.text == e.text } } }

        let code = language.shortTitle.lowercased()
        let tip = tip(for: category)
        return chosen.prefix(count).map { entry in
            ShadowingPhrase(
                text: entry.text,
                translation: entry.translation,
                languageCode: code,
                level: level,
                category: category,
                tip: tip
            )
        }
    }

    private static func localPhraseTexts(
        language: GrammarLanguage,
        category: ShadowingCategory
    ) -> [Entry] {
        switch language {
        case .english: return english(category)
        case .spanish: return spanish(category)
        case .french:  return french(category)
        case .german:  return german(category)
        default:       return english(category)
        }
    }

    private static func tip(for category: ShadowingCategory) -> String {
        switch category {
        case .daily:         return "Match the natural rhythm — don't pause between every word."
        case .travel:        return "Keep a steady pace; travel phrases are said quickly."
        case .cafe:          return "Be polite and clear — stress the request word."
        case .interview:     return "Speak confidently and finish your sentences."
        case .academic:      return "Articulate longer words fully and slow down slightly."
        case .pronunciation: return "Focus on the tricky sounds; exaggerate them at first."
        case .fromVideo:     return "Repeat the word clearly, matching the pronunciation you heard."
        }
    }

    private static func english(_ c: ShadowingCategory) -> [Entry] {
        switch c {
        case .daily:
            return [
                Entry(text: "How are you doing today?", translation: nil),
                Entry(text: "I'll see you later this evening.", translation: nil),
                Entry(text: "Could you help me with this, please?", translation: nil),
                Entry(text: "That sounds like a great idea.", translation: nil),
                Entry(text: "Don't forget to call me back.", translation: nil),
                Entry(text: "Let me know if you need anything.", translation: nil),
                Entry(text: "I completely agree with you.", translation: nil)
            ]
        case .travel:
            return [
                Entry(text: "Where is the nearest train station?", translation: nil),
                Entry(text: "How much does a ticket to the centre cost?", translation: nil),
                Entry(text: "I would like to check in, please.", translation: nil),
                Entry(text: "Can you recommend a good local restaurant?", translation: nil),
                Entry(text: "What time does the next bus leave?", translation: nil),
                Entry(text: "Could you show me on the map?", translation: nil),
                Entry(text: "Is there a pharmacy near here?", translation: nil)
            ]
        case .cafe:
            return [
                Entry(text: "Could I have a flat white, please?", translation: nil),
                Entry(text: "I'll take a slice of the carrot cake.", translation: nil),
                Entry(text: "Is this table free?", translation: nil),
                Entry(text: "Can we get the bill, please?", translation: nil),
                Entry(text: "Do you have any oat milk?", translation: nil),
                Entry(text: "I'd like that to go, please.", translation: nil),
                Entry(text: "Could I see the menu, please?", translation: nil)
            ]
        case .interview:
            return [
                Entry(text: "Thank you for inviting me to this interview.", translation: nil),
                Entry(text: "I have three years of experience in this field.", translation: nil),
                Entry(text: "My greatest strength is solving problems calmly.", translation: nil),
                Entry(text: "I work well both independently and in a team.", translation: nil),
                Entry(text: "I'm excited about the opportunity to contribute here.", translation: nil),
                Entry(text: "I'm always keen to learn new skills.", translation: nil),
                Entry(text: "Could you tell me more about the role?", translation: nil)
            ]
        case .academic:
            return [
                Entry(text: "This essay examines the causes of climate change.", translation: nil),
                Entry(text: "The data clearly supports our hypothesis.", translation: nil),
                Entry(text: "In conclusion, further research is needed.", translation: nil),
                Entry(text: "The author argues that technology shapes society.", translation: nil),
                Entry(text: "These findings have significant implications.", translation: nil),
                Entry(text: "Let us consider the evidence carefully.", translation: nil),
                Entry(text: "This theory remains widely debated.", translation: nil)
            ]
        case .pronunciation:
            return [
                Entry(text: "She sells seashells by the seashore.", translation: nil),
                Entry(text: "The thirty-three thieves thought they thrilled the throne.", translation: nil),
                Entry(text: "Red lorry, yellow lorry.", translation: nil),
                Entry(text: "Peter Piper picked a peck of pickled peppers.", translation: nil),
                Entry(text: "World Wide Web rarely works well.", translation: nil),
                Entry(text: "Six slippery snails slid slowly seaward.", translation: nil),
                Entry(text: "A proper copper coffee pot.", translation: nil)
            ]
        case .fromVideo:
            return []
        }
    }

    private static func spanish(_ c: ShadowingCategory) -> [Entry] {
        switch c {
        case .daily:
            return [
                Entry(text: "¿Cómo estás hoy?", translation: "How are you today?"),
                Entry(text: "Nos vemos esta tarde.", translation: "See you this afternoon."),
                Entry(text: "¿Puedes ayudarme con esto, por favor?", translation: "Can you help me with this, please?"),
                Entry(text: "Me parece una buena idea.", translation: "That sounds like a good idea."),
                Entry(text: "No olvides llamarme.", translation: "Don't forget to call me."),
                Entry(text: "Avísame si necesitas algo.", translation: "Let me know if you need anything."),
                Entry(text: "Estoy completamente de acuerdo.", translation: "I completely agree.")
            ]
        case .travel:
            return [
                Entry(text: "¿Dónde está la estación de tren?", translation: "Where is the train station?"),
                Entry(text: "¿Cuánto cuesta un billete al centro?", translation: "How much is a ticket to the centre?"),
                Entry(text: "Quisiera registrarme, por favor.", translation: "I would like to check in, please."),
                Entry(text: "¿Puede recomendarme un buen restaurante?", translation: "Can you recommend a good restaurant?"),
                Entry(text: "¿A qué hora sale el próximo autobús?", translation: "What time does the next bus leave?"),
                Entry(text: "¿Hay una farmacia cerca?", translation: "Is there a pharmacy nearby?"),
                Entry(text: "¿Me lo muestra en el mapa?", translation: "Can you show me on the map?")
            ]
        case .cafe:
            return [
                Entry(text: "¿Me pone un café con leche, por favor?", translation: "A coffee with milk, please?"),
                Entry(text: "Quiero un trozo de tarta.", translation: "I'd like a slice of cake."),
                Entry(text: "¿Está libre esta mesa?", translation: "Is this table free?"),
                Entry(text: "La cuenta, por favor.", translation: "The bill, please."),
                Entry(text: "¿Tienen leche de avena?", translation: "Do you have oat milk?"),
                Entry(text: "Para llevar, por favor.", translation: "To go, please."),
                Entry(text: "¿Me trae la carta, por favor?", translation: "Could I see the menu, please?")
            ]
        case .interview:
            return [
                Entry(text: "Gracias por invitarme a esta entrevista.", translation: "Thank you for inviting me to this interview."),
                Entry(text: "Tengo tres años de experiencia.", translation: "I have three years of experience."),
                Entry(text: "Mi mayor fortaleza es la calma.", translation: "My greatest strength is staying calm."),
                Entry(text: "Trabajo bien en equipo.", translation: "I work well in a team."),
                Entry(text: "Me entusiasma esta oportunidad.", translation: "I'm excited about this opportunity."),
                Entry(text: "Siempre quiero aprender cosas nuevas.", translation: "I always want to learn new things."),
                Entry(text: "¿Puede contarme más sobre el puesto?", translation: "Can you tell me more about the role?")
            ]
        case .academic:
            return [
                Entry(text: "Este ensayo analiza el cambio climático.", translation: "This essay analyses climate change."),
                Entry(text: "Los datos apoyan nuestra hipótesis.", translation: "The data supports our hypothesis."),
                Entry(text: "En conclusión, se necesita más investigación.", translation: "In conclusion, more research is needed."),
                Entry(text: "El autor sostiene una idea interesante.", translation: "The author holds an interesting idea."),
                Entry(text: "Estos resultados son significativos.", translation: "These results are significant."),
                Entry(text: "Consideremos la evidencia con cuidado.", translation: "Let us consider the evidence carefully."),
                Entry(text: "Esta teoría sigue siendo debatida.", translation: "This theory is still debated.")
            ]
        case .pronunciation:
            return [
                Entry(text: "Tres tristes tigres tragaban trigo.", translation: "Three sad tigers swallowed wheat."),
                Entry(text: "El perro de Rosa y Roque no tiene rabo.", translation: "Rosa and Roque's dog has no tail."),
                Entry(text: "Pablito clavó un clavito.", translation: "Pablito hammered a little nail."),
                Entry(text: "Erre con erre, cigarro.", translation: "R with R, cigar."),
                Entry(text: "Mi mamá me mima mucho.", translation: "My mum pampers me a lot."),
                Entry(text: "Como poco coco como, poco coco compro.", translation: "As I eat little coconut, I buy little coconut."),
                Entry(text: "El cielo está enladrillado.", translation: "The sky is bricked.")
            ]
        case .fromVideo:
            return []
        }
    }

    private static func french(_ c: ShadowingCategory) -> [Entry] {
        switch c {
        case .daily:
            return [
                Entry(text: "Comment allez-vous aujourd'hui ?", translation: "How are you today?"),
                Entry(text: "On se voit ce soir.", translation: "See you tonight."),
                Entry(text: "Peux-tu m'aider, s'il te plaît ?", translation: "Can you help me, please?"),
                Entry(text: "Ça me semble une bonne idée.", translation: "That sounds like a good idea."),
                Entry(text: "N'oublie pas de me rappeler.", translation: "Don't forget to call me back."),
                Entry(text: "Dis-moi si tu as besoin de quelque chose.", translation: "Tell me if you need anything."),
                Entry(text: "Je suis tout à fait d'accord.", translation: "I completely agree.")
            ]
        case .travel:
            return [
                Entry(text: "Où est la gare la plus proche ?", translation: "Where is the nearest station?"),
                Entry(text: "Combien coûte un billet pour le centre ?", translation: "How much is a ticket to the centre?"),
                Entry(text: "Je voudrais m'enregistrer, s'il vous plaît.", translation: "I'd like to check in, please."),
                Entry(text: "Pouvez-vous recommander un bon restaurant ?", translation: "Can you recommend a good restaurant?"),
                Entry(text: "À quelle heure part le prochain bus ?", translation: "When does the next bus leave?"),
                Entry(text: "Y a-t-il une pharmacie près d'ici ?", translation: "Is there a pharmacy near here?"),
                Entry(text: "Pouvez-vous me montrer sur la carte ?", translation: "Can you show me on the map?")
            ]
        case .cafe:
            return [
                Entry(text: "Un café au lait, s'il vous plaît.", translation: "A coffee with milk, please."),
                Entry(text: "Je prends une part de gâteau.", translation: "I'll take a slice of cake."),
                Entry(text: "Cette table est libre ?", translation: "Is this table free?"),
                Entry(text: "L'addition, s'il vous plaît.", translation: "The bill, please."),
                Entry(text: "Avez-vous du lait d'avoine ?", translation: "Do you have oat milk?"),
                Entry(text: "À emporter, s'il vous plaît.", translation: "To go, please."),
                Entry(text: "Puis-je voir la carte ?", translation: "Could I see the menu?")
            ]
        case .interview:
            return [
                Entry(text: "Merci de m'avoir invité à cet entretien.", translation: "Thank you for inviting me to this interview."),
                Entry(text: "J'ai trois ans d'expérience.", translation: "I have three years of experience."),
                Entry(text: "Ma plus grande qualité est le calme.", translation: "My greatest strength is staying calm."),
                Entry(text: "Je travaille bien en équipe.", translation: "I work well in a team."),
                Entry(text: "Cette opportunité m'enthousiasme.", translation: "This opportunity excites me."),
                Entry(text: "J'aime toujours apprendre.", translation: "I always like to learn."),
                Entry(text: "Pouvez-vous m'en dire plus sur le poste ?", translation: "Can you tell me more about the role?")
            ]
        case .academic:
            return [
                Entry(text: "Cet essai analyse le changement climatique.", translation: "This essay analyses climate change."),
                Entry(text: "Les données soutiennent notre hypothèse.", translation: "The data supports our hypothesis."),
                Entry(text: "En conclusion, des recherches sont nécessaires.", translation: "In conclusion, research is needed."),
                Entry(text: "L'auteur défend une idée intéressante.", translation: "The author defends an interesting idea."),
                Entry(text: "Ces résultats sont significatifs.", translation: "These results are significant."),
                Entry(text: "Examinons les preuves attentivement.", translation: "Let us examine the evidence carefully."),
                Entry(text: "Cette théorie est encore débattue.", translation: "This theory is still debated.")
            ]
        case .pronunciation:
            return [
                Entry(text: "Les chaussettes de l'archiduchesse sont sèches.", translation: "The archduchess's socks are dry."),
                Entry(text: "Un chasseur sachant chasser.", translation: "A hunter who knows how to hunt."),
                Entry(text: "Les vers verts vont vers le verre.", translation: "The green worms go toward the glass."),
                Entry(text: "Cinq chiens chassent six chats.", translation: "Five dogs chase six cats."),
                Entry(text: "Trois tortues trottaient.", translation: "Three turtles trotted."),
                Entry(text: "Je veux et j'exige.", translation: "I want and I demand."),
                Entry(text: "Ton thé t'a-t-il ôté ta toux ?", translation: "Did your tea take away your cough?")
            ]
        case .fromVideo:
            return []
        }
    }

    private static func german(_ c: ShadowingCategory) -> [Entry] {
        switch c {
        case .daily:
            return [
                Entry(text: "Wie geht es dir heute?", translation: "How are you today?"),
                Entry(text: "Wir sehen uns heute Abend.", translation: "See you this evening."),
                Entry(text: "Kannst du mir bitte helfen?", translation: "Can you help me, please?"),
                Entry(text: "Das klingt nach einer guten Idee.", translation: "That sounds like a good idea."),
                Entry(text: "Vergiss nicht, mich zurückzurufen.", translation: "Don't forget to call me back."),
                Entry(text: "Sag mir, wenn du etwas brauchst.", translation: "Tell me if you need anything."),
                Entry(text: "Ich stimme dir völlig zu.", translation: "I completely agree.")
            ]
        case .travel:
            return [
                Entry(text: "Wo ist der nächste Bahnhof?", translation: "Where is the nearest station?"),
                Entry(text: "Was kostet ein Ticket ins Zentrum?", translation: "How much is a ticket to the centre?"),
                Entry(text: "Ich möchte einchecken, bitte.", translation: "I'd like to check in, please."),
                Entry(text: "Können Sie ein gutes Restaurant empfehlen?", translation: "Can you recommend a good restaurant?"),
                Entry(text: "Wann fährt der nächste Bus?", translation: "When does the next bus leave?"),
                Entry(text: "Gibt es hier eine Apotheke?", translation: "Is there a pharmacy here?"),
                Entry(text: "Können Sie es mir auf der Karte zeigen?", translation: "Can you show me on the map?")
            ]
        case .cafe:
            return [
                Entry(text: "Einen Milchkaffee, bitte.", translation: "A coffee with milk, please."),
                Entry(text: "Ich nehme ein Stück Kuchen.", translation: "I'll take a slice of cake."),
                Entry(text: "Ist dieser Tisch frei?", translation: "Is this table free?"),
                Entry(text: "Die Rechnung, bitte.", translation: "The bill, please."),
                Entry(text: "Haben Sie Hafermilch?", translation: "Do you have oat milk?"),
                Entry(text: "Zum Mitnehmen, bitte.", translation: "To go, please."),
                Entry(text: "Kann ich die Karte sehen?", translation: "Could I see the menu?")
            ]
        case .interview:
            return [
                Entry(text: "Danke für die Einladung zu diesem Gespräch.", translation: "Thank you for the invitation to this interview."),
                Entry(text: "Ich habe drei Jahre Erfahrung.", translation: "I have three years of experience."),
                Entry(text: "Meine größte Stärke ist Ruhe.", translation: "My greatest strength is calmness."),
                Entry(text: "Ich arbeite gut im Team.", translation: "I work well in a team."),
                Entry(text: "Diese Gelegenheit begeistert mich.", translation: "This opportunity excites me."),
                Entry(text: "Ich lerne immer gerne dazu.", translation: "I always like to learn."),
                Entry(text: "Können Sie mir mehr über die Stelle sagen?", translation: "Can you tell me more about the role?")
            ]
        case .academic:
            return [
                Entry(text: "Dieser Aufsatz untersucht den Klimawandel.", translation: "This essay examines climate change."),
                Entry(text: "Die Daten stützen unsere Hypothese.", translation: "The data supports our hypothesis."),
                Entry(text: "Zusammenfassend ist mehr Forschung nötig.", translation: "In summary, more research is needed."),
                Entry(text: "Der Autor vertritt eine interessante These.", translation: "The author holds an interesting thesis."),
                Entry(text: "Diese Ergebnisse sind bedeutend.", translation: "These results are significant."),
                Entry(text: "Betrachten wir die Belege sorgfältig.", translation: "Let us consider the evidence carefully."),
                Entry(text: "Diese Theorie ist weiterhin umstritten.", translation: "This theory is still disputed.")
            ]
        case .pronunciation:
            return [
                Entry(text: "Fischers Fritz fischt frische Fische.", translation: "Fischer's Fritz fishes fresh fish."),
                Entry(text: "Blaukraut bleibt Blaukraut.", translation: "Red cabbage stays red cabbage."),
                Entry(text: "Zehn zahme Ziegen zogen Zucker.", translation: "Ten tame goats pulled sugar."),
                Entry(text: "Brautkleid bleibt Brautkleid.", translation: "Wedding dress stays wedding dress."),
                Entry(text: "Der dicke Dachdecker deckt dir dein Dach.", translation: "The fat roofer covers your roof."),
                Entry(text: "In Ulm und um Ulm herum.", translation: "In Ulm and around Ulm."),
                Entry(text: "Wenn Fliegen hinter Fliegen fliegen.", translation: "When flies fly behind flies.")
            ]
        case .fromVideo:
            return []
        }
    }
}

final class MockShadowingPhraseService: ShadowingPhraseProviding {
    func phrases(
        for language: GrammarLanguage,
        level: EssayDifficulty,
        category: ShadowingCategory,
        count: Int,
        avoidPhrases: [String]
    ) async throws -> ShadowingPhraseBatch {
        try? await Task.sleep(nanoseconds: 150_000_000)
        let phrases = [
            ShadowingPhrase(text: "Could you repeat that, please?", languageCode: "en", level: level, category: category, tip: "Include the small words."),
            ShadowingPhrase(text: "I would like a coffee, please.", languageCode: "en", level: level, category: category, tip: nil)
        ]
        return ShadowingPhraseBatch(phrases: phrases, usedFallback: false, fallbackReason: nil)
    }
}
