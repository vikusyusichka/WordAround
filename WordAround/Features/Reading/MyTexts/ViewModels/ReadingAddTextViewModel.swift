import Foundation
import Combine
import SwiftUI
import PhotosUI
import UIKit

@MainActor
final class ReadingAddTextViewModel: ObservableObject {
    @Published var title = ""
    @Published var editorText = ""
    @Published var importSourceTitle = ReadingTextImportSource.pasteText.title
    @Published var selectedLanguage: GrammarLanguage = .english
    @Published var difficultyModeTitle = ReadingMyTextsDifficultyMode.autoDetect.title
    @Published var manualLevelTitle = ReadingManualLevel.b1.rawValue
    @Published var readingFocusTitle = ReadingFocus.mainIdea.title
    @Published var enabledQuestionTypes: Set<ReadingQuestionType> = ReadingQuestionType.defaultEnabled
    @Published var assistance = ReadingAssistanceOptions.default

    @Published var isSaving = false
    @Published var saveStatusMessage: String?
    @Published var validationMessage: String?
    @Published var importErrorMessage: String?
    @Published var isImporting = false

    @Published var savedText: ReadingUserText?
    @Published var shouldStartSession = false

    // MARK: - Generate Text inputs

    @Published var generateTopic = ""
    @Published var generateStyleTitle: String = MyTextsAIGenerationRequest.Style.informative.title
    @Published var generateLengthTitle: String = ReadingLength.medium.title
    @Published var isGenerating = false
    @Published var generateErrorMessage: String?

    // MARK: - Explore Reading inputs

    @Published var exploreTopic = ""
    @Published var exploreSourceTitle: String = MyTextsExploreRequest.SourcePreference.wikipedia.title
    @Published var exploreLengthTitle: String = ReadingLength.medium.title
    @Published var isExploring = false
    @Published var exploreErrorMessage: String?
    @Published private(set) var exploreSourceLabel: String?
    @Published private(set) var exploreResultIsPlaceholder = false

    // MARK: - Dependencies

    private let storage: ReadingMyTextsStorageServicing
    private let analyzer: ReadingTextAnalyzing
    private let detector: ReadingDifficultyDetector
    private let ocr: ReadingOCRServicing
    private let pdfImporter: ReadingPDFImportServicing
    private let aiGenerator: MyTextsAIGenerating
    private let explorer: MyTextsExploreReading

    private var sourceType: ReadingSourceType = .pastedText
    private var pendingSourceMetadata: [String: String] = [:]

    init(
        storage: ReadingMyTextsStorageServicing = ReadingMyTextsStorageService.shared,
        analyzer: ReadingTextAnalyzing = ReadingTextAnalyzerService.shared,
        detector: ReadingDifficultyDetector = .shared,
        ocr: ReadingOCRServicing = ReadingOCRService.shared,
        pdfImporter: ReadingPDFImportServicing = ReadingPDFImportService.shared,
        aiGenerator: MyTextsAIGenerating = MyTextsAIGenerationService(),
        explorer: MyTextsExploreReading = MyTextsExploreReadingService()
    ) {
        self.storage = storage
        self.analyzer = analyzer
        self.detector = detector
        self.ocr = ocr
        self.pdfImporter = pdfImporter
        self.aiGenerator = aiGenerator
        self.explorer = explorer
    }

    var wordCount: Int { analyzer.wordCount(for: editorText) }
    var characterCount: Int { editorText.count }
    var estimatedMinutes: Int { analyzer.estimatedReadingMinutes(wordCount: wordCount) }

    var detectedLevel: EssayDifficulty {
        detector.detect(content: editorText, wordCount: wordCount)
    }

    var resolvedLevel: EssayDifficulty {
        if ReadingMyTextsDifficultyMode.from(title: difficultyModeTitle) == .manual {
            return ReadingManualLevel.from(title: manualLevelTitle).essayDifficulty
        }
        return detectedLevel
    }

