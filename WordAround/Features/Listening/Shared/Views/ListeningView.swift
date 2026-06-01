import SwiftUI

struct ListeningView: View {
    @StateObject private var viewModel = ListeningHomeViewModel()

    @State private var openListenFromText = false
    @State private var openImportAudio = false
    @State private var openVideoListening = false
    @State private var openSavedPractice = false

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: Layout.listeningModeGridSpacing),
            GridItem(.flexible(), spacing: Layout.listeningModeGridSpacing)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
            ListeningProgressCardView(
                currentMinutes: viewModel.minutesListenedToday,
                totalMinutes: viewModel.dailyGoalMinutes
            )

            Text("Practice modes")
                .font(.system(size: Layout.homeSectionTitleSize, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .padding(.top, Layout.homeSectionTitleTopPadding)

            LazyVGrid(columns: columns, spacing: Layout.listeningModeGridSpacing) {
                ForEach(viewModel.modes) { mode in
                    Button {
                        open(mode)
                    } label: {
                        ListeningModeCardView(mode: mode)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { viewModel.refreshDailyProgress() }
        .navigationDestination(isPresented: $openListenFromText) {
            ListenFromTextSetupView(onExitToListening: { openListenFromText = false })
        }
        .navigationDestination(isPresented: $openImportAudio) {
            ImportAudioSetupView(onExitToListening: { openImportAudio = false })
        }
        .navigationDestination(isPresented: $openVideoListening) {
            VideoListeningSetupView(onExitToListening: { openVideoListening = false })
        }
        .navigationDestination(isPresented: $openSavedPractice) {
            SavedPracticeView(onExitToListening: { openSavedPractice = false })
        }
    }

    private func open(_ mode: ListeningMode) {
        switch mode.id {
        case "listen-from-text": openListenFromText = true
        case "import-audio":     openImportAudio = true
        case "video-listening":  openVideoListening = true
        case "saved-practice":   openSavedPractice = true
        default:                 break
        }
    }
}

#Preview {
    NavigationStack {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()
            ScrollView {
                ListeningView()
                    .padding(.horizontal, Layout.homeHorizontalPadding)
                    .padding(.top, Layout.homeTopSpacing)
            }
        }
    }
}
