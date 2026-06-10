import SwiftUI

struct PronunciationItemCardView: View {
    let item: PronunciationItem?
    let isLoading: Bool
    let isSpeaking: Bool
    let onPlay: () -> Void
    let onPlayExample: () -> Void

    private let accent = PronunciationTrainerTheme.accent
    private let accentDark = PronunciationTrainerTheme.accentDark

    var body: some View {
        VStack(spacing: 16) {
            header

            if isLoading {
                loadingState
            } else if let item {
                content(item)
                playButtons(item)
            } else {
                Text(L10n.string("spkNoItemAvailable"))
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.vertical, 16)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.96))
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
        )
    }

    private var header: some View {
        HStack(spacing: 8) {
            if let item {
                chip(icon: item.type.systemImage, text: item.type.label)
                if let focus = item.focusSound, !focus.isEmpty {
                    chip(icon: "waveform", text: focus)
                }
                chip(icon: "chart.bar.fill", text: item.difficulty.title)
            }
            Spacer(minLength: 0)
        }
    }

    private func content(_ item: PronunciationItem) -> some View {
        VStack(spacing: 10) {
            Text(item.text)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: true)

            if let translation = item.translation, !translation.isEmpty {
                Text(translation)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let tip = item.tip, !tip.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(accent)
                    Text(tip)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(accentDark.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(accent.opacity(0.08)))
                .padding(.top, 4)
            }
        }
    }

    private func playButtons(_ item: PronunciationItem) -> some View {
        VStack(spacing: 10) {
            Button(action: onPlay) {
                HStack(spacing: 8) {
                    Image(systemName: isSpeaking ? "speaker.wave.2.fill" : "play.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text(isSpeaking ? "Playing…" : "Play pronunciation")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 22)
                .frame(height: 46)
                .background(LinearGradient(colors: [accent, accentDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(Capsule())
                .shadow(color: accent.opacity(0.30), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(isSpeaking)
            .hoverEffect(.lift)

            if item.hasExample {
                Button(action: onPlayExample) {
                    HStack(spacing: 6) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 13, weight: .semibold))
                        Text(L10n.string("spkPlayExample"))
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(accent)
                    .padding(.horizontal, 16)
                    .frame(height: 38)
                    .background(accent.opacity(0.10))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isSpeaking)
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView().tint(accent)
            Text(L10n.string("spkGeneratingItems"))
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(accentDark)
        }
        .padding(.vertical, 24)
    }

    private func chip(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 10, weight: .bold))
            Text(text).font(.system(size: 12, weight: .bold, design: .rounded)).lineLimit(1)
        }
        .foregroundColor(accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(accent.opacity(0.10))
        .clipShape(Capsule())
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        VStack(spacing: 16) {
            PronunciationItemCardView(
                item: PronunciationItem(
                    type: .word, text: "perro", translation: "dog", languageCode: "es",
                    level: .a2, difficulty: .balanced, focusSound: "rr",
                    tip: "Try to roll the rr sound.", example: "El perro corre rápido."
                ),
                isLoading: false, isSpeaking: false, onPlay: {}, onPlayExample: {}
            )
            PronunciationItemCardView(item: nil, isLoading: true, isSpeaking: false, onPlay: {}, onPlayExample: {})
        }
        .padding()
    }
}
