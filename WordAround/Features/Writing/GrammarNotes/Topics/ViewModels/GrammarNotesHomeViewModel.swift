import Foundation
import FirebaseFirestore
import Combine
import SwiftUI

@MainActor
final class GrammarNotesHomeViewModel: ObservableObject {
    @Published private(set) var topics: [GrammarNoteTopic] = []
    @Published private(set) var filteredTopics: [GrammarNoteTopic] = []
    @Published private(set) var topicOptions: [GrammarQuickTopicOption] = []
    @Published private(set) var regularTopicOptions: [GrammarQuickTopicOption] = []
    @Published private(set) var mistakesTopicOption: GrammarQuickTopicOption?
    @Published private(set) var isLoading = false
    @Published private(set) var isCreatingTopic = false
    @Published private(set) var isCreatingQuickNote = false
    @Published private(set) var isCreatingQuickMistake = false
    @Published var searchText = ""
    @Published var loadError: String?
    @Published var createTopicError: String?
    @Published private(set) var quickNoteError: String?
    @Published private(set) var quickMistakeError: String?

    private let ownerUID: String
    private let service: GrammarNoteTopicServicing
    private let noteService: GrammarNoteServicing
    private let createQuickNoteUseCase: CreateQuickGrammarNoteUseCase
    private let saveQuickMistakeUseCase: SaveQuickGrammarMistakeUseCase
    private var isEnsuringDefaultTopic = false
    private var isFetchingTopics = false
    private var cancellables = Set<AnyCancellable>()

    var hasOnlyMistakesTopic: Bool {
        topics.filter { !$0.isMistakesTopic }.isEmpty
    }

    init(
        ownerUID: String,
        service: GrammarNoteTopicServicing? = nil,
        noteService: GrammarNoteServicing? = nil,
        previewTopics: [GrammarNoteTopic] = []
    ) {
        self.ownerUID = ownerUID
        let resolvedTopicService = service ?? GrammarNoteTopicService()
        let resolvedNoteService = noteService ?? GrammarNoteService()
        self.service = resolvedTopicService
        self.noteService = resolvedNoteService
        self.createQuickNoteUseCase = CreateQuickGrammarNoteUseCase(noteService: resolvedNoteService)
        self.saveQuickMistakeUseCase = SaveQuickGrammarMistakeUseCase(noteService: resolvedNoteService)
        updateTopics(previewTopics)
        bindSearch()
    }

    func loadTopics() async {
        guard !ownerUID.isEmpty else {
            loadError = "User session is not available. Please sign in again."
            return
        }
        guard !isFetchingTopics else { return }
        isFetchingTopics = true
        defer { isFetchingTopics = false }

        if topics.isEmpty {
            if let cached = try? await service.fetchTopics(for: ownerUID, source: .cache),
               !cached.isEmpty {
                updateTopics(sortTopics(cached))
            }
        }

        let needsSpinner = topics.isEmpty
        if needsSpinner { isLoading = true }
        defer { isLoading = false }
        loadError = nil

        do {
            var loadedTopics = try await service.fetchTopics(for: ownerUID)
            loadedTopics = try await ensureCommonMistakesTopicExists(in: loadedTopics)
            updateTopics(sortTopics(loadedTopics))
        } catch {
            if topics.isEmpty {
                loadError = readableMessage(for: error)
            }
        }
    }

    func createTopic(
        title: String,
        description: String,
        languageCode: String,
        languageName: String,
        icon: String,
        colorHex: String
    ) async -> Bool {
        guard !isCreatingTopic else { return false }

        isCreatingTopic = true
        createTopicError = nil
        defer { isCreatingTopic = false }

        await Task.yield()

        guard !ownerUID.isEmpty else {
            createTopicError = "User session is not available. Please sign in again."
            #if DEBUG
            print("[CreateTopic] failed: ownerUID is empty")
            #endif
            return false
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            createTopicError = "Topic title is required."
            return false
        }
        guard trimmedTitle.count <= 40 else {
            createTopicError = "Topic title must be under 40 characters."
            return false
        }
        guard trimmedDescription.count <= 120 else {
            createTopicError = "Description must be under 120 characters."
            return false
        }

        let now = Date()
        let topic = GrammarNoteTopic(
            id: UUID().uuidString,
            ownerUID: ownerUID,
            title: trimmedTitle,
            description: trimmedDescription,
            languageCode: languageCode,
            languageName: languageName,
            icon: icon,
            colorHex: colorHex,
            notesCount: 0,
            isPinned: false,
            isMistakesTopic: false,
            createdAt: now,
            updatedAt: now
        )

        #if DEBUG
        print("[CreateTopic] saving to users/\(ownerUID)/grammarNoteTopics/\(topic.id)")
        #endif

        do {
            try await service.createTopic(topic)
            updateTopics(sortTopics(topics + [topic]))
            #if DEBUG
            print("[CreateTopic] saved id=\(topic.id)")
            #endif
            return true
        } catch {
            createTopicError = readableMessage(for: error)
            #if DEBUG
            print("[CreateTopic] failed:", error)
            #endif
            return false
        }
    }

