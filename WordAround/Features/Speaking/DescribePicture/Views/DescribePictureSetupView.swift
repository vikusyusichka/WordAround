import SwiftUI

struct DescribePictureSetupView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedLanguage: GrammarLanguage = .english
    @State private var selectedLevel: EssayDifficulty = .a2
    @State private var selectedLength: ConversationLength = .short
    @State private var showSession = false

    private let orange = AppColors.orangeAccent
    private let orangeDark = AppColors.orangeTitle

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    SpeakingSetupTopBar(
                        title: "Describe Picture",
                        subtitle: "Describe images and improve your speaking.",
                        accent: orange,
                        accentDark: orangeDark,
                        onBack: { dismiss() }
                    )
                    .padding(.bottom, 4)

                    SpeakingSetupSectionTitle("Language", accentDark: orangeDark)
                    LanguageSelectorView(
                        selectedLanguage: selectedLanguage,
                        onSelect: { selectedLanguage = $0 },
                        accent: orange,
                        accentDark: orangeDark
                    )

                    SpeakingSetupSectionTitle("Level", accentDark: orangeDark)
                    DifficultySelectorView(
                        selectedDifficulty: selectedLevel,
                        onSelect: { selectedLevel = $0 },
                        accent: orange,
                        accentDark: orangeDark
                    )

                    SpeakingSetupSectionTitle("Session length", accentDark: orangeDark)
                    SpeakingSetupDurationPicker(
                        selection: $selectedLength,
                        accent: orange,
                        accentDark: orangeDark
                    )

                    SpeakingSetupSectionTitle("Preview", accentDark: orangeDark)
                    previewCard

                    Spacer().frame(height: Layout.convSetupStartButtonHeight + 32)
                }
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }

            SpeakingSetupStartButton(
                title: "Start Describe Picture",
                icon: "photo.fill",
                accent: orange,
                accentDark: orangeDark,
                action: { showSession = true }
            )
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showSession) {
            DescribePictureView(
                setup: SpeakingConversationSetup(
                    language: selectedLanguage,
                    level: selectedLevel,
                    scenario: nil,
                    length: selectedLength
                )
            )
        }
    }

    private var previewCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(orange.opacity(0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: "photo.fill")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundColor(orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Random picture")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(orangeDark)
                Text("We'll load a fresh photo for \(selectedLanguage.title) · \(selectedLevel.title) when you start.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 5)
        )
    }
}

#Preview {
    NavigationStack {
        DescribePictureSetupView()
    }
}
