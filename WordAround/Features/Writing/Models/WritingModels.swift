import SwiftUI

struct WritingMenuItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let systemImage: String
    let accentColor: Color
    let blobColor: Color
    let action: WritingMenuAction
}

enum WritingMenuAction {
    case writeFromSets
    case essays
}

struct WriteWordsExercise: Identifiable {
    let id: String
    let sourceLanguageWord: String
    let hint: String
    let targetLanguageTitle: String
    let answer: String
}
