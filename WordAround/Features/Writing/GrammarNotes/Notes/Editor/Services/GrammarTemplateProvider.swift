import Foundation

/// Top-level template provider exposing both:
///  - `topicTemplates`: curated topic packs (Spanish A1, English Tenses, etc.)
///  - `noteTemplates`: generic note templates (delegated to `GrammarNoteTemplateProvider`)
///
/// Static, local-only. Nothing here is persisted to Firestore directly;
/// producing a topic/note from a template uses the regular services.
struct GrammarTemplateProvider {
    static let shared = GrammarTemplateProvider()

    // MARK: - Topic templates

    let topicTemplates: [GrammarTopicTemplate] = [
        Self.spanishA1Essentials,
        Self.englishTensesPack,
        Self.germanCasesStarter,
        Self.frenchSurvivalGrammar,
        Self.customBlankTopic
    ]

    // MARK: - Note templates (delegated)

    var noteTemplates: [GrammarNoteTemplate] {
        GrammarNoteTemplateProvider.shared.templates
    }

    // MARK: - Filtering — topics

    func topicTemplates(languageCode: String?) -> [GrammarTopicTemplate] {
        guard let languageCode, !languageCode.isEmpty else { return topicTemplates }
        return topicTemplates.filter { $0.languageCode == nil || $0.languageCode == languageCode }
    }

    func topicTemplates(difficulty: String?) -> [GrammarTopicTemplate] {
        guard let difficulty, !difficulty.isEmpty else { return topicTemplates }
        return topicTemplates.filter { $0.difficulty.caseInsensitiveCompare(difficulty) == .orderedSame }
    }

    func topicTemplates(
        languageCode: String? = nil,
        difficulty: String? = nil,
        searchQuery: String? = nil
    ) -> [GrammarTopicTemplate] {
        var result = topicTemplates
        if let languageCode, !languageCode.isEmpty {
            result = result.filter { $0.languageCode == nil || $0.languageCode == languageCode }
        }
        if let difficulty, !difficulty.isEmpty {
            result = result.filter { $0.difficulty.caseInsensitiveCompare(difficulty) == .orderedSame }
        }
        if let trimmed = searchQuery?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
           !trimmed.isEmpty {
            result = result.filter { template in
                template.title.lowercased().contains(trimmed)
                || template.description.lowercased().contains(trimmed)
                || template.tags.contains { $0.lowercased().contains(trimmed) }
            }
        }
        return result
    }

    // MARK: - Note templates pass-through filtering

    func noteTemplates(
        noteType: GrammarNoteType? = nil,
        languageCode: String? = nil,
        difficulty: String? = nil,
        searchQuery: String? = nil
    ) -> [GrammarNoteTemplate] {
        GrammarNoteTemplateProvider.shared.templates(
            noteType: noteType,
            languageCode: languageCode,
            difficulty: difficulty,
            searchQuery: searchQuery
        )
    }

    // MARK: - Built-in topic packs

