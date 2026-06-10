import SwiftUI

struct FlashcardSetDetailView: View {
    let set: FlashcardSet

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: FlashcardSetDetailViewModel

    @State private var isDescriptionExpanded = false
    @State private var isExpandedMode = false
    @State private var editingCard: Flashcard? = nil
    @State private var isAddingCard = false

    private let theme: CreateSetTheme

    init(set: FlashcardSet, onSetChanged: @escaping (FlashcardSet) -> Void = { _ in }) {
        self.set = set
        self.theme = CreateSetTheme.theme(forHex: set.colorHex)
        _viewModel = StateObject(
            wrappedValue: FlashcardSetDetailViewModel(
                set: set,
                onSetChanged: onSetChanged
            )
        )
    }

    var body: some View {
        ZStack {
            theme.screenBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
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
                        card: viewModel.activeCard,
                        currentIndex: viewModel.currentCardIndex,
                        cardsCount: viewModel.cards.count,
                        isShowingTranslation: viewModel.isShowingTranslation,
                        onTap: { viewModel.toggleTranslation() },
                        onSpeak: { viewModel.speakCurrentCard() },
                        onExpand: { isExpandedMode = true },
                        onSwipeLeft: { viewModel.handleSwipe(.left) },
                        onSwipeRight: { viewModel.handleSwipe(.right) },
                        onEditMain: { editingCard = viewModel.activeCard }
                    )

                    FlashcardSetDetailControlsView(
                        theme: theme,
                        trackProgress: $viewModel.trackProgress,
                        onShuffle: { viewModel.shuffleCards() },
                        onEdit: { editingCard = viewModel.activeCard }
                    )
                    .padding(.top, Layout.flashcardDetailControlsTopPadding)

                    FlashcardSetDetailFilterTabsView(
                        theme: theme,
                        selectedFilter: filterBinding,
                        count: { filter in viewModel.count(for: mapBack(filter)) }
                    )
                    .padding(.top, 8)

                    cardsList
                        .padding(.top, 8)

                    FlashcardSetDetailAddButton(
                        theme: theme,
                        onTap: { isAddingCard = true }
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
        .fullScreenCover(isPresented: $isExpandedMode) {
            FlashcardExpandedView(viewModel: viewModel, isPresented: $isExpandedMode)
        }
        .sheet(item: $editingCard) { card in
            FlashcardEditView(
                theme: theme,
                card: card,
                onSave: { viewModel.saveEdit($0) },
                onDelete: { viewModel.deleteCard($0) }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isAddingCard) {
            FlashcardSetAddCardView(
                theme: theme,
                onSave: { viewModel.addCard($0) }
            )
            .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Cards List

private extension FlashcardSetDetailView {
    var cardsList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(viewModel.filteredCards.enumerated()), id: \.element.id) { index, card in
                FlashcardSetDetailCardRowView(
                    theme: theme,
                    card: card,
                    index: index + 1,
                    isMastered: viewModel.isMastered(card),
                    onToggleMastered: { viewModel.toggleMastered(card) },
                    onSpeak: { viewModel.speakWordAndTranslation(card) },
                    onEdit: { editingCard = card }
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        viewModel.deleteCard(card)
                    } label: {
                        Label(L10n.string("commonDelete"), systemImage: "trash")
                    }
                }

                if index < viewModel.filteredCards.count - 1 {
                    Divider()
                        .background(theme.borderColor.opacity(0.3))
                        .padding(.horizontal, Layout.flashcardDetailRowHorizontalPadding)
                }
            }
        }
        .background(theme.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: Layout.flashcardDetailListCornerRadius, style: .continuous))
        .shadow(color: theme.shadowColor, radius: 12, x: 0, y: 6)
    }
}

// MARK: - Filter Mapping

private extension FlashcardSetDetailView {
    var filterBinding: Binding<FlashcardSetDetailCardFilter> {
        Binding(
            get: { mapFilter(viewModel.selectedFilter) },
            set: { viewModel.selectFilter(mapBack($0)) }
        )
    }

    func mapFilter(_ filter: FlashcardSetDetailViewModel.CardFilter) -> FlashcardSetDetailCardFilter {
        switch filter {
        case .all:       return .all
        case .studied:   return .studied
        case .remaining: return .remaining
        case .mastered:  return .mastered
        }
    }

    func mapBack(_ filter: FlashcardSetDetailCardFilter) -> FlashcardSetDetailViewModel.CardFilter {
        switch filter {
        case .all:       return .all
        case .studied:   return .studied
        case .remaining: return .remaining
        case .mastered:  return .mastered
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
            description: "A collection of useful phrases.",
            privacy: "private",
            folderName: nil,
            colorHex: SetColor.purple.hex,
            icon: .systemName("rectangle.stack.fill"),
            cards: [
                Flashcard(
                    id: UUID().uuidString,
                    word: "Hola",
                    translation: "Привіт",
                    example: "Hola, ¿cómo estás?",
                    imageURL: nil
                ),
                Flashcard(
                    id: UUID().uuidString,
                    word: "Gracias",
                    translation: "Дякую",
                    example: "Gracias por tu ayuda.",
                    imageURL: nil
                )
            ],
            createdAt: Date(),
            updatedAt: Date()
        )
    )
}
