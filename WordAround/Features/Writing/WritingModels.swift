import SwiftUI

struct WritingMenuItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
    let gradient: [Color]
    let action: WritingMenuAction
}

enum WritingMenuAction {
    case writeFromSets
    case essays
    case grammarNotes
}

struct WritingGoal {
    let title: String
    let currentWords: Int
    let targetWords: Int

    var remainingWords: Int { max(targetWords - currentWords, 0) }
    var progress: CGFloat {
        guard targetWords > 0 else { return 0 }
        return min(CGFloat(currentWords) / CGFloat(targetWords), 1)
    }
}

struct WriteWordsExercise: Identifiable {
    let id: String
    let sourceLanguageWord: String
    let hint: String
    let targetLanguageTitle: String
    let answer: String
}