    private static let spanishA1Essentials = GrammarTopicTemplate(
        id: "topic-spanish-a1-essentials",
        title: "Spanish A1 Essentials",
        description: "The grammar core every Spanish beginner trips on — ser vs estar, gender, present tense, hay/está and questions.",
        languageCode: "es",
        languageName: "Spanish",
        icon: "text.book.closed.fill",
        colorHex: "#FF7B54",
        difficulty: "A1",
        estimatedMinutes: 45,
        noteTemplates: ordered([
            note(
                id: "es-a1-ser-estar",
                title: "Ser vs Estar",
                description: "The classic Spanish trap. When to use which copula.",
                noteType: .comparison,
                languageCode: "es",
                tags: ["A1", "verbs", "ser-estar"],
                difficulty: "A1",
                blocks: [
                    .init(type: .heading,    text: "Ser vs Estar"),
                    .init(type: .rule,       text: "Use ser for identity, origin, occupation, and permanent traits. Use estar for state, location and temporary conditions.", secondaryText: "Ser = essence. Estar = state."),
                    .init(type: .comparison, text: "Ser: Soy estudiante. (I am a student — identity)", secondaryText: "Estar: Estoy cansado. (I am tired — state)"),
                    .init(type: .example,    text: "La fiesta es en mi casa. (The party is at my house — event)", secondaryText: "Mi casa está en Madrid. (My house is in Madrid — location)"),
                    .init(type: .warning,    text: "Don't use estar for nationality, profession or material — those stay with ser."),
                    .init(type: .exercise,   text: "Fill in: Ella _____ profesora. / Hoy _____ lloviendo.")
                ]
            ),
            note(
                id: "es-a1-gender-articles",
                title: "Gender and Articles",
                description: "Every Spanish noun has a gender — choose el/la, un/una correctly.",
                noteType: .rule,
                languageCode: "es",
                tags: ["A1", "nouns", "articles"],
                difficulty: "A1",
                blocks: [
                    .init(type: .heading,     text: "Gender and Articles"),
                    .init(type: .rule,        text: "Most nouns ending in -o are masculine; most ending in -a are feminine.", secondaryText: "Articles: el/los (masc), la/las (fem); un/unos, una/unas (indefinite)."),
                    .init(type: .bulletList,  items: ["el libro (the book)", "la mesa (the table)", "un coche (a car)", "una casa (a house)"]),
                    .init(type: .warning,     text: "Watch the exceptions: el día, la mano, el problema, el mapa."),
                    .init(type: .exercise,    text: "Add the right article: ___ agua, ___ programa, ___ universidad.")
                ]
            ),
            note(
                id: "es-a1-present-tense",
                title: "Present Tense Basics",
                description: "Regular -ar, -er, -ir conjugation in the present.",
                noteType: .rule,
                languageCode: "es",
                tags: ["A1", "verbs", "present"],
                difficulty: "A1",
                blocks: [
                    .init(type: .heading,        text: "Present Tense Basics"),
                    .init(type: .rule,           text: "Drop the infinitive ending (-ar/-er/-ir), add the personal ending.", secondaryText: "hablar → habl- / comer → com- / vivir → viv-"),
                    .init(type: .numberedList,   items: ["yo hablo / como / vivo", "tú hablas / comes / vives", "él, ella habla / come / vive", "nosotros hablamos / comemos / vivimos", "ellos hablan / comen / viven"]),
                    .init(type: .example,        text: "Hablo español todos los días."),
                    .init(type: .exercise,       text: "Conjugate: trabajar, leer, escribir for yo/tú/nosotros.")
                ]
            ),
            note(
                id: "es-a1-hay-esta",
                title: "Hay vs Está",
                description: "There is / there are vs is located.",
                noteType: .comparison,
                languageCode: "es",
                tags: ["A1", "location"],
                difficulty: "A1",
                blocks: [
                    .init(type: .heading,    text: "Hay vs Está"),
                    .init(type: .rule,       text: "Use hay to say something exists (there is/are). Use está/están for known things in a specific location.", secondaryText: "Hay + indefinite/quantity. Está + definite article."),
                    .init(type: .comparison, text: "Hay un banco en la calle. (There is a bank…)", secondaryText: "El banco está en la calle. (The bank is on the street.)"),
                    .init(type: .warning,    text: "Don't say 'Hay el coche' — use 'está' with the definite article."),
                    .init(type: .exercise,   text: "Choose hay/está: ___ tres libros en la mesa. / Mi llave ___ en la mochila.")
                ]
            ),
            note(
                id: "es-a1-questions",
                title: "Basic Question Structure",
                description: "How to ask yes/no questions and use interrogatives.",
                noteType: .rule,
                languageCode: "es",
                tags: ["A1", "questions"],
                difficulty: "A1",
                blocks: [
                    .init(type: .heading,    text: "Basic Question Structure"),
                    .init(type: .rule,       text: "Spanish flips word order or just adds intonation. Question words always carry an accent.", secondaryText: "¿qué? ¿quién? ¿dónde? ¿cuándo? ¿por qué? ¿cómo?"),
                    .init(type: .example,    text: "¿Hablas inglés?", secondaryText: "¿Dónde vives?"),
                    .init(type: .warning,    text: "Spanish opens questions with ¿ — don't forget the inverted mark."),
                    .init(type: .exercise,   text: "Turn into questions: Vives en Madrid. / Tiene un perro.")
                ]
            )
        ]),
        tags: ["spanish", "A1", "essentials"]
    )

