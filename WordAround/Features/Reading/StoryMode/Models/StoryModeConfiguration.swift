import Foundation

struct StoryModeConfiguration: Equatable, Codable, Hashable {
    let language: GrammarLanguage
    let storyType: ReadingStoryType
    let storyLength: ReadingStoryLength
    let difficultyTitle: String

    var summaryText: String {
        "\(language.title) • \(storyType.title) • \(difficultyTitle) • \(storyLength.title)"
    }

    var generatedTitle: String {
        "\(storyType.title) — \(storyLength.title)"
    }

    init(from setup: ReadingSessionSetup) {
        self.language = setup.language
        self.storyType = ReadingStoryType.allCases.first {
            $0.title == setup.selection("type")
        } ?? .adventure
        self.storyLength = ReadingStoryLength.allCases.first {
            $0.title == setup.selection("length")
        } ?? .shortStory
        self.difficultyTitle = setup.selection("difficulty", default: ReadingLevel.b1.title)
    }

    init(
        language: GrammarLanguage = .english,
        storyType: ReadingStoryType = .adventure,
        storyLength: ReadingStoryLength = .shortStory,
        difficultyTitle: String = ReadingLevel.b1.title
    ) {
        self.language = language
        self.storyType = storyType
        self.storyLength = storyLength
        self.difficultyTitle = difficultyTitle
    }

    var asSelections: [String: String] {
        [
            "type":       storyType.title,
            "length":     storyLength.title,
            "difficulty": difficultyTitle,
            "language":   language.rawValue
        ]
    }

    static func from(selections: [String: String]) -> StoryModeConfiguration {
        let lang = GrammarLanguage(rawValue: selections["language"] ?? "") ?? .english
        let type_ = ReadingStoryType.allCases.first { $0.title == selections["type"] } ?? .adventure
        let length = ReadingStoryLength.allCases.first { $0.title == selections["length"] } ?? .shortStory
        let diff = selections["difficulty"] ?? ReadingLevel.b1.title
        return StoryModeConfiguration(language: lang, storyType: type_, storyLength: length, difficultyTitle: diff)
    }
}

extension ReadingStoryType: Codable {
    public init(from decoder: Decoder) throws {
        let title = try decoder.singleValueContainer().decode(String.self)
        self = Self.allCases.first { $0.title == title } ?? .adventure
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(title)
    }
}

extension ReadingStoryType: Hashable {}

extension ReadingStoryLength: Codable {
    public init(from decoder: Decoder) throws {
        let title = try decoder.singleValueContainer().decode(String.self)
        self = Self.allCases.first { $0.title == title } ?? .shortStory
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(title)
    }
}

extension ReadingStoryLength: Hashable {}
