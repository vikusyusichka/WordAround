import SwiftUI

struct ConversationMicBarView: View {
    let state: SpeakingConversationState
    let onEnd: () -> Void
    let onMic: () -> Void
    let onHint: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            endButton
            Spacer()
            micButton
            Spacer()
            hintButton
        }
        .padding(.horizontal, Layout.convMicBarHorizontalPadding)
        .frame(height: Layout.convMicBarHeight)
        .background(
            RoundedRectangle(cornerRadius: Layout.convMicBarCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.97))
                .shadow(
                    color: Color.black.opacity(0.07),
                    radius: 22, x: 0, y: -4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.convMicBarCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.90), lineWidth: 1)
        )
    }

    private var endButton: some View {
        Button(action: onEnd) {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(AppColors.foodBackground)
                        .frame(
                            width: Layout.convMicSideButtonSize,
                            height: Layout.convMicSideButtonSize
                        )

                    Image(systemName: "xmark")
                        .font(.system(size: Layout.convMicSideIconSize, weight: .bold))
                        .foregroundColor(AppColors.foodAccent)
                }

                Text(L10n.string("spkEnd"))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.foodAccent)
            }
        }
        .buttonStyle(.plain)
    }

    private var micButton: some View {
        Button(action: onMic) {
            ZStack {
                if state.isListening {
                    Circle()
                        .stroke(
                            AppColors.primaryBlue.opacity(0.20),
                            lineWidth: 9
                        )
                        .frame(
                            width: Layout.convMicCircleSize + 18,
                            height: Layout.convMicCircleSize + 18
                        )
                }

                Circle()
                    .fill(micCircleColor)
                    .frame(
                        width: Layout.convMicCircleSize,
                        height: Layout.convMicCircleSize
                    )
                    .shadow(
                        color: micCircleColor.opacity(0.30),
                        radius: 14, x: 0, y: 6
                    )

                micIcon
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.78), value: state.isListening)
        }
        .buttonStyle(.plain)
        .disabled(state.isBusy)
    }

    @ViewBuilder
    private var micIcon: some View {
        switch state {
        case .processing:
            ProgressView()
                .tint(.white)
                .scaleEffect(1.2)
        case .listening:
            Image(systemName: "stop.fill")
                .font(.system(size: Layout.convMicIconSize, weight: .medium))
                .foregroundColor(.white)
        case .speaking:
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: Layout.convMicIconSize, weight: .medium))
                .foregroundColor(.white)
        case .idle, .error:
            Image(systemName: "mic.fill")
                .font(.system(size: Layout.convMicIconSize, weight: .medium))
                .foregroundColor(.white)
        }
    }

    private var hintButton: some View {
        Button(action: onHint) {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(AppColors.primaryBlue.opacity(0.08))
                        .frame(
                            width: Layout.convMicSideButtonSize,
                            height: Layout.convMicSideButtonSize
                        )

                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: Layout.convMicSideIconSize, weight: .medium))
                        .foregroundColor(AppColors.primaryBlue)
                }

                Text(L10n.string("spkHint"))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlue)
            }
        }
        .buttonStyle(.plain)
    }

    private var micCircleColor: Color {
        switch state {
        case .idle, .error:
            return AppColors.primaryBlue
        case .listening:
            return Color(red: 0.93, green: 0.22, blue: 0.22)
        case .processing:
            return Color(red: 0.60, green: 0.71, blue: 0.98)
        case .speaking:
            return AppColors.greenAccent
        }
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()

        VStack(spacing: 16) {
            Spacer()
            ConversationMicBarView(state: .idle,       onEnd: {}, onMic: {}, onHint: {})
            ConversationMicBarView(state: .listening,  onEnd: {}, onMic: {}, onHint: {})
            ConversationMicBarView(state: .processing, onEnd: {}, onMic: {}, onHint: {})
            ConversationMicBarView(state: .speaking,   onEnd: {}, onMic: {}, onHint: {})
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }
}
