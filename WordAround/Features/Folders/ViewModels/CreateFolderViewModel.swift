import SwiftUI
import FirebaseAuth
import Combine

@MainActor
final class CreateFolderViewModel: ObservableObject {
    @Published var title = ""
    @Published var description = ""
    @Published var selectedColor: SetColor = .blue
    @Published var theme: CreateSetTheme = .blue

    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var didCreateFolder = false

    private let folderService = FolderService()

    let availableColors = SetColor.allCases

    func selectColor(_ color: SetColor) {
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedColor = color
            theme = CreateSetTheme.theme(for: color)
        }
    }

    func createFolder() async {
        guard !isSaving else { return }

        guard let user = Auth.auth().currentUser else {
            errorMessage = L10n.string("commonNotSignedIn")
            return
        }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanTitle.isEmpty else {
            errorMessage = L10n.string("folderNameRequired")
            return
        }

        guard cleanTitle.count <= 80 else {
            errorMessage = L10n.string("folderNameTooLong")
            return
        }

        guard cleanDescription.count <= 120 else {
            errorMessage = L10n.string("folderDescTooLong")
            return
        }

        isSaving = true
        errorMessage = nil

        do {
            let folder = Folder(
                id: UUID().uuidString,
                ownerUID: user.uid,
                title: cleanTitle,
                description: cleanDescription,
                colorHex: selectedColor.hex,
                createdAt: Date(),
                updatedAt: Date()
            )

            try await folderService.createFolder(folder)

            isSaving = false
            didCreateFolder = true
        } catch {
            isSaving = false
            errorMessage = error.localizedDescription
        }
    }
}
