import Foundation

enum SpeedReadingMetricsService {

    static func wpm(wordsRead: Int, seconds: Int) -> Int {
        guard seconds > 0, wordsRead > 0 else { return 0 }
        let minutes = max(Double(seconds) / 60.0, 1.0 / 60.0)
        return Int((Double(wordsRead) / minutes).rounded())
    }

    static func paceStatus(currentWPM: Int, target: ReadingSpeedTarget) -> String {
        guard currentWPM > 0 else { return "Building pace…" }
        let band = target.wpmRange
        if currentWPM < band.lowerBound - 20 { return "Too slow — speed up" }
        if currentWPM < band.lowerBound      { return "Slightly below target" }
        if currentWPM <= band.upperBound     { return "On target" }
        return "Ahead of target"
    }

    static func timerViolations(
        chunkSeconds: [Int],
        target: SpeedReadingConfiguration
    ) -> Int {
        guard target.timer.penalisesViolations else { return 0 }
        let limit = max(1, target.chunkSeconds)
        return chunkSeconds.filter { $0 > limit }.count
    }

    static func feedback(
        result: SpeedReadingResult,
        configuration: SpeedReadingConfiguration
    ) -> [String] {
        var lines: [String] = []
        let band = configuration.target.wpmRange
        if result.wordsPerMinute < band.lowerBound {
            lines.append("Pace dipped below the \(configuration.target.title) band (\(band.lowerBound)+ WPM). Try shorter glances per chunk.")
        } else if result.wordsPerMinute > band.upperBound {
            lines.append("You moved faster than the \(configuration.target.title) band — comfortable for you. Consider the next tier up.")
        } else {
            lines.append("Pace landed inside the \(configuration.target.title) band. Steady control of speed.")
        }
        if result.comprehensionPercent < 60 {
            lines.append("Comprehension under \(Int(result.comprehensionPercent.rounded()))% — slow the pace a touch and re-test.")
        } else if result.comprehensionPercent >= 90 {
            lines.append("Strong comprehension at this pace. Push the next session to the next speed tier.")
        }
        if configuration.timer.penalisesViolations, result.timerViolations > 0 {
            lines.append("Missed \(result.timerViolations) chunk timer\(result.timerViolations == 1 ? "" : "s") — focus on staying ahead of the bar.")
        }
        if lines.isEmpty {
            lines.append("Solid run — keep the rhythm consistent next session.")
        }
        return lines
    }
}
