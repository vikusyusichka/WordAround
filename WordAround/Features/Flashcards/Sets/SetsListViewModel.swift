import SwiftUI
import Combine
import FirebaseAuth

@MainActor
final class SetsListViewModel: ObservableObject {
    @Published var userSets: [HomeSetPreviewItem] = []
    @Published var continueLearningSet: HomeSetPreviewItem?
    @Published var isLoadingSets = false
    @Published var errorMessage: String?

    private let setService: FlashcardSetService

    init(setService: FlashcardSetService? = nil) {
        self.setService = setService ?? FlashcardSetService()

        Task {
            await loadUserSets()
        }
    }

    func refresh() async {
        await loadUserSets()
    }

    func loadUserSets() async {
        guard let user = Auth.auth().currentUser else {
            userSets = []
            continueLearningSet = nil
            errorMessage = L10n.string("commonNotSignedIn")
            return
        }

        isLoadingSets = true
        errorMessage = nil

        do {
            let sets = try await setService.fetchSets(for: user.uid)
            let previewItems = sets.map { makePreviewItem(from: $0) }

            userSets = previewItems
            continueLearningSet = mostRelevantSet(from: sets)
            isLoadingSets = false
        } catch {
            isLoadingSets = false
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func deleteSet(_ item: HomeSetPreviewItem) async -> Bool {
        guard let user = Auth.auth().currentUser else {
            errorMessage = L10n.string("commonNotSignedIn")
            await refresh()
            return false
        }

        guard let sourceSet = item.sourceSet else {
            errorMessage = L10n.string("flashcardSetDataMissing")
            await refresh()
            return false
        }

        do {
            try await setService.deleteSet(id: sourceSet.id, ownerUID: user.uid)

            userSets.removeAll { $0.sourceSet?.id == sourceSet.id }

            if continueLearningSet?.sourceSet?.id == sourceSet.id {
                continueLearningSet = userSets.first
            }

            return true
        } catch {
            errorMessage = error.localizedDescription
            await refresh()
            return false
        }
    }

    func moveSets(from source: IndexSet, to destination: Int) {
        userSets.move(fromOffsets: source, toOffset: destination)

        if let firstSet = userSets.first {
            continueLearningSet = firstSet
        }
    }

    @discardableResult
    func updateSet(_ item: HomeSetPreviewItem, title: String, description: String) async -> Bool {
        guard let sourceSet = item.sourceSet else {
            errorMessage = L10n.string("flashcardSetDataMissing")
            return false
        }

        var updatedSet = sourceSet
        updatedSet.title = title
        updatedSet.description = description
        updatedSet.updatedAt = Date()

        do {
            try await setService.updateSet(updatedSet)
            applyUpdatedSet(updatedSet)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func applyUpdatedSet(_ updatedSet: FlashcardSet) {
        let updatedItem = makePreviewItem(from: updatedSet)

        if let index = userSets.firstIndex(where: { $0.sourceSet?.id == updatedSet.id }) {
            userSets[index] = updatedItem
        }

        if continueLearningSet?.sourceSet?.id == updatedSet.id {
            continueLearningSet = updatedItem
        }
    }

    private func mostRelevantSet(from sets: [FlashcardSet]) -> HomeSetPreviewItem? {
        let mostRecent = sets.max { lhs, rhs in
            (lhs.updatedAt, lhs.createdAt) < (rhs.updatedAt, rhs.createdAt)
        }
        return mostRecent.map { makePreviewItem(from: $0) }
    }

    private func makePreviewItem(from set: FlashcardSet) -> HomeSetPreviewItem {
        let theme = CreateSetTheme.theme(forHex: set.colorHex)

        return HomeSetPreviewItem(
            sourceSet: set,
            title: set.title,
            subtitle: set.description.isEmpty ? L10n.cardsCount(set.cards.count) : set.description,
            iconSystemName: iconName(from: set.icon),
            currentValue: 0,
            totalValue: max(set.cards.count, 1),
            unit: L10n.string("commonCards"),
            progress: 0,
            accentColor: theme.accent,
            backgroundColor: theme.previewBackground,
            progressBackgroundColor: theme.softAccent,
            titleColor: theme.titleColor,
            valueColor: theme.titleColor,
            subtitleColor: theme.mutedTextColor,
            iconBackground: theme.softAccent,
            blobColor: theme.softAccent
        )
    }

    private func iconName(from icon: SetIconType) -> String {
        switch icon {
        case .systemName(let name):
            return name
        default:
            return "rectangle.stack.fill"
        }
    }
}
