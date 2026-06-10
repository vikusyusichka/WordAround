import Foundation
import FirebaseAuth

protocol StoryStorageServicing: Sendable {
    func fetchSessions(for userId: String) async throws -> [StorySession]
    func createSession(config: StoryModeConfiguration, for userId: String) async throws -> StorySession
    func updateProgress(_ session: StorySession, toggles: [String: Bool], for userId: String) async throws
    func deleteSession(_ session: StorySession, for userId: String) async throws
    func markOpened(sessionId: String, for userId: String) async throws
}

extension StoryStorageServicing {
    func updateProgress(_ session: StorySession, for userId: String) async throws {
        try await updateProgress(session, toggles: [:], for: userId)
    }
}

final class StoryStorageService: StoryStorageServicing {
    static let shared = StoryStorageService()

    private let storage: ReadingStorageServicing

    init(storage: ReadingStorageServicing = ReadingStorageService()) {
        self.storage = storage
    }

    private static var storyReadingMode: ReadingMode {
        ReadingMode(
            id: "story-mode",
            title: L10n.string("storyModeTitle"),
            subtitle: L10n.string("readingStoryShortSubtitle"),
            systemImage: "books.vertical.fill",
            accentColor: ReadingSetupConfig.storyMode.accent,
            blobColor: AppColors.blobPink
        )
    }

    func fetchSessions(for userId: String) async throws -> [StorySession] {
        let items = try await storage.fetchItems(for: userId, mode: Self.storyReadingMode)
        return items.map { StorySession.from(item: $0) }
    }

    func createSession(config: StoryModeConfiguration, for userId: String) async throws -> StorySession {
        var session = StorySession(userId: userId, configuration: config)
        switch config.storyLength {
        case .multiChapter:
            session.progress = StoryProgress(totalChaptersTarget: 5)
        case .infinite:
            session.progress = StoryProgress(totalChaptersTarget: 0)
        case .shortStory:
            session.progress = StoryProgress(totalChaptersTarget: 1)
        }
        let item = session.toLibraryItem()
        try await storage.saveItem(item, for: userId)
        return session
    }

    func updateProgress(_ session: StorySession, toggles: [String: Bool], for userId: String) async throws {
        let item = session.toLibraryItem(toggles: toggles)
        try await storage.updateItem(item, for: userId)
    }

    func deleteSession(_ session: StorySession, for userId: String) async throws {
        let item = session.toLibraryItem()
        try await storage.deleteItem(item, for: userId)
    }

    func markOpened(sessionId: String, for userId: String) async throws {
        try await storage.updateLastOpened(
            itemId: sessionId,
            mode: Self.storyReadingMode,
            for: userId
        )
    }
}

final class MockStoryStorageService: StoryStorageServicing {
    private var sessions: [StorySession]

    init(sessions: [StorySession] = []) {
        self.sessions = sessions
    }

    func fetchSessions(for userId: String) async throws -> [StorySession] {
        sessions.filter { $0.userId == userId }
            .sorted { ($0.lastOpenedAt ?? $0.createdAt) > ($1.lastOpenedAt ?? $1.createdAt) }
    }

    func createSession(config: StoryModeConfiguration, for userId: String) async throws -> StorySession {
        let session = StorySession(userId: userId, configuration: config)
        sessions.append(session)
        return session
    }

    func updateProgress(_ session: StorySession, toggles: [String: Bool], for userId: String) async throws {
        if let i = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[i] = session
        }
    }

    func deleteSession(_ session: StorySession, for userId: String) async throws {
        sessions.removeAll { $0.id == session.id }
    }

    func markOpened(sessionId: String, for userId: String) async throws {
        if let i = sessions.firstIndex(where: { $0.id == sessionId }) {
            var s = sessions[i]
            s.lastOpenedAt = Date()
            sessions[i] = s
        }
    }
}
