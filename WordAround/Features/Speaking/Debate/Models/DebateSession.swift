import Foundation

/// Holds the mutable state of a single debate: the topic being argued, the
/// learner's resolved side, the planned rounds and which round is current.
/// Owned by `DebateModeViewModel`; the view reads it for the topic card,
/// progress indicator and round guidance.
struct DebateSession: Equatable {
    let topic: GeneratedConversationTopic

    /// The learner's resolved side (never `.surpriseMe`).
    let learnerSide: DebateSide

    /// The side the AI opponent argues — always the opposite of the learner.
    let aiSide: DebateSide

    let rounds: [DebateRound]
    var currentRoundIndex: Int

    init(topic: GeneratedConversationTopic, requestedSide: DebateSide, rounds: [DebateRound]) {
        self.topic = topic
        let resolved = requestedSide.resolvedConcreteSide()
        self.learnerSide = resolved
        self.aiSide = resolved == .agree ? .disagree : .agree
        self.rounds = rounds
        self.currentRoundIndex = 0
    }

    var currentRound: DebateRound? {
        guard rounds.indices.contains(currentRoundIndex) else { return nil }
        return rounds[currentRoundIndex]
    }

    var isLastRound: Bool {
        currentRoundIndex >= rounds.count - 1
    }

    var isFinished: Bool {
        currentRoundIndex >= rounds.count
    }

    /// Advances to the next round. Returns `false` when there are no rounds
    /// left (the debate should end).
    mutating func advance() -> Bool {
        guard currentRoundIndex < rounds.count - 1 else {
            currentRoundIndex = rounds.count
            return false
        }
        currentRoundIndex += 1
        return true
    }
}
