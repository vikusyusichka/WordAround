import Foundation
import Combine

struct GrammarReviewRecommendation: Identifiable, Codable, Equatable {
    let id: String
    let ownerUID: String
    let topicId: String
    let noteId: String
    let title: String
    let previewText: String
    let languageCode: String
    let languageName: String
    let lastOpenedAt: Date?
    let lastEditedAt: Date?

    var label: String {
        if let lastOpenedAt {
            return "Last opened " + Self.relativeDate(lastOpenedAt)
        }
        if let lastEditedAt {
            return "Last edited " + Self.relativeDate(lastEditedAt)
        }
        return "Recommended"
    }

    var reviewItem: GrammarReviewItem {
        let now = Date()
        return GrammarReviewItem(
            id: GrammarReviewItem.id(forNoteTopicId: topicId, noteId: noteId),
            ownerUID: ownerUID,
            sourceType: .note,
            topicId: topicId,
            noteId: noteId,
            quizId: nil,
            title: title.isEmpty ? "Untitled note" : title,
            previewText: previewText,
            languageCode: languageCode,
            languageName: languageName,
            priority: .normal,
            dueAt: now,
            createdAt: now,
            updatedAt: now
        )
    }

    private static func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    static func from(note: GrammarNote, openedAt: Date = Date()) -> GrammarReviewRecommendation {
        GrammarReviewRecommendation(
            id: "\(note.topicId)_\(note.id)",
            ownerUID: note.ownerUID,
            topicId: note.topicId,
            noteId: note.id,
            title: note.title,
            previewText: note.previewText,
            languageCode: note.languageCode,
            languageName: note.languageName,
            lastOpenedAt: openedAt,
            lastEditedAt: note.lastEditedAt
        )
    }
}

@MainActor
final class GrammarReviewViewModel: ObservableObject {

    @Published private(set) var summary: GrammarReviewSummary = .empty
    @Published private(set) var isLoadingSummary = false
    @Published private(set) var summaryError: String?
    @Published private(set) var recentlyOpenedItems: [GrammarReviewRecommendation] = []
    @Published private(set) var recentlyEditedItems: [GrammarReviewRecommendation] = []
    @Published private(set) var recommendedItems: [GrammarReviewRecommendation] = []
    @Published private(set) var isAddingRecommendation = false

    @Published private(set) var mistakeHighlights: [GrammarReviewItem] = []
    @Published private(set) var quizHighlights: [GrammarReviewItem] = []
    @Published private(set) var isLoadingHighlights = false

    @Published private(set) var items: [GrammarReviewItem] = []
    @Published private(set) var currentIndex: Int = 0
    @Published private(set) var isLoadingSession = false
    @Published private(set) var sessionError: String?
    @Published private(set) var isRating = false
    @Published private(set) var sessionFinished = false
    @Published private(set) var ratedHardCount = 0
    @Published private(set) var ratedForgotCount = 0
    @Published private(set) var ratedCount = 0

    private let ownerUID: String
    private let service: GrammarReviewServicing
    private let queueBuilder: GrammarReviewQueueBuilder
    private var lastSummaryLoadAt: Date?

    @Published private(set) var previewQueue: GrammarReviewQueueBuilder.Result = .empty
    @Published private(set) var isBuildingPreviewQueue: Bool = false

    init(
        ownerUID: String,
        service: GrammarReviewServicing = GrammarReviewService(),
        queueBuilder: GrammarReviewQueueBuilder = GrammarReviewQueueBuilder()
    ) {
        self.ownerUID = ownerUID
        self.service = service
        self.queueBuilder = queueBuilder
    }

    var currentItem: GrammarReviewItem? {
        guard !items.isEmpty, currentIndex >= 0, currentIndex < items.count else { return nil }
        return items[currentIndex]
    }

    var totalItems: Int { items.count }
    var hasRecommendations: Bool { !recommendedItems.isEmpty }

    var progressFraction: Double {
        guard !items.isEmpty else { return 0 }
        return Double(min(currentIndex + 1, items.count)) / Double(items.count)
    }

    var effectiveSourcePool: GrammarReviewSourcePool? {
        previewQueue.pool
    }

    var effectiveCount: Int {
        previewQueue.count
    }

