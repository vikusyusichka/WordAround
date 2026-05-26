import Foundation

enum SetIconType: Codable, Equatable {
    case systemName(String)
    case emoji(String)
    case customImageURL(String)

    enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    enum IconType: String, Codable {
        case systemName
        case emoji
        case customImageURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(IconType.self, forKey: .type)
        let value = try container.decode(String.self, forKey: .value)

        switch type {
        case .systemName:
            self = .systemName(value)
        case .emoji:
            self = .emoji(value)
        case .customImageURL:
            self = .customImageURL(value)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .systemName(let value):
            try container.encode(IconType.systemName, forKey: .type)
            try container.encode(value, forKey: .value)

        case .emoji(let value):
            try container.encode(IconType.emoji, forKey: .type)
            try container.encode(value, forKey: .value)

        case .customImageURL(let value):
            try container.encode(IconType.customImageURL, forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }
}