    private static let englishTensesPack = GrammarTopicTemplate(
        id: "topic-english-tenses-pack",
        title: "English Tenses Pack",
        description: "Five tenses that cover ~80% of everyday English.",
        languageCode: "en",
        languageName: "English",
        icon: "clock.fill",
        colorHex: "#4F7CFF",
        difficulty: "A2",
        estimatedMinutes: 50,
        noteTemplates: ordered([
            note(
                id: "en-a2-present-simple",
                title: "Present Simple",
                description: "Habits, facts, schedules.",
                noteType: .rule,
                languageCode: "en",
                tags: ["A2", "tense", "present-simple"],
                difficulty: "A2",
                blocks: [
                    .init(type: .heading,      text: "Present Simple"),
                    .init(type: .rule,         text: "Used for habits, general truths and fixed schedules.", secondaryText: "Subject + base verb (+ s for he/she/it)"),
                    .init(type: .numberedList, items: ["I work / You work / He works", "Negative: do/does + not + base", "Question: Do/Does + subject + base"]),
                    .init(type: .example,      text: "She speaks three languages. / The train leaves at 7."),
                    .init(type: .exercise,     text: "Write 3 sentences about your daily routine.")
                ]
            ),
            note(
                id: "en-a2-present-continuous",
                title: "Present Continuous",
                description: "Now, around now, temporary actions.",
                noteType: .rule,
                languageCode: "en",
                tags: ["A2", "tense", "present-continuous"],
                difficulty: "A2",
                blocks: [
                    .init(type: .heading,    text: "Present Continuous"),
                    .init(type: .rule,       text: "Use for actions happening now or around now, and temporary states.", secondaryText: "am/is/are + verb-ing"),
                    .init(type: .example,    text: "I am studying right now. / She's working from home this week."),
                    .init(type: .warning,    text: "Avoid with stative verbs: know, like, want, believe."),
                    .init(type: .exercise,   text: "Describe what 3 people in your room are doing.")
                ]
            ),
            note(
                id: "en-a2-past-simple",
                title: "Past Simple",
                description: "Finished actions at a defined time in the past.",
                noteType: .rule,
                languageCode: "en",
                tags: ["A2", "tense", "past-simple"],
                difficulty: "A2",
                blocks: [
                    .init(type: .heading,    text: "Past Simple"),
                    .init(type: .rule,       text: "Used for completed actions at a specific past time.", secondaryText: "Regular: verb + -ed. Irregular: see list."),
                    .init(type: .example,    text: "I visited Rome last year. / She went home early."),
                    .init(type: .warning,    text: "Watch irregular forms: go→went, have→had, see→saw, do→did."),
                    .init(type: .exercise,   text: "Write 5 sentences about yesterday.")
                ]
            ),
            note(
                id: "en-a2-present-perfect",
                title: "Present Perfect",
                description: "Past action connected to now.",
                noteType: .rule,
                languageCode: "en",
                tags: ["B1", "tense", "present-perfect"],
                difficulty: "B1",
                blocks: [
                    .init(type: .heading,    text: "Present Perfect"),
                    .init(type: .rule,       text: "Use when the time is unspecified, or for experience and recent actions still relevant now.", secondaryText: "have/has + past participle"),
                    .init(type: .example,    text: "I have lived here for 5 years. / She has just arrived."),
                    .init(type: .comparison, text: "Past simple: I saw it yesterday.", secondaryText: "Present perfect: I have seen it. (any time before now)"),
                    .init(type: .exercise,   text: "Choose past simple vs present perfect in 5 sentences.")
                ]
            ),
            note(
                id: "en-a2-future-forms",
                title: "Future Forms",
                description: "Will, going to, present continuous for future.",
                noteType: .comparison,
                languageCode: "en",
                tags: ["A2", "future"],
                difficulty: "A2",
                blocks: [
                    .init(type: .heading,    text: "Future Forms"),
                    .init(type: .rule,       text: "Three common ways to talk about the future.", secondaryText: "will (decision now / prediction), be going to (plan / evidence), present continuous (fixed arrangement)"),
                    .init(type: .comparison, text: "I'll help you. (decision now)", secondaryText: "I'm going to study tonight. (plan)"),
                    .init(type: .example,    text: "I'm meeting Anna at 6. (arrangement)"),
                    .init(type: .exercise,   text: "Match: decision / plan / arrangement to 6 sentences.")
                ]
            )
        ]),
        tags: ["english", "A2", "tenses"]
    )

