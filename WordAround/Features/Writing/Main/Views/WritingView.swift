import SwiftUI

struct WritingView: View {
    @StateObject private var viewModel = WritingViewModel()
    @State private var openEssays = false
    @State private var openGrammarNotes = false

    var onOpenWriteSets: () -> Void = {}

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: Layout.readingModeGridSpacing),
            GridItem(.flexible(), spacing: Layout.readingModeGridSpacing)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
            WritingProgressSummaryCardView(
                currentWords: viewModel.currentWordsToday,
                totalWords: viewModel.targetWords
            )

            Text("Practice modes")
                .font(.system(size: Layout.homeSectionTitleSize, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .padding(.top, Layout.homeSectionTitleTopPadding)

            LazyVGrid(columns: columns, spacing: Layout.readingModeGridSpacing) {
                ForEach(viewModel.menuItems) { item in
                    Button {
                        handleMenuAction(item.action)
                    } label: {
                        WritingMenuCardView(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { viewModel.refreshDailyProgress() }
        .navigationDestination(isPresented: $openEssays) {
            EssayPracticeView()
        }
        .navigationDestination(isPresented: $openGrammarNotes) {
            GrammarNotesHomeView()
        }
    }

    private func handleMenuAction(_ action: WritingMenuAction) {
        switch action {
        case .writeFromSets:
            onOpenWriteSets()
        case .essays:
            openEssays = true
        case .grammarNotes:
            openGrammarNotes = true
        }
    }
}

#Preview {
    NavigationStack {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView {
                WritingView()
                    .padding(24)
            }
        }
    }
}
