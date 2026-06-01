import Foundation

enum ReadingQuestionType: String, Codable, CaseIterable, Equatable, Hashable {
    case comprehension
    case trueFalse
    case fillGap
    case vocabulary
    case findEvidence
    case orderReconstruction

    var displayTitle: String {
        switch self {
        case .comprehension: return "Comprehension"
        case .trueFalse: return "True / False"
        case .fillGap: return "Fill Gaps"
        case .vocabulary: return "Vocabulary"
        case .findEvidence: return "Find Evidence"
        case .orderReconstruction: return "Order Reconstruction"
        }
    }

    static var defaultEnabled: Set<ReadingQuestionType> {
        [.comprehension, .vocabulary, .trueFalse]
    }

    static var defaultEnabledRawValues: [String] {
        defaultEnabled.map(\.rawValue)
    }

    static func from(rawValues: [String]) -> Set<ReadingQuestionType> {
        let set = Set(rawValues.compactMap { ReadingQuestionType(rawValue: $0) })
        return set.isEmpty ? defaultEnabled : set
    }
}
