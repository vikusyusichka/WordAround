import SwiftUI
import Combine

/// Shared UI-only state for every Reading setup screen. Driven entirely by a
/// `ReadingSetupConfig`; holds the current selections/toggles generically.
/// No generation logic.
@MainActor
final class ReadingSetupViewModel: ObservableObject {
    let config: ReadingSetupConfig

    @Published var selectedLanguage: GrammarLanguage = .english
    /// sectionID -> selected option title (for segmented sections).
    @Published var selections: [String: String] = [:]
    /// toggleID -> on/off (for toggle sections).
    @Published var toggles: [String: Bool] = [:]

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

    /// Placeholder. Real reading sessions are out of scope for this UI task.
    func start() {
        #if DEBUG
        print("[ReadingSetup] start \(config.title) language=\(selectedLanguage.title) selections=\(selections) toggles=\(toggles) — UI only, no-op")
        #endif
        // TODO: implement the reading session for \(config.title).
    }
}
