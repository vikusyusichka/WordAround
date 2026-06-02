import SwiftUI

struct GrammarTemplateLibraryView: View {

    enum Kind {
        case topic
        case note
    }

    let kind: Kind
    let onSelectTopic: ((GrammarTopicTemplate) -> Void)?
    let onSelectNote:  ((GrammarNoteTemplate)  -> Void)?
    let onCancel: () -> Void

    @State private var searchText: String = ""
    @State private var selectedLanguageCode: String? = nil
    @State private var selectedDifficulty: String? = nil
    @State private var previewTopic: GrammarTopicTemplate? = nil
    @State private var previewNote:  GrammarNoteTemplate?  = nil

    init(
        kind: Kind,
        onSelectTopic: ((GrammarTopicTemplate) -> Void)? = nil,
        onSelectNote: ((GrammarNoteTemplate) -> Void)? = nil,
        onCancel: @escaping () -> Void
    ) {
        self.kind = kind
        self.onSelectTopic = onSelectTopic
        self.onSelectNote = onSelectNote
        self.onCancel = onCancel
    }

    private let languages: [(code: String?, label: String)] = [
        (nil,  "All languages"),
        ("en", "English"),
        ("es", "Spanish"),
        ("fr", "French"),
        ("de", "German")
    ]

    private let difficulties: [(value: String?, label: String)] = [
        (nil,  "Any"),
        ("A1", "A1"),
        ("A2", "A2"),
        ("B1", "B1"),
        ("B2", "B2")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.appBackground.ignoresSafeArea()

                VStack(spacing: 14) {
                    modalHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 18)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            searchField
                            filtersRow
                            cardsList
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 34)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(item: $previewTopic) { topic in
            GrammarTemplatePreviewView(
                kind: .topic(topic),
                onUse: {
                    previewTopic = nil
                    onSelectTopic?(topic)
                },
                onCancel: { previewTopic = nil }
            )
        }
        .sheet(item: $previewNote) { note in
            GrammarTemplatePreviewView(
                kind: .note(note),
                onUse: {
                    previewNote = nil
                    onSelectNote?(note)
                },
                onCancel: { previewNote = nil }
            )
        }
    }

    private var modalHeader: some View {
        HStack(spacing: 12) {
            Color.clear.frame(width: 84, height: 48)

            Spacer()

            Text(kind == .topic ? "Topic templates" : "Note templates")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlue)
                .lineLimit(1)

            Spacer()

            Button(action: onCancel) {
                Text("Close")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 20)
                    .frame(height: 48)
                    .background(AppColors.primaryBlue)
                    .clipShape(Capsule())
                    .shadow(color: AppColors.primaryBlue.opacity(0.16), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)
            TextField("Search templates", text: $searchText)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .tint(AppColors.primaryBlue)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
        )
    }

    private var filtersRow: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(languages, id: \.label) { item in
                        filterChip(
                            label: item.label,
                            isSelected: selectedLanguageCode == item.code,
                            tint: AppColors.primaryBlue
                        ) {
                            withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                                selectedLanguageCode = item.code
                            }
                        }
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(difficulties, id: \.label) { item in
                        filterChip(
                            label: item.label,
                            isSelected: selectedDifficulty == item.value,
                            tint: AppColors.primaryBlueDark
                        ) {
                            withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                                selectedDifficulty = item.value
                            }
                        }
                    }
                }
            }
        }
    }

    private func filterChip(label: String, isSelected: Bool, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? Color.white : tint)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? tint : tint.opacity(0.10))
                .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
    }

    @ViewBuilder
    private var cardsList: some View {
        switch kind {
        case .topic: topicCards
        case .note:  noteCards
        }
    }

    private var topicCards: some View {
        let templates = GrammarTemplateProvider.shared.topicTemplates(
            languageCode: selectedLanguageCode,
            difficulty: selectedDifficulty,
            searchQuery: searchText
        )
        return Group {
            if templates.isEmpty {
                emptyState
            } else {
                VStack(spacing: 10) {
                    ForEach(templates) { template in
                        Button { previewTopic = template } label: {
                            GrammarTemplateCardView(
                                title: template.title,
                                description: template.description,
                                iconName: template.icon,
                                tint: CreateSetTheme.theme(forHex: template.colorHex).accent,
                                difficulty: template.difficulty,
                                estimatedMinutes: template.estimatedMinutes,
                                tags: template.tags,
                                includedNotesCount: template.noteTemplates.isEmpty ? nil : template.noteTemplates.count
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .transition(.scale(scale: 0.98).combined(with: .opacity))
                    }
                }
            }
        }
    }

    private var noteCards: some View {
        let templates = GrammarTemplateProvider.shared.noteTemplates(
            noteType: nil,
            languageCode: selectedLanguageCode,
            difficulty: selectedDifficulty,
            searchQuery: searchText
        )
        return Group {
            if templates.isEmpty {
                emptyState
            } else {
                VStack(spacing: 10) {
                    ForEach(templates) { template in
                        Button { previewNote = template } label: {
                            GrammarTemplateCardView(
                                title: template.title,
                                description: template.description,
                                iconName: template.noteType.systemImage,
                                tint: template.noteType.tintColor,
                                difficulty: template.difficulty,
                                estimatedMinutes: template.estimatedMinutes,
                                tags: template.tags
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .transition(.scale(scale: 0.98).combined(with: .opacity))
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
            Text("No templates match your filters.")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview("Topic library") {
    GrammarTemplateLibraryView(
        kind: .topic,
        onSelectTopic: { _ in },
        onSelectNote: nil,
        onCancel: {}
    )
}

#Preview("Note library") {
    GrammarTemplateLibraryView(
        kind: .note,
        onSelectTopic: nil,
        onSelectNote: { _ in },
        onCancel: {}
    )
}
