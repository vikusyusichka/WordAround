import SwiftUI

struct SpeakingView: View {
    @State private var openAIConversation = false
    @State private var openFreeSpeaking = false
    @State private var openDescribePicture = false

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
            AIConversationSetupView()
        }
        .navigationDestination(isPresented: $openFreeSpeaking) {
            FreeSpeakingSetupView()
        }
        .navigationDestination(isPresented: $openDescribePicture) {
            DescribePictureSetupView()
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
