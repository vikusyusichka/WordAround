import SwiftUI

struct ReadingPostSetupRouterView: View {
    let setup: ReadingSessionSetup
    var onExitToSetup: () -> Void
    var onExitToReading: () -> Void

    var body: some View {
        switch setup.modeID {
        case "my-texts":
            ReadingMyTextsView()
        case "story-mode":
            StorySessionView(setup: setup, onExitToSetup: onExitToSetup, onExitToReading: onExitToReading)
        case "speed-reading":
            SpeedReadingCountdownView(setup: setup, onExitToSetup: onExitToSetup, onExitToReading: onExitToReading)

        case "generated-reading":
            ReadingMyTextsView()
        case "interactive-reading":
            StorySessionView(setup: setup, onExitToSetup: onExitToSetup, onExitToReading: onExitToReading)
        case "reading-from-sets":
            unknownModeFallback(
                message: "Open Reading From Sets from the library to choose a set."
            )

        default:
            unknownModeFallback(message: "This reading mode isn't available.")
        }
    }

    private func unknownModeFallback(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 38, weight: .bold))
                .foregroundColor(.orange)
            Text(message)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button("Back to Reading", action: onExitToReading)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(setup.accentDark)
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(setup.accent.opacity(0.12))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}
