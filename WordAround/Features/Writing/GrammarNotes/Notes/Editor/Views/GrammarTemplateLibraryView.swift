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

    @ObservedObject private var userStore = GrammarUserTemplateStore.shared

    @State private var searchText: String = ""
    @State private var selectedLanguageCode: String? = nil
    @State private var selectedDifficulty: String? = nil
    @State private var previewTopic: GrammarTopicTemplate? = nil
    @State private var previewNote:  GrammarNoteTemplate?  = nil
    @State private var topicTemplatePendingDeletion: GrammarTopicTemplate? = nil
    @State private var noteTemplatePendingDeletion:  GrammarNoteTemplate?  = nil

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

    private var languages: [(code: String?, label: String)] {
        [
            (nil,  L10n.string("templateLibLangAll")),
            ("en", AppLanguage.english.displayName),
            ("es", AppLanguage.spanish.displayName),
            ("fr", AppLanguage.french.displayName),
            ("de", AppLanguage.german.displayName)
        ]
    }

    private var difficulties: [(value: String?, label: String)] {
        [
            (nil,  L10n.string("templateLibDifficultyAny")),
            ("A1", "A1"),
            ("A2", "A2"),
            ("B1", "B1"),
            ("B2", "B2")
        ]
    }

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
        .confirmationDialog(
            L10n.string("templateLibDeleteTitle"),
            isPresented: Binding(
                get: { topicTemplatePendingDeletion != nil },
                set: { if !$0 { topicTemplatePendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: topicTemplatePendingDeletion
        ) { template in
            Button(String(format: L10n.string("templateLibDeleteFmt"), template.title), role: .destructive) {
                userStore.deleteTopicTemplate(id: template.id)
                topicTemplatePendingDeletion = nil
            }
            Button(L10n.localized(.commonCancel), role: .cancel) { topicTemplatePendingDeletion = nil }
        } message: { _ in
            Text(L10n.string("templateLibDeleteTopicMsg"))
        }
        .confirmationDialog(
            L10n.string("templateLibDeleteTitle"),
            isPresented: Binding(
                get: { noteTemplatePendingDeletion != nil },
                set: { if !$0 { noteTemplatePendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: noteTemplatePendingDeletion
        ) { template in
            Button(String(format: L10n.string("templateLibDeleteFmt"), template.title), role: .destructive) {
                userStore.deleteNoteTemplate(id: template.id)
                noteTemplatePendingDeletion = nil
            }
            Button(L10n.localized(.commonCancel), role: .cancel) { noteTemplatePendingDeletion = nil }
        } message: { _ in
            Text(L10n.string("templateLibDeleteNoteMsg"))
        }
    }

    private var modalHeader: some View {
        HStack(spacing: 12) {
            Color.clear.frame(width: 84, height: 48)

            Spacer()

            Text(L10n.string(kind == .topic ? "templateLibTopicTitle" : "templateLibNoteTitle"))
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlue)
                .lineLimit(1)

            Spacer()

            Button(action: onCancel) {
                Text(L10n.string("templateLibClose"))
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
            TextField(L10n.string("templateLibSearchPlaceholder"), text: $searchText)
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
        let builtIn = GrammarTemplateProvider.shared.topicTemplates(
            languageCode: selectedLanguageCode,
            difficulty: selectedDifficulty,
            searchQuery: searchText
        )
        let mine = userStore.topicTemplates.filter(matchesFilters)

        return Group {
            if builtIn.isEmpty && mine.isEmpty {
                emptyState
            } else {
                VStack(spacing: 14) {
                    if !mine.isEmpty {
                        templateSection(title: L10n.string("templateLibMyTemplates")) {
                            ForEach(mine) { template in
                                topicCard(template, deletable: true)
                            }
                        }
                    }
                    if !builtIn.isEmpty {
                        templateSection(title: mine.isEmpty ? nil : L10n.string("templateLibBuiltIn")) {
                            ForEach(builtIn) { template in
                                topicCard(template, deletable: false)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func topicCard(_ template: GrammarTopicTemplate, deletable: Bool) -> some View {
        let card = Button { previewTopic = template } label: {
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

        if deletable {
            card.contextMenu {
                Button(role: .destructive) {
                    topicTemplatePendingDeletion = template
                } label: {
                    Label(L10n.string("templateLibDeleteAction"), systemImage: "trash")
                }
            }
        } else {
            card
        }
    }

    private var noteCards: some View {
        let builtIn = GrammarTemplateProvider.shared.noteTemplates(
            noteType: nil,
            languageCode: selectedLanguageCode,
            difficulty: selectedDifficulty,
            searchQuery: searchText
        )
        let mine = userStore.noteTemplates.filter(matchesFilters)

        return Group {
            if builtIn.isEmpty && mine.isEmpty {
                emptyState
            } else {
                VStack(spacing: 14) {
                    if !mine.isEmpty {
                        templateSection(title: L10n.string("templateLibMyTemplates")) {
                            ForEach(mine) { template in
                                noteCard(template, deletable: true)
                            }
                        }
                    }
                    if !builtIn.isEmpty {
                        templateSection(title: mine.isEmpty ? nil : L10n.string("templateLibBuiltIn")) {
                            ForEach(builtIn) { template in
                                noteCard(template, deletable: false)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func noteCard(_ template: GrammarNoteTemplate, deletable: Bool) -> some View {
        let card = Button { previewNote = template } label: {
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

        if deletable {
            card.contextMenu {
                Button(role: .destructive) {
                    noteTemplatePendingDeletion = template
                } label: {
                    Label(L10n.string("templateLibDeleteAction"), systemImage: "trash")
                }
            }
        } else {
            card
        }
    }

    @ViewBuilder
    private func templateSection<Content: View>(
        title: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                Text(title)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            content()
        }
    }

    private func matchesFilters(_ language: String?, _ difficulty: String, _ title: String, _ description: String, _ tags: [String]) -> Bool {
        if let selectedLanguageCode, !selectedLanguageCode.isEmpty,
           language != nil, language != selectedLanguageCode {
            return false
        }
        if let selectedDifficulty, !selectedDifficulty.isEmpty,
           difficulty.caseInsensitiveCompare(selectedDifficulty) != .orderedSame {
            return false
        }
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !trimmed.isEmpty {
            let haystack = ([title, description] + tags).map { $0.lowercased() }
            return haystack.contains { $0.contains(trimmed) }
        }
        return true
    }

    private func matchesFilters(_ template: GrammarTopicTemplate) -> Bool {
        matchesFilters(template.languageCode, template.difficulty, template.title, template.description, template.tags)
    }

    private func matchesFilters(_ template: GrammarNoteTemplate) -> Bool {
        matchesFilters(template.languageCode, template.difficulty, template.title, template.description, template.tags)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(AppColors.textSecondary)
            Text(L10n.string("templateLibEmpty"))
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