    func loadSummary(force: Bool = false) async {
        if !force, let last = lastSummaryLoadAt, Date().timeIntervalSince(last) < 30 { return }
        guard !isLoadingSummary else { return }
        guard !ownerUID.isEmpty else {
            summaryError = "User session is not available."
            summary = .empty
            loadLocalRecommendations()
            previewQueue = .empty
            return
        }

        isLoadingSummary = true
        summaryError = nil
        defer { isLoadingSummary = false }

        var manualItems: [GrammarReviewItem] = []
        do {
            manualItems = try await service.fetchDueReviewItems(ownerUID: ownerUID, limit: 30)
            summary = GrammarReviewSummary.from(items: manualItems)
            lastSummaryLoadAt = Date()
            loadLocalRecommendations()
        } catch {
            summary = .empty
            summaryError = Self.readable(error)
            loadLocalRecommendations()
            #if DEBUG
            print("[Review] summary load failed:", error)
            #endif
            previewQueue = .empty
            return
        }

        await rebuildPreviewQueue(manualItems: manualItems)
    }

    private func rebuildPreviewQueue(manualItems: [GrammarReviewItem]) async {
        isBuildingPreviewQueue = true
        defer { isBuildingPreviewQueue = false }

        let result = await queueBuilder.build(
            manualItems: manualItems,
            recentlyOpened: recentlyOpenedItems,
            recentlyEdited: recentlyEditedItems
        )
        previewQueue = result

        #if DEBUG
        print("[Review] previewQueue → pool=\(result.pool?.rawValue ?? "nil") count=\(result.count)")
        #endif
    }

    func loadHighlights(limit: Int = 5) async {
        guard !isLoadingHighlights else { return }
        guard !ownerUID.isEmpty else { return }

        isLoadingHighlights = true
        defer { isLoadingHighlights = false }

        async let mistakes = safeFetch(sourceType: .mistake, limit: limit)
        async let quizzes  = safeFetch(sourceType: .quiz,    limit: limit)
        let (m, q) = await (mistakes, quizzes)
        mistakeHighlights = m
        quizHighlights = q
    }

    private func safeFetch(
        sourceType: GrammarReviewSourceType,
        limit: Int
    ) async -> [GrammarReviewItem] {
        do {
            return try await service.fetchItemsBySource(
                ownerUID: ownerUID,
                sourceType: sourceType,
                limit: limit
            )
        } catch {
            #if DEBUG
            print("[Review] highlights \(sourceType.rawValue) failed:", error)
            #endif
            return []
        }
    }

    func startSession() async {
        guard !isLoadingSession else { return }
        guard !ownerUID.isEmpty else {
            sessionError = "User session is not available."
            return
        }

        isLoadingSession = true
        sessionError = nil
        sessionFinished = false
        currentIndex = 0
        ratedHardCount = 0
        ratedForgotCount = 0
        ratedCount = 0
        items = []
        defer { isLoadingSession = false }

        do {
            items = try await service.fetchDueReviewItems(ownerUID: ownerUID, limit: 30)
            if items.isEmpty { sessionFinished = true }
        } catch {
            sessionError = Self.readable(error)
            #if DEBUG
            print("[Review] session load failed:", error)
            #endif
        }
    }

    func startRecommendedSession(with recommendation: GrammarReviewRecommendation) {
        sessionError = nil
        isLoadingSession = false
        isRating = false
        sessionFinished = false
        currentIndex = 0
        ratedHardCount = 0
        ratedForgotCount = 0
        ratedCount = 0
        items = [recommendation.reviewItem]
    }

    func addRecommendationToReview(_ recommendation: GrammarReviewRecommendation) async {
        guard !isAddingRecommendation else { return }
        isAddingRecommendation = true
        defer { isAddingRecommendation = false }

        do {
            try await service.createOrUpdateReviewItem(recommendation.reviewItem)
            recommendedItems.removeAll { $0.id == recommendation.id }
            recentlyOpenedItems.removeAll { $0.id == recommendation.id }
            recentlyEditedItems.removeAll { $0.id == recommendation.id }
            lastSummaryLoadAt = nil
            await loadSummary(force: true)
        } catch {
            summaryError = Self.readable(error)
            #if DEBUG
            print("[Review] add recommendation failed:", error)
            #endif
        }
    }