    private static let germanCasesStarter = GrammarTopicTemplate(
        id: "topic-german-cases-starter",
        title: "German Cases Starter",
        description: "Nominativ, Akkusativ, Dativ, Genitiv — the foundation of German grammar.",
        languageCode: "de",
        languageName: "German",
        icon: "square.grid.2x2.fill",
        colorHex: "#7C5CFF",
        difficulty: "A2",
        estimatedMinutes: 60,
        noteTemplates: ordered([
            note(
                id: "de-nom",
                title: "Nominativ",
                description: "Subject case — who/what is doing the action.",
                noteType: .rule,
                languageCode: "de",
                tags: ["A1", "case", "nominativ"],
                difficulty: "A1",
                blocks: [
                    .init(type: .heading,    text: "Nominativ"),
                    .init(type: .rule,       text: "The Nominativ marks the subject of the sentence.", secondaryText: "Articles: der / die / das / die (pl)"),
                    .init(type: .example,    text: "Der Hund schläft. (The dog sleeps.)"),
                    .init(type: .warning,    text: "The subject can be a noun phrase, a pronoun, or a name — always Nominativ."),
                    .init(type: .exercise,   text: "Identify the Nominativ in: Die Frau liest ein Buch.")
                ]
            ),
            note(
                id: "de-akk",
                title: "Akkusativ",
                description: "Direct object case.",
                noteType: .rule,
                languageCode: "de",
                tags: ["A2", "case", "akkusativ"],
                difficulty: "A2",
                blocks: [
                    .init(type: .heading,    text: "Akkusativ"),
                    .init(type: .rule,       text: "The Akkusativ marks the direct object — what is being acted upon.", secondaryText: "Articles: den / die / das / die. Only der → den changes!"),
                    .init(type: .example,    text: "Ich sehe den Mann. / Sie liest das Buch."),
                    .init(type: .warning,    text: "Prepositions that always take Akkusativ: durch, für, gegen, ohne, um."),
                    .init(type: .exercise,   text: "Translate: I have a brother. I see the woman.")
                ]
            ),
            note(
                id: "de-dat",
                title: "Dativ",
                description: "Indirect object case.",
                noteType: .rule,
                languageCode: "de",
                tags: ["A2", "case", "dativ"],
                difficulty: "A2",
                blocks: [
                    .init(type: .heading,    text: "Dativ"),
                    .init(type: .rule,       text: "The Dativ marks the indirect object — the recipient/beneficiary.", secondaryText: "Articles: dem / der / dem / den (pl) + -n on plural noun"),
                    .init(type: .example,    text: "Ich gebe dem Kind ein Geschenk."),
                    .init(type: .warning,    text: "Dativ prepositions: aus, bei, mit, nach, seit, von, zu."),
                    .init(type: .exercise,   text: "Mark Nominativ/Akkusativ/Dativ in: Der Mann gibt der Frau das Buch.")
                ]
            ),
            note(
                id: "de-gen",
                title: "Genitiv Overview",
                description: "Possession case (formal/written German).",
                noteType: .rule,
                languageCode: "de",
                tags: ["B1", "case", "genitiv"],
                difficulty: "B1",
                blocks: [
                    .init(type: .heading,   text: "Genitiv Overview"),
                    .init(type: .rule,      text: "Used for possession and after specific prepositions. In spoken German, often replaced by 'von + Dativ'.", secondaryText: "Articles: des / der / des / der. Masculine/neuter nouns add -s or -es."),
                    .init(type: .example,   text: "Das Auto meines Vaters. / Die Farbe des Hauses."),
                    .init(type: .warning,   text: "Genitiv prepositions: während, trotz, wegen, statt — formal use."),
                    .init(type: .exercise,  text: "Rewrite using 'von + Dativ': Das Buch des Lehrers.")
                ]
            ),
            note(
                id: "de-articles-by-case",
                title: "Articles by Case",
                description: "Compact reference table.",
                noteType: .cheatSheet,
                languageCode: "de",
                tags: ["A2", "cheat-sheet"],
                difficulty: "A2",
                blocks: [
                    .init(type: .heading,    text: "Articles by Case"),
                    .init(type: .bulletList, items: [
                        "Nominativ: der / die / das / die",
                        "Akkusativ: den / die / das / die",
                        "Dativ: dem / der / dem / den (+ noun-n)",
                        "Genitiv: des / der / des / der"
                    ]),
                    .init(type: .divider),
                    .init(type: .example,    text: "Nom → Akk: der → den (the only masculine change in singular).")
                ]
            )
        ]),
        tags: ["german", "A2", "cases"]
    )

