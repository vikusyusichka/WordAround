import Foundation

struct SpeakingRecentTopicTitlesStore {

    static let shared = SpeakingRecentTopicTitlesStore()

    static let maxTitlesPerBucket = 10

    private let defaults: UserDefaults
    private let keyPrefix = "speaking.recentTopics."

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func recentTitles(language: GrammarLanguage, level: EssayDifficulty) -> [String] {
        let key = bucketKey(language: language, level: level)
        return defaults.stringArray(forKey: key) ?? []
    }

    func remember(
        title: String,
        language: GrammarLanguage,
        level: EssayDifficulty
    ) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let key = bucketKey(language: language, level: level)
        var titles = defaults.stringArray(forKey: key) ?? []

        titles.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        titles.append(trimmed)
        if titles.count > Self.maxTitlesPerBucket {
            titles.removeFirst(titles.count - Self.maxTitlesPerBucket)
        }
        defaults.set(titles, forKey: key)
    }

    func reset(language: GrammarLanguage, level: EssayDifficulty) {
        defaults.removeObject(forKey: bucketKey(language: language, level: level))
    }

    private func bucketKey(language: GrammarLanguage, level: EssayDifficulty) -> String {
        "\(keyPrefix)\(language.rawValue).\(level.rawValue)"
    }
}
