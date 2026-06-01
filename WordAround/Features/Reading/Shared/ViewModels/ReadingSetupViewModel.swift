import SwiftUI
import Combine

@MainActor
final class ReadingSetupViewModel: ObservableObject {
    let config: ReadingSetupConfig

    @Published var selectedLanguage: GrammarLanguage = .english
    @Published var selections: [String: String] = [:]
    @Published var toggles: [String: Bool] = [:]
    @Published var isStartingSession = false

    init(config: ReadingSetupConfig) {
        self.config = config
        for section in config.sections {
            switch section.kind {
            case .segmented(_, _, let defaultSelection):
                selections[section.id] = defaultSelection
            case .toggles(let specs):
                for spec in specs { toggles[spec.id] = spec.defaultOn }
            case .infoCard:
                break
            }
        }
    }

    var previewChips: [String] {
        config.chips(selections, toggles)
    }

    func start() {
        isStartingSession = true
    }
}
