import Foundation


enum PronunciationContentError: LocalizedError {
    case noItems
    case notConfigured
    case network(String)
    case serverError(Int, String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noItems:              return "No pronunciation items are available for this selection."
        case .notConfigured:        return "Pronunciation content generation is not configured."
        case .network(let m):       return "Network error: \(m)"
        case .serverError(let c, let m): return m.isEmpty ? "Content service error (\(c))." : "Content service error (\(c)): \(m)"
        case .invalidResponse:      return "The content service returned an unexpected response."
        }
    }
}


struct PronunciationItemBatch {
    let items: [PronunciationItem]
    let usedFallback: Bool
    let fallbackReason: String?
}


protocol PronunciationContentProviding {
    func items(
        for language: GrammarLanguage,
        level: EssayDifficulty,
        difficulty: PronunciationDifficulty,
        focus: PronunciationFocus,
        count: Int,
        avoidItems: [String]
    ) async throws -> PronunciationItemBatch
}

extension PronunciationContentProviding {
    func items(
        for language: GrammarLanguage,
        level: EssayDifficulty,
        difficulty: PronunciationDifficulty,
        focus: PronunciationFocus
    ) async throws -> PronunciationItemBatch {
        try await items(for: language, level: level, difficulty: difficulty, focus: focus, count: 10, avoidItems: [])
    }
}


enum PronunciationContentConfiguration {
    static let workerPath = "/api/pronunciation/content"

    static var endpointURL: URL? {
        guard
            let base = GrammarQuizAIConfiguration.endpointURL,
            var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        else { return nil }
        components.path = workerPath
        return components.url
    }
}


final class PronunciationContentService: PronunciationContentProviding {

    private let aiClient: CloudflarePronunciationContentClient?
    private let recentStore: PronunciationRecentItemStore

    init(
        aiClient: CloudflarePronunciationContentClient? = nil,
        recentStore: PronunciationRecentItemStore = .shared
    ) {
        if let aiClient {
            self.aiClient = aiClient
        } else if let url = PronunciationContentConfiguration.endpointURL {
            self.aiClient = CloudflarePronunciationContentClient(endpointURL: url)
        } else {
            self.aiClient = nil
        }
        self.recentStore = recentStore
    }

    func items(
        for language: GrammarLanguage,
        level: EssayDifficulty,
        difficulty: PronunciationDifficulty,
        focus: PronunciationFocus,
        count: Int,
        avoidItems: [String]
    ) async throws -> PronunciationItemBatch {
        let remembered = recentStore.recentItems(language: language, level: level, difficulty: difficulty)
        let avoid = Array((avoidItems + remembered).suffix(40))

        #if DEBUG
        print("[PronunciationContent] request lang=\(language.title) level=\(level.rawValue) difficulty=\(difficulty.rawValue) focus=\(focus.promptValue) count=\(count) avoidCount=\(avoid.count) aiConfigured=\(aiClient != nil)")
        #endif

        if let aiClient {
            do {
                let generated = try await aiClient.generateItems(
                    language: language, level: level, difficulty: difficulty,
                    focus: focus, count: count, avoidItems: avoid
                )
                if !generated.isEmpty {
                    recentStore.remember(texts: generated.map(\.text), language: language, level: level, difficulty: difficulty)
                    #if DEBUG
                    print("[PronunciationContent] AI success count=\(generated.count) fallback=false")
                    #endif
                    return PronunciationItemBatch(items: generated, usedFallback: false, fallbackReason: nil)
                }
                #if DEBUG
                print("[PronunciationContent] AI returned empty — falling back")
                #endif
            } catch {
                #if DEBUG
                print("[PronunciationContent] AI failed: \((error as? LocalizedError)?.errorDescription ?? error.localizedDescription) — falling back")
                #endif
            }
        }

        let fallback = Self.localFallback(
            language: language, level: level, difficulty: difficulty, count: count, avoid: avoid
        )
        guard !fallback.isEmpty else { throw PronunciationContentError.noItems }
        recentStore.remember(texts: fallback.map(\.text), language: language, level: level, difficulty: difficulty)

        let reason = aiClient == nil
            ? "Item generation isn't configured. Showing local items."
            : "Couldn't generate items. Showing local items."
        #if DEBUG
        print("[PronunciationContent] fallback used count=\(fallback.count) reason='\(reason)'")
        #endif
        return PronunciationItemBatch(items: fallback, usedFallback: true, fallbackReason: reason)
    }


    private struct Entry {
        let type: PronunciationItemType
        let text: String
        let translation: String?
        let focusSound: String?
        let tip: String?
        let example: String?
    }