    private static let frenchSurvivalGrammar = GrammarTopicTemplate(
        id: "topic-french-survival",
        title: "French Survival Grammar",
        description: "Five rules that keep you afloat in any French conversation.",
        languageCode: "fr",
        languageName: "French",
        icon: "flag.fill",
        colorHex: "#22B07D",
        difficulty: "A1",
        estimatedMinutes: 40,
        noteTemplates: ordered([
            note(
                id: "fr-etre-avoir",
                title: "Être vs Avoir",
                description: "The two essential verbs.",
                noteType: .comparison,
                languageCode: "fr",
                tags: ["A1", "verbs", "etre-avoir"],
                difficulty: "A1",
                blocks: [
                    .init(type: .heading,    text: "Être vs Avoir"),
                    .init(type: .rule,       text: "Être = to be (identity, state, location). Avoir = to have (possession, age, sensations).", secondaryText: "je suis / tu es / il est | j'ai / tu as / il a"),
                    .init(type: .comparison, text: "Je suis fatigué. (I am tired.)", secondaryText: "J'ai faim. (I am hungry — literally: I have hunger.)"),
                    .init(type: .warning,    text: "French uses avoir where English uses 'to be': age, hunger, thirst, fear."),
                    .init(type: .exercise,   text: "Translate: I am happy. I am 25. I am hungry. I have a brother.")
                ]
            ),
            note(
                id: "fr-articles",
                title: "Definite and Indefinite Articles",
                description: "Le, la, les, un, une, des.",
                noteType: .rule,
                languageCode: "fr",
                tags: ["A1", "articles"],
                difficulty: "A1",
                blocks: [
                    .init(type: .heading,    text: "Definite and Indefinite Articles"),
                    .init(type: .rule,       text: "French has gendered articles. Use definite (le/la/les) for specific things, indefinite (un/une/des) for one of many.", secondaryText: "le + masc, la + fem, l' before vowel; les + plural"),
                    .init(type: .bulletList, items: ["le livre / la table / l'ami / les enfants", "un livre / une table / des amis"]),
                    .init(type: .warning,    text: "Both le/la become l' before a vowel or silent h."),
                    .init(type: .exercise,   text: "Add the right article: ___ chat, ___ école, ___ étudiants.")
                ]
            ),
            note(
                id: "fr-negation",
                title: "Negation with Ne...pas",
                description: "Wrap the verb to make it negative.",
                noteType: .rule,
                languageCode: "fr",
                tags: ["A1", "negation"],
                difficulty: "A1",
                blocks: [
                    .init(type: .heading,    text: "Negation with Ne...pas"),
                    .init(type: .rule,       text: "Place 'ne' before the verb and 'pas' after.", secondaryText: "ne + verb + pas"),
                    .init(type: .example,    text: "Je ne parle pas français. / Il n'aime pas le café."),
                    .init(type: .warning,    text: "In spoken French, 'ne' is often dropped: 'Je parle pas.'"),
                    .init(type: .exercise,   text: "Make negative: J'aime le thé. / Nous parlons espagnol.")
                ]
            ),
            note(
                id: "fr-questions",
                title: "Basic Questions",
                description: "Three ways to ask.",
                noteType: .rule,
                languageCode: "fr",
                tags: ["A1", "questions"],
                difficulty: "A1",
                blocks: [
                    .init(type: .heading,    text: "Basic Questions"),
                    .init(type: .rule,       text: "Three common patterns: intonation, est-ce que, inversion.", secondaryText: "Tu parles français? / Est-ce que tu parles français? / Parles-tu français?"),
                    .init(type: .example,    text: "Où est-ce que tu habites? / Comment t'appelles-tu?"),
                    .init(type: .warning,    text: "Inversion is formal — use est-ce que in everyday speech."),
                    .init(type: .exercise,   text: "Turn into questions: Tu aimes la pizza. / Il travaille ici.")
                ]
            ),
            note(
                id: "fr-adj-agreement",
                title: "Adjective Agreement",
                description: "Adjectives match the noun in gender and number.",
                noteType: .rule,
                languageCode: "fr",
                tags: ["A2", "adjectives"],
                difficulty: "A2",
                blocks: [
                    .init(type: .heading,    text: "Adjective Agreement"),
                    .init(type: .rule,       text: "Adjectives agree with the noun in gender and number.", secondaryText: "Default add -e for feminine, -s for plural, -es for feminine plural."),
                    .init(type: .example,    text: "un petit chat / une petite chatte / des petits chats / des petites chattes"),
                    .init(type: .warning,    text: "Watch irregular adjectives: beau/belle, vieux/vieille, nouveau/nouvelle."),
                    .init(type: .exercise,   text: "Agree the adjective (grand): ___ maison, ___ enfants, ___ amies.")
                ]
            )
        ]),
        tags: ["french", "A1", "survival"]
    )

