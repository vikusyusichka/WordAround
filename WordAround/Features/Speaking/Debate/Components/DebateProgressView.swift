import SwiftUI

struct DebateProgressView: View {
    let rounds: [DebateRound]
    let currentIndex: Int

    private let accent = DebateTheme.accent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ForEach(rounds) { round in
                    Capsule()
                        .fill(fill(for: round.index))
                        .frame(height: 6)
                        .frame(maxWidth: .infinity)
                        .animation(.easeInOut(duration: 0.25), value: currentIndex)
                }
            }

            if let round = currentRound {
                Text(round.title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
            } else {
                Text("Debate complete")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(accent)
            }
        }
    }

    private var currentRound: DebateRound? {
        guard rounds.indices.contains(currentIndex) else { return nil }
        return rounds[currentIndex]
    }

    private func fill(for index: Int) -> Color {
        if index < currentIndex { return accent }
        if index == currentIndex { return accent.opacity(0.65) }
        return accent.opacity(0.14)
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        VStack(spacing: 24) {
            DebateProgressView(rounds: DebatePlan.rounds(for: .medium), currentIndex: 0)
            DebateProgressView(rounds: DebatePlan.rounds(for: .medium), currentIndex: 2)
        }
        .padding()
    }
}
