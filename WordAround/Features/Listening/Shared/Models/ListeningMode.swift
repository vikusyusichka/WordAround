import SwiftUI

struct ListeningMode: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let accentColor: Color
    let blobColor: Color

    static var allModes: [ListeningMode] {
        [
            ListeningMode(
                id: "listen-from-text",
                title: L10n.string("listeningModeTextTitle"),
                subtitle: L10n.string("listeningModeTextSubtitle"),
                systemImage: "headphones",
                accentColor: ListeningTheme.listenFromTextAccent,
                blobColor: ListeningTheme.listenFromTextBlob
            ),
            ListeningMode(
                id: "import-audio",
                title: L10n.string("listeningModeAudioTitle"),
                subtitle: L10n.string("listeningModeAudioSubtitle"),
                systemImage: "waveform.badge.plus",
                accentColor: ListeningTheme.importAudioAccent,
                blobColor: ListeningTheme.importAudioBlob
            ),
            ListeningMode(
                id: "import-video",
                title: L10n.string("listeningModeVideoTitle"),
                subtitle: L10n.string("listeningModeVideoSubtitle"),
                systemImage: "film.stack",
                accentColor: ListeningTheme.importVideoAccent,
                blobColor: ListeningTheme.importVideoBlob
            ),
            ListeningMode(
                id: "saved-practice",
                title: L10n.string("listeningModeSavedTitle"),
                subtitle: L10n.string("listeningModeSavedSubtitle"),
                systemImage: "bookmark.fill",
                accentColor: ListeningTheme.savedPracticeAccent,
                blobColor: ListeningTheme.savedPracticeBlob
            )
        ]
    }

    var chipTitle: String { title }
}
