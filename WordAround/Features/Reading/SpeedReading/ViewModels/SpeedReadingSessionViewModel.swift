import SwiftUI
import Combine

@MainActor
final class SpeedReadingSessionViewModel: ObservableObject {
    let setup: ReadingSessionSetup
    let chunks = ReadingPlaceholderData.speedChunks

    @Published var countdownValue = 3
    @Published var currentChunkIndex = 0
    @Published var timerText = "04:32"
    @Published var isPaused = false
    @Published var fontScale: CGFloat = 1.0

    init(setup: ReadingSessionSetup) {
        self.setup = setup
    }

    var targetWPM: Int {
        ReadingSpeedTarget.from(title: setup.selection("target", default: "Balanced")).wpmTarget
    }

    var currentWPM: Int { 230 }
    var paceStatus: String { "Slightly below target" }
    var paceLabel: String { setup.selection("target", default: "Balanced pace") }

    var countdownChips: [String] {
        [
            setup.selection("target", default: "Balanced"),
            setup.selection("timer", default: "Soft Timer"),
            setup.selection("length", default: "5 min"),
            "\(targetWPM) WPM target"
        ]
    }

    var readingProgress: Double {
        Double(currentChunkIndex + 1) / Double(chunks.count)
    }

    func startCountdown() {
        countdownValue = 3
    }

    func tickCountdown() {
        if countdownValue > 1 {
            countdownValue -= 1
        }
    }

    func goNextChunk() {
        currentChunkIndex = min(currentChunkIndex + 1, chunks.count - 1)
    }

    func goPreviousChunk() {
        currentChunkIndex = max(currentChunkIndex - 1, 0)
    }

    func togglePause() {
        isPaused.toggle()
    }

    func increaseFont() {
        fontScale = min(fontScale + 0.1, 1.3)
    }

    func decreaseFont() {
        fontScale = max(fontScale - 0.1, 0.8)
    }
}
