import Foundation

struct SpeedReadingSession: Identifiable, Equatable {

    private static let historyLimit = 10

    let id: String
    let userId: String
    var configuration: SpeedReadingConfiguration
    var title: String
    var text: String
    var chunks: [String]
    var status: ReadingLibraryItemStatus
    var progress: Double
    var createdAt: Date
    var updatedAt: Date
    var lastOpenedAt: Date?
    var history: [SpeedReadingResult]

    // MARK: - Init

    init(
        id: String = UUID().uuidString,
        userId: String,
        configuration: SpeedReadingConfiguration,
        title: String? = nil,
        text: String = "",
        chunks: [String] = [],
        status: ReadingLibraryItemStatus = .new,
        progress: Double = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastOpenedAt: Date? = nil,
        history: [SpeedReadingResult] = []
    ) {
        self.id = id
        self.userId = userId
        self.configuration = configuration
        self.title = title ?? configuration.generatedTitle
        self.text = text
        self.chunks = chunks
        self.status = status
        self.progress = min(max(progress, 0), 1)
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastOpenedAt = lastOpenedAt
        self.history = history
    }

    // MARK: - Derived

    var hasGeneratedContent: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var lastResult: SpeedReadingResult? { history.first }

    var averageWPM: Int {
        guard !history.isEmpty else { return 0 }
        let total = history.reduce(0) { $0 + $1.wordsPerMinute }
        return total / history.count
    }

    var bestWPM: Int { history.map(\.wordsPerMinute).max() ?? 0 }

    mutating func record(result: SpeedReadingResult) {
        history.insert(result, at: 0)
        if history.count > Self.historyLimit {
            history = Array(history.prefix(Self.historyLimit))
        }
    }

    // MARK: - Library item bridge

    func toLibraryItem() -> ReadingLibraryItem {
        var selections = configuration.asSelections
        if let json = Self.encode(history: history) {
            selections["history"] = json
        }
        let lastResult = self.lastResult
        let tags: [String] = [
            configuration.target.title,
            configuration.timer.title,
            configuration.length.title
        ]
        let preview: String = {
            if let result = lastResult {
                return "\(result.wordsPerMinute) WPM • \(result.comprehensionPercentInt)% comprehension"
            }
            if hasGeneratedContent {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.count > 160 ? String(trimmed.prefix(160)) + "…" : trimmed
            }
            return "Train reading pace with timed practice."
        }()
        let wordCount = ReadingTextAnalyzerService.shared.wordCount(for: text)
        let comprehension = lastResult.map { $0.comprehensionPercent / 100 }

        return ReadingLibraryItem(
            id: id,
            userId: userId,
            modeID: "speed-reading",
            title: title,
            preview: preview,
            fullText: Self.encodeChunks(chunks, fallback: text),
            difficulty: configuration.length.title,
            estimatedMinutes: configuration.length.minutes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastOpenedAt: lastOpenedAt,
            progress: progress,
            comprehensionScore: comprehension,
            tags: tags,
            sourceType: .speedPractice,
            sourceId: id,
            status: status,
            selections: selections,
            languageCode: configuration.language.rawValue,
            wordCount: wordCount,
            readingTimeSeconds: lastResult?.readingTimeSeconds
        )
    }

    static func from(item: ReadingLibraryItem) -> SpeedReadingSession {
        let configuration = SpeedReadingConfiguration.from(
            selections: item.selections,
            language: item.language
        )
        let history = decode(history: item.selections["history"] ?? "")
        let chunks = decodeChunks(item.fullText)
        let text: String = {
            if !chunks.isEmpty { return chunks.joined(separator: "\n\n") }
            return item.fullText
        }()

        return SpeedReadingSession(
            id: item.id,
            userId: item.userId,
            configuration: configuration,
            title: item.title,
            text: text,
            chunks: chunks,
            status: item.status,
            progress: item.progress,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            lastOpenedAt: item.lastOpenedAt,
            history: history
        )
    }

    // MARK: - Chunk serialisation

    private static func encodeChunks(_ chunks: [String], fallback: String) -> String {
        if chunks.isEmpty { return fallback }
        let envelope = ChunksEnvelope(chunks: chunks)
        guard let data = try? JSONEncoder().encode(envelope),
              let json = String(data: data, encoding: .utf8) else {
            return chunks.joined(separator: "\n\n")
        }
        return json
    }

    private static func decodeChunks(_ raw: String) -> [String] {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("{"), let data = trimmed.data(using: .utf8) else {
            return raw
                .components(separatedBy: "\n\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        return (try? JSONDecoder().decode(ChunksEnvelope.self, from: data))?.chunks ?? []
    }

    private struct ChunksEnvelope: Codable { let chunks: [String] }

    // MARK: - History serialisation

    private static func encode(history: [SpeedReadingResult]) -> String? {
        guard !history.isEmpty else { return nil }
        guard let data = try? JSONEncoder().encode(history) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func decode(history raw: String) -> [SpeedReadingResult] {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("["), let data = trimmed.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([SpeedReadingResult].self, from: data)) ?? []
    }
}
