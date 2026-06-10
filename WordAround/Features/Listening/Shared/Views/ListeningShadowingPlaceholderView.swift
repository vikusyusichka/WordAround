import SwiftUI

struct ListeningShadowingPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss
    let payload: ListeningShadowingPayload
    var accent: Color = ListeningTheme.accent
    var accentDark: Color = ListeningTheme.accentDark

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                ListeningSetupTopBar(
                    title: L10n.string("spkShadowing"),
                    subtitle: payload.title,
                    accent: accent,
                    accentDark: accentDark,
                    onBack: { dismiss() }
                )

                card {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle().fill(accent.opacity(0.14)).frame(width: 64, height: 64)
                            Image(systemName: "waveform.and.mic")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(accent)
                        }
                        Text(L10n.string("listeningShadowingTitle"))
                            .font(.system(size: Layout.homeSectionTitleSize, weight: .bold, design: .rounded))
                            .foregroundColor(accentDark)
                        Text(L10n.string("listeningShadowingDesc"))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                }

                if !payload.selectedWords.isEmpty {
                    ListeningSetupSectionTitle(L10n.string("listenSectionSavedWords"), accentDark: accentDark)
                    card {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(payload.selectedWords) { word in
                                HStack {
                                    Text(word.originalText)
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(accentDark)
                                    Spacer()
                                    Text(word.translatedText)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                        }
                    }
                }

                if !payload.phrases.isEmpty {
                    ListeningSetupSectionTitle(L10n.string("listenSectionPhrasesToPractice"), accentDark: accentDark)
                    card {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(payload.phrases.enumerated()), id: \.offset) { _, phrase in
                                Text("• \(phrase)")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundColor(accentDark)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: Layout.convContentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.top, Layout.homeTopSpacing)
            .padding(.bottom, Layout.homeBottomSafeSpacing)
        }
        .background(AppColors.appBackground.ignoresSafeArea())
        .tint(accentDark)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.94))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            )
    }
}
