import Foundation
import Combine
import SwiftUI

@MainActor
final class GrammarNoteEditorViewModel: ObservableObject {

    enum SaveState: Equatable {
        case idle
        case saving
        case saved
        case failed(String)

        var title: String {
            switch self {
            case .idle:          return "Not saved"
            case .saving:        return "Saving..."
            case .saved:         return "Saved"
            case .failed:        return "Failed to save"
            }
        }
    }

    @Published private(set) var note: GrammarNote
    @Published var title: String
    @Published var blocks: [GrammarNoteBlock]
    @Published private(set) var saveState: SaveState = .idle
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoadingBlocks = false
    @Published private(set) var reviewToast: String?

    let ownerUID: String
    let topicId: String
    private let noteService: GrammarNoteServicing
    private let reviewService: GrammarReviewServicing
    private var autosaveTask: Task<Void, Never>?
    private var hasLoadedBlocks = false
    private var reviewToastTask: Task<Void, Never>?

    private static let autosaveDelay: UInt64 = 1_200_000_000 // 1.2 s in nanoseconds

    init(
        note: GrammarNote,
        ownerUID: String,
        topicId: String,
        noteService: GrammarNoteServicing? = nil,
        reviewService: GrammarReviewServicing? = nil
    ) {
        self.note = note
        self.ownerUID = ownerUID
        self.topicId = topicId
        self.noteService = noteService ?? GrammarNoteService()
        self.reviewService = reviewService ?? GrammarReviewService()
        self.title = note.title
        self.blocks = note.contentBlocks.sorted { $0.order < $1.order }
        self.saveState = .saved
    }

    deinit {
        autosaveTask?.cancel()
        reviewToastTask?.cancel()
    }

    func addBlock(_ type: GrammarNoteBlockType) {
        var block = GrammarNoteBlock(type: type, order: blocks.count)
        switch type {
        case .bulletList, .numberedList, .checklist:
            block.items = [""]
        case .comparison:
            block.secondaryText = ""
        default:
            break
        }
        blocks.append(block)
        scheduleAutosave()
    }

    enum TemplateApplyMode {
        case replace
        case append
    }

    func applyTemplate(_ template: GrammarNoteTemplate) {
        applyTemplate(template, mode: .replace, allowsQuiz: true)
    }

    func applyTemplate(
        _ template: GrammarNoteTemplate,
        mode: TemplateApplyMode,
        allowsQuiz: Bool
    ) {
        let now = Date()
        let templateSource = allowsQuiz ? template : template.withoutQuizBlocks()

        switch mode {
        case .replace:
            blocks = templateSource.blocks.enumerated().map { index, block in
                var copy = block
                copy.id = UUID().uuidString
                copy.order = index
                copy.createdAt = now
                copy.updatedAt = now
                return copy
            }
            note.templateId = template.id
            note.noteType = template.noteType

        case .append:
            let baseOrder = blocks.count
            let appended = templateSource.blocks.enumerated().map { index, block -> GrammarNoteBlock in
                var copy = block
                copy.id = UUID().uuidString
                copy.order = baseOrder + index
                copy.createdAt = now
                copy.updatedAt = now
                return copy
            }
            blocks.append(contentsOf: appended)
        }

        if templateSource.hasQuizBlock {
            note.hasQuiz = true
        }
        scheduleAutosave()
    }

    func deleteBlock(_ block: GrammarNoteBlock) {
        let before = blocks.count
        blocks.removeAll { $0.id == block.id }
        guard blocks.count != before else { return }
        reorderBlocks()
        scheduleAutosave()
    }

    func moveBlock(from source: IndexSet, to destination: Int) {
        guard !source.isEmpty else { return }
        blocks.move(fromOffsets: source, toOffset: destination)
        reorderBlocks()
        scheduleAutosave()
    }

    func updateBlock(_ block: GrammarNoteBlock) {
        guard let index = blocks.firstIndex(where: { $0.id == block.id }),
              blocks[index] != block else { return }
        blocks[index] = block.touching()
        scheduleAutosave()
    }

    func updateTitle(_ newTitle: String) {
        guard title != newTitle else { return }
        title = newTitle
        scheduleAutosave()
    }

    func markHasQuiz(_ value: Bool) {
        note.hasQuiz = value
    }

