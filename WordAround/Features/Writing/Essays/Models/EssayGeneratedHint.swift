import Foundation

struct EssayGeneratedHint: Codable, Equatable, Identifiable {
    let id: UUID
    let text: String
    let category: EssayHintCategory

    init(
        id: UUID = UUID(),
        text: String,
        category: EssayHintCategory
    ) {
        self.id = id
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.category = category
    }

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case category
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        let text = try container.decodeIfPresent(String.self, forKey: .text) ?? "Add one clear supporting example."
        let categoryRaw = try container.decodeIfPresent(String.self, forKey: .category) ?? EssayHintCategory.content.rawValue
        let category = EssayHintCategory(rawValue: categoryRaw.lowercased()) ?? .content

        self.init(id: id, text: text, category: category)
    }
}

enum EssayHintCategory: String, Codable, CaseIterable {
    case content
    case grammar
    case vocabulary
    case structure
}
