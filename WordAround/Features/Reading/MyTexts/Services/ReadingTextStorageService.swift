import Foundation

protocol ReadingTextStorageServicing: Sendable {
    func fetchTexts() async throws -> [ReadingUserText]
    func saveText(_ text: ReadingUserText) async throws
    func updateText(_ text: ReadingUserText) async throws
    func deleteText(id: String) async throws
    func updateProgress(textId: String, progress: Double, lastReadCharacterIndex: Int) async throws
    func markCompleted(textId: String, score: Double?) async throws
    func markOpened(textId: String) async throws
}

/// Local JSON persistence for My Texts (UserDefaults).
/// TODO: Firestore sync can replace this implementation later.
final class ReadingTextStorageService: ReadingTextStorageServicing, @unchecked Sendable {
    static let shared = ReadingTextStorageService()

    private let storageKey = "wordaround.reading.myTexts.v1"
    private let legacyStorageKey = "reading.userTexts.v1"
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let queue = DispatchQueue(label: "wordaround.reading.myTexts.storage")

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func fetchTexts() async throws -> [ReadingUserText] {
        try await run { Self.sort(self.loadTexts()) }
    }

    func saveText(_ text: ReadingUserText) async throws {
        try await run {
            var texts = self.loadTexts()
            texts.removeAll { $0.id == text.id }
            texts.insert(text, at: 0)
            self.persist(texts)
        }
    }

    func updateText(_ text: ReadingUserText) async throws {
        try await run {
            var texts = self.loadTexts()
            if let index = texts.firstIndex(where: { $0.id == text.id }) {
                texts[index] = text
                self.persist(texts)
            } else {
                texts.insert(text, at: 0)
                self.persist(texts)
            }
        }
    }

    func deleteText(id: String) async throws {
        try await run {
            var texts = self.loadTexts()
            texts.removeAll { $0.id == id }
            self.persist(texts)
        }
    }

    func updateProgress(textId: String, progress: Double, lastReadCharacterIndex: Int) async throws {
        try await run {
            guard var text = self.loadTexts().first(where: { $0.id == textId }) else { return }
            text.progress = min(max(progress, 0), 0.99)
            text.lastReadCharacterIndex = lastReadCharacterIndex
            text.isCompleted = false
            text.updatedAt = Date()
            text.clampProgress()
            var texts = self.loadTexts()
            if let index = texts.firstIndex(where: { $0.id == textId }) {
                texts[index] = text
                self.persist(texts)
            }
        }
    }

    func markCompleted(textId: String, score: Double?) async throws {
        try await run {
            guard var text = self.loadTexts().first(where: { $0.id == textId }) else { return }
            let previousCount = text.completedSessionsCount
            text.completedSessionsCount = previousCount + 1
            text.progress = 1
            text.isCompleted = true
            text.updatedAt = Date()

            if let score {
                let previousTotal = (text.averageScore ?? 0) * Double(previousCount)
                text.averageScore = (previousTotal + score) / Double(text.completedSessionsCount)
            }

            var texts = self.loadTexts()
            if let index = texts.firstIndex(where: { $0.id == textId }) {
                texts[index] = text
                self.persist(texts)
            }
        }
    }

    func markOpened(textId: String) async throws {
        try await run {
            guard var text = self.loadTexts().first(where: { $0.id == textId }) else { return }
            text.lastOpenedAt = Date()
            text.updatedAt = Date()
            var texts = self.loadTexts()
            if let index = texts.firstIndex(where: { $0.id == textId }) {
                texts[index] = text
                self.persist(texts)
            }
        }
    }

    // MARK: - Sync helpers (legacy / internal)

    func fetchAll() -> [ReadingUserText] {
        queue.sync { Self.sort(loadTexts()) }
    }

    func save(_ text: ReadingUserText) {
        queue.sync {
            var texts = loadTexts()
            texts.removeAll { $0.id == text.id }
            texts.insert(text, at: 0)
            persist(texts)
        }
    }

    func update(_ text: ReadingUserText) {
        queue.sync {
            var texts = loadTexts()
            if let index = texts.firstIndex(where: { $0.id == text.id }) {
                texts[index] = text
            } else {
                texts.insert(text, at: 0)
            }
            persist(texts)
        }
    }

    func delete(id: String) {
        queue.sync {
            var texts = loadTexts()
            texts.removeAll { $0.id == id }
            persist(texts)
        }
    }

    func text(withId id: String) -> ReadingUserText? {
        queue.sync { loadTexts().first { $0.id == id } }
    }

    func updateProgress(textId: String, progress: Double, lastReadCharacterIndex: Int, isCompleted: Bool) {
        queue.sync {
            guard var text = loadTexts().first(where: { $0.id == textId }) else { return }
            text.progress = min(max(progress, 0), isCompleted ? 1 : 0.99)
            text.lastReadCharacterIndex = lastReadCharacterIndex
            text.isCompleted = isCompleted
            text.updatedAt = Date()
            if isCompleted { text.progress = 1 }
            var texts = loadTexts()
            if let index = texts.firstIndex(where: { $0.id == textId }) {
                texts[index] = text
                persist(texts)
            }
        }
    }

    func markOpened(textId: String) {
        queue.sync {
            guard var text = loadTexts().first(where: { $0.id == textId }) else { return }
            text.lastOpenedAt = Date()
            text.updatedAt = Date()
            var texts = loadTexts()
            if let index = texts.firstIndex(where: { $0.id == textId }) {
                texts[index] = text
                persist(texts)
            }
        }
    }

    // MARK: - Private

    private func run<T>(_ work: @escaping () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                do {
                    continuation.resume(returning: try work())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func loadTexts() -> [ReadingUserText] {
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? decoder.decode([ReadingUserText].self, from: data) {
            return decoded
        }

        if let legacyData = defaults.data(forKey: legacyStorageKey),
           let decoded = try? decoder.decode([ReadingUserText].self, from: legacyData) {
            persist(decoded)
            defaults.removeObject(forKey: legacyStorageKey)
            return decoded
        }

        if defaults.data(forKey: storageKey) != nil {
            #if DEBUG
            print("ReadingTextStorageService: decode failed — returning empty list")
            #endif
        }
        return []
    }

    private func persist(_ texts: [ReadingUserText]) {
        guard let data = try? encoder.encode(texts) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private static func sort(_ texts: [ReadingUserText]) -> [ReadingUserText] {
        texts.sorted { lhs, rhs in
            let lhsDate = lhs.lastOpenedAt ?? lhs.updatedAt
            let rhsDate = rhs.lastOpenedAt ?? rhs.updatedAt
            if lhsDate != rhsDate { return lhsDate > rhsDate }
            return lhs.updatedAt > rhs.updatedAt
        }
    }
}

typealias ReadingTextStorageServiceProtocol = ReadingTextStorageServicing
