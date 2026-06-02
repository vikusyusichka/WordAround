import Foundation

final class LocalDailyPracticeStatsStore: DailyPracticeStatsStoring, @unchecked Sendable {
    static let shared = LocalDailyPracticeStatsStore()

    private let fileURL: URL
    private let queue = DispatchQueue(label: "wordaround.dailypracticestats.store")
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileName: String = "daily_practice_stats.json") {
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

    func append(_ entry: DailyPracticeEntry) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            queue.async {
                var all = self.readAll()
                all.append(entry)
                self.writeAll(all)
                continuation.resume()
            }
        }
    }

    func fetchAll() async -> [DailyPracticeEntry] {
        await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.readAll())
            }
        }
    }

    private func readAll() -> [DailyPracticeEntry] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? decoder.decode([DailyPracticeEntry].self, from: data)) ?? []
    }

    private func writeAll(_ entries: [DailyPracticeEntry]) {
        guard let data = try? encoder.encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

final class MockDailyPracticeStatsStore: DailyPracticeStatsStoring, @unchecked Sendable {
    private var entries: [DailyPracticeEntry]
    private let lock = NSLock()

    init(entries: [DailyPracticeEntry] = []) {
        self.entries = entries
    }

    func append(_ entry: DailyPracticeEntry) async {
        lock.lock(); defer { lock.unlock() }
        entries.append(entry)
    }

    func fetchAll() async -> [DailyPracticeEntry] {
        lock.lock(); defer { lock.unlock() }
        return entries
    }
}