    func createTopicFromTemplate(
        _ template: GrammarTopicTemplate,
        settings: GrammarNotesSettingsStore
    ) async -> GrammarNoteTopic? {
        guard !isCreatingTopic else { return nil }

        isCreatingTopic = true
        createTopicError = nil
        defer { isCreatingTopic = false }

        await Task.yield()

        guard !ownerUID.isEmpty else {
            createTopicError = "User session is not available. Please sign in again."
            #if DEBUG
            print("[CreateTopicFromTemplate] failed: ownerUID empty")
            #endif
            return nil
        }

        let effectiveTemplate = settings.allowQuickQuizzes
            ? template
            : template.withoutQuizBlocks()

        let now = Date()
        let topicID = UUID().uuidString
        let topic = GrammarNoteTopic(
            id: topicID,
            ownerUID: ownerUID,
            title: effectiveTemplate.title,
            description: effectiveTemplate.description,
            languageCode: effectiveTemplate.languageCode ?? "",
            languageName: effectiveTemplate.languageName ?? "",
            icon: effectiveTemplate.icon,
            colorHex: effectiveTemplate.colorHex,
            notesCount: 0,
            isPinned: false,
            isMistakesTopic: false,
            createdAt: now,
            updatedAt: now
        )

        #if DEBUG
        print("[CreateTopicFromTemplate] writing topic \(topicID) with \(effectiveTemplate.noteTemplates.count) notes")
        #endif

        do {
            try await service.createTopic(topic)
        } catch {
            createTopicError = readableMessage(for: error)
            #if DEBUG
            print("[CreateTopicFromTemplate] topic write failed:", error)
            #endif
            return nil
        }

        var savedCount = 0
        for (index, noteTemplate) in effectiveTemplate.noteTemplates.enumerated() {
            let blocks = noteTemplate.blocks.enumerated().map { i, block -> GrammarNoteBlock in
                var copy = block
                copy.id = UUID().uuidString
                copy.order = i
                copy.createdAt = now
                copy.updatedAt = now
                return copy
            }
            let plainText = Self.plainText(from: blocks)
            let previewText = Self.previewText(from: blocks, fallback: noteTemplate.description)

            let note = GrammarNote(
                id: UUID().uuidString,
                ownerUID: ownerUID,
                topicId: topicID,
                title: noteTemplate.title,
                previewText: previewText,
                languageCode: effectiveTemplate.languageCode ?? noteTemplate.languageCode ?? "",
                languageName: effectiveTemplate.languageName ?? "",
                noteType: noteTemplate.noteType,
                tags: noteTemplate.tags,
                imageURLs: [],
                isPinned: false,
                isFavorite: false,
                isMistakeNote: noteTemplate.noteType == .mistake,
                savedIssueKey: nil,
                hasQuiz: blocks.contains { $0.type == .quiz },
                contentBlocks: blocks,
                plainTextContent: plainText,
                coverImageURL: nil,
                localImagePaths: [],
                templateId: noteTemplate.id,
                createdAt: now,
                updatedAt: now,
                lastEditedAt: now,
                searchableText: GrammarNoteSearchIndexer.makeSearchableText(
                    title: noteTemplate.title,
                    previewText: previewText,
                    tags: noteTemplate.tags,
                    noteType: noteTemplate.noteType,
                    blocks: blocks,
                    plainTextContent: plainText
                )
            )

            do {
                try await noteService.createNote(note)
                savedCount += 1
                #if DEBUG
                print("[CreateTopicFromTemplate] note \(index + 1)/\(effectiveTemplate.noteTemplates.count) saved")
                #endif
            } catch {
                #if DEBUG
                print("[CreateTopicFromTemplate] note \(index + 1) failed (continuing):", error)
                #endif
            }
        }

        var localTopic = topic
        localTopic.notesCount = savedCount
        updateTopics(sortTopics(topics + [localTopic]))

        return localTopic
    }

