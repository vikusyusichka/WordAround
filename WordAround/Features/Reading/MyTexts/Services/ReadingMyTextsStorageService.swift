import Foundation
import FirebaseAuth
import FirebaseFirestore

final class ReadingMyTextsStorageService: ReadingMyTextsStorageServicing, @unchecked Sendable {
    static let shared = ReadingMyTextsStorageService()

    private let storage: ReadingStorageServicing
    private let legacyLocal: ReadingTextStorageServicing
    private let migrationKey = "wordaround.reading.myTexts.firestoreMigrated"
    private let defaults: UserDefaults

    init(
        storage: ReadingStorageServicing = ReadingStorageService(),
        legacyLocal: ReadingTextStorageServicing = ReadingTextStorageService.shared,
        defaults: UserDefaults = .standard
    ) {
        self.storage = storage
        self.legacyLocal = legacyLocal
        self.defaults = defaults
    }

    func currentUserId() -> String? { Auth.auth().currentUser?.uid }

    func fetchTexts() async throws -> [ReadingUserText] {
        guard let userId = currentUserId() else {
            throw ReadingMyTextsStorageError.notSignedIn
        }
        await migrateLocalTextsIfNeeded()

        do {
            let items = try await storage.fetchItems(for: userId, mode: .myTexts)
            let texts = items.map(ReadingUserText.init(libraryItem:))
            await cacheLocally(texts)
            return texts
        } catch {
            let cached = try await legacyLocal.fetchTexts()
            if !cached.isEmpty { return cached }
            if Self.isFirestorePermissionDenied(error) {
                throw ReadingMyTextsStorageError.cloudPermissionDenied
            }
            throw error
        }
    }

    func save(_ text: ReadingUserText) async throws {
        guard let userId = currentUserId() else { throw ReadingMyTextsStorageError.notSignedIn }
        try await legacyLocal.saveText(text)
        await syncToCloud(text, userId: userId)
    }

    func update(_ text: ReadingUserText) async throws {
        guard let userId = currentUserId() else { throw ReadingMyTextsStorageError.notSignedIn }
        try await legacyLocal.updateText(text)
        await syncToCloud(text, userId: userId)
    }

    func delete(id: String) async throws {
        guard let userId = currentUserId() else { throw ReadingMyTextsStorageError.notSignedIn }
        try await legacyLocal.deleteText(id: id)
        if let items = try? await storage.fetchItems(for: userId, mode: .myTexts),
           let item = items.first(where: { $0.id == id }) {
            try? await storage.deleteItem(item, for: userId)
        }
    }

    func markOpened(textId: String) async throws {
        guard let userId = currentUserId() else { return }
        try await storage.updateLastOpened(itemId: textId, mode: .myTexts, for: userId)
    }

    func updateProgress(textId: String, progress: Double, lastReadCharacterIndex: Int) async throws {
        guard let userId = currentUserId() else { return }
        let clamped = min(max(progress, 0), 0.99)
        try await storage.updateProgress(itemId: textId, mode: .myTexts, progress: clamped, for: userId)
        if var text = try await text(withId: textId) {
            text.progress = clamped
            text.lastReadCharacterIndex = lastReadCharacterIndex
            text.status = .inProgress
            text.isCompleted = false
            try await update(text)
        }
    }

    func markInProgress(textId: String) async throws {
        guard var text = try await text(withId: textId) else { return }
        text.status = .inProgress
        text.lastOpenedAt = Date()
        if text.progress <= 0 { text.progress = 0.05 }
        try await update(text)
        if let userId = currentUserId() {
            try? await storage.updateLastOpened(itemId: textId, mode: .myTexts, for: userId)
        }
    }

