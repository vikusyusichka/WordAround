import SwiftUI

/// Reading home / menu screen.
///
/// A single uniform 2-column grid of mode cards (same principle as
/// `SpeakingView`). Generated Reading is highlighted via the card's `isFeatured`
/// treatment (gradient + badge), not a larger size, so the grid stays balanced.
/// Tapping a card pushes the shared `ReadingSetupView`. Sessions aren't built.
struct ReadingView: View {
    @StateObject private var viewModel = ReadingHomeViewModel()

    @State private var openGenerated = false
    @State private var openMyTexts = false
    @State private var openFromSets = false
    @State private var openStory = false
    @State private var openSpeed = false
    @State private var openInteractive = false

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: Layout.readingModeGridSpacing),
            GridItem(.flexible(), spacing: Layout.readingModeGridSpacing)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
            ReadingProgressSummaryCardView(
                currentMinutes: viewModel.minutesReadToday,
                totalMinutes: viewModel.dailyGoalMinutes
            )

            Text("Practice modes")
                .font(.system(size: Layout.homeSectionTitleSize, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .padding(.top, Layout.homeSectionTitleTopPadding)

            LazyVGrid(columns: columns, spacing: Layout.readingModeGridSpacing) {
                ForEach(viewModel.modes) { mode in
                    Button {
                        open(mode)
                    } label: {
                        ReadingModeCardView(mode: mode, isFeatured: mode.id == "generated-reading")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .navigationDestination(isPresented: $openGenerated) {
            ReadingSetupView(config: .generatedReading)
        }
        .navigationDestination(isPresented: $openMyTexts) {
            ReadingSetupView(config: .myTexts)
        }
        .navigationDestination(isPresented: $openFromSets) {
            ReadingSetupView(config: .readingFromSets)
        }
        .navigationDestination(isPresented: $openStory) {
            ReadingSetupView(config: .storyMode)
        }
        .navigationDestination(isPresented: $openSpeed) {
            ReadingSetupView(config: .speedReading)
        }
        .navigationDestination(isPresented: $openInteractive) {
            ReadingSetupView(config: .interactiveReading)
        }
    }

    private func open(_ mode: ReadingMode) {
        switch mode.id {
        case "generated-reading":   openGenerated = true
        case "my-texts":            openMyTexts = true
        case "reading-from-sets":   openFromSets = true
        case "story-mode":          openStory = true
        case "speed-reading":       openSpeed = true
        case "interactive-reading": openInteractive = true
        default:                    break
        }
    }
}

#Preview {
    NavigationStack {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()
            ScrollView {
                ReadingView()
                    .padding(.horizontal, Layout.homeHorizontalPadding)
                    .padding(.top, Layout.homeTopSpacing)
            }
        }
    }
}
