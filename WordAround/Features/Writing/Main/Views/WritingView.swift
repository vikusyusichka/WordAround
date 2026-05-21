import SwiftUI

struct WritingView: View {
    @StateObject private var viewModel = WritingViewModel()
    @State private var openEssays = false
    @State private var openGrammarNotes = false

    var onOpenWriteSets: () -> Void = {}

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isPadLike ? 24 : 18) {
            WritingGoalCardView(goal: viewModel.goal)

            VStack(spacing: isPadLike ? 16 : 12) {
                ForEach(viewModel.menuItems) { item in
                    Button {
                        switch item.action {
                        case .writeFromSets:
                            onOpenWriteSets()

                        case .essays:
                            openEssays = true

                        case .grammarNotes:
                            openGrammarNotes = true
                        }
                    } label: {
                        WritingMenuCardView(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .navigationDestination(isPresented: $openEssays) {
            EssayPracticeView()
        }
        .navigationDestination(isPresented: $openGrammarNotes) {
            GrammarNotesHomeView()
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
