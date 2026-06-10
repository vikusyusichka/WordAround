import SwiftUI

enum ReadingMyTextsMode {
    static let id = ReadingMyTextsTheme.modeID

    static var homeCard: ReadingMode {
        ReadingMode(
            id: id,
            title: L10n.string("readingModeMyTextsTitle"),
            subtitle: L10n.string("readingModeMyTextsSubtitle"),
            systemImage: "doc.text.fill",
            accentColor: ReadingMyTextsTheme.accent,
            blobColor: ReadingMyTextsTheme.blobColor
        )
    }

    static var firestoreMode: ReadingMode { .myTexts }
}

extension ReadingMode {
    static let myTextsID = ReadingMyTextsMode.id

    static var myTexts: ReadingMode {
        ReadingMode(
            id: myTextsID,
            title: L10n.string("readingModeMyTextsTitle"),
            subtitle: L10n.string("readingMyTextsSubtitle"),
            systemImage: "doc.text.fill",
            accentColor: ReadingMyTextsTheme.accent,
            blobColor: ReadingMyTextsTheme.blobColor
        )
    }
}
