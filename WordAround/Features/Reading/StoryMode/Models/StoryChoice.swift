import Foundation

struct StoryChoice: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var prompt: String
    var label: String
    var hint: String?
    var iconName: String?

    init(
        id: String = UUID().uuidString,
        prompt: String = "",
        label: String,
        hint: String? = nil,
        iconName: String? = nil
    ) {
        self.id = id
        self.prompt = prompt
        self.label = label
        self.hint = hint
        self.iconName = iconName
    }
}
