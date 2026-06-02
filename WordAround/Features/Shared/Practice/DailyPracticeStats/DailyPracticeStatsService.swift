import Foundation

/// Records practice activity from individual modes and aggregates it for the
/// dashboard progress cards. Entries are stamped with the start of the local
/// day they happened on, so `totalToday(skill:)` resets automatically when the
/// calendar day changes — previous entries are kept on disk untouched.
///
/// Units stored per skill:
/// - `.speaking`, `.listening`, `.reading` → seconds
/// - `.writing` → words
///
/// `defaultGoal(skill:)` returns the goal in the unit the dashboard already
/// displays (minutes for time skills, words for writing).
final class DailyPracticeStatsService: @unchecked Sendable {
    static let shared = DailyPracticeStatsService()

    private let store: DailyPracticeStatsStoring
    private let calendar: Calendar

    init(
        store: DailyPracticeStatsStoring = LocalDailyPracticeStatsStore.shared,
        calendar: Calendar = .current
    ) {
        self.store = store
        self.calendar = calendar
    }

    /// Fire-and-forget. Non-positive values are dropped so it's safe to call
    /// from cleanup paths where the user never actually practiced.
    func record(
        skill: DailyPracticeSkill,
        value: Int,
        sourceModeID: String? = nil,
        sessionId: String? = nil
    ) {
        guard value > 0 else { return }
        let now = Date()
        let entry = DailyPracticeEntry(
            id: UUID().uuidString,
            skill: skill,
            date: calendar.startOfDay(for: now),
            createdAt: now,
            value: value,
            sourceModeID: sourceModeID,
            sessionId: sessionId
        )
        Task { await store.append(entry) }
    }

    func totalToday(skill: DailyPracticeSkill) async -> Int {
        let today = calendar.startOfDay(for: Date())
        let entries = await store.fetchAll()
        return entries
            .filter { $0.skill == skill && calendar.isDate($0.date, inSameDayAs: today) }
            .reduce(0) { $0 + $1.value }
    }

    /// Goal expressed in the unit the dashboard card already shows:
    /// minutes for time skills, words for writing.
    func defaultGoal(skill: DailyPracticeSkill) -> Int {
        switch skill {
        case .speaking, .listening, .reading: return 15
        case .writing:                         return 200
        }
    }
}