    func markCompleted(textId: String, scorePercent: Double, readingTimeSeconds: Int) async throws {
        guard let userId = currentUserId() else { return }
        guard var text = try await text(withId: textId) else { return }
        text.progress = 1
        text.isCompleted = true
        text.status = .completed
        text.readingTimeSeconds = readingTimeSeconds
        let normalizedScore = min(max(scorePercent, 0), 100)
        if let previous = text.averageScore, text.completedSessionsCount > 0 {
            let count = Double(text.completedSessionsCount + 1)
            text.averageScore = ((previous * (count - 1)) + normalizedScore) / count
        } else {
            text.averageScore = normalizedScore
        }
        text.completedSessionsCount += 1
        text.updatedAt = Date()
        var item = text.toLibraryItem(userId: userId)
        item.progress = 1
        item.status = .completed
        item.comprehensionScore = normalizedScore / 100
        item.readingTimeSeconds = readingTimeSeconds
        try await storage.updateItem(item, for: userId)
    }

    func rename(textId: String, newTitle: String) async throws {
        guard var text = try await text(withId: textId) else { return }
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        text.title = trimmed
        text.updatedAt = Date()
        try await update(text)
    }

    func migrateLocalTextsIfNeeded() async {
        guard let userId = currentUserId() else { return }
        let key = "\(migrationKey).\(userId)"
        guard !defaults.bool(forKey: key) else { return }

        guard let legacy = try? await legacyLocal.fetchTexts(), !legacy.isEmpty else {
            defaults.set(true, forKey: key)
            return
        }

        for legacyText in legacy {
            var bridged = legacyText
            if bridged.characterCount == 0 { bridged.characterCount = bridged.content.count }
            let item = bridged.toLibraryItem(userId: userId)
            try? await storage.saveItem(item, for: userId)
        }
        defaults.set(true, forKey: key)
    }

    private func text(withId id: String) async throws -> ReadingUserText? {
        try await fetchTexts().first { $0.id == id }
    }

    private func cacheLocally(_ texts: [ReadingUserText]) async {
        for text in texts {
            try? await legacyLocal.updateText(text)
        }
    }

    private func syncToCloud(_ text: ReadingUserText, userId: String) async {
        var item = text.toLibraryItem(userId: userId)
        item.updatedAt = Date()
        if (try? await storage.fetchItems(for: userId, mode: .myTexts))?
            .contains(where: { $0.id == text.id }) == true {
            try? await storage.updateItem(item, for: userId)
        } else {
            try? await storage.saveItem(item, for: userId)
        }
    }

    private static func isFirestorePermissionDenied(_ error: Error) -> Bool {
        let ns = error as NSError
        return ns.domain == FirestoreErrorDomain && ns.code == FirestoreErrorCode.permissionDenied.rawValue
    }
}

enum ReadingMyTextsStorageError: LocalizedError {
    case notSignedIn
    case cloudPermissionDenied

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "Please sign in to save and sync your texts."
        case .cloudPermissionDenied:
            return "Cloud sync is blocked by Firestore rules. Add access for users/{uid}/readingItems, then deploy rules. Texts you save are stored on this device."
        }
    }
}

final class MockReadingMyTextsStorageService: ReadingMyTextsStorageServicing, @unchecked Sendable {
    private var texts: [ReadingUserText]

    init(texts: [ReadingUserText] = ReadingMyTextsPreviewData.sampleTexts) {
        self.texts = texts
    }

    func currentUserId() -> String? { "preview-user" }
    func fetchTexts() async throws -> [ReadingUserText] { texts }
    func save(_ text: ReadingUserText) async throws {
        texts.removeAll { $0.id == text.id }
        texts.insert(text, at: 0)
    }
    func update(_ text: ReadingUserText) async throws {
        if let i = texts.firstIndex(where: { $0.id == text.id }) { texts[i] = text }
    }
    func delete(id: String) async throws { texts.removeAll { $0.id == id } }
    func markOpened(textId: String) async throws {}
    func updateProgress(textId: String, progress: Double, lastReadCharacterIndex: Int) async throws {}
    func markInProgress(textId: String) async throws {}
    func markCompleted(textId: String, scorePercent: Double, readingTimeSeconds: Int) async throws {}
    func rename(textId: String, newTitle: String) async throws {}
    func migrateLocalTextsIfNeeded() async {}
}
