import Foundation

struct ListeningVideoItem: Identifiable, Equatable {
    let id: String
    let title: String
    let channel: String
    let durationText: String
    let difficultyTitle: String
    let hasCaptions: Bool
    let thumbnailSystemImage: String
}
