import Combine
import Foundation

@MainActor
final class VideoListeningResultsViewModel: ObservableObject {
    let setup: ListeningVideoSetup
    let videos: [ListeningVideoItem]

    @Published var selectedVideo: ListeningVideoItem?
    @Published var showSession = false

    init(
        setup: ListeningVideoSetup,
        videos: [ListeningVideoItem] = VideoListeningPreviewData.sampleVideos
    ) {
        self.setup = setup
        self.videos = videos
    }

    func selectVideo(_ video: ListeningVideoItem) {
        selectedVideo = video
        showSession = true
    }
}
