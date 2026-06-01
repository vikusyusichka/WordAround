import Foundation

enum VideoListeningPreviewData {
    static let sampleVideos: [ListeningVideoItem] = [
        ListeningVideoItem(
            id: "v1",
            title: "A Day in London — Real English Conversations",
            channel: "English Everyday",
            durationText: "8:24",
            difficultyTitle: "B1",
            hasCaptions: true,
            thumbnailSystemImage: "play.rectangle.fill"
        ),
        ListeningVideoItem(
            id: "v2",
            title: "Street Food Tour in Barcelona",
            channel: "Travel Talk",
            durationText: "11:02",
            difficultyTitle: "B1",
            hasCaptions: true,
            thumbnailSystemImage: "play.rectangle.fill"
        ),
        ListeningVideoItem(
            id: "v3",
            title: "Morning Routine Vlog",
            channel: "Daily Life English",
            durationText: "4:15",
            difficultyTitle: "A2",
            hasCaptions: false,
            thumbnailSystemImage: "play.rectangle.fill"
        )
    ]
}
