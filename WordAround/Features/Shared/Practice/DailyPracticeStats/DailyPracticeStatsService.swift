import Foundation

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

    func currentStreak() async -> Int {
        let entries = await store.fetchAll()
        guard !entries.isEmpty else { return 0 }

        let activeDays = Set(entries.map { calendar.startOfDay(for: $0.date) })
        let today = calendar.startOfDay(for: Date())

        var anchor = today
        if !activeDays.contains(today) {
            guard
                let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
                activeDays.contains(yesterday)
            else {
                return 0
            }
            anchor = yesterday
        }

        var streak = 0
        var cursor = anchor
        while activeDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return streak
    }

    func defaultGoal(skill: DailyPracticeSkill) -> Int {
        switch skill {
        case .speaking, .listening, .reading: return 15
        case .writing:                         return 200
        }
    }
}
