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

    private let storage: ReadingMyTextsStorageServicing
    private let analyzer: ReadingTextAnalyzing
    private let detector: ReadingDifficultyDetector
    private let ocr: ReadingOCRServicing
    private let pdfImporter: ReadingPDFImportServicing

    private var sourceType: ReadingSourceType = .pastedText

    init(
        storage: ReadingMyTextsStorageServicing = ReadingMyTextsStorageService.shared,
        analyzer: ReadingTextAnalyzing = ReadingTextAnalyzerService.shared,
        detector: ReadingDifficultyDetector = .shared,
        ocr: ReadingOCRServicing = ReadingOCRService.shared,
        pdfImporter: ReadingPDFImportServicing = ReadingPDFImportService.shared
    ) {
        self.storage = storage
        self.analyzer = analyzer
        self.detector = detector
        self.ocr = ocr
        self.pdfImporter = pdfImporter
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

    func clearValidation() {
        validationMessage = nil
        importErrorMessage = nil
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
        } catch let error as ReadingOCRError {
            importErrorMessage = error.errorDescription
        } catch {
            importErrorMessage = "Could not read text from the photo."
        }
    }

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
            status: startSession ? .inProgress : .new
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
