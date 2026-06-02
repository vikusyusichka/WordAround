import SwiftUI

struct ListeningAudioPlayerCard: View {
    @Binding var isPlaying: Bool
    let progress: Double
    let currentTimeText: String
    let durationText: String
    let speedLabel: String
    var accent: Color = ListeningTheme.accent
    var accentDark: Color = ListeningTheme.accentDark
    var onPlayPause: (() -> Void)? = nil
    var onReplay: (() -> Void)? = nil

    var body: some View {
        ListeningWhiteCard {
            VStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(accent.opacity(0.08))
                        .frame(height: 120)

                    HStack(spacing: 6) {
                        ForEach(0..<24, id: \.self) { index in
                            Capsule()
                                .fill(accent.opacity(isPlaying ? 0.55 : 0.25))
                                .frame(width: 4, height: waveformHeight(for: index))
                                .animation(
                                    isPlaying
                                        ? .easeInOut(duration: 0.35).repeatForever().delay(Double(index) * 0.04)
                                        : .default,
                                    value: isPlaying
                                )
                        }
                    }
                    .padding(.horizontal, 24)

                    Image(systemName: "waveform")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(accent.opacity(0.18))
                }

                HStack(spacing: 16) {
                    Button {
                        if let onPlayPause {
                            onPlayPause()
                        } else {
                            withAnimation(.easeInOut(duration: 0.2)) { isPlaying.toggle() }
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(accent)
                                .frame(width: 56, height: 56)
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: isPlaying ? 0 : 2)
                        }
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 8) {
                        ReadingProgressBar(progress: progress, accent: accent)

                        HStack {
                            Text(currentTimeText)
                            Spacer()
                            Text(durationText)
                        }
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                    }
                }

                HStack(spacing: 10) {
                    ListeningMetadataChip(text: speedLabel, accent: accent)

                    Button { onReplay?() } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 12, weight: .semibold))
                            Text("Replay")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(accentDark)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(accent.opacity(0.10))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
            }
        }
    }

    private func waveformHeight(for index: Int) -> CGFloat {
        let base: CGFloat = isPlaying ? 18 : 12
        let variation = CGFloat((index * 7 + 11) % 28)
        return base + variation
    }
}
