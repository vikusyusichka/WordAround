import Foundation

struct DailyPracticeEntry: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let skill: DailyPracticeSkill
    let date: Date
    let createdAt: Date
    let value: Int
    let sourceModeID: String?
    let sessionId: String?
}
