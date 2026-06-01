import SwiftUI
import Combine
import FirebaseAuth

@MainActor
final class SpeedReadingSetupViewModel: ObservableObject {

    @Published private(set) var isCreating = false
    @Published var errorMessage: String?

    private let storage: ReadingStorageServicing
    private let currentUserId: () -> String?

    init(
        storage: ReadingStorageServicing = ReadingStorageService(),
        currentUserId: @escaping () -> String? = { Auth.auth().currentUser?.uid }
    ) {
        self.storage = storage
        self.currentUserId = currentUserId
    }

    func configuration(from setup: ReadingSessionSetup) -> SpeedReadingConfiguration {
        SpeedReadingConfiguration(from: setup)
    }

    func createSession(from setup: ReadingSessionSetup) async -> SpeedReadingSession? {
        guard let userId = currentUserId() else { return nil }
        let configuration = configuration(from: setup)
        return SpeedReadingSession(userId: userId, configuration: configuration)
    }
}
