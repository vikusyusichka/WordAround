import Foundation
import Combine
import SwiftUI

@MainActor
final class GrammarNoteEditorViewModel: ObservableObject {

    // MARK: - Save State
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

    // MARK: - Published
    @Published private(set) var note: GrammarNote
    @Published var title: String
    @Published var blocks: [GrammarNoteBlock]
    @Published private(set) var saveState: SaveState = .idle
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoadingBlocks = false

    // MARK: - Private
    let ownerUID: String
    let topicId: String
    private let noteService: GrammarNoteServicing
    private var autosaveTask: Task<Void, Never>?
    private var hasLoadedBlocks = false

    private static let autosaveDelay: UInt64 = 1_200_000_000 // 1.2 s in nanoseconds

    // MARK: - Init / deinit
    init(
        note: GrammarNote,
        ownerUID: String,
        topicId: String,
        noteService: GrammarNoteServicing? = nil
    ) {
        self.note = note
        self.ownerUID = ownerUID
        self.topicId = topicId
        self.noteService = noteService ?? GrammarNoteService()
        self.title = note.title
        self.blocks = note.contentBlocks.sorted { $0.order < $1.order }
        self.saveState = .saved
    }

    deinit { autosaveTask?.cancel() }

    // MARK: - Public mutations
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

    func applyTemplate(_ template: GrammarNoteTemplate) {
        blocks = template.blocks.enumerated().map { index, block in
            var copy = block
            copy.id = UUID().uuidString
            copy.order = index
            copy.createdAt = Date()
            copy.updatedAt = Date()
            return copy
        }
        note.templateId = template.id
        note.noteType = template.noteType
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

    // MARK: - Block loading (lazy — called when the note was opened from a list preview)
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

    // MARK: - Save
    func saveNow() async {
        autosaveTask?.cancel()
        await performSave()
    }

    /// Saves only if there are unsaved changes; called on editor dismissal to
    /// avoid a redundant Firestore write when state is already `.saved`.
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
                // Task was cancelled — no-op
            }
        }
    }

    // MARK: - Private helpers
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
        updatedNote.updatedAt = now
        updatedNote.lastEditedAt = now

        do {
            try await noteService.updateNote(updatedNote)
            note = updatedNote
            blocks = cleanedBlocks
            saveState = .saved
            errorMessage = nil
        } catch {
            saveState = .failed(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }

    private func reorderBlocks() {
        blocks = Self.reindexed(blocks)
    }

    // MARK: - Static text helpers
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
