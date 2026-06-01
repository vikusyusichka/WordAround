import Foundation

struct ListeningSavedSession: Identifiable, Equatable {
    let id: String
    let title: String
    let modeTitle: String
    let languageTitle: String
    let levelTitle: String
    let score: Int?
    let progress: Double
    let status: String
    let dateText: String
    let isInProgress: Bool
}
