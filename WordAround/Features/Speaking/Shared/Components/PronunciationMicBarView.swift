import SwiftUI

/// Floating bottom bar for Pronunciation Trainer. Presentation only.
/// LEFT: Retry · CENTER: Mic · RIGHT: Next.
struct PronunciationMicBarView: View {
    let state: SpeakingConversationState
    let canRetry: Bool
    let isLastItem: Bool
    let onRetry: () -> Void
    let onMic: () -> Void
    let onNext: () -> Void

    private let accent = PronunciationTrainerTheme.accent

    private var isRecording: Bool { state.isListening }
    private var isProcessing: Bool { if case .processing = state { return true } else { return false } }

    var body: some View {
        ZStack {
            waveformDecoration

            HStack(spacing: 0) {
                retryButton
                Spacer()
                micButton
                Spacer()
                nextButton
            }
            .padding(.horizontal, Layout.convMicBarHorizontalPadding)
            .frame(height: Layout.convMicBarHeight)
        }
        .background(
            RoundedRectangle(cornerRadius: Layout.convMicBarCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.97))
                .shadow(color: Color.black.opacity(0.07), radius: 22, x: 0, y: -4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.convMicBarCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.90), lineWidth: 1)
        )
    }

    private var waveformDecoration: some View {
        let heights: [CGFloat] = [8, 14, 20, 28, 20, 14, 8]
        return HStack(alignment: .center, spacing: 4) {
            ForEach(Array(heights.enumerated()), id: \.offset) { _, h in
                Capsule()
                    .fill(accent.opacity(isRecording ? 0.18 : 0.07))
                    .frame(width: 3, height: h)
            }
        }
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.3), value: isRecording)
    }

    private var retryButton: some View {
        Button(action: onRetry) {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(canRetry ? accent.opacity(0.12) : Color.gray.opacity(0.10))
                        .frame(width: Layout.convMicSideButtonSize, height: Layout.convMicSideButtonSize)
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: Layout.convMicSideIconSize, weight: .semibold))
                        .foregroundColor(canRetry ? accent : AppColors.mutedText)
                }
                Text("Retry")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(canRetry ? accent : AppColors.mutedText)
            }
        }
        .buttonStyle(.plain)
        .disabled(!canRetry)
    }

    private var micButton: some View {
        Button(action: onMic) {
            ZStack {
                if isRecording {
                    Circle()
                        .stroke(accent.opacity(0.20), lineWidth: 9)
                        .frame(width: Layout.convMicCircleSize + 18, height: Layout.convMicCircleSize + 18)
                }

                Circle()
                    .fill(micCircleColor)
                    .frame(width: Layout.convMicCircleSize, height: Layout.convMicCircleSize)
                    .shadow(color: micCircleColor.opacity(0.30), radius: 14, x: 0, y: 6)

                if isProcessing {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: Layout.convMicIconSize, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.78), value: isRecording)
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
    }

    private var nextButton: some View {
        Button(action: onNext) {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.12))
                        .frame(width: Layout.convMicSideButtonSize, height: Layout.convMicSideButtonSize)
                    Image(systemName: isLastItem ? "flag.checkered" : "arrow.right")
                        .font(.system(size: Layout.convMicSideIconSize, weight: .semibold))
                        .foregroundColor(accent)
                }
                Text(isLastItem ? "Finish" : "Next")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(accent)
            }
        }
        .buttonStyle(.plain)
    }

    private var micCircleColor: Color {
        isRecording ? Color(red: 0.93, green: 0.22, blue: 0.22) : accent
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        VStack(spacing: 16) {
            Spacer()
            PronunciationMicBarView(state: .idle, canRetry: false, isLastItem: false, onRetry: {}, onMic: {}, onNext: {})
            PronunciationMicBarView(state: .listening, canRetry: true, isLastItem: true, onRetry: {}, onMic: {}, onNext: {})
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }
}
