import SwiftUI

enum FlashcardSetDetailCardFilter: CaseIterable, Identifiable {
    case all
    case studied
    case remaining
    case mastered

    var id: Self { self }

    var title: String {
        switch self {
        case .all: "All"
        case .studied: "Studied"
        case .remaining: "Remaining"
        case .mastered: "Mastered"
        }
    }
}

#Preview {
    ZStack {
        CreateSetTheme.yellow.screenBackground
            .ignoresSafeArea()

        FlashcardSetDetailFilterTabsView(
            theme: .yellow,
            selectedFilter: .constant(.studied),
            count: { filter in
                switch filter {
                case .all: return 10
                case .studied: return 4
                case .remaining: return 6
                case .mastered: return 2
                }
            }
        )
        .padding(.horizontal, 15)
    }
}
