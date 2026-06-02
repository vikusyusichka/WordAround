import Foundation
import FirebaseAuth

enum ListeningSetSavingError: LocalizedError {
    case notSignedIn
    case setNotFound

    var errorDescription: String? {
        switch self {
        case .notSignedIn: return "Please sign in to save words to a set."
        case .setNotFound: return "That set could not be found."
        }
    }
}

protocol ListeningSetSavingServicing {
    func fetchSets() async throws -> [FlashcardSet]
    @discardableResult
    func addCard(_ card: Flashcard, toSetID setID: String) async throws -> FlashcardSet
    func createSet(
        title: String,
        description: String,
        color: SetColor,
        firstCard: Flashcard
    ) async throws -> FlashcardSet
}

struct ListeningSetSavingService: ListeningSetSavingServicing {
    private let setService: FlashcardSetService

    init(setService: FlashcardSetService = FlashcardSetService()) {
        self.setService = setService
    }

    private func currentUser() throws -> User {
        guard let user = Auth.auth().currentUser else { throw ListeningSetSavingError.notSignedIn }
        return user
    }

    func fetchSets() async throws -> [FlashcardSet] {
        let user = try currentUser()
        return try await setService.fetchSets(for: user.uid)
    }

    @discardableResult
    func addCard(_ card: Flashcard, toSetID setID: String) async throws -> FlashcardSet {
        let user = try currentUser()
        let sets = try await setService.fetchSets(for: user.uid)
        guard var set = sets.first(where: { $0.id == setID }) else {
            throw ListeningSetSavingError.setNotFound
        }
        set.cards.append(card)
        set.updatedAt = Date()
        try await setService.createSet(set)
        return set
    }

    func createSet(
        title: String,
        description: String,
        color: SetColor,
        firstCard: Flashcard
    ) async throws -> FlashcardSet {
        let user = try currentUser()
        let now = Date()
        let set = FlashcardSet(
            id: UUID().uuidString,
            ownerUID: user.uid,
            ownerEmail: user.email ?? "",
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            privacy: FlashcardSetPrivacy.privateSet.rawValue,
            folderID: nil,
            folderName: nil,
            colorHex: color.hex,
            icon: .systemName("film.stack"),
            cards: [firstCard],
            createdAt: now,
            updatedAt: now
        )
        try await setService.createSet(set)
        return set
    }
}

extension Flashcard {
    static func fromListening(_ result: ListeningTranslationResult, videoTitle: String?) -> Flashcard {
        var example = result.contextSentence ?? ""
        if example.isEmpty, let videoTitle { example = "From: \(videoTitle)" }
        return Flashcard(
            id: UUID().uuidString,
            word: result.originalText,
            translation: result.translatedText,
            example: example,
            imageURL: nil
        )
    }
}

final class MockListeningSetSavingService: ListeningSetSavingServicing, @unchecked Sendable {
    private(set) var sets: [FlashcardSet]
    init(sets: [FlashcardSet] = []) { self.sets = sets }

    func fetchSets() async throws -> [FlashcardSet] { sets }

    @discardableResult
    func addCard(_ card: Flashcard, toSetID setID: String) async throws -> FlashcardSet {
        guard let idx = sets.firstIndex(where: { $0.id == setID }) else {
            throw ListeningSetSavingError.setNotFound
        }
        sets[idx].cards.append(card)
        return sets[idx]
    }

    func createSet(title: String, description: String, color: SetColor, firstCard: Flashcard) async throws -> FlashcardSet {
        let set = FlashcardSet(
            id: UUID().uuidString, ownerUID: "preview", ownerEmail: "",
            title: title, description: description, privacy: "Private",
            folderID: nil, folderName: nil, colorHex: color.hex,
            icon: .systemName("film.stack"), cards: [firstCard],
            createdAt: Date(), updatedAt: Date()
        )
        sets.insert(set, at: 0)
        return set
    }
}
