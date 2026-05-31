import SwiftUI

struct ReadingFromSetsResultView: View {
    let setup: ReadingSessionSetup
    var onExitToSetup: () -> Void
    var onExitToReading: () -> Void

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingResultHeaderView(
                        icon: "rectangle.stack.fill",
                        title: "Set Reading Complete",
                        subtitle: "You practiced words from \(ReadingPlaceholderData.setName).",
                        accent: setup.accent,
                        accentDark: setup.accentDark
                    )

                    ReadingResultSummaryCard(
                        primaryValue: "85%",
                        primaryLabel: "Comprehension",
                        secondaryMetrics: [
                            ("28", "Set words practiced"),
                            ("12", "New examples"),
                            ("5 / 6", "Correct")
                        ],
                        accent: setup.accent
                    )

                    ReadingSectionTitle(title: "Practiced Set Words")
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(ReadingPlaceholderData.setWords) { word in
                            ReadingVocabularyReviewCard(
                                word: word.word,
                                translation: word.translation,
                                example: word.example,
                                status: word.status,
                                accent: setup.accent
                            )
                        }
                    }

                    ReadingSectionTitle(title: "Add to Review")
                    actionCard("Add difficult words to review", icon: "plus.circle.fill")
                    actionCard("Practice this set again", icon: "arrow.clockwise")
                    actionCard("Generate another reading", icon: "sparkles")

                    ReadingResultActions(
                        primaryTitle: "Back to Set",
                        secondaryTitle: "Back to Reading",
                        primaryIcon: "rectangle.stack.fill",
                        accent: setup.accent,
                        accentDark: setup.accentDark,
                        onPrimary: onExitToSetup,
                        onSecondary: onExitToReading
                    )
                }
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func actionCard(_ title: String, icon: String) -> some View {
        Button {} label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundColor(setup.accent)
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.mutedText)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.94))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ReadingFromSetsResultView(
        setup: ReadingSetupViewModel(config: .readingFromSets).makeSessionSetup(),
        onExitToSetup: {},
        onExitToReading: {}
    )
}
