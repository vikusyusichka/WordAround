import Foundation

/// Local-first session store backed by a JSON file in Application Support.
/// Persists draft, in-progress and completed sessions so the user can continue
/// later or review results. Thread-safe via an internal serial queue.
final class LocalListeningSessionStore: ListeningSessionStoring, @unchecked Sendable {
    static let shared = LocalListeningSessionStore()

    private let fileURL: URL
    private let queue = DispatchQueue(label: "wordaround.listening.sessionstore")
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileName: String = "listening_sessions.json") {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        if !FileManager.default.fileExists(atPath: base.path) {
            try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        }
        self.fileURL = base.appendingPathComponent(fileName)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func fetchSessions() async -> [ListeningPersistedSession] {
        await withCheckedContinuation { continuation in
            queue.async {
                let sessions = self.readAll().sorted { $0.updatedAt > $1.updatedAt }
                continuation.resume(returning: sessions)
            }
        }
    }

    func session(id: String) async -> ListeningPersistedSession? {
        await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.readAll().first { $0.id == id })
            }
        }
    }

    func save(_ session: ListeningPersistedSession) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async {
                var all = self.readAll()
                var updated = session
                updated.updatedAt = Date()
                if let index = all.firstIndex(where: { $0.id == session.id }) {
                    all[index] = updated
                } else {
                    all.append(updated)
                }
                self.writeAll(all)
                continuation.resume()
            }
        }
    }

    func delete(id: String) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async {
                var all = self.readAll()
                if let session = all.first(where: { $0.id == id }),
                   let audioFile = session.localAudioFileName {
                    ListeningAudioImporter.deleteAudio(fileName: audioFile)
                }
                all.removeAll { $0.id == id }
                self.writeAll(all)
                continuation.resume()
            }
        }
    }

    // MARK: - Disk I/O (must run on `queue`)

    private func readAll() -> [ListeningPersistedSession] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        // Decode tolerantly: a corrupted file should not crash the app.
        return (try? decoder.decode([ListeningPersistedSession].self, from: data)) ?? []
    }

    private func writeAll(_ sessions: [ListeningPersistedSession]) {
        guard let data = try? encoder.encode(sessions) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

/// In-memory store for previews and tests.
final class MockListeningSessionStore: ListeningSessionStoring, @unchecked Sendable {
    private var sessions: [ListeningPersistedSession]

    init(sessions: [ListeningPersistedSession] = SavedPracticePreviewData.persistedSessions) {
        self.sessions = sessions
    }

    func fetchSessions() async -> [ListeningPersistedSession] {
        sessions.sorted { $0.updatedAt > $1.updatedAt }
    }
    func session(id: String) async -> ListeningPersistedSession? {
        sessions.first { $0.id == id }
    }
    func save(_ session: ListeningPersistedSession) async {
        sessions.removeAll { $0.id == session.id }
        sessions.append(session)
    }
    func delete(id: String) async {
        sessions.removeAll { $0.id == id }
    }
}
