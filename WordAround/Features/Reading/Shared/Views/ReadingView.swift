import SwiftUI

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
        // Each mode opens its own library first. My Texts keeps its existing,
        // richer library screen; the other modes share `ReadingModeLibraryView`.
        .navigationDestination(isPresented: $openGenerated) {
            library(for: "generated-reading")
        }
        .navigationDestination(isPresented: $openMyTexts) {
            ReadingMyTextsView()
        }
        .navigationDestination(isPresented: $openFromSets) {
            library(for: "reading-from-sets")
        }
        .navigationDestination(isPresented: $openStory) {
            library(for: "story-mode")
        }
        .navigationDestination(isPresented: $openSpeed) {
            library(for: "speed-reading")
        }
        .navigationDestination(isPresented: $openInteractive) {
            library(for: "interactive-reading")
        }
    }

    @ViewBuilder
    private func library(for id: String) -> some View {
        if let mode = viewModel.modes.first(where: { $0.id == id }) {
            ReadingModeLibraryView(mode: mode)
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
