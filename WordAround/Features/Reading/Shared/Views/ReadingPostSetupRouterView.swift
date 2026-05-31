import SwiftUI

/// Routes from the shared setup screen into the first post-setup screen for each mode.
struct ReadingPostSetupRouterView: View {
    let setup: ReadingSessionSetup
    var onExitToSetup: () -> Void
    var onExitToReading: () -> Void

    var body: some View {
        switch setup.modeID {
        case "generated-reading":
            GeneratedReadingLoadingView(setup: setup, onExitToSetup: onExitToSetup, onExitToReading: onExitToReading)
        case "my-texts":
            MyTextsEditorView(setup: setup, onExitToSetup: onExitToSetup, onExitToReading: onExitToReading)
        case "reading-from-sets":
            ReadingFromSetsPreviewView(setup: setup, onExitToSetup: onExitToSetup, onExitToReading: onExitToReading)
        case "story-mode":
            StoryModeSessionView(setup: setup, onExitToSetup: onExitToSetup, onExitToReading: onExitToReading)
        case "speed-reading":
            SpeedReadingCountdownView(setup: setup, onExitToSetup: onExitToSetup, onExitToReading: onExitToReading)
        case "interactive-reading":
            InteractiveReadingSessionView(setup: setup, onExitToSetup: onExitToSetup, onExitToReading: onExitToReading)
        default:
            Text("Unknown reading mode")
                .onAppear { onExitToSetup() }
        }
    }
}