    private static func plainText(from blocks: [GrammarNoteBlock]) -> String {
        blocks.flatMap { block -> [String] in
            var parts: [String] = []
            if !block.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { parts.append(block.text) }
            if let s = block.secondaryText,
               !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { parts.append(s) }
            parts.append(contentsOf: block.items.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
            return parts
        }
        .joined(separator: "\n")
    }

    private static func previewText(from blocks: [GrammarNoteBlock], fallback: String) -> String {
        let first = blocks
            .flatMap { [$0.text, $0.secondaryText ?? ""] + $0.items }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? fallback
        return String(first.prefix(180))
    }

    func deleteTopic(_ topic: GrammarNoteTopic) async {
        guard !topic.isMistakesTopic else { return }
        do {
            try await service.deleteTopic(id: topic.id, ownerUID: ownerUID)
            updateTopics(topics.filter { $0.id != topic.id })
            loadError = nil
        } catch {
            loadError = readableMessage(for: error)
        }
    }

    func moveTopics(from source: IndexSet, to destination: Int) {
        var reordered = topics
        reordered.move(fromOffsets: source, toOffset: destination)

        if let mistakesIndex = reordered.firstIndex(where: { $0.isMistakesTopic }),
           mistakesIndex != 0 {
            let mistakes = reordered.remove(at: mistakesIndex)
            reordered.insert(mistakes, at: 0)
        }

        for (offset, _) in reordered.enumerated() {
            reordered[offset].sortIndex = offset
        }

        updateTopics(reordered)
        persistTopicOrder(reordered)
    }

    private func persistTopicOrder(_ orderedTopics: [GrammarNoteTopic]) {
        guard !ownerUID.isEmpty else { return }
        let indices = orderedTopics.enumerated().map { (id: $1.id, sortIndex: $0) }
        let topicService = service
        let owner = ownerUID
        Task.detached(priority: .utility) {
            do {
                try await topicService.updateTopicSortIndices(
                    ownerUID: owner,
                    indices: indices
                )
            } catch {
                #if DEBUG
                print("[ReorderTopics] persist failed:", error)
                #endif
            }
        }
    }

    func createQuickNote(draft: QuickGrammarNoteDraft) async -> GrammarNote? {
        guard !isCreatingQuickNote else { return nil }

        isCreatingQuickNote = true
        quickNoteError = nil
        defer { isCreatingQuickNote = false }

        await Task.yield()

        guard !ownerUID.isEmpty else {
            quickNoteError = "User session is not available. Please sign in again."
            #if DEBUG
            print("[QuickNote] save failed: ownerUID is empty")
            #endif
            return nil
        }
        guard let matchedTopic = topics.first(where: { $0.id == draft.topic.id }) else {
            quickNoteError = "Selected topic not found. Please reload and try again."
            #if DEBUG
            print("[QuickNote] save failed: topic \(draft.topic.id) not found in \(topics.count) topics")
            #endif
            return nil
        }

        #if DEBUG
        print("[QuickNote] saving to users/\(ownerUID)/grammarNoteTopics/\(matchedTopic.id)/notes")
        #endif

        do {
            let saved = try await createQuickNoteUseCase.execute(
                ownerUID: ownerUID,
                topic: matchedTopic,
                draft: draft
            )
            incrementNotesCount(for: matchedTopic.id)
            #if DEBUG
            print("[QuickNote] saved id=\(saved.id)")
            #endif
            return saved
        } catch {
            quickNoteError = readableMessage(for: error)
            #if DEBUG
            print("[QuickNote] save failed:", error)
            #endif
            return nil
        }
    }

    func createQuickMistake(
        draft: QuickGrammarMistakeDraft,
        settings: GrammarNotesSettingsStore
    ) async -> GrammarNote? {
        guard !isCreatingQuickMistake else { return nil }

        isCreatingQuickMistake = true
        quickMistakeError = nil
        defer { isCreatingQuickMistake = false }

        await Task.yield()

        guard !ownerUID.isEmpty else {
            quickMistakeError = "User session is not available. Please sign in again."
            #if DEBUG
            print("[QuickMistake] save failed: ownerUID is empty")
            #endif
            return nil
        }

        let targetTopic: GrammarNoteTopic
        if settings.groupMistakesByTopic,
           let found = topics.first(where: { $0.id == draft.topic.id }) {
            targetTopic = found
        } else {
            guard let mistakes = await getOrCreateMistakesTopic() else {
                quickMistakeError = L10n.string("notesCommonMistakesError")
                #if DEBUG
                print("[QuickMistake] save failed: could not resolve mistakes topic")
                #endif
                return nil
            }
            targetTopic = mistakes
        }

        #if DEBUG
        print("[QuickMistake] saving to users/\(ownerUID)/grammarNoteTopics/\(targetTopic.id)/notes")
        #endif

        do {
            let outcome = try await saveQuickMistakeUseCase.execute(
                ownerUID: ownerUID,
                targetTopic: targetTopic,
                draft: draft,
                settings: settings
            )

            switch outcome {
            case .duplicate(let duplicate):
                quickMistakeError = nil
                #if DEBUG
                print("[QuickMistake] duplicate detected id=\(duplicate.id)")
                #endif
                return duplicate
            case .created(let saved):
                incrementNotesCount(for: targetTopic.id)
                #if DEBUG
                print("[QuickMistake] saved id=\(saved.id)")
                #endif
                return saved
            }
        } catch {
            quickMistakeError = readableMessage(for: error)
            #if DEBUG
            print("[QuickMistake] save failed:", error)
            #endif
            return nil
        }
    }

    private func getOrCreateMistakesTopic() async -> GrammarNoteTopic? {
        if let existing = topics.first(where: { $0.isMistakesTopic }) { return existing }
        do {
            let topic = try await service.ensureDefaultMistakesTopic(ownerUID: ownerUID)
            if !topics.contains(where: { $0.id == topic.id }) {
                updateTopics(sortTopics(topics + [topic]))
            }
            return topic
        } catch {
            return nil
        }
    }

    private func ensureCommonMistakesTopicExists(in loadedTopics: [GrammarNoteTopic]) async throws -> [GrammarNoteTopic] {
        guard !loadedTopics.contains(where: { $0.isMistakesTopic }) else { return loadedTopics }
        guard !isEnsuringDefaultTopic else { return loadedTopics }
        isEnsuringDefaultTopic = true
        defer { isEnsuringDefaultTopic = false }

        let mistakesTopic = try await service.ensureDefaultMistakesTopic(ownerUID: ownerUID)
        return loadedTopics.contains(where: { $0.id == mistakesTopic.id }) ? loadedTopics : loadedTopics + [mistakesTopic]
    }

    private func bindSearch() {
        $searchText
            .sink { [weak self] _ in
                self?.refreshFilteredTopics()
            }
            .store(in: &cancellables)
    }

    private func updateTopics(_ newTopics: [GrammarNoteTopic]) {
        guard newTopics != topics else {
            refreshFilteredTopics()
            refreshTopicOptions()
            return
        }
        topics = newTopics
        refreshFilteredTopics()
        refreshTopicOptions()
    }

    private func refreshFilteredTopics() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else {
            filteredTopics = topics
            return
        }
        filteredTopics = topics.filter { topic in
            topic.title.lowercased().contains(query)
            || topic.description.lowercased().contains(query)
            || topic.languageName.lowercased().contains(query)
        }
    }

