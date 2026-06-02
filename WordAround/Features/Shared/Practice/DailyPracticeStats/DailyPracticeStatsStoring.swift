import Foundation

protocol DailyPracticeStatsStoring: Sendable {
    func append(_ entry: DailyPracticeEntry) async
    func fetchAll() async -> [DailyPracticeEntry]
}
