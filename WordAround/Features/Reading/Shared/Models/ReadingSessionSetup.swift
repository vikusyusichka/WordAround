import SwiftUI

struct ReadingSessionSetup {
    let modeID: String
    let language: GrammarLanguage
    let selections: [String: String]
    let toggles: [String: Bool]
    let accent: Color
    let accentDark: Color
    let title: String
    let subtitle: String

    func selection(_ key: String, default defaultValue: String = "") -> String {
        selections[key] ?? defaultValue
    }

    func toggle(_ key: String, default defaultValue: Bool = false) -> Bool {
        toggles[key] ?? defaultValue
    }
}

extension ReadingSetupViewModel {
    func makeSessionSetup() -> ReadingSessionSetup {
        ReadingSessionSetup(
            modeID: config.modeID,
            language: selectedLanguage,
            selections: selections,
            toggles: toggles,
            accent: config.accent,
            accentDark: config.accentDark,
            title: config.title,
            subtitle: config.subtitle
        )
    }
}
