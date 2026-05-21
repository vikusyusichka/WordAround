import SwiftUI
import Combine

@MainActor
final class WritingViewModel: ObservableObject {
    let goal = WritingGoal(title: "Today's writing goal", currentWords: 120, targetWords: 200)

    let menuItems: [WritingMenuItem] = [
        WritingMenuItem(
            title: "Write from sets",
            subtitle: "Practice spelling and writing\nwords from your sets.",
            systemImage: "square.grid.2x2.fill",
            gradient: [Color(red: 0.52, green: 0.39, blue: 1.00), Color(red: 0.42, green: 0.55, blue: 1.00)],
            action: .writeFromSets
        ),
        WritingMenuItem(
            title: "Essays",
            subtitle: "Write texts and get AI feedback\non grammar and style.",
            systemImage: "note.text.badge.plus",
            gradient: [Color(red: 0.36, green: 0.58, blue: 1.00), Color(red: 0.43, green: 0.77, blue: 1.00)],
            action: .essays
        ),
        WritingMenuItem(
            title: "Grammar notes",
            subtitle: "Learn grammar with clear notes,\nexamples and mini exercises.",
            systemImage: "book.pages.fill",
            gradient: [Color(red: 1.00, green: 0.71, blue: 0.24), Color(red: 1.00, green: 0.50, blue: 0.36)],
            action: .grammarNotes
        )
    ]
}
