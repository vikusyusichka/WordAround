import SwiftUI

/// Three-step guide (Listen → Repeat → Compare) with the active step
/// highlighted from the current speaking state. Presentation only.
struct ShadowingListenRepeatCardView: View {
    let state: SpeakingConversationState
    let isSpeakingTarget: Bool
    let hasAttempt: Bool

    private let accent = ShadowingTheme.accent
    private let accentDark = ShadowingTheme.accentDark

    private enum Step: Int { case listen, repeatStep, compare }

    private var activeStep: Step {
        if isSpeakingTarget { return .listen }
        switch state {
        case .listening, .processing: return .repeatStep
        default: return hasAttempt ? .compare : .listen
        }
    }

    private var statusText: String {
        if isSpeakingTarget { return "Listening to the target phrase…" }
        switch state {
        case .listening:  return "Your turn. Repeat the phrase aloud."
        case .processing: return "Analyzing your attempt…"
        default:          return hasAttempt ? "Compare your result below." : "Tap Play, then repeat the phrase."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                stepView(index: 1, label: "Listen", systemImage: "ear.fill", step: .listen)
                connector
                stepView(index: 2, label: "Repeat", systemImage: "mic.fill", step: .repeatStep)
                connector
                stepView(index: 3, label: "Compare", systemImage: "checkmark.seal.fill", step: .compare)
            }

            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(accent)
                Text(statusText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(accentDark)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 5)
        )
        .animation(.easeInOut(duration: 0.2), value: activeStep)
    }

    private func stepView(index: Int, label: String, systemImage: String, step: Step) -> some View {
        let isActive = activeStep == step
        return VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isActive ? accent : accent.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isActive ? .white : accent)
            }
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(isActive ? accentDark : AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var connector: some View {
        Rectangle()
            .fill(accent.opacity(0.18))
            .frame(height: 2)
            .frame(maxWidth: 24)
            .offset(y: -10)
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        VStack(spacing: 16) {
            ShadowingListenRepeatCardView(state: .speaking, isSpeakingTarget: true, hasAttempt: false)
            ShadowingListenRepeatCardView(state: .listening, isSpeakingTarget: false, hasAttempt: false)
            ShadowingListenRepeatCardView(state: .idle, isSpeakingTarget: false, hasAttempt: true)
        }
        .padding()
    }
}
