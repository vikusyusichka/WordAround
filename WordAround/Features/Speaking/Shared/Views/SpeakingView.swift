import SwiftUI

struct SpeakingView: View {
    @State private var openAIConversation = false
    @State private var openFreeSpeaking = false
    @State private var openDescribePicture = false
    @State private var openDebateMode = false
    @State private var openShadowing = false
    @State private var openPronunciation = false

    private let modes = SpeakingMode.allModes

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: Layout.speakingModeGridSpacing),
            GridItem(.flexible(), spacing: Layout.speakingModeGridSpacing)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
            SpeakingProgressCardView(currentMinutes: 7, totalMinutes: 15)

            Text("Practice modes")
                .font(.system(size: Layout.homeSectionTitleSize, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .padding(.top, Layout.homeSectionTitleTopPadding)

            LazyVGrid(columns: columns, spacing: Layout.speakingModeGridSpacing) {
                ForEach(modes) { mode in
                    Button {
                        if mode.id == "ai-conversation" {
                            openAIConversation = true
                        } else if mode.id == "free-speaking" {
                            openFreeSpeaking = true
                        } else if mode.id == "describe-picture" {
                            openDescribePicture = true
                        } else if mode.id == "debate-mode" {
                            openDebateMode = true
                        } else if mode.id == "shadowing" {
                            openShadowing = true
                        } else if mode.id == "pronunciation" {
                            openPronunciation = true
                        }
                    } label: {
                        SpeakingModeCardView(mode: mode)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .navigationDestination(isPresented: $openAIConversation) {
            AIConversationSetupView(onExitToSpeaking: { openAIConversation = false })
        }
        .navigationDestination(isPresented: $openFreeSpeaking) {
            FreeSpeakingSetupView(onExitToSpeaking: { openFreeSpeaking = false })
        }
        .navigationDestination(isPresented: $openDescribePicture) {
            DescribePictureSetupView()
        }
        .navigationDestination(isPresented: $openDebateMode) {
            DebateModeSetupView()
        }
        .navigationDestination(isPresented: $openShadowing) {
            ShadowingSetupView()
        }
        .navigationDestination(isPresented: $openPronunciation) {
            PronunciationTrainerSetupView()
        }
    }
}

#Preview {
    NavigationStack {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView {
                SpeakingView()
                    .padding(.horizontal, Layout.homeHorizontalPadding)
                    .padding(.top, Layout.homeTopSpacing)
            }
        }
    }
}
