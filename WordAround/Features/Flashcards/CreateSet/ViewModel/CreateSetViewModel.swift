import SwiftUI
import Combine
import FirebaseAuth
import PhotosUI
import UIKit

@MainActor
final class CreateSetViewModel: ObservableObject {
    @Published var draft = CreateFlashcardSetDraft()
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var didCreateSet = false
    @Published var theme: CreateSetTheme = .red
    @Published var folders: [Folder] = []
    @Published var isLoadingFolders = false

    private let createSetUseCase: CreateSetSavingUseCase
    private let folderService: FolderService

    let availableColors: [SetColor] = SetColor.allCases

    let previewIcons: [String] = [
        "rectangle.stack.fill",
        "book.closed.fill",
        "graduationcap.fill",
        "brain.head.profile",
        "globe.europe.africa.fill",
        "star.fill",
        "heart.fill",
        "bolt.fill",
        "pencil.and.outline",
        "text.book.closed.fill"
    ]

    init(
        createSetUseCase: CreateSetSavingUseCase = CreateSetSavingUseCase(),
        folderService: FolderService = FolderService()
    ) {
        self.createSetUseCase = createSetUseCase
        self.folderService = folderService
    }

    func addCard() {
        draft.cards.append(CreateFlashcardDraft())
    }

    func selectColor(_ color: SetColor) {
        withAnimation(.easeInOut(duration: 0.25)) {
            draft.selectedColor = color
            theme = CreateSetTheme.theme(for: color)
        }
    }

    func selectIcon(_ icon: String) {
        draft.selectedIcon = icon
    }

    func setImage(for cardID: UUID, from item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data),
                  let index = draft.cards.firstIndex(where: { $0.id == cardID }) else {
                errorMessage = "Could not load selected image."
                return
            }

            draft.cards[index].selectedImage = image
            draft.cards[index].imageURL = nil
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createSet() async {
        guard !isSaving else { return }

        let resolvedIcon = createSetUseCase.resolvedIcon(for: draft)
        draft.selectedIcon = resolvedIcon

        isSaving = true
        errorMessage = nil

        do {
            try await createSetUseCase.createSet(from: draft)
            isSaving = false
            didCreateSet = true
        } catch {
            isSaving = false
            errorMessage = error.localizedDescription
        }
    }

    func loadFolders() async {
        guard let user = Auth.auth().currentUser else {
            folders = []
            return
        }

        isLoadingFolders = true

        do {
            folders = try await folderService.fetchFolders(for: user.uid)
            isLoadingFolders = false
        } catch {
            isLoadingFolders = false
            errorMessage = error.localizedDescription
        }
    }

    func selectFolder(_ folder: Folder?) {
        draft.folderID = folder?.id
        draft.folderName = folder?.title
    }
}
