import Foundation

enum EssayDifficulty: String, CaseIterable, Identifiable, Equatable, Codable {
    case a1 = "A1"
    case a2 = "A2"
    case b1 = "B1"
    case b2 = "B2"
    case c1 = "C1"
    case native = "Native"

    var id: String { rawValue }

    var title: String {
        rawValue
    }

    var hintsLimit: Int {
        switch self {
        case .a1:
            return 15
        case .a2:
            return 12
        case .b1:
            return 7
        case .b2:
            return 5
        case .c1:
            return 3
        case .native:
            return 0
        }
    }

    var translationLimit: Int {
        switch self {
        case .a1:
            return 20
        case .a2:
            return 15
        case .b1:
            return 10
        case .b2:
            return 6
        case .c1:
            return 3
        case .native:
            return 0
        }
    }

    var synonymLimit: Int {
        switch self {
        case .a1:
            return 10
        case .a2:
            return 8
        case .b1:
            return 6
        case .b2:
            return 5
        case .c1:
            return 3
        case .native:
            return 0
        }
    }

    var allowsTranslation: Bool {
        translationLimit > 0
    }

    var translationWordLimit: Int {
        switch self {
        case .a1:
            return 20
        case .a2:
            return 15
        case .b1:
            return 10
        case .b2:
            return 6
        case .c1:
            return 3
        case .native:
            return 0
        }
    }

    var helperIntensityTitle: String {
        switch self {
        case .a1, .a2:
            return L10n.string("essayDifficultyGuided")
        case .b1:
            return L10n.string("essayDifficultyBalanced")
        case .b2, .c1:
            return L10n.string("essayDifficultyLimited")
        case .native:
            return L10n.string("essayDifficultyIndependent")
        }
    }

    var scoringPenaltyMultiplier: Double {
        switch self {
        case .a1:
            return 0.6
        case .a2:
            return 0.75
        case .b1:
            return 1.0
        case .b2:
            return 1.15
        case .c1:
            return 1.3
        case .native:
            return 1.45
        }
    }
}
