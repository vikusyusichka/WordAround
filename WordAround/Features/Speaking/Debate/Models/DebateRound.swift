import Foundation

/// The kind of speaking turn a debate round asks the learner to make.
/// Drives both the on-screen guidance and the instruction sent to the AI
/// opponent for that round.
enum DebateRoundKind: String, Equatable {
    case openingArgument
    case rebuttal
    case crossExamination
    case closingStatement

    var label: String {
        switch self {
        case .openingArgument:  return "Opening"
        case .rebuttal:         return "Rebuttal"
        case .crossExamination: return "Cross-examination"
        case .closingStatement: return "Closing"
        }
    }

    /// What the learner is asked to do this round (shown on the round card).
    var learnerPrompt: String {
        switch self {
        case .openingArgument:
            return "State your opinion and give your strongest reason."
        case .rebuttal:
            return "Respond to the opponent and defend your position."
        case .crossExamination:
            return "Challenge the opponent's point or add a new argument."
        case .closingStatement:
            return "Summarise your case in one strong final statement."
        }
    }

    /// How the AI opponent should behave this round (sent in the prompt).
    var aiInstruction: String {
        switch self {
        case .openingArgument:
            return "Acknowledge the learner's opening, then present one clear counter-argument."
        case .rebuttal:
            return "Challenge the learner's reasoning and ask one probing follow-up question."
        case .crossExamination:
            return "Press the weakest point in the learner's argument, but stay respectful and constructive."
        case .closingStatement:
            return "Give a brief closing counter-point and invite the learner's final statement."
        }
    }
}

struct DebateRound: Identifiable, Equatable {
    let id = UUID()
    let index: Int
    let kind: DebateRoundKind

    /// Human label, e.g. "Round 2 · Rebuttal".
    var title: String { "Round \(index + 1) · \(kind.label)" }
    var learnerPrompt: String { kind.learnerPrompt }
    var aiInstruction: String { kind.aiInstruction }
}

/// Builds an ordered list of debate rounds. The number of middle rounds
/// scales with the chosen session length so longer debates have more
/// back-and-forth, while always opening with an argument and finishing
/// with a closing statement.
enum DebatePlan {
    static func rounds(for length: ConversationLength) -> [DebateRound] {
        let kinds: [DebateRoundKind]
        switch length {
        case .short:
            kinds = [.openingArgument, .rebuttal, .closingStatement]
        case .medium:
            kinds = [.openingArgument, .rebuttal, .crossExamination, .closingStatement]
        case .long:
            kinds = [.openingArgument, .rebuttal, .crossExamination, .rebuttal, .closingStatement]
        }
        return kinds.enumerated().map { DebateRound(index: $0.offset, kind: $0.element) }
    }
}
