import SwiftUI

struct GrammarQuickTopicOption: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let tint: Color
    let systemImage: String

    init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String,
        tint: Color = AppColors.primaryBlue,
        systemImage: String = "book.closed.fill"
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.tint = tint
        self.systemImage = systemImage
    }
}

struct QuickGrammarNoteDraft: Equatable {
    var title: String
    var text: String
    var topic: GrammarQuickTopicOption
    var noteType: GrammarNoteType
    var opensEditorAfterSaving: Bool
}

struct QuickGrammarNoteSheet: View {
    let topics: [GrammarQuickTopicOption]
    let isCreating: Bool
    let errorMessage: String?
    let showsTopicPicker: Bool
    let onCancel: () -> Void
    let onSave: (QuickGrammarNoteDraft) -> Void

    @State private var title = ""
    @State private var noteText = ""
    @State private var selectedTopic: GrammarQuickTopicOption
    @State private var selectedType: GrammarNoteType = .standard
    @AppStorage("grammarNotes.opensEditorAfterQuickSave") private var opensEditorAfterSaving: Bool = true
    @State private var validationMessage: String?
    @State private var didSubmitSave = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case title
        case noteText
    }

    init(
        topics: [GrammarQuickTopicOption],
        isCreating: Bool = false,
        errorMessage: String? = nil,
        showsTopicPicker: Bool = true,
        onCancel: @escaping () -> Void,
        onSave: @escaping (QuickGrammarNoteDraft) -> Void
    ) {
        let safeTopics = topics.isEmpty ? Self.mockTopics : topics
        self.topics = safeTopics
        self.isCreating = isCreating
        self.errorMessage = errorMessage
        self.showsTopicPicker = showsTopicPicker
        self.onCancel = onCancel
        self.onSave = onSave
        _selectedTopic = State(initialValue: safeTopics[0])
    }

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.grammarQuickSheetSectionSpacing) {
                    header
                    titleSection
                    noteSection
                    selectorGrid
                    openEditorToggle
                    validationView
                    actions
                }
                .padding(Layout.grammarQuickSheetPadding)
                .frame(maxWidth: Layout.grammarQuickSheetMaxWidth)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .presentationDetents([.height(Layout.grammarQuickNoteSheetHeight), .large])
        .presentationDragIndicator(.visible)
        .onChange(of: isCreating) { _, creating in
            guard !creating else { return }
            didSubmitSave = false
        }
        .onChange(of: errorMessage) { _, message in
            // Reset on a NEW error (transition to non-nil). The same-error-
            // twice edge case is now covered by the VM (which always flips
            // isCreating true→false) plus the watchdog below.
            guard message != nil else { return }
            didSubmitSave = false
        }
        // Safety watchdog: if `didSubmitSave` ever stays `true` while the
        // parent never publishes `isCreating == true` (e.g. the Task was
        // cancelled, the parent VM returned synchronously, or onChange
        // missed a coalesced transition), force-reset after a generous
        // timeout so the user is never trapped in an infinite spinner.
        .task(id: didSubmitSave) {
            guard didSubmitSave else { return }
            try? await Task.sleep(nanoseconds: 12_000_000_000) // 12s
            if didSubmitSave {
                didSubmitSave = false
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                focusedField = .title
            }
        }
        .animation(Layout.grammarQuickSheetAnimation, value: validationMessage)
        .animation(Layout.grammarQuickSheetAnimation, value: selectedTopic)
        .animation(Layout.grammarQuickSheetAnimation, value: selectedType)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryBlue.opacity(0.12))
                Image(systemName: "square.and.pencil")
                    .font(.system(size: Layout.grammarQuickHeaderIconSize, weight: .bold))
                    .foregroundStyle(AppColors.primaryBlue)
            }
            .frame(width: Layout.grammarQuickHeaderIconBox, height: Layout.grammarQuickHeaderIconBox)

            VStack(alignment: .leading, spacing: 4) {
                Text("Quick Note")
                    .font(.system(size: Layout.grammarQuickTitleSize, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                Text("Capture a grammar idea without opening the full editor.")
                    .font(.system(size: Layout.grammarQuickSubtitleSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(2)
            }

            Spacer(minLength: 0)

            closeButton
        }
    }

    private var titleSection: some View {
        quickSection(title: "Title", helper: "Keep it short. Future you already has enough enemies.") {
            TextField("Example: Ser vs Estar", text: $title)
                .focused($focusedField, equals: .title)
                .submitLabel(.next)
                .font(.system(size: Layout.grammarQuickTitleFieldSize, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .frame(height: Layout.grammarQuickTitleFieldHeight)
                .background(fieldBackground(isFocused: focusedField == .title))
                .clipShape(RoundedRectangle(cornerRadius: Layout.grammarQuickFieldCornerRadius, style: .continuous))
                .onSubmit { focusedField = .noteText }
        }
    }

    private var noteSection: some View {
        quickSection(title: "Note", helper: "A rule, tiny explanation, or sentence you want to remember.") {
            ZStack(alignment: .topLeading) {
                if noteText.isEmpty {
                    Text("Write the useful part here")
                        .font(.system(size: Layout.grammarQuickEditorTextSize, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.58))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 17)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $noteText)
                    .focused($focusedField, equals: .noteText)
                    .font(.system(size: Layout.grammarQuickEditorTextSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .tint(AppColors.primaryBlue)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .frame(minHeight: Layout.grammarQuickNoteEditorMinHeight)
            }
            .background(fieldBackground(isFocused: focusedField == .noteText))
            .clipShape(RoundedRectangle(cornerRadius: Layout.grammarQuickFieldCornerRadius, style: .continuous))
        }
    }

    private var selectorGrid: some View {
        VStack(spacing: Layout.grammarQuickMiniSectionSpacing) {
            if showsTopicPicker {
                topicSelector
            }
            noteTypeSelector
        }
    }

    private var topicSelector: some View {
        quickSection(title: "Topic", helper: "Choose where this note should visually belong.") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(topics) { topic in
                        topicChip(topic)
                    }
                }
                .padding(.vertical, 1)
            }
        }
    }

    private func topicChip(_ topic: GrammarQuickTopicOption) -> some View {
        let isSelected = selectedTopic == topic

        return Button {
            selectedTopic = topic
        } label: {
            HStack(spacing: 8) {
                Image(systemName: topic.systemImage)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(isSelected ? Color.white : topic.tint)

                VStack(alignment: .leading, spacing: 2) {
                    Text(topic.title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? Color.white : AppColors.primaryBlueDark)
                        .lineLimit(1)
                    Text(topic.subtitle)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.82) : AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 50)
            .background(isSelected ? topic.tint : Color.white.opacity(0.78))
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 17, style: .continuous)
                    .stroke(isSelected ? Color.white.opacity(0.42) : topic.tint.opacity(0.10), lineWidth: 1)
            )
        }
        .buttonStyle(GrammarNotesScaleButtonStyle())
    }

    private var noteTypeSelector: some View {
        quickSection(title: "Note type", helper: "This only changes visual grouping for now.") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: Layout.grammarQuickTypeMinWidth), spacing: 9)], spacing: 9) {
                ForEach(GrammarNoteType.allCases) { type in
                    typeButton(type)
                }
            }
        }
    }

    private func typeButton(_ type: GrammarNoteType) -> some View {
        let isSelected = selectedType == type

        return Button {
            selectedType = type
        } label: {
            HStack(spacing: 8) {
                Image(systemName: type.systemImage)
                    .font(.system(size: 13, weight: .bold))
                Text(type.title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(isSelected ? Color.white : type.tintColor)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(isSelected ? type.tintColor : type.tintColor.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(GrammarNotesScaleButtonStyle())
    }

    private var openEditorToggle: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(AppColors.primaryBlue.opacity(0.10))
                Image(systemName: "arrow.up.forward.app.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.primaryBlue)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("Open editor after saving")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                Text("Useful when the quick version grows legs and becomes a full note.")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Toggle("", isOn: $opensEditorAfterSaving)
                .labelsHidden()
                .tint(AppColors.primaryBlue)
        }
        .padding(14)
        .background(Color.white.opacity(0.80))
        .clipShape(RoundedRectangle(cornerRadius: Layout.grammarQuickSectionCornerRadius, style: .continuous))
    }

    @ViewBuilder
    private var validationView: some View {
        if let message = validationMessage ?? errorMessage {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 12, weight: .bold))
                Text(message)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            .foregroundStyle(CreateSetTheme.red.accent)
            .padding(.horizontal, 3)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private var effectiveIsCreating: Bool {
        isCreating || didSubmitSave
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button("Cancel") {
                didSubmitSave = false
                onCancel()
            }
            .buttonStyle(GrammarQuickSecondaryButtonStyle())

            Button {
                save()
            } label: {
                if effectiveIsCreating {
                    ProgressView()
                        .tint(Color.white)
                        .scaleEffect(0.9)
                } else {
                    Text("Save quick note")
                }
            }
            .buttonStyle(GrammarQuickPrimaryButtonStyle(tint: AppColors.primaryBlue))
            .disabled(effectiveIsCreating)
        }
    }

    private var closeButton: some View {
        Button(action: onCancel) {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(AppColors.textSecondary)
                .frame(width: 38, height: 38)
                .background(Color.white.opacity(0.9))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func quickSection<Content: View>(
        title: String,
        helper: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: Layout.grammarQuickSectionTitleSize, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                Text(helper)
                    .font(.system(size: Layout.grammarQuickHelperSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            }

            content()
        }
        .padding(14)
        .background(Color.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: Layout.grammarQuickSectionCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.grammarQuickSectionCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.56), lineWidth: 1)
        )
    }

    private func fieldBackground(isFocused: Bool) -> some View {
        RoundedRectangle(cornerRadius: Layout.grammarQuickFieldCornerRadius, style: .continuous)
            .fill(Color.white.opacity(isFocused ? 0.98 : 0.84))
            .overlay(
                RoundedRectangle(cornerRadius: Layout.grammarQuickFieldCornerRadius, style: .continuous)
                    .stroke(AppColors.primaryBlue.opacity(isFocused ? 0.26 : 0.08), lineWidth: 1)
            )
    }

    private func save() {
        guard !effectiveIsCreating else { return }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedText = noteText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty || !trimmedText.isEmpty else {
            validationMessage = "Add a title or note text first. Revolutionary, I know."
            return
        }

        validationMessage = nil
        didSubmitSave = true
        onSave(
            QuickGrammarNoteDraft(
                title: trimmedTitle.isEmpty ? "Untitled quick note" : trimmedTitle,
                text: trimmedText,
                topic: selectedTopic,
                noteType: selectedType,
                opensEditorAfterSaving: opensEditorAfterSaving
            )
        )
    }

    static let mockTopics: [GrammarQuickTopicOption] = [
        GrammarQuickTopicOption(title: "Spanish Basics", subtitle: "12 notes", tint: AppColors.primaryBlue, systemImage: "text.book.closed.fill"),
        GrammarQuickTopicOption(title: "Mistakes", subtitle: "5 notes", tint: GrammarNoteType.mistake.tintColor, systemImage: "exclamationmark.triangle.fill"),
        GrammarQuickTopicOption(title: "Verbs", subtitle: "8 notes", tint: CreateSetTheme.purple.accent, systemImage: "bolt.fill")
    ]
}

extension GrammarQuickTopicOption {
    static func == (lhs: GrammarQuickTopicOption, rhs: GrammarQuickTopicOption) -> Bool {
        lhs.id == rhs.id
    }
}

// `GrammarQuickPrimaryButtonStyle` and `GrammarQuickSecondaryButtonStyle`
// were extracted to `GrammarQuickButtonStyles.swift` (same group) and are
// reused across both this sheet and `QuickGrammarMistakeSheet`.

#Preview {
    QuickGrammarNoteSheet(
        topics: QuickGrammarNoteSheet.mockTopics,
        isCreating: false,
        errorMessage: nil,
        showsTopicPicker: true,
        onCancel: {},
        onSave: { _ in }
    )
}
