import Foundation
import FirebaseAuth
import Combine

@MainActor
final class FolderDetailViewModel: ObservableObject {
    @Published var sets: [HomeSetPreviewItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let folder: Folder

    private let setService = FlashcardSetService()

    init(folder: Folder) {
        self.folder = folder
    }

    func loadSets() async {
        guard let user = Auth.auth().currentUser else {
            errorMessage = "User is not signed in."
            sets = []
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            var fetchedSets = try await setService.fetchSets(
                folderID: folder.id,
                ownerUID: user.uid
            )

            if fetchedSets.isEmpty {
                fetchedSets = try await setService.fetchSets(
                    folderName: folder.title,
                    ownerUID: user.uid
                )
            }

            sets = fetchedSets.map { HomeSetPreviewMapper.map($0) }
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
}