    private static func localFallback(
        language: GrammarLanguage,
        level: EssayDifficulty,
        difficulty: PronunciationDifficulty,
        count: Int,
        avoid: [String]
    ) -> [PronunciationItem] {
        let pool = library(for: language).shuffled()
        let avoidSet = Set(avoid.map { $0.lowercased() })

        var chosen = pool.filter { !avoidSet.contains($0.text.lowercased()) }
        if chosen.count < count { chosen += pool.filter { e in !chosen.contains { $0.text == e.text } } }

        let code = language.shortTitle.lowercased()
        return chosen.prefix(count).map { entry in
            PronunciationItem(
                type: entry.type,
                text: entry.text,
                translation: entry.translation,
                languageCode: code,
                level: level,
                difficulty: difficulty,
                focusSound: entry.focusSound,
                tip: entry.tip,
                example: entry.example
            )
        }
    }

    private static func library(for language: GrammarLanguage) -> [Entry] {
        switch language {
        case .english: return english
        case .spanish: return spanish
        case .french:  return french
        case .german:  return german
        default:       return english
        }
    }


    private static let english: [Entry] = [
        Entry(type: .minimalPair, text: "ship / sheep", translation: "ship / sheep", focusSound: "ɪ vs iː", tip: "Keep the vowel short for 'ship', long for 'sheep'.", example: "The sheep is on the ship."),
        Entry(type: .word, text: "world", translation: "world", focusSound: "rl", tip: "Blend the 'r' into the 'l' at the end.", example: "The whole world is watching."),
        Entry(type: .word, text: "three", translation: "three", focusSound: "θr", tip: "Tongue between the teeth for 'th'.", example: "I have three books."),
        Entry(type: .word, text: "thought", translation: "thought", focusSound: "θ + ɔː", tip: "Soft 'th' then a rounded 'aw'.", example: "I thought about it."),
        Entry(type: .minimalPair, text: "would / wood", translation: "would / wood", focusSound: "homophone", tip: "These sound the same — relax the 'w'.", example: "I would knock on wood."),
        Entry(type: .word, text: "rural", translation: "rural", focusSound: "r-r", tip: "Two 'r' sounds close together — keep the tongue loose.", example: "They live in a rural area."),
        Entry(type: .phrase, text: "clothes on the floor", translation: "clothes on the floor", focusSound: "ðz", tip: "Don't drop the 'th' in 'clothes'.", example: nil),
        Entry(type: .word, text: "comfortable", translation: "comfortable", focusSound: "schwa", tip: "Say it as 'comf-ter-ble', three syllables.", example: "This chair is comfortable."),
        Entry(type: .minimalPair, text: "bat / bad", translation: "bat / bad", focusSound: "t vs d", tip: "Voice the final 'd' in 'bad'.", example: "The bad bat flew away."),
        Entry(type: .word, text: "squirrel", translation: "squirrel", focusSound: "skwɪrəl", tip: "Glide through the 'qu' then the 'rr'.", example: "A squirrel ran up the tree.")
    ]


    private static let spanish: [Entry] = [
        Entry(type: .minimalPair, text: "pero / perro", translation: "but / dog", focusSound: "r vs rr", tip: "Tap once for 'pero', roll for 'perro'.", example: "Pero el perro ladra."),
        Entry(type: .word, text: "gracias", translation: "thank you", focusSound: "θ/s", tip: "Soft 'c' before 'i'; clear final 's'.", example: "Muchas gracias por todo."),
        Entry(type: .sound, text: "rr", translation: nil, focusSound: "trilled r", tip: "Vibrate the tongue tip against the ridge.", example: "El perro corre."),
        Entry(type: .word, text: "calle", translation: "street", focusSound: "ll", tip: "Pronounce 'll' like a 'y'.", example: "La calle es larga."),
        Entry(type: .word, text: "jamón", translation: "ham", focusSound: "j (jota)", tip: "Strong 'h' from the back of the throat.", example: "Me gusta el jamón."),
        Entry(type: .minimalPair, text: "casa / caza", translation: "house / hunt", focusSound: "s vs θ", tip: "In Spain, 'z' is a soft 'th'.", example: "La casa y la caza."),
        Entry(type: .word, text: "desarrollar", translation: "to develop", focusSound: "rr", tip: "Roll the double 'r' clearly.", example: "Vamos a desarrollar la idea."),
        Entry(type: .phrase, text: "erre con erre", translation: "r with r", focusSound: "rr", tip: "Classic trill practice phrase.", example: nil),
        Entry(type: .word, text: "ñandú", translation: "rhea (bird)", focusSound: "ñ", tip: "Press the tongue to the palate for 'ñ'.", example: "El ñandú corre rápido."),
        Entry(type: .word, text: "guitarra", translation: "guitar", focusSound: "rr", tip: "Roll the 'rr' at the end.", example: "Toca la guitarra.")
    ]


