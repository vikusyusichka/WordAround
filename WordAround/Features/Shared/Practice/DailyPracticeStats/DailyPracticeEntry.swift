import Foundation

/// One unit of practice recorded by a practice mode.
/// - `value` is stored in the skill's natural unit:
///   - `.speaking`, `.listening`, `.reading` → seconds
///   - `.writing` → words
/// - `date` is the start of the local day the practice happened on, so
///   today's totals can be aggregated cheaply via `Calendar.isDate(_:inSameDayAs:)`.
struct DailyPracticeEntry: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let skill: DailyPracticeSkill
    let date: Date
    let createdAt: Date
    let value: Int
    let sourceModeID: String?
    let sessionId: String?
}
