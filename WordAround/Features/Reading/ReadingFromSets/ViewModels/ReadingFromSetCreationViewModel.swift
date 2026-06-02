import SwiftUI
import Combine
import FirebaseAuth

@MainActor
final class ReadingFromSetCreationViewModel: ObservableObject {
    let mode: ReadingMode

    @Published private(set) var availableSets: [FlashcardSet] = []
    @Published private(set) var isLoadingSets = false
    @Published var isShowingSetPicker = false
    @Published private(set) var vocabulary: ReadingFromSetVocabulary?

    @Published var difficulty: EssayDifficulty = .b1
    @Published var length: ReadingLength = .medium
    @Published var generationMode: ReadingGenerationStyle = .natural
    @Published var language: GrammarLanguage = .english
    @Published var readingFocus: ReadingFocus = .mainIdea

    @Published private(set) var isGenerating = false
    @Published var errorMessage: String?
    @Published var createdItem: ReadingLibraryItem?

    private let generator: ReadingFromSetGenerating
    private let storage: ReadingStorageServicing
    private let analyzer: ReadingTextAnalyzing
    private let setService: FlashcardSetService
    private let currentUserId: () -> String?

    init(
        mode: ReadingMode,
        generator: ReadingFromSetGenerating = ReadingFromSetGenerationService(),
        storage: ReadingStorageServicing = ReadingStorageService(),
        analyzer: ReadingTextAnalyzing = ReadingTextAnalyzerService.shared,
        setService: FlashcardSetService = FlashcardSetService(),
        currentUserId: @escaping () -> String? = { Auth.auth().currentUser?.uid }
    ) {
        self.mode = mode
        self.generator = generator
        self.storage = storage
        self.analyzer = analyzer
        self.setService = setService
        self.currentUserId = currentUserId
    }

    private var config: ReadingSetupConfig { ReadingSetupConfig.readingFromSets }
    var accent: Color { config.accent }
    var accentDark: Color { config.accentDark }

    var hasSet: Bool { vocabulary != nil }
    var wordCount: Int { vocabulary?.count ?? 0 }
    var setTitle: String { vocabulary?.setTitle ?? "" }
    var previewTerms: [String] { Array((vocabulary?.terms ?? []).prefix(14)) }
    var canGenerate: Bool { wordCount >= ReadingFromSetVocabularyExtractor.minimumWords && !isGenerating }

    let generationModeOptions: [ReadingGenerationStyle] = [.natural, .strict, .mixed]
    let lengthOptions: [ReadingLength] = [.short, .medium, .long]
    let difficultyOptions: [EssayDifficulty] = [.a1, .a2, .b1, .b2, .c1]

    func loadSets() async {
        guard let userId = currentUserId() else {
            errorMessage = "Sign in to create readings from your sets."
            return
        }
        isLoadingSets = true
        defer { isLoadingSets = false }
        do {
            availableSets = try await setService.fetchSets(for: userId)
        } catch {
            errorMessage = "Couldn't load your sets. Check your connection and try again."
            #if DEBUG
            print("[ReadingFromSetCreationViewModel] loadSets failed:", error)
            #endif
        }
    }

    func presentSetPicker() {
        errorMessage = nil
        isShowingSetPicker = true
    }

    func handleSetSelected(_ set: FlashcardSet) {
        do {
            vocabulary = try ReadingFromSetVocabularyExtractor.extract(from: set)
            errorMessage = nil
        } catch {
            vocabulary = nil
            errorMessage = error.localizedDescription
        }
    }

    func generate() {
        guard let vocab = vocabulary else {
            errorMessage = "Choose a set first."
            return
        }
        guard vocab.count >= ReadingFromSetVocabularyExtractor.minimumWords else {
            errorMessage = "This set needs at least \(ReadingFromSetVocabularyExtractor.minimumWords) words to create a reading."
            return
        }
        guard let userId = currentUserId() else {
            errorMessage = "Sign in to create readings from your sets."
            return
        }
        guard !isGenerating else { return }

        isGenerating = true
        errorMessage = nil

        let request = ReadingFromSetGenerationRequest(
            setId: vocab.setId,
            setTitle: vocab.setTitle,
            words: vocab.words,
            targetLanguage: language,
            difficulty: difficulty,
            length: length,
            generationMode: generationMode,
            readingFocus: readingFocus
        )

        Task {
            defer { isGenerating = false }
            do {
                let generated = try await generator.generateReading(from: request)
                let title = makeTitle(generated: generated, setTitle: vocab.setTitle)
                let analysis = analyzer.analyze(
                    title: title,
                    content: generated.body,
                    language: language,
                    manualLevel: difficulty
                )

                var selections: [String: String] = [
                    "setTitle": vocab.setTitle,
                    "length": length.title,
                    "style": generationMode.title,
                    "wordCount": String(vocab.count)
                ]
                if let termsJSON = try? JSONEncoder().encode(vocab.terms),
                   let termsString = String(data: termsJSON, encoding: .utf8) {
                    selections["source.vocabularyTerms"] = termsString
                }
                selections["source.setId"] = vocab.setId
                selections["source.setTitle"] = vocab.setTitle

                let item = ReadingLibraryItem(
                    userId: userId,
                    modeID: mode.id,
                    title: title,
                    preview: analysis.preview,
                    fullText: analysis.normalizedContent,
                    difficulty: difficulty.rawValue,
                    estimatedMinutes: analysis.estimatedReadingMinutes,
                    tags: [vocab.setTitle, "\(vocab.count) words"],
                    sourceType: .flashcardSet,
                    sourceId: vocab.setId,
                    status: .new,
                    selections: selections,
                    languageCode: language.rawValue,
                    wordCount: analysis.wordCount,
                    characterCount: analysis.normalizedContent.count,
                    detectedDifficulty: analysis.estimatedLevel.rawValue,
                    readingFocus: readingFocus.rawValue
                )

                try await storage.saveItem(item, for: userId)
                createdItem = item
            } catch let error as ReadingFromSetGenerationError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = "Couldn't save the reading. Check your connection and try again."
                #if DEBUG
                print("[ReadingFromSetCreationViewModel] generate failed:", error)
                #endif
            }
        }
    }

    private func makeTitle(generated: ReadingGeneratedReadingText, setTitle: String) -> String {
        if let t = generated.title?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty {
            return t
        }
        return "\(setTitle) — Reading"
    }
}
