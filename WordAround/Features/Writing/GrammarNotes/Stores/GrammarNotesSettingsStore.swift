import Foundation
import Combine

// MARK: - UserDefaults convenience helpers (file-private)

private let _ud = UserDefaults.standard

private func boolSetting(_ key: String, default def: Bool) -> Bool {
    _ud.object(forKey: key) != nil ? _ud.bool(forKey: key) : def
}

// MARK: - Store

/// Persists all Grammar Notes user preferences.
/// Views observe it via `@StateObject`; ViewModels read it at save-time.
/// Uses @Published + UserDefaults so ObservableObject conformance works
/// correctly in Swift 6 (unlike @AppStorage inside a class).
@MainActor
final class GrammarNotesSettingsStore: ObservableObject {

    // MARK: - Quick capture

    @Published var opensEditorAfterQuickSave: Bool = boolSetting("grammarNotes.opensEditorAfterQuickSave", default: true) {
        didSet { _ud.set(opensEditorAfterQuickSave, forKey: "grammarNotes.opensEditorAfterQuickSave") }
    }

    @Published var allowQuickQuizzes: Bool = boolSetting("grammarNotes.allowQuickQuizzes", default: true) {
        didSet { _ud.set(allowQuickQuizzes, forKey: "grammarNotes.allowQuickQuizzes") }
    }

    // MARK: - Mistake notes

    @Published var includeOriginalSentence: Bool = boolSetting("grammarNotes.includeOriginalSentence", default: true) {
        didSet { _ud.set(includeOriginalSentence, forKey: "grammarNotes.includeOriginalSentence") }
    }

    @Published var includeCorrectedSentence: Bool = boolSetting("grammarNotes.includeCorrectedSentence", default: true) {
        didSet { _ud.set(includeCorrectedSentence, forKey: "grammarNotes.includeCorrectedSentence") }
    }

    @Published var createMistakeNotesWithExplanation: Bool = boolSetting("grammarNotes.createMistakeNotesWithExplanation", default: true) {
        didSet { _ud.set(createMistakeNotesWithExplanation, forKey: "grammarNotes.createMistakeNotesWithExplanation") }
    }

    @Published var groupMistakesByTopic: Bool = boolSetting("grammarNotes.groupMistakesByTopic", default: false) {
        didSet { _ud.set(groupMistakesByTopic, forKey: "grammarNotes.groupMistakesByTopic") }
    }

    @Published var askBeforeSavingMistakes: Bool = boolSetting("grammarNotes.askBeforeSavingMistakes", default: false) {
        didSet { _ud.set(askBeforeSavingMistakes, forKey: "grammarNotes.askBeforeSavingMistakes") }
    }

    @Published var saveGrammarMistakesAutomatically: Bool = boolSetting("grammarNotes.saveGrammarMistakesAutomatically", default: false) {
        didSet { _ud.set(saveGrammarMistakesAutomatically, forKey: "grammarNotes.saveGrammarMistakesAutomatically") }
    }

    // MARK: - Appearance

    @Published var showsMistakeHighlights: Bool = boolSetting("grammarNotes.showsMistakeHighlights", default: true) {
        didSet { _ud.set(showsMistakeHighlights, forKey: "grammarNotes.showsMistakeHighlights") }
    }

    @Published var groupsPinnedNotesFirst: Bool = boolSetting("grammarNotes.groupsPinnedNotesFirst", default: true) {
        didSet { _ud.set(groupsPinnedNotesFirst, forKey: "grammarNotes.groupsPinnedNotesFirst") }
    }

    @Published var usesCompactCards: Bool = boolSetting("grammarNotes.usesCompactCards", default: false) {
        didSet { _ud.set(usesCompactCards, forKey: "grammarNotes.usesCompactCards") }
    }

    // MARK: - Learning helpers

    @Published var showsHelperTips: Bool = boolSetting("grammarNotes.showsHelperTips", default: true) {
        didSet { _ud.set(showsHelperTips, forKey: "grammarNotes.showsHelperTips") }
    }

    @Published var enableReviewReminders: Bool = boolSetting("grammarNotes.enableReviewReminders", default: false) {
        didSet { _ud.set(enableReviewReminders, forKey: "grammarNotes.enableReviewReminders") }
    }
}
