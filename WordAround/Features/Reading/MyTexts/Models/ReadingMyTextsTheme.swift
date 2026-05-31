import SwiftUI

enum ReadingMyTextsTheme {
    static let modeID = "my-texts"

    static let accent = Color(red: 0.13, green: 0.66, blue: 0.74)
    static let accentDark = Color(red: 0.06, green: 0.42, blue: 0.50)
    static let blobColor = Color(red: 0.80, green: 0.94, blue: 0.96)

    static func sessionAccent(for text: ReadingUserText) -> Color {
        text.sourceType == .flashcardSet ? ReadingSetupConfig.readingFromSets.accent : accent
    }

    static func sessionAccentDark(for text: ReadingUserText) -> Color {
        text.sourceType == .flashcardSet ? ReadingSetupConfig.readingFromSets.accentDark : accentDark
    }
}
