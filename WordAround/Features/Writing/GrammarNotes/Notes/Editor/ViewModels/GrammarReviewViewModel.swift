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
    /// Notes the user has opened in the editor recently — loaded from
    /// UserDefaults so it works offline. Priority 2 source for Review Today.
    @Published private(set) var recentlyOpenedItems: [GrammarReviewRecommendation] = []
    /// Notes the user has edited recently — also from UserDefaults.
    /// Priority 3 source for Review Today.
    @Published private(set) var recentlyEditedItems: [GrammarReviewRecommendation] = []
    /// Kept for backwards-compat with any old callers; mirrors
    /// `recentlyOpenedItems` for the duration of the deprecation window.
    @Published private(set) var recommendedItems: [GrammarReviewRecommendation] = []
    @Published private(set) var isAddingRecommendation = false

    /// Top mistake review items for the Home "Mistakes to Fix" section.
    /// NOT filtered by due-date — we want the user to see their open
    /// mistakes regardless of when the algorithm scheduled them.
    @Published private(set) var mistakeHighlights: [GrammarReviewItem] = []
    /// Quizzes that scored low and were promoted into the review queue —
    /// surfaced under "Weak Quiz Areas" on Home.
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

    // MARK: - Pre-built queue (single source of truth)

    /// The pre-built queue that drives BOTH the Review Today home card and
    /// the active session. Card reads `previewQueue.count` / `previewQueue.pool`;
    /// session reads `previewQueue.cards`. The queue is never rebuilt at
    /// "Start Review" time — pressing the button just hands this result
    /// to the session view model verbatim.
    @Published private(set) var previewQueue: GrammarReviewQueueBuilder.Result = .empty
    /// True while the home card is computing the queue. The card shows a
    /// loading row instead of misleading counts during this window.
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

    /// Which pool the next session will use. Read directly from the
    /// pre-built queue so it ALWAYS matches what the session will show.
    /// No more "1 ready" → "Nothing reviewed" mismatches.
    var effectiveSourcePool: GrammarReviewSourcePool? {
        previewQueue.pool
    }

    /// How many cards the next session will surface. Same source as
    /// the session — pulled from the pre-built queue, not from raw counts.
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
            // Pull the full set of due items so the queue builder uses the
            // exact same list. `fetchDueSummary` only returns counts — we
            // need real items here to feed the builder.
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

    /// Builds the pre-fetched queue used by both the home card and the
    /// session. Called by `loadSummary` and any time the recommendation
    /// pools change. Safe to call repeatedly — the builder is idempotent
    /// and the result is cached locally.
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

    /// Loads the two Home highlight strips in parallel: open mistakes and
    /// weak quiz areas. Never blocks the rest of the home screen — Errors
    /// are swallowed (only DEBUG-logged) because empty highlight strips
    /// degrade gracefully to "nothing to show".
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

    /// Stamps `note` as the most-recently-opened entry in the local cache.
    /// Idempotent — dedupes by (topicId, noteId) so reopening a note moves
    /// it to the front instead of duplicating it. Capped at `limit` so the
    /// cache stays small.
    static func recordOpenedNote(_ note: GrammarNote, limit: Int = 10) {
        upsertRecommendation(
            for: note,
            key: recentlyOpenedKey,
            kind: .opened,
            limit: limit
        )
    }

    /// Stamps `note` as the most-recently-edited entry in the local cache.
    /// Called from the editor autosave so the Review Today "Recently edited"
    /// fallback can surface freshly-touched notes even when they were never
    /// added to the manual queue.
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
        // Keep the legacy `recommendedItems` mirror for any UI that still
        // reads it during this transition. The new home card uses
        // `effectiveSourcePool` instead.
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
