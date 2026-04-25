import SwiftUI

struct FlashcardSetDetailView: View {
    let set: FlashcardSet

    @Environment(\.dismiss) private var dismiss

    @State private var currentCardIndex = 0
    @State private var isShowingTranslation = false
    @State private var trackProgress = true
    @State private var selectedFilter: FlashcardSetDetailCardFilter = .all
    @State private var shuffledCards: [Flashcard]? = nil

    @State private var studiedCardIDs: Set<String> = []
    @State private var masteredCardIDs: Set<String> = []
    @State private var isDescriptionExpanded = false

    private var theme: CreateSetTheme {
        CreateSetTheme.theme(forHex: set.colorHex)
    }

    private var displayedCards: [Flashcard] {
        shuffledCards ?? set.cards
    }

    private var filteredCards: [Flashcard] {
        switch selectedFilter {
        case .all:
            displayedCards
        case .studied:
            displayedCards.filter { studiedCardIDs.contains($0.id) }
        case .remaining:
            displayedCards.filter { !studiedCardIDs.contains($0.id) }
        case .mastered:
            displayedCards.filter { masteredCardIDs.contains($0.id) }
        }
    }

    private var activeCard: Flashcard? {
        guard !displayedCards.isEmpty else { return nil }
        return displayedCards[min(currentCardIndex, displayedCards.count - 1)]
    }

    var body: some View {
        ZStack {
            theme.screenBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    FlashcardSetDetailTopBarView(
                        theme: theme,
                        onBack: { dismiss() },
                        onMore: { }
                    )
                    .padding(.bottom, 8)

                    FlashcardSetDetailHeaderView(
                        theme: theme,
                        title: set.title,
                        description: set.description,
                        ownerEmail: set.ownerEmail,
                        isDescriptionExpanded: $isDescriptionExpanded
                    )
                    .padding(.bottom, isDescriptionExpanded ? 14 : 4)
                    .animation(.easeInOut(duration: 0.22), value: isDescriptionExpanded)

                    FlashcardSetDetailMainCardView(
                        theme: theme,
                        card: activeCard,
                        currentIndex: currentCardIndex,
                        cardsCount: displayedCards.count,
                        isShowingTranslation: isShowingTranslation,
                        onTap: toggleTranslation,
                        onSpeak: { }
                    )

                    FlashcardSetDetailControlsView(
                        theme: theme,
                        trackProgress: $trackProgress,
                        onShuffle: shuffleCards,
                        onEdit: { }
                    )
                    .padding(.top, Layout.flashcardDetailControlsTopPadding)

                    FlashcardSetDetailFilterTabsView(
                        theme: theme,
                        selectedFilter: $selectedFilter,
                        count: count(for:)
                    )
                    .padding(.top, 8)

                    cardsList
                        .padding(.top, 8)

                    FlashcardSetDetailAddButton(
                        theme: theme,
                        onTap: { }
                    )
                    .padding(.top, 10)
                }
                .frame(maxWidth: Layout.flashcardDetailContentMaxWidth)
                .padding(.horizontal, Layout.flashcardDetailHorizontalPadding)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Cards List

private extension FlashcardSetDetailView {
    var cardsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(filteredCards.enumerated()), id: \.element.id) { index, card in
                FlashcardSetDetailCardRowView(
                    theme: theme,
                    card: card,
                    index: index + 1,
                    isMastered: masteredCardIDs.contains(card.id),
                    onToggleMastered: { toggleMastered(card) },
                    onSpeak: { },
                    onEdit: { }
                )
            }
        }
        .background(theme.sectionBackground)
        .clipShape(
            RoundedRectangle(
                cornerRadius: Layout.flashcardDetailListCornerRadius,
                style: .continuous
            )
        )
        .shadow(color: theme.shadowColor, radius: 12, x: 0, y: 6)
    }
}

// MARK: - Counts

private extension FlashcardSetDetailView {
    func count(for filter: FlashcardSetDetailCardFilter) -> Int {
        switch filter {
        case .all:
            displayedCards.count
        case .studied:
            studiedCardIDs.count
        case .remaining:
            max(displayedCards.count - studiedCardIDs.count, 0)
        case .mastered:
            masteredCardIDs.count
        }
    }
}

// MARK: - Actions

private extension FlashcardSetDetailView {
    func toggleTranslation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isShowingTranslation.toggle()
        }
    }

    func shuffleCards() {
        withAnimation(.easeInOut(duration: 0.25)) {
            shuffledCards = displayedCards.shuffled()
            currentCardIndex = 0
            isShowingTranslation = false
        }
    }

    func toggleMastered(_ card: Flashcard) {
        if masteredCardIDs.contains(card.id) {
            masteredCardIDs.remove(card.id)
        } else {
            masteredCardIDs.insert(card.id)
            studiedCardIDs.insert(card.id)
        }
    }
}

// MARK: - Preview

#Preview {
    FlashcardSetDetailView(
        set: FlashcardSet(
            id: UUID().uuidString,
            ownerUID: "preview-user",
            ownerEmail: "vika@example.com",
            title: "Daily Conversation",
            description: "A collection of useful phrases for everyday conversations. Practice speaking and listening to sound more natural and confident.",
            privacy: "private",
            folderName: nil,
            colorHex: SetColor.green.hex,
            icon: .systemName("rectangle.stack.fill"),
            cards: previewCards,
            createdAt: Date(),
            updatedAt: Date()
        )
    )
}

private let previewCards: [Flashcard] = [
    Flashcard(
        id: UUID().uuidString,
        word: "Hola",
        translation: "Hello",
        example: "Hola, ¿cómo estás?",
        imageURL: nil
    ),
    Flashcard(
        id: UUID().uuidString,
        word: "Gracias",
        translation: "Thank you",
        example: "Gracias por tu ayuda.",
        imageURL: nil
    ),
    Flashcard(
        id: UUID().uuidString,
        word: "Buenos días",
        translation: "Good morning",
        example: "Buenos días, ¿cómo estás?",
        imageURL: nil
    )
]