    func addToReview() {
        let snapshot = note
        let item = GrammarReviewItem(
            id: GrammarReviewItem.id(forNoteTopicId: snapshot.topicId, noteId: snapshot.id),
            ownerUID: snapshot.ownerUID,
            sourceType: .note,
            topicId: snapshot.topicId,
            noteId: snapshot.id,
            quizId: nil,
            title: snapshot.title.isEmpty ? "Untitled note" : snapshot.title,
            previewText: snapshot.previewText,
            languageCode: snapshot.languageCode,
            languageName: snapshot.languageName,
            priority: .normal,
            dueAt: Date(),
            createdAt: Date(),
            updatedAt: Date()
        )

        showReviewToast("Added to Review")

        let service = reviewService
        Task.detached(priority: .userInitiated) { [service, item, weak self] in
            do {
                try await service.createOrUpdateReviewItem(item)
            } catch {
                #if DEBUG
                print("[Review] addToReview failed:", error)
                #endif
                await MainActor.run {
                    self?.showReviewToast("Could not add to Review. Try again.")
                }
            }
        }
    }

    private func showReviewToast(_ message: String) {
        reviewToastTask?.cancel()
        reviewToast = message
        reviewToastTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            await MainActor.run {
                guard self?.reviewToast == message else { return }
                self?.reviewToast = nil
            }
        }
    }

    func loadBlocks() async {
        guard !isLoadingBlocks, !hasLoadedBlocks else { return }
        guard blocks.isEmpty else { hasLoadedBlocks = true; return }

        isLoadingBlocks = true
        defer { isLoadingBlocks = false }

        guard let fullNote = try? await noteService.fetchNote(
            id: note.id,
            ownerUID: ownerUID,
            topicId: topicId
        ) else {
            hasLoadedBlocks = true
            return
        }

        note = fullNote
        blocks = fullNote.contentBlocks.sorted { $0.order < $1.order }
        hasLoadedBlocks = true
    }

    func saveNow() async {
        autosaveTask?.cancel()
        await performSave()
    }

    func saveIfDirty() async {
        guard saveState != .saved else { return }
        await saveNow()
    }

    private func scheduleAutosave() {
        autosaveTask?.cancel()
        saveState = .saving
        autosaveTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(nanoseconds: Self.autosaveDelay)
                guard !Task.isCancelled else { return }
                await self.performSave()
            } catch {
            }
        }
    }

    private func performSave() async {
        let now = Date()
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedBlocks = Self.reindexed(blocks)

        var updatedNote = note
        updatedNote.title = cleanTitle.isEmpty ? "Untitled note" : cleanTitle
        updatedNote.contentBlocks = cleanedBlocks
        updatedNote.plainTextContent = Self.makePlainText(from: cleanedBlocks)
        updatedNote.previewText = Self.makePreviewText(from: cleanedBlocks, fallback: updatedNote.previewText)
        updatedNote.hasQuiz = updatedNote.hasQuiz || cleanedBlocks.contains { $0.type == .quiz }
        updatedNote.searchableText = GrammarNoteSearchIndexer.makeSearchableText(
            title: updatedNote.title,
            previewText: updatedNote.previewText,
            tags: updatedNote.tags,
            noteType: updatedNote.noteType,
            blocks: cleanedBlocks,
            plainTextContent: updatedNote.plainTextContent
        )
        updatedNote.updatedAt = now
        updatedNote.lastEditedAt = now

        do {
            try await noteService.updateNote(updatedNote)
            note = updatedNote
            blocks = cleanedBlocks
            saveState = .saved
            errorMessage = nil
            GrammarReviewViewModel.recordEditedNote(updatedNote)
        } catch {
            saveState = .failed(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }

    func recordOpened() {
        let snapshot = note
        GrammarReviewViewModel.recordOpenedNote(snapshot)

        let service = noteService
        let now = Date()
        Task.detached(priority: .background) {
            do {
                try await service.setNoteRecentlyOpenedAt(
                    id: snapshot.id,
                    ownerUID: snapshot.ownerUID,
                    topicId: snapshot.topicId,
                    openedAt: now
                )
            } catch {
                #if DEBUG
                print("[Review] setNoteRecentlyOpenedAt failed:", error)
                #endif
            }
        }
    }

    private func reorderBlocks() {
        blocks = Self.reindexed(blocks)
    }

    private static func reindexed(_ blocks: [GrammarNoteBlock]) -> [GrammarNoteBlock] {
        blocks.enumerated().map { index, block in
            guard block.order != index else { return block }
            var copy = block; copy.order = index; return copy
        }
    }

    static func makePlainText(from blocks: [GrammarNoteBlock]) -> String {
        blocks
            .flatMap { block -> [String] in
                var parts = [block.text]
                if let secondary = block.secondaryText { parts.append(secondary) }
                parts.append(contentsOf: block.items)
                if let caption = block.imageCaption { parts.append(caption) }
                return parts
            }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    static func makePreviewText(from blocks: [GrammarNoteBlock], fallback: String) -> String {
        let first = blocks
            .flatMap { [$0.text, $0.secondaryText ?? ""] + $0.items }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? fallback
        return String(first.prefix(180))
    }
}
