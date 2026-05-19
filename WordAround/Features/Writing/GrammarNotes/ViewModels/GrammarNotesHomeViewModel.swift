import Foundation
import FirebaseFirestore
import Combine

@MainActor
final class GrammarNotesHomeViewModel: ObservableObject {
    @Published private(set) var topics: [GrammarNoteTopic] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isCreatingTopic = false
    @Published var searchText = ""
    @Published var errorMessage: String?

    private let ownerUID: String
    private let service: GrammarNoteTopicServicing

    var filteredTopics: [GrammarNoteTopic] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !query.isEmpty else { return topics }

        return topics.filter { topic in
            topic.title.lowercased().contains(query)
            || topic.description.lowercased().contains(query)
            || topic.languageName.lowercased().contains(query)
        }
    }

    var hasOnlyMistakesTopic: Bool {
        topics.filter { !$0.isMistakesTopic }.isEmpty
    }

    init(
        ownerUID: String,
        service: GrammarNoteTopicServicing = GrammarNoteTopicService(),
        previewTopics: [GrammarNoteTopic] = []
    ) {
        self.ownerUID = ownerUID
        self.service = service
        self.topics = previewTopics
    }

    func loadTopics() async {
        guard !ownerUID.isEmpty else {
            errorMessage = "User session is not available. Please sign in again."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            var loadedTopics = try await service.fetchTopics(for: ownerUID)
            loadedTopics = try await ensureCommonMistakesTopicExists(in: loadedTopics)
            topics = sortTopics(loadedTopics)
        } catch {
            errorMessage = readableMessage(for: error)
        }

        isLoading = false
    }

    func createTopic(
        title: String,
        description: String,
        languageCode: String,
        languageName: String,
        icon: String,
        colorHex: String
    ) async -> Bool {
        guard !ownerUID.isEmpty else {
            errorMessage = "User session is not available. Please sign in again."
            return false
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            errorMessage = "Topic title is required."
            return false
        }

        guard trimmedTitle.count <= 40 else {
            errorMessage = "Topic title must be under 40 characters."
            return false
        }

        guard trimmedDescription.count <= 120 else {
            errorMessage = "Description must be under 120 characters."
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

        isCreatingTopic = true
        errorMessage = nil

        do {
            try await service.createTopic(topic)
            topics = sortTopics(topics + [topic])
            isCreatingTopic = false
            return true
        } catch {
            isCreatingTopic = false
            errorMessage = readableMessage(for: error)
            return false
        }
    }

    func deleteTopic(_ topic: GrammarNoteTopic) async {
        guard !topic.isMistakesTopic else { return }

        do {
            try await service.deleteTopic(id: topic.id, ownerUID: ownerUID)
            topics.removeAll { $0.id == topic.id }
            errorMessage = nil
        } catch {
            errorMessage = readableMessage(for: error)
        }
    }

    private func ensureCommonMistakesTopicExists(in loadedTopics: [GrammarNoteTopic]) async throws -> [GrammarNoteTopic] {
        guard !loadedTopics.contains(where: { $0.isMistakesTopic }) else {
            return loadedTopics
        }

        let mistakesTopic = GrammarNoteTopic.commonMistakes(ownerUID: ownerUID)
        try await service.createTopic(mistakesTopic)
        return loadedTopics + [mistakesTopic]
    }

    private func sortTopics(_ topics: [GrammarNoteTopic]) -> [GrammarNoteTopic] {
        topics.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }

            if lhs.isMistakesTopic != rhs.isMistakesTopic {
                return lhs.isMistakesTopic && !rhs.isMistakesTopic
            }

            return lhs.updatedAt > rhs.updatedAt
        }
    }

    private func readableMessage(for error: Error) -> String {
        let nsError = error as NSError

        if nsError.domain == FirestoreErrorDomain,
           nsError.code == FirestoreErrorCode.permissionDenied.rawValue {
            return "Missing Firestore permission for grammar note topics. Update Firestore rules for users/{uid}/grammarNoteTopics."
        }

        return error.localizedDescription
    }
}
