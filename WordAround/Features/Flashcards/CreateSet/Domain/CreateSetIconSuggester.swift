import Foundation

struct CreateSetIconSuggester {
    func suggestedIcon(for title: String) -> String {
        let text = title.lowercased()

        if text.contains("spanish") || text.contains("español") || text.contains("language") {
            return "globe.europe.africa.fill"
        }

        if text.contains("english") || text.contains("англій") {
            return "character.bubble.fill"
        }

        if text.contains("book") || text.contains("reading") || text.contains("study") {
            return "book.fill"
        }

        if text.contains("music") || text.contains("audio") || text.contains("listening") {
            return "headphones"
        }

        if text.contains("food") {
            return "fork.knife"
        }

        if text.contains("travel") {
            return "airplane"
        }

        if text.contains("health") {
            return "heart.fill"
        }

        if text.contains("work") {
            return "briefcase.fill"
        }

        return "star.fill"
    }
}
