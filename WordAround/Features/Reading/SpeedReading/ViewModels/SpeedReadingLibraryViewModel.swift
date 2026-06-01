import Foundation
import SwiftUI

struct SpeedReadingLibraryViewModel {
    let items: [ReadingLibraryItem]

    init(items: [ReadingLibraryItem]) {
        self.items = items.filter { $0.modeID == "speed-reading" }
    }

    var totalSessions: Int { items.count }

    var bestWPM: Int {
        sessions.map(\.bestWPM).max() ?? 0
    }

    var averageWPM: Int {
        let wpms = sessions.flatMap { $0.history.map(\.wordsPerMinute) }
        guard !wpms.isEmpty else { return 0 }
        return wpms.reduce(0, +) / wpms.count
    }

    var headline: String? {
        guard totalSessions > 0 else { return nil }
        if averageWPM > 0 {
            return "\(totalSessions) session\(totalSessions == 1 ? "" : "s") • \(averageWPM) avg WPM"
        }
        return "\(totalSessions) session\(totalSessions == 1 ? "" : "s")"
    }

    func cardChips(for item: ReadingLibraryItem) -> [String] {
        let session = SpeedReadingSession.from(item: item)
        var chips: [String] = []
        chips.append(session.configuration.target.title)
        chips.append(session.configuration.timer.title)
        chips.append(session.configuration.length.title)
        if let last = session.lastResult {
            chips.append("\(last.wordsPerMinute) WPM")
        }
        return chips
    }

    private var sessions: [SpeedReadingSession] {
        items.map(SpeedReadingSession.from(item:))
    }
}
