import Foundation
import FirebaseAuth
import Combine

@MainActor
final class FolderDetailViewModel: ObservableObject {
    @Published var sets: [HomeSetPreviewItem] = []
    @Published var isLoading = false
    @Published var isSavingFolder = false
    @Published var errorMessage: String?

    @Published private(set) var folder: Folder

    private let setService = FlashcardSetService()
    private let folderService = FolderService()

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

    func updateFolder(title: String, description: String) async -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            errorMessage = "Folder title cannot be empty."
            return false
        }

        isSavingFolder = true
        errorMessage = nil

        var updatedFolder = folder
        updatedFolder.title = trimmedTitle
        updatedFolder.description = trimmedDescription
        updatedFolder.updatedAt = Date()

        do {
            try await folderService.updateFolder(updatedFolder)
            folder = updatedFolder
            isSavingFolder = false
            return true
        } catch {
            isSavingFolder = false
            errorMessage = error.localizedDescription
            return false
        }
    }

    func applyUpdatedSet(_ updatedSet: FlashcardSet) {
        let updatedItem = HomeSetPreviewMapper.map(updatedSet)

        if let index = sets.firstIndex(where: { $0.sourceSet?.id == updatedSet.id }) {
            sets[index] = updatedItem
        }
    }
}
