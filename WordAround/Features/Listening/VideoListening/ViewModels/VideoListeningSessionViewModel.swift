import Combine
import Foundation

@MainActor
final class VideoListeningSessionViewModel: ObservableObject {
    let setup: ListeningVideoSetup
    let video: ListeningVideoItem
    let questions: [ListeningQuestion]

    @Published var selectedAnswers: [String: Int] = [:]
    @Published var showResult = false

    init(
        setup: ListeningVideoSetup,
        video: ListeningVideoItem,
        questions: [ListeningQuestion] = ListeningPlaceholderData.sampleQuestions
    ) {
        self.setup = setup
        self.video = video
        self.questions = questions
    }

    var metadataLine: String {
        "\(setup.language.title) • \(setup.level.title) • \(video.durationText)"
    }

    func selectAnswer(questionID: String, optionIndex: Int) {
        selectedAnswers[questionID] = optionIndex
    }
}
