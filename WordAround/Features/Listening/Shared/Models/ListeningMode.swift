import SwiftUI

struct ListeningMode: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let accentColor: Color
    let blobColor: Color

    static let allModes: [ListeningMode] = [
        ListeningMode(
            id: "listen-from-text",
            title: "Listen from Text",
            subtitle: "Paste text, listen to it, and check your understanding.",
            systemImage: "headphones",
            accentColor: ListeningTheme.listenFromTextAccent,
            blobColor: ListeningTheme.listenFromTextBlob
        ),
        ListeningMode(
            id: "import-audio",
            title: "Import Audio",
            subtitle: "Upload your own audio and turn it into listening practice.",
            systemImage: "waveform.badge.plus",
            accentColor: ListeningTheme.importAudioAccent,
            blobColor: ListeningTheme.importAudioBlob
        ),
        ListeningMode(
            id: "import-video",
            title: "Import Video",
            subtitle: "Upload a video, get subtitles, and practice with questions.",
            systemImage: "film.stack",
            accentColor: ListeningTheme.importVideoAccent,
            blobColor: ListeningTheme.importVideoBlob
        ),
        ListeningMode(
            id: "saved-practice",
            title: "Saved Practice",
            subtitle: "Continue previous sessions and review mistakes.",
            systemImage: "bookmark.fill",
            accentColor: ListeningTheme.savedPracticeAccent,
            blobColor: ListeningTheme.savedPracticeBlob
        )
    ]

    var chipTitle: String { title }
}
