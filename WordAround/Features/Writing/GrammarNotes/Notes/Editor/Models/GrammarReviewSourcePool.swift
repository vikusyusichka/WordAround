import Foundation

enum GrammarReviewSourcePool: String, Codable, Equatable, Identifiable {
    case manual
    case recentlyOpened
    case recentlyEdited

    var id: String { rawValue }

    var title: String {
        switch self {
        case .manual:          return "Manual"
        case .recentlyOpened:  return "Recently opened"
        case .recentlyEdited:  return "Recently edited"
        }
    }

    var systemImage: String {
        switch self {
        case .manual:          return "bookmark.fill"
        case .recentlyOpened:  return "clock.fill"
        case .recentlyEdited:  return "pencil"
        }
    }

    func homeCardSubtitle(count: Int) -> String {
        guard count > 0 else { return "Nothing due. Open a note to add it to review." }
        switch self {
        case .manual:
            return count == 1
                ? "1 manually added note ready for review"
                : "\(count) manually added notes ready for review"
        case .recentlyOpened:
            return count == 1
                ? "No manual review items. 1 recently opened note suggested"
                : "No manual review items. \(count) recently opened notes suggested"
        case .recentlyEdited:
            return count == 1
                ? "No recent opened notes. 1 recently edited note suggested"
                : "No recent opened notes. \(count) recently edited notes suggested"
        }
    }
}