    private func refreshTopicOptions() {
        let mapped = topics.map { Self.topicOption(for: $0) }
        topicOptions = mapped
        regularTopicOptions = mapped.filter { option in
            topics.first(where: { $0.id == option.id })?.isMistakesTopic == false
        }
        mistakesTopicOption = mapped.first { option in
            topics.first(where: { $0.id == option.id })?.isMistakesTopic == true
        }
    }

    private func incrementNotesCount(for topicID: String) {
        guard let index = topics.firstIndex(where: { $0.id == topicID }) else { return }
        var updatedTopics = topics
        updatedTopics[index].notesCount += 1
        updatedTopics[index].updatedAt = Date()
        updateTopics(sortTopics(updatedTopics))
    }

    private static func topicOption(for topic: GrammarNoteTopic) -> GrammarQuickTopicOption {
        let tint = CreateSetTheme.theme(forHex: topic.colorHex).accent
        return GrammarQuickTopicOption(
            id: topic.id,
            title: topic.title,
            subtitle: "\(topic.notesCount) notes",
            tint: tint,
            systemImage: topic.icon
        )
    }

    private func sortTopics(_ topics: [GrammarNoteTopic]) -> [GrammarNoteTopic] {
        topics.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned && !rhs.isPinned }
            if lhs.isMistakesTopic != rhs.isMistakesTopic { return lhs.isMistakesTopic && !rhs.isMistakesTopic }
            switch (lhs.sortIndex, rhs.sortIndex) {
            case let (l?, r?):
                if l != r { return l < r }
                return lhs.updatedAt > rhs.updatedAt
            case (nil, nil): return lhs.updatedAt > rhs.updatedAt
            case (_?, nil):  return false
            case (nil, _?):  return true
            }
        }
    }

    private func readableMessage(for error: Error) -> String {
        GrammarNotesErrorMessages.readable(
            for: error,
            firestorePermission: "Missing Firestore permission for grammar note topics. Update Firestore rules for users/{uid}/grammarNoteTopics."
        )
    }
}
