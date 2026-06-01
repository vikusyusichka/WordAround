import SwiftUI

enum ReadingMyTextsMode {
    static let id = ReadingMyTextsTheme.modeID

    static var homeCard: ReadingMode {
        ReadingMode(
            id: id,
            title: "My Texts",
            subtitle: "Paste your own text and read it with help.",
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
            title: "My Texts",
            subtitle: "Paste your own text and read it with help.",
            systemImage: "doc.text.fill",
            accentColor: ReadingMyTextsTheme.accent,
            blobColor: ReadingMyTextsTheme.blobColor
        )
    }
}
