import SwiftUI

/// A navigation target for continuing or reviewing a saved session.
private struct SavedPracticeRoute: Identifiable, Hashable {
    let id: String
    let session: ListeningPersistedSession

    static func == (lhs: SavedPracticeRoute, rhs: SavedPracticeRoute) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct SavedPracticeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SavedPracticeViewModel()

    var onExitToListening: (() -> Void)? = nil

    @State private var route: SavedPracticeRoute?

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
                        session: continueSession.toSavedSession(),
                        onContinue: { open(continueSession) },
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
                        ForEach(viewModel.savedSessions) { session in
                            ListeningSavedSessionCardView(
                                session: session.toSavedSession(),
                                onContinue: { open(session) },
                                onReview: { open(session) },
                                onDelete: { viewModel.delete(session) },
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
        .tint(accentDark)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { viewModel.load() }
        .navigationDestination(item: $route) { route in
            SavedPracticeDestinationView(
                session: route.session,
                onExit: {
                    self.route = nil
                    viewModel.load()
                }
            )
        }
    }

    private func open(_ session: ListeningPersistedSession) {
        route = SavedPracticeRoute(id: session.id, session: session)
    }
}

/// Resolves a persisted session into the right destination: a review result
/// screen for completed sessions, or the matching mode session screen to
/// continue an unfinished one.
private struct SavedPracticeDestinationView: View {
    let session: ListeningPersistedSession
    let onExit: () -> Void

    var body: some View {
        if let result = session.result {
            ListeningResultView(
                result: result,
                subtitle: session.title,
                chips: [session.language.title, session.level.title, session.modeTitle],
                accent: ListeningTheme.savedPracticeAccent,
                accentDark: ListeningTheme.savedPracticeDark,
                practiceAgainTitle: "Back to Saved Practice",
                backButtonTitle: "Done",
                onPracticeAgain: onExit,
                onBack: onExit
            )
        } else {
            continueDestination
        }
    }

    @ViewBuilder
    private var continueDestination: some View {
        switch session.modeID {
        case "listen-from-text":
            ListenFromTextSessionView(
                setup: session.makeTextSetup(),
                restore: session,
                onExitToSetup: onExit,
                onExitToListening: onExit
            )
        case "import-audio":
            ImportAudioSessionView(
                setup: session.makeAudioSetup(),
                restore: session,
                onExitToSetup: onExit,
                onExitToListening: onExit
            )
        case "video-listening":
            let rebuilt = session.makeVideo()
            VideoListeningSessionView(
                setup: rebuilt.setup,
                video: rebuilt.video,
                sessionId: session.id,
                restore: session,
                onExitToResults: onExit,
                onExitToListening: onExit
            )
        default:
            ListeningEmptyStateView(onStart: onExit)
        }
    }
}

#Preview {
    NavigationStack {
        SavedPracticeView()
    }
}