    var canSave: Bool {
        !isSaving && wordCount >= 20 && !editorText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var currentSource: ReadingTextImportSource {
        ReadingTextImportSource.from(title: importSourceTitle)
    }

    func clearValidation() {
        validationMessage = nil
        importErrorMessage = nil
        generateErrorMessage = nil
        exploreErrorMessage = nil
    }

    func setImportSource(_ title: String) {
        importSourceTitle = title
        clearValidation()
    }

    func toggleQuestionType(_ type: ReadingQuestionType) {
        if enabledQuestionTypes.contains(type) {
            if enabledQuestionTypes.count > 1 {
                enabledQuestionTypes.remove(type)
            }
        } else {
            enabledQuestionTypes.insert(type)
        }
    }

    func applyImportedText(_ text: String, source: ReadingSourceType) {
        editorText = text
        sourceType = source
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            title = suggestedTitle(from: text)
        }
        importErrorMessage = nil
    }

    // MARK: - Photo / PDF imports (unchanged)

    func importPhoto(_ item: PhotosPickerItem) async {
        isImporting = true
        importErrorMessage = nil
        defer { isImporting = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                importErrorMessage = "Could not read that image. Try another photo."
                return
            }
            let text = try await ocr.extractText(from: image)
            applyImportedText(text, source: .photoImport)
            importSourceTitle = ReadingTextImportSource.photo.title
            pendingSourceMetadata = ["importedAt": ISO8601DateFormatter().string(from: Date())]
        } catch let error as ReadingOCRError {
            importErrorMessage = error.errorDescription
        } catch {
            importErrorMessage = "Could not read text from the photo. Try a clearer image."
        }
    }

    func importPDF(url: URL) {
        isImporting = true
        importErrorMessage = nil
        defer { isImporting = false }

        do {
            let text = try pdfImporter.extractText(from: url)
            applyImportedText(text, source: .pdfImport)
            importSourceTitle = ReadingTextImportSource.pdf.title
            pendingSourceMetadata = [
                "importedAt": ISO8601DateFormatter().string(from: Date()),
                "fileName": url.lastPathComponent
            ]
        } catch let error as ReadingPDFImportError {
            importErrorMessage = error.errorDescription
        } catch {
            importErrorMessage = "Could not import this PDF. Try another file."
        }
    }

    func importCameraImage(_ image: UIImage) async {
        isImporting = true
        importErrorMessage = nil
        defer { isImporting = false }

        do {
            let text = try await ocr.extractText(from: image)
            applyImportedText(text, source: .photoImport)
            importSourceTitle = ReadingTextImportSource.photo.title
            pendingSourceMetadata = ["importedAt": ISO8601DateFormatter().string(from: Date())]
        } catch let error as ReadingOCRError {
            importErrorMessage = error.errorDescription
        } catch {
            importErrorMessage = "Could not read text from the photo."
        }
    }

    // MARK: - Generate Text

    var canGenerate: Bool {
        !isGenerating && !generateTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func generateText() async {
        guard canGenerate else { return }
        isGenerating = true
        generateErrorMessage = nil
        defer { isGenerating = false }

        let request = MyTextsAIGenerationRequest(
            topic: generateTopic,
            language: selectedLanguage,
            level: resolvedLevel,
            length: ReadingLength.allCases.first { $0.title == generateLengthTitle } ?? .medium,
            style: MyTextsAIGenerationRequest.Style.from(title: generateStyleTitle),
            focus: ReadingFocus.from(title: readingFocusTitle)
        )

        do {
            let result = try await aiGenerator.generate(request)
            editorText = result.body
            if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                title = result.title
            }
            sourceType = .aiGenerated
            pendingSourceMetadata = [
                "topic": result.topic,
                "sourceTitle": result.title,
                "style": request.style.rawValue,
                "generatedByAI": "true",
                "generatedAt": ISO8601DateFormatter().string(from: Date())
            ]
        } catch let error as MyTextsAIGenerationError {
            generateErrorMessage = error.errorDescription
        } catch {
            generateErrorMessage = "Could not generate that text. Try a different topic."
        }
    }

    // MARK: - Explore Reading

    var canExplore: Bool {
        !isExploring && !exploreTopic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func exploreReading() async {
        guard canExplore else { return }
        isExploring = true
        exploreErrorMessage = nil
        defer { isExploring = false }

        let request = MyTextsExploreRequest(
            topic: exploreTopic,
            language: selectedLanguage,
            preference: MyTextsExploreRequest.SourcePreference.from(title: exploreSourceTitle),
            length: ReadingLength.allCases.first { $0.title == exploreLengthTitle } ?? .medium
        )

        do {
            let result = try await explorer.fetch(request)
            editorText = result.body
            if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                title = result.title
            }
            sourceType = .exploredArticle
            exploreSourceLabel = result.sourceLabel
            exploreResultIsPlaceholder = result.isPlaceholder
            var metadata: [String: String] = [
                "topic": result.topic,
                "sourceTitle": result.title,
                "preference": request.preference.rawValue,
                "sourceLabel": result.sourceLabel,
                "isPlaceholder": result.isPlaceholder ? "true" : "false",
                "fetchedAt": ISO8601DateFormatter().string(from: result.fetchedAt)
            ]
            if let url = result.sourceURL {
                metadata["originalSourceURL"] = url.absoluteString
            }
            pendingSourceMetadata = metadata
        } catch let error as MyTextsExploreError {
            exploreErrorMessage = error.errorDescription
        } catch {
            exploreErrorMessage = "Could not load that article. Try another topic."
        }
    }

    // MARK: - Lifecycle

    func cancel() {
        savedText = nil
        shouldStartSession = false
    }

    func save(startSession: Bool) async {
        clearValidation()
        guard validate() else { return }

        isSaving = true
        saveStatusMessage = "Saving…"
        defer { isSaving = false }

        guard storage.currentUserId() != nil else {
            validationMessage = "Please sign in to save your text."
            saveStatusMessage = nil
            return
        }

        let trimmedContent = editorText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = trimmedTitle.isEmpty ? suggestedTitle(from: trimmedContent) : trimmedTitle
        let detected = detector.detect(content: trimmedContent, wordCount: wordCount)
        let level = resolvedLevel

        let text = ReadingUserText(
            title: finalTitle,
            content: analyzer.analyze(
                title: finalTitle,
                content: trimmedContent,
                language: selectedLanguage,
                manualLevel: ReadingMyTextsDifficultyMode.from(title: difficultyModeTitle) == .manual ? level : nil
            ).normalizedContent,
            language: selectedLanguage,
            level: level,
            wordCount: wordCount,
            estimatedReadingMinutes: estimatedMinutes,
            preview: analyzer.preview(for: trimmedContent, maxLength: 120),
            readingFocus: ReadingFocus.from(title: readingFocusTitle),
            enabledQuestionTypes: enabledQuestionTypes,
            assistance: assistance,
            sourceType: sourceType,
            detectedLevel: detected,
            characterCount: characterCount,
            status: startSession ? .inProgress : .new,
            sourceMetadata: pendingSourceMetadata
        )

        do {
            try await storage.save(text)
            saveStatusMessage = "Saved"
            savedText = text
            shouldStartSession = startSession
        } catch {
            validationMessage = "Could not save your text. Check your connection and try again."
            saveStatusMessage = nil
        }
    }

    private func validate() -> Bool {
        if editorText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationMessage = "Please add a text first."
            return false
        }
        if wordCount < 20 {
            validationMessage = "Add at least 20 words."
            return false
        }
        validationMessage = nil
        return true
    }

    private func suggestedTitle(from content: String) -> String {
        let firstLine = content
            .components(separatedBy: .newlines)
            .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? "My reading text"
        if firstLine.count <= 48 { return firstLine }
        return String(firstLine.prefix(45)) + "…"
    }
}
