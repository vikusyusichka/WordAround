import Foundation
import Combine

@MainActor
final class ReadingMyTextsViewModel: ObservableObject {
    @Published var texts: [ReadingUserText] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showAddTextSheet = false
    @Published var selectedText: ReadingUserText?
    @Published var navigateToSession = false

    private let storage: ReadingTextStorageServicing
    private let analyzer: ReadingTextAnalyzing

    init(
        storage: ReadingTextStorageServicing = ReadingTextStorageService.shared,
        analyzer: ReadingTextAnalyzing = ReadingTextAnalyzerService.shared
    ) {
        self.storage = storage
        self.analyzer = analyzer
    }

    var continueReadingText: ReadingUserText? {
        texts
            .filter { $0.progress > 0 && $0.progress < 1 && !$0.isCompleted }
            .sorted { ($0.lastOpenedAt ?? $0.updatedAt) > ($1.lastOpenedAt ?? $1.updatedAt) }
            .first
    }

    var continueText: ReadingUserText? { continueReadingText }

    var completedTexts: [ReadingUserText] {
        texts.filter(\.isCompleted)
    }

    var activeTexts: [ReadingUserText] {
        texts.filter { !$0.isCompleted }
    }

    var isEmpty: Bool { texts.isEmpty }

    var sortedTexts: [ReadingUserText] { texts }

    func loadTexts() {
        Task { await loadTextsAsync() }
    }

    func load() { loadTexts() }

    func loadTextsAsync() async {
        isLoading = true
        defer { isLoading = false }
        errorMessage = nil
        do {
            texts = try await storage.fetchTexts()
        } catch {
            errorMessage = "Could not load saved texts."
            texts = []
        }
    }

    @discardableResult
    func addText(
        title: String,
        content: String,
        language: GrammarLanguage,
        manualLevel: EssayDifficulty?,
        useAutoLevel: Bool,
        focus: ReadingFocus = .mainIdea
    ) async -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            errorMessage = "Please enter a title."
            return false
        }
        guard !trimmedContent.isEmpty else {
            errorMessage = "Please paste some text content."
            return false
        }

        let analysis = analyzer.analyze(
            title: trimmedTitle,
            content: trimmedContent,
            language: language,
            manualLevel: useAutoLevel ? nil : manualLevel
        )

        if analysis.wordCount < 20 {
            #if DEBUG
            print("ReadingMyTextsViewModel: saving short text (\(analysis.wordCount) words)")
            #endif
        }

        let text = ReadingUserText(
            title: analysis.title,
            content: analysis.normalizedContent,
            language: language,
            level: analysis.estimatedLevel,
            wordCount: analysis.wordCount,
            estimatedReadingMinutes: analysis.estimatedReadingMinutes,
            preview: analysis.preview
        )

        do {
            try await storage.saveText(text)
            texts = try await storage.fetchTexts()
            clearError()
            return true
        } catch {
            errorMessage = "Could not save text. Try again."
            return false
        }
    }

    func deleteText(_ text: ReadingUserText) {
        Task {
            do {
                try await storage.deleteText(id: text.id)
                if selectedText?.id == text.id {
                    selectedText = nil
                    navigateToSession = false
                }
                texts = try await storage.fetchTexts()
            } catch {
                errorMessage = "Could not delete text."
            }
        }
    }

    func startSession(for text: ReadingUserText) {
        selectedText = text
        navigateToSession = true
    }

    func continueText(_ text: ReadingUserText) {
        startSession(for: text)
    }

    func text(withId id: String) -> ReadingUserText? {
        texts.first { $0.id == id }
    }

    func clearError() {
        errorMessage = nil
    }
}
