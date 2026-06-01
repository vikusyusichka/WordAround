import Foundation

struct SpeedReadingConfiguration: Equatable, Hashable, Codable {

    enum LengthBand: String, Codable, CaseIterable {
        case two, five, ten

        var minutes: Int {
            switch self {
            case .two: return 2
            case .five: return 5
            case .ten:  return 10
            }
        }

        var wordCountRange: ClosedRange<Int> {
            switch self {
            case .two:  return 250...450
            case .five: return 600...1000
            case .ten:  return 1200...1800
            }
        }

        var questionTarget: Int {
            switch self {
            case .two:  return 3
            case .five: return 5
            case .ten:  return 8
            }
        }

        var title: String {
            switch self {
            case .two: return "2 min"
            case .five: return "5 min"
            case .ten: return "10 min"
            }
        }

        static func from(title: String) -> LengthBand {
            ReadingSpeedLength.allCases.first { $0.title == title }
                .map(LengthBand.from(speedLength:)) ?? .five
        }

        static func from(speedLength: ReadingSpeedLength) -> LengthBand {
            switch speedLength {
            case .two:  return .two
            case .five: return .five
            case .ten:  return .ten
            }
        }
    }

    let language: GrammarLanguage
    let target: ReadingSpeedTarget
    let timer: ReadingTimerStyle
    let length: LengthBand

    var wpmTarget: Int { target.wpmTarget }
    var wordsPerChunk: Int { target.wordsPerChunk }

    var chunkSeconds: Int {
        guard timer.enforcesPace else { return 0 }
        let baseSeconds = Double(target.wordsPerChunk) / Double(target.wpmTarget) * 60.0
        return max(6, Int((baseSeconds * timer.perChunkMultiplier).rounded()))
    }

    var targetWordCount: Int {
        let range = length.wordCountRange
        return (range.lowerBound + range.upperBound) / 2
    }

    var summaryChips: [String] {
        [target.title, timer.title, length.title, "\(wpmTarget) WPM"]
    }

    // MARK: - From / to setup

    init(
        language: GrammarLanguage = .english,
        target: ReadingSpeedTarget = .balanced,
        timer: ReadingTimerStyle = .soft,
        length: LengthBand = .five
    ) {
        self.language = language
        self.target = target
        self.timer = timer
        self.length = length
    }

    init(from setup: ReadingSessionSetup) {
        let target = ReadingSpeedTarget.from(title: setup.selection("target"))
        let timer = ReadingTimerStyle.allCases.first { $0.title == setup.selection("timer") } ?? .soft
        let length = LengthBand.from(title: setup.selection("length"))
        self.init(
            language: setup.language,
            target: target,
            timer: timer,
            length: length
        )
    }

    // MARK: - Library item bridge

    var asSelections: [String: String] {
        [
            "target": target.title,
            "timer":  timer.title,
            "length": length.title
        ]
    }

    static func from(selections: [String: String], language: GrammarLanguage) -> SpeedReadingConfiguration {
        let target = ReadingSpeedTarget.from(title: selections["target"] ?? "")
        let timer = ReadingTimerStyle.allCases.first { $0.title == selections["timer"] } ?? .soft
        let length = LengthBand.from(title: selections["length"] ?? "")
        return SpeedReadingConfiguration(
            language: language,
            target: target,
            timer: timer,
            length: length
        )
    }

    // MARK: - Display

    var generatedTitle: String {
        "Speed \(length.title) • \(target.title)"
    }
}

// MARK: - Codable conformance for the setup enums

extension ReadingSpeedTarget: Codable {
    public init(from decoder: Decoder) throws {
        let title = try decoder.singleValueContainer().decode(String.self)
        self = Self.from(title: title)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(title)
    }
}

extension ReadingSpeedTarget: Hashable {}

extension ReadingTimerStyle: Codable {
    public init(from decoder: Decoder) throws {
        let title = try decoder.singleValueContainer().decode(String.self)
        self = Self.allCases.first { $0.title == title } ?? .soft
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(title)
    }
}

extension ReadingTimerStyle: Hashable {}
