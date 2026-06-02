import Foundation

struct DebateSession: Equatable {
    let topic: GeneratedConversationTopic

    let learnerSide: DebateSide

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

    mutating func advance() -> Bool {
        guard currentRoundIndex < rounds.count - 1 else {
            currentRoundIndex = rounds.count
            return false
        }
        currentRoundIndex += 1
        return true
    }
}
