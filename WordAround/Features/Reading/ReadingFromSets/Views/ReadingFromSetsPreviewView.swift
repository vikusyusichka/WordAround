import SwiftUI

struct ReadingFromSetsPreviewView: View {
    let setup: ReadingSessionSetup
    var onExitToSetup: () -> Void
    var onExitToReading: () -> Void

    @State private var showSession = false

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingSessionHeaderView(
                        title: "Reading From Set",
                        subtitle: "Built from your flashcard vocabulary.",
                        accent: setup.accent,
                        accentDark: setup.accentDark,
                        onBack: onExitToSetup
                    )

                    summaryCard

                    ReadingTextCardView(
                        bodyText: ReadingPlaceholderData.setPreviewText,
                        highlightedWords: ReadingPlaceholderData.setHighlightedWords,
                        highlightColor: setup.accent,
                        legend: "Highlighted = from your set",
                        accent: setup.accent
                    )

                    Spacer().frame(height: Layout.convSetupStartButtonHeight + 24)
                }
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }

            ReadingContinueButton(
                title: "Start Practice",
                icon: "play.fill",
                accent: setup.accent,
                accentDark: setup.accentDark
            ) {
                showSession = true
            }
            .frame(maxWidth: Layout.convContentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showSession) {
            ReadingFromSetsSessionView(
                setup: setup,
                onExitToSetup: onExitToSetup,
                onExitToReading: onExitToReading
            )
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(ReadingPlaceholderData.setName)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(setup.accentDark)

            HStack(spacing: 8) {
                ReadingMetadataChip(text: "\(ReadingPlaceholderData.setWordCount) words", accent: setup.accent)
                ReadingMetadataChip(text: setup.selection("style", default: "Natural style"), accent: setup.accent)
                ReadingMetadataChip(text: "\(ReadingPlaceholderData.setWordsIncluded) words included", accent: setup.accent)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
    }
}

#Preview {
    NavigationStack {
        ReadingFromSetsPreviewView(
            setup: ReadingSetupViewModel(config: .readingFromSets).makeSessionSetup(),
            onExitToSetup: {},
            onExitToReading: {}
        )
    }
}
