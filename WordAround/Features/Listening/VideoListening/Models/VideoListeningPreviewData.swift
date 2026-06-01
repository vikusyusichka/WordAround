import Foundation

enum VideoListeningPreviewData {
    private static let demoVideoIDs = ["aqz-KE-bpKQ", "LXb3EKWsInQ", "eRsGyueVVak"]

    /// YouTube hqdefault thumbnails are always available without an API key.
    private static func ytThumbnail(_ videoID: String) -> String {
        "https://img.youtube.com/vi/\(videoID)/hqdefault.jpg"
    }

    static let sampleVideos: [ListeningVideoItem] = [
        ListeningVideoItem(
            id: demoVideoIDs[0],
            title: "A Day in London — Real English Conversations",
            channel: "English Everyday",
            durationText: "8:24",
            difficultyTitle: "B1",
            hasCaptions: true,
            durationSeconds: 504,
            thumbnailURL: ytThumbnail(demoVideoIDs[0]),
            playableURL: "https://www.youtube.com/watch?v=\(demoVideoIDs[0])",
            sourceURL: "https://www.youtube.com/watch?v=\(demoVideoIDs[0])",
            transcriptText: ListeningPlaceholderData.sampleText
        ),
        ListeningVideoItem(
            id: demoVideoIDs[1],
            title: "Street Food Tour in Barcelona",
            channel: "Travel Talk",
            durationText: "11:02",
            difficultyTitle: "B1",
            hasCaptions: true,
            durationSeconds: 662,
            thumbnailURL: ytThumbnail(demoVideoIDs[1]),
            playableURL: "https://www.youtube.com/watch?v=\(demoVideoIDs[1])",
            sourceURL: "https://www.youtube.com/watch?v=\(demoVideoIDs[1])",
            transcriptText: ListeningPlaceholderData.sampleText
        ),
        ListeningVideoItem(
            id: demoVideoIDs[2],
            title: "Morning Routine Vlog",
            channel: "Daily Life English",
            durationText: "4:15",
            difficultyTitle: "A2",
            hasCaptions: false,
            durationSeconds: 255,
            thumbnailURL: ytThumbnail(demoVideoIDs[2]),
            playableURL: "https://www.youtube.com/watch?v=\(demoVideoIDs[2])",
            sourceURL: "https://www.youtube.com/watch?v=\(demoVideoIDs[2])"
        )
    ]
}
