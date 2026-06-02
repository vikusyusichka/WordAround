import Foundation
import Combine

@MainActor
final class ReadingResultViewModel: ObservableObject {
    let result: ReadingResult
    let title: String
    let levelTitle: String
    let focusTitle: String

    init(
        result: ReadingResult,
        title: String,
        levelTitle: String = "",
        focusTitle: String = ""
    ) {
        self.result = result
        self.title = title
        self.levelTitle = levelTitle
        self.focusTitle = focusTitle
    }

    var comprehensionPercent: Int { result.comprehensionPercentInt }

    var formattedTime: String {
        let minutes = result.readingTimeSeconds / 60
        let seconds = result.readingTimeSeconds % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }

    var hasMistakes: Bool { !result.mistakes.isEmpty }

    var showMetadata: Bool { !levelTitle.isEmpty || !focusTitle.isEmpty }
}
