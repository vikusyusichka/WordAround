import SwiftUI

struct SavedPracticeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SavedPracticeViewModel()

    var onExitToListening: (() -> Void)? = nil

    private let accent = ListeningTheme.savedPracticeAccent
    private let accentDark = ListeningTheme.savedPracticeDark

    private var columns: [GridItem] {
        if Layout.isPadLike {
            return [GridItem(.flexible()), GridItem(.flexible())]
        }
        return [GridItem(.flexible())]
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                ListeningSetupTopBar(
                    title: "Saved Practice",
                    subtitle: "Continue sessions and review your listening mistakes.",
                    accent: accent,
                    accentDark: accentDark,
                    onBack: { dismiss() }
                )

                if let continueSession = viewModel.continueSession {
                    ListeningSetupSectionTitle("Continue listening", accentDark: accentDark)
                    ListeningContinueCardView(
                        session: continueSession,
                        onContinue: {},
                        accent: accent,
                        accentDark: accentDark
                    )
                }

                if viewModel.isEmpty {
                    ListeningEmptyStateView(onStart: {
                        onExitToListening?()
                        dismiss()
                    }, accent: accent, accentDark: accentDark)
                } else {
                    ListeningSetupSectionTitle("Saved sessions", accentDark: accentDark)
                    LazyVGrid(columns: columns, spacing: Layout.listeningModeGridSpacing) {
                        ForEach(viewModel.savedSessionItems) { session in
                            ListeningSavedSessionCardView(
                                session: session,
                                onContinue: {},
                                accent: accent,
                                accentDark: accentDark
                            )
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
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { viewModel.load() }
    }
}

#Preview {
    NavigationStack {
        SavedPracticeView()
    }
}
