import SwiftUI

struct VideoListeningSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = VideoListeningSetupViewModel()

    var onExitToListening: (() -> Void)? = nil

    private let accent = ListeningTheme.videoListeningAccent
    private let accentDark = ListeningTheme.videoListeningDark

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ListeningSetupTopBar(
                        title: "Video Listening",
                        subtitle: "Practice with real videos for your level.",
                        accent: accent,
                        accentDark: accentDark,
                        onBack: { dismiss() }
                    )
                    .padding(.bottom, 4)

                    ListeningSetupSectionTitle("Language", accentDark: accentDark)
                    LanguageSelectorView(
                        selectedLanguage: viewModel.selectedLanguage,
                        onSelect: { viewModel.selectedLanguage = $0 },
                        accent: accent,
                        accentDark: accentDark
                    )

                    ListeningSetupSectionTitle("Level", accentDark: accentDark)
                    DifficultySelectorView(
                        selectedDifficulty: viewModel.selectedLevel,
                        onSelect: { viewModel.selectedLevel = $0 },
                        accent: accent,
                        accentDark: accentDark
                    )

                    ListeningSetupSectionTitle("Video Length", accentDark: accentDark)
                    lengthSelector
                    Text(viewModel.selectedLength.helperText)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.mutedText)

                    ListeningSetupSectionTitle("Preview", accentDark: accentDark)
                    ListeningPreviewCard(
                        title: "Level-based video search",
                        subtitle: viewModel.previewSubtitle,
                        chips: viewModel.previewChips,
                        accent: accent,
                        accentDark: accentDark
                    )

                    Spacer().frame(height: Layout.convSetupStartButtonHeight + 32)
                }
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }

            ListeningSetupStartButton(
                title: "Find Videos",
                icon: "magnifyingglass",
                accent: accent,
                accentDark: accentDark,
                action: { viewModel.findVideos() }
            )
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
        }
        .ignoresSafeArea(edges: .bottom)
        .tint(accentDark)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $viewModel.showResults) {
            VideoListeningResultsView(
                setup: viewModel.makeSetup(),
                onExitToSetup: { viewModel.showResults = false },
                onExitToListening: onExitToListening
            )
        }
    }

    private var lengthSelector: some View {
        HStack(spacing: Layout.convSetupGridSpacing) {
            ForEach(ListeningVideoLength.allCases) { length in
                let isSelected = viewModel.selectedLength == length
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) { viewModel.selectedLength = length }
                } label: {
                    Text(length.rawValue)
                        .font(.system(size: Layout.convSetupDurationChipTextSize, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .white : accentDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: Layout.convSetupDurationChipHeight)
                        .background(isSelected ? accent : accent.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                                .stroke(isSelected ? Color.clear : accent.opacity(0.22), lineWidth: 1)
                        )
                }
                .buttonStyle(ListeningSetupPressStyle())
            }
        }
    }
}

#Preview {
    NavigationStack {
        VideoListeningSetupView()
    }
}
