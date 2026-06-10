import SwiftUI

struct ShadowingPhraseCardView: View {
    let phrase: ShadowingPhrase?
    let isLoading: Bool
    let isSpeaking: Bool
    let onPlay: () -> Void

    private let accent = ShadowingTheme.accent
    private let accentDark = ShadowingTheme.accentDark

    var body: some View {
        VStack(spacing: 16) {
            header

            if isLoading {
                loadingState
            } else if let phrase {
                phraseContent(phrase)
                playButton
            } else {
                Text(L10n.string("spkNoPhraseAvailable"))
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
            if let phrase {
                chip(icon: phrase.category.systemImage, text: phrase.category.title)
                chip(icon: "chart.bar.fill", text: phrase.level.title)
            }
            Spacer(minLength: 0)
        }
    }

    private func phraseContent(_ phrase: ShadowingPhrase) -> some View {
        VStack(spacing: 10) {
            Text(phrase.text)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let translation = phrase.translation, !translation.isEmpty {
                Text(translation)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let tip = phrase.tip, !tip.isEmpty {
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
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(accent.opacity(0.08))
                )
                .padding(.top, 4)
            }
        }
    }

    private var playButton: some View {
        Button(action: onPlay) {
            HStack(spacing: 8) {
                Image(systemName: isSpeaking ? "speaker.wave.2.fill" : "play.fill")
                    .font(.system(size: 15, weight: .bold))
                Text(isSpeaking ? "Playing…" : "Play phrase")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 22)
            .frame(height: 46)
            .background(
                LinearGradient(colors: [accent, accentDark], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(Capsule())
            .shadow(color: accent.opacity(0.30), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(isSpeaking)
        .hoverEffect(.lift)
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView().tint(accent)
            Text(L10n.string("spkGeneratingPhrases"))
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(accentDark)
        }
        .padding(.vertical, 24)
    }

    private func chip(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(.system(size: 12, weight: .bold, design: .rounded))
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
            ShadowingPhraseCardView(
                phrase: ShadowingPhrase(
                    text: "Could you repeat that, please?",
                    translation: nil,
                    languageCode: "en",
                    level: .b1,
                    category: .daily,
                    tip: "Include all the small function words."
                ),
                isLoading: false,
                isSpeaking: false,
                onPlay: {}
            )
            ShadowingPhraseCardView(phrase: nil, isLoading: true, isSpeaking: false, onPlay: {})
        }
        .padding()
    }
}