    private static let customBlankTopic = GrammarTopicTemplate(
        id: "topic-custom-blank",
        title: "Custom Blank Topic",
        description: "Start from scratch — only the topic is created, no notes inside.",
        languageCode: nil,
        languageName: nil,
        icon: "doc.badge.plus",
        colorHex: "#4F7CFF",
        difficulty: "A1",
        estimatedMinutes: 1,
        noteTemplates: [],
        tags: ["blank"]
    )

    // MARK: - Private helpers

    private static func ordered(_ templates: [GrammarNoteTemplate]) -> [GrammarNoteTemplate] {
        templates.map { template in
            GrammarNoteTemplate(
                id: template.id,
                title: template.title,
                description: template.description,
                noteType: template.noteType,
                languageCode: template.languageCode,
                tags: template.tags,
                blocks: template.blocks.enumerated().map { index, block in
                    var copy = block
                    copy.order = index
                    return copy
                },
                estimatedMinutes: template.estimatedMinutes,
                difficulty: template.difficulty
            )
        }
    }

    private static func note(
        id: String,
        title: String,
        description: String,
        noteType: GrammarNoteType,
        languageCode: String?,
        tags: [String],
        difficulty: String,
        blocks: [GrammarNoteBlock]
    ) -> GrammarNoteTemplate {
        GrammarNoteTemplate(
            id: id,
            title: title,
            description: description,
            noteType: noteType,
            languageCode: languageCode,
            tags: tags,
            blocks: blocks,
            estimatedMinutes: 8,
            difficulty: difficulty
        )
    }
}