    private static let french: [Entry] = [
        Entry(type: .word, text: "rue", translation: "street", focusSound: "French r + u", tip: "Guttural 'r' then rounded 'u'.", example: "J'habite dans cette rue."),
        Entry(type: .minimalPair, text: "tu / tout", translation: "you / all", focusSound: "y vs u", tip: "'tu' is tight lips; 'tout' is rounded 'oo'.", example: "Tu as tout vu ?"),
        Entry(type: .sound, text: "r", translation: nil, focusSound: "uvular r", tip: "Make a soft gargle at the back of the throat.", example: "Paris au revoir."),
        Entry(type: .word, text: "grenouille", translation: "frog", focusSound: "r + ouille", tip: "Combine the French 'r' with a 'y' glide.", example: "La grenouille saute."),
        Entry(type: .word, text: "écureuil", translation: "squirrel", focusSound: "euil", tip: "One of the hardest French words — go slowly.", example: "L'écureuil grimpe."),
        Entry(type: .minimalPair, text: "dessus / dessous", translation: "above / below", focusSound: "u vs ou", tip: "Front 'u' vs back 'ou'.", example: "Dessus ou dessous ?"),
        Entry(type: .word, text: "bonjour", translation: "hello", focusSound: "nasal on + r", tip: "Nasalize 'on', then the French 'r'.", example: "Bonjour, ça va ?"),
        Entry(type: .phrase, text: "un bon vin blanc", translation: "a good white wine", focusSound: "nasal vowels", tip: "Four nasal sounds in a row.", example: nil),
        Entry(type: .word, text: "heure", translation: "hour", focusSound: "eu + r", tip: "Rounded 'eu' then soft 'r'.", example: "Quelle heure est-il ?"),
        Entry(type: .word, text: "feuille", translation: "leaf", focusSound: "euille", tip: "Glide 'eu' into a 'y'.", example: "La feuille tombe.")
    ]


    private static let german: [Entry] = [
        Entry(type: .word, text: "ich", translation: "I", focusSound: "ç (ich-laut)", tip: "Soft 'h' with the tongue near the palate.", example: "Ich bin müde."),
        Entry(type: .sound, text: "ü", translation: nil, focusSound: "ü umlaut", tip: "Say 'ee' but round your lips.", example: "Über die Brücke."),
        Entry(type: .word, text: "schön", translation: "beautiful", focusSound: "sch + ö", tip: "'sch' like English 'sh', then rounded 'ö'.", example: "Das ist sehr schön."),
        Entry(type: .word, text: "Eichhörnchen", translation: "squirrel", focusSound: "ch", tip: "Famous tongue-twister word — take it slowly.", example: "Das Eichhörnchen klettert."),
        Entry(type: .minimalPair, text: "schon / schön", translation: "already / beautiful", focusSound: "o vs ö", tip: "Round the lips more for 'schön'.", example: "Schon schön, oder?"),
        Entry(type: .word, text: "Brötchen", translation: "bread roll", focusSound: "ö + ch", tip: "Rounded 'ö' then soft 'ch'.", example: "Ich kaufe ein Brötchen."),
        Entry(type: .word, text: "fünf", translation: "five", focusSound: "ü", tip: "Rounded 'ü' between 'f' and 'nf'.", example: "Ich habe fünf Bücher."),
        Entry(type: .minimalPair, text: "Kirche / Kirsche", translation: "church / cherry", focusSound: "ch vs sch", tip: "Soft 'ch' vs 'sh' sound.", example: "Die Kirche und die Kirsche."),
        Entry(type: .word, text: "Straße", translation: "street", focusSound: "ß", tip: "'ß' is a sharp 's' after a long vowel.", example: "Die Straße ist breit."),
        Entry(type: .phrase, text: "rote Rosen", translation: "red roses", focusSound: "rolled/uvular r", tip: "Two German 'r' sounds.", example: nil)
    ]
}


final class MockPronunciationContentService: PronunciationContentProviding {
    func items(
        for language: GrammarLanguage,
        level: EssayDifficulty,
        difficulty: PronunciationDifficulty,
        focus: PronunciationFocus,
        count: Int,
        avoidItems: [String]
    ) async throws -> PronunciationItemBatch {
        try? await Task.sleep(nanoseconds: 150_000_000)
        let items = [
            PronunciationItem(type: .word, text: "world", translation: "world", languageCode: "en", level: level, difficulty: difficulty, focusSound: "rl", tip: "Focus on the ending sound.", example: "The whole world."),
            PronunciationItem(type: .minimalPair, text: "ship / sheep", translation: "ship / sheep", languageCode: "en", level: level, difficulty: difficulty, focusSound: "ɪ vs iː", tip: "Short vs long vowel.", example: nil)
        ]
        return PronunciationItemBatch(items: items, usedFallback: false, fallbackReason: nil)
    }
}
