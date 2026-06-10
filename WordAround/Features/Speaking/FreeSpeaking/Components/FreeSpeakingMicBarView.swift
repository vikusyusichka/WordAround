import SwiftUI

struct FreeSpeakingMicBarView: View {
    let isRecording: Bool
    let isPaused: Bool
    let onEnd: () -> Void
    let onMicTap: () -> Void
    let onPause: () -> Void

    private var isActive: Bool { isRecording && !isPaused }

    var body: some View {
        ZStack {
            waveformDecoration

            HStack(spacing: 0) {
                endButton
                Spacer()
                micButton
                Spacer()
                pauseButton
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
                    .fill(AppColors.greenAccent.opacity(isActive ? 0.18 : 0.07))
                    .frame(width: 3, height: h)
            }
        }
        .allowsHitTesting(false)
        .animation(.easeInOut(duration: 0.3), value: isActive)
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
        Button(action: onMicTap) {
            ZStack {
                if isActive {
                    Circle()
                        .stroke(AppColors.greenAccent.opacity(0.20), lineWidth: 9)
                        .frame(
                            width: Layout.convMicCircleSize + 18,
                            height: Layout.convMicCircleSize + 18
                        )
                }

                Circle()
                    .fill(micCircleColor)
                    .frame(width: Layout.convMicCircleSize, height: Layout.convMicCircleSize)
                    .shadow(color: micCircleColor.opacity(0.30), radius: 14, x: 0, y: 6)

                Image(systemName: isActive ? "stop.fill" : "mic.fill")
                    .font(.system(size: Layout.convMicIconSize, weight: .medium))
                    .foregroundColor(.white)
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.78), value: isRecording)
            .animation(.spring(response: 0.32, dampingFraction: 0.78), value: isPaused)
        }
        .buttonStyle(.plain)
    }

    private var pauseButton: some View {
        Button(action: onPause) {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(AppColors.greenAccent.opacity(0.10))
                        .frame(
                            width: Layout.convMicSideButtonSize,
                            height: Layout.convMicSideButtonSize
                        )
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: Layout.convMicSideIconSize, weight: .medium))
                        .foregroundColor(AppColors.greenAccent)
                }
                Text(isPaused ? "Resume" : "Pause")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.greenAccent)
            }
        }
        .buttonStyle(.plain)
        .opacity(isRecording ? 1.0 : 0.40)
    }

    private var micCircleColor: Color {
        isActive
            ? Color(red: 0.93, green: 0.22, blue: 0.22)
            : AppColors.greenAccent
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        VStack(spacing: 16) {
            Spacer()
            FreeSpeakingMicBarView(
                isRecording: false, isPaused: false,
                onEnd: {}, onMicTap: {}, onPause: {}
            )
            FreeSpeakingMicBarView(
                isRecording: true, isPaused: false,
                onEnd: {}, onMicTap: {}, onPause: {}
            )
            FreeSpeakingMicBarView(
                isRecording: true, isPaused: true,
                onEnd: {}, onMicTap: {}, onPause: {}
            )
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }
}