    func rate(_ result: GrammarReviewResult) async {
        guard !isRating else { return }
        guard let current = currentItem else {
            sessionFinished = true
            return
        }

        isRating = true
        defer { isRating = false }

        do {
            if current.ownerUID == ownerUID {
                _ = try await service.markReviewed(item: current, result: result)
            }
        } catch {
            sessionError = Self.readable(error)
            #if DEBUG
            print("[Review] rating failed for \(current.id):", error)
            #endif
            return
        }

        ratedCount += 1
        switch result {
        case .hard: ratedHardCount += 1
        case .forgot: ratedForgotCount += 1
        default: break
        }

        items.removeAll { $0.id == current.id }
        if currentIndex >= items.count { currentIndex = max(0, items.count - 1) }
        if items.isEmpty { sessionFinished = true }
        lastSummaryLoadAt = nil
    }

    func skipCurrent() {
        guard currentIndex + 1 < items.count else {
            sessionFinished = true
            return
        }
        currentIndex += 1
    }

    func resetSession() {
        items = []
        currentIndex = 0
        sessionFinished = false
        ratedHardCount = 0
        ratedForgotCount = 0
        ratedCount = 0
        sessionError = nil
        isRating = false
        isLoadingSession = false
    }

    static let recentlyOpenedKey = "grammarNotes.review.recentlyOpenedNotes"
    static let recentlyEditedKey = "grammarNotes.review.recentlyEditedNotes"

    static func recordOpenedNote(_ note: GrammarNote, limit: Int = 10) {
        upsertRecommendation(
            for: note,
            key: recentlyOpenedKey,
            kind: .opened,
            limit: limit
        )
    }

    static func recordEditedNote(_ note: GrammarNote, limit: Int = 10) {
        upsertRecommendation(
            for: note,
            key: recentlyEditedKey,
            kind: .edited,
            limit: limit
        )
    }

    private enum RecommendationKind { case opened, edited }

    private static func upsertRecommendation(
        for note: GrammarNote,
        key: String,
        kind: RecommendationKind,
        limit: Int
    ) {
        let now = Date()
        let recommendation: GrammarReviewRecommendation
        switch kind {
        case .opened:
            recommendation = GrammarReviewRecommendation.from(note: note, openedAt: now)
        case .edited:
            recommendation = GrammarReviewRecommendation(
                id: "\(note.topicId)_\(note.id)",
                ownerUID: note.ownerUID,
                topicId: note.topicId,
                noteId: note.id,
                title: note.title,
                previewText: note.previewText,
                languageCode: note.languageCode,
                languageName: note.languageName,
                lastOpenedAt: nil,
                lastEditedAt: now
            )
        }

        let decoder = JSONDecoder()
        let encoder = JSONEncoder()
        var stored: [GrammarReviewRecommendation] = []

        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? decoder.decode([GrammarReviewRecommendation].self, from: data) {
            stored = decoded
        }

        stored.removeAll { $0.noteId == recommendation.noteId && $0.topicId == recommendation.topicId }
        stored.insert(recommendation, at: 0)
        stored = Array(stored.prefix(limit))

        if let data = try? encoder.encode(stored) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func loadLocalRecommendations(limit: Int = 10) {
        recentlyOpenedItems = Self.loadRecommendations(
            key: Self.recentlyOpenedKey,
            ownerUID: ownerUID,
            limit: limit
        )
        recentlyEditedItems = Self.loadRecommendations(
            key: Self.recentlyEditedKey,
            ownerUID: ownerUID,
            limit: limit
        )
        recommendedItems = recentlyOpenedItems
    }

    private static func loadRecommendations(
        key: String,
        ownerUID: String,
        limit: Int
    ) -> [GrammarReviewRecommendation] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([GrammarReviewRecommendation].self, from: data) else {
            return []
        }
        return Array(
            decoded
                .filter { $0.ownerUID == ownerUID || ownerUID.isEmpty }
                .prefix(limit)
        )
    }

    private static func readable(_ error: Error) -> String {
        GrammarNotesErrorMessages.readable(
            for: error,
            firestorePermission: "Review needs Firestore access. Update rules to allow users/{uid}/grammarReviewItems."
        )
    }
}
