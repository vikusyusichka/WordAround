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
        case .comprehension:       return L10n.string("readingComprehension")
        case .trueFalse:           return L10n.string("listenTrueFalseShort")
        case .fillGap:             return L10n.string("readingQTypeFillGaps")
        case .vocabulary:          return L10n.string("spkVocabulary")
        case .findEvidence:        return L10n.string("readingQTypeFindEvidence")
        case .orderReconstruction: return L10n.string("readingQTypeOrderReconstruction")
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
