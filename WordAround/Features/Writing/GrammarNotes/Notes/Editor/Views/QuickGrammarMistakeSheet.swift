import SwiftUI

struct QuickGrammarMistakeDraft: Equatable {
    var originalSentence: String
    var correctedSentence: String
    var explanation: String
    var language: GrammarLanguage
    var topic: GrammarQuickTopicOption
    var opensEditorAfterSaving: Bool
}

struct QuickGrammarMistakeSheet: View {
    let topics: [GrammarQuickTopicOption]
    let languages: [GrammarLanguage]
    let isCreating: Bool
    let errorMessage: String?
    let showsTopicPicker: Bool
    let onCancel: () -> Void
    let onSave: (QuickGrammarMistakeDraft) -> Void

    @State private var originalSentence = ""
    @State private var correctedSentence = ""
    @State private var explanation = ""
    @State private var selectedLanguage: GrammarLanguage
    @State private var selectedTopic: GrammarQuickTopicOption
    @AppStorage("grammarNotes.opensEditorAfterQuickSave") private var opensEditorAfterSaving: Bool = true
    @AppStorage("grammarNotes.showsHelperTips")
    private var showHelperTips: Bool = true
    @State private var validationMessage: String?
    @State private var didSubmitSave = false
    @State private var didSaveSuccessfully = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case original
        case corrected
        case explanation
    }

    init(
        topics: [GrammarQuickTopicOption],
        languages: [GrammarLanguage] = GrammarLanguage.allCases,
        isCreating: Bool = false,
        errorMessage: String? = nil,
        showsTopicPicker: Bool = true,
        onCancel: @escaping () -> Void,
        onSave: @escaping (QuickGrammarMistakeDraft) -> Void
    ) {
        let safeTopics = topics.isEmpty ? QuickGrammarNoteSheet.mockTopics : topics
        let safeLanguages = languages.isEmpty ? GrammarLanguage.allCases : languages
        self.topics = safeTopics
        self.languages = safeLanguages
        self.isCreating = isCreating
        self.errorMessage = errorMessage
        self.showsTopicPicker = showsTopicPicker
        self.onCancel = onCancel
        self.onSave = onSave
        _selectedTopic = State(initialValue: safeTopics[0])
        _selectedLanguage = State(initialValue: safeLanguages.first ?? .english)
    }

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.grammarQuickSheetSectionSpacing) {
                    header
                    languageAndTopicSection
                    sentenceBlock(
                        title: L10n.string("notesOriginalSentence"),
                        helper: "The version that went slightly feral.",
                        placeholder: L10n.string("notesMistakeOriginalPlaceholder"),
                        text: $originalSentence,
                        field: .original,
                        tint: GrammarNoteType.mistake.tintColor,
                        icon: "exclamationmark.circle.fill"
                    )
                    sentenceBlock(
                        title: L10n.string("notesCorrection"),
                        helper: "The fixed version you want to remember.",
                        placeholder: L10n.string("notesMistakeCorrectionPlaceholder"),
                        text: $correctedSentence,
                        field: .corrected,
                        tint: CreateSetTheme.green.accent,
                        icon: "checkmark.circle.fill"
                    )
                    explanationBlock
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
        .presentationDetents([.height(Layout.grammarQuickMistakeSheetHeight), .large])
        .presentationDragIndicator(.hidden)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                focusedField = .original
            }
        }
        .onChange(of: errorMessage) { _, message in
            guard message != nil else { return }
            didSubmitSave = false
            didSaveSuccessfully = false
        }
        .onChange(of: isCreating) { _, creating in
            guard !creating else { return }
            if didSubmitSave && errorMessage == nil {
                didSaveSuccessfully = true
            }
            didSubmitSave = false
        }
        .task(id: didSubmitSave) {
            guard didSubmitSave else { return }
            try? await Task.sleep(nanoseconds: 12_000_000_000)
            if didSubmitSave {
                didSubmitSave = false
            }
        }
        .animation(Layout.grammarQuickSheetAnimation, value: validationMessage)
        .animation(Layout.grammarQuickSheetAnimation, value: selectedLanguage)
        .animation(Layout.grammarQuickSheetAnimation, value: selectedTopic)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(GrammarNoteType.mistake.tintColor.opacity(0.13))
                Image(systemName: "exclamationmark.bubble.fill")
                    .font(.system(size: Layout.grammarQuickHeaderIconSize, weight: .bold))
                    .foregroundStyle(GrammarNoteType.mistake.tintColor)
            }
            .frame(width: Layout.grammarQuickHeaderIconBox, height: Layout.grammarQuickHeaderIconBox)

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.string("notesQuickMistake"))
                    .font(.system(size: Layout.grammarQuickTitleSize, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                Text(L10n.string("notesQuickMistakeSubtitle"))
                    .font(.system(size: Layout.grammarQuickSubtitleSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(2)
            }

            Spacer(minLength: 0)

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
    }

    private var languageAndTopicSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.string("notesSetup"))
                .font(.system(size: Layout.grammarQuickSectionTitleSize, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)

            if showsTopicPicker {
                if Layout.isPadLike {
                    HStack(alignment: .top, spacing: 12) {
                        languageSelector
                        topicSelector
                    }
                } else {
                    VStack(spacing: 10) {
                        languageSelector
                        topicSelector
                    }
                }
            } else {
                languageSelector
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: Layout.grammarQuickSectionCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.grammarQuickSectionCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.56), lineWidth: 1)
        )
    }

    private var languageSelector: some View {
        Menu {
            ForEach(languages) { language in
                Button(language.title) {
                    selectedLanguage = language
                }
            }
        } label: {
            selectorShell(
                label: L10n.string("profileRowLanguage"),
                title: selectedLanguage.title,
                badge: selectedLanguage.shortTitle,
                icon: "globe.europe.africa.fill",
                tint: AppColors.primaryBlue
            )
        }
        .buttonStyle(.plain)
    }

    private var topicSelector: some View {
        Menu {
            ForEach(topics) { topic in
                Button(topic.title) {
                    selectedTopic = topic
                }
            }
        } label: {
            selectorShell(
                label: L10n.string("notesTopic"),
                title: selectedTopic.title,
                badge: selectedTopic.subtitle,
                icon: selectedTopic.systemImage,
                tint: selectedTopic.tint
            )
        }
        .buttonStyle(.plain)
    }

    private func selectorShell(label: String, title: String, badge: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(tint.opacity(0.12))
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(tint)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            Text(badge)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(tint)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(tint.opacity(0.09))
                .clipShape(Capsule())

            Image(systemName: "chevron.down")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func sentenceBlock(
        title: String,
        helper: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        tint: Color,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            labelRow(title: title, helper: helper, tint: tint, icon: icon)

            TextField(placeholder, text: text, axis: .vertical)
                .focused($focusedField, equals: field)
                .lineLimit(2...4)
                .submitLabel(.next)
                .font(.system(size: Layout.grammarQuickEditorTextSize, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .tint(tint)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: Layout.grammarQuickFieldCornerRadius, style: .continuous)
                        .fill(tint.opacity(focusedField == field ? 0.13 : 0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.grammarQuickFieldCornerRadius, style: .continuous)
                                .stroke(tint.opacity(focusedField == field ? 0.30 : 0.10), lineWidth: 1)
                        )
                )
        }
        .padding(14)
        .background(Color.white.opacity(0.76))
        .clipShape(RoundedRectangle(cornerRadius: Layout.grammarQuickSectionCornerRadius, style: .continuous))
    }

    private var explanationBlock: some View {
        VStack(alignment: .leading, spacing: 9) {
            labelRow(
                title: L10n.string("notesExplanation"),
                helper: L10n.string("notesExplanationHelper"),
                tint: AppColors.primaryBlue,
                icon: "lightbulb.fill"
            )

            ZStack(alignment: .topLeading) {
                if explanation.isEmpty {
                    Text(L10n.string("notesExplanationPlaceholder"))
                        .font(.system(size: Layout.grammarQuickEditorTextSize, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary.opacity(0.55))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 17)
                }

                TextEditor(text: $explanation)
                    .focused($focusedField, equals: .explanation)
                    .font(.system(size: Layout.grammarQuickEditorTextSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .tint(AppColors.primaryBlue)
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .frame(minHeight: Layout.grammarQuickMistakeExplanationHeight)
            }
            .background(Color.white.opacity(focusedField == .explanation ? 0.98 : 0.86))
            .clipShape(RoundedRectangle(cornerRadius: Layout.grammarQuickFieldCornerRadius, style: .continuous))
        }
        .padding(14)
        .background(Color.white.opacity(0.76))
        .clipShape(RoundedRectangle(cornerRadius: Layout.grammarQuickSectionCornerRadius, style: .continuous))
    }

    private func labelRow(title: String, helper: String, tint: Color, icon: String) -> some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: Layout.grammarQuickSectionTitleSize, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                if showHelperTips {
                    Text(helper)
                        .font(.system(size: Layout.grammarQuickHelperSize, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
    }

    private var openEditorToggle: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(GrammarNoteType.mistake.tintColor.opacity(0.10))
                Image(systemName: "arrow.up.forward.app.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(GrammarNoteType.mistake.tintColor)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.string("notesOpenEditorAfterSave"))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                Text(L10n.string("notesMistakeEditorHelper"))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer(minLength: 0)

            Toggle("", isOn: $opensEditorAfterSaving)
                .labelsHidden()
                .tint(GrammarNoteType.mistake.tintColor)
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
        } else if didSaveSuccessfully {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .bold))
                Text(L10n.string("notesSavedShort"))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            .foregroundStyle(CreateSetTheme.green.accent)
            .padding(.horizontal, 3)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button(L10n.string("commonCancel")) {
                didSubmitSave = false
                didSaveSuccessfully = false
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
                } else if didSaveSuccessfully {
                    Text(L10n.string("readingSaved"))
                } else {
                    Text(L10n.string("notesSaveMistake"))
                }
            }
            .buttonStyle(GrammarQuickPrimaryButtonStyle(tint: GrammarNoteType.mistake.tintColor))
            .disabled(effectiveIsCreating || didSaveSuccessfully)
        }
    }

    private var effectiveIsCreating: Bool {
        isCreating || didSubmitSave
    }

    private func save() {
        guard !effectiveIsCreating else { return }
        let original = originalSentence.trimmingCharacters(in: .whitespacesAndNewlines)
        let corrected = correctedSentence.trimmingCharacters(in: .whitespacesAndNewlines)
        let reason = explanation.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !original.isEmpty else {
            validationMessage = "Add the original sentence first. Sadly, the app cannot capture invisible mistakes."
            return
        }

        guard !corrected.isEmpty else {
            validationMessage = "Add the corrected sentence too. That is the whole plot."
            return
        }

        validationMessage = nil
        didSaveSuccessfully = false
        didSubmitSave = true
        onSave(
            QuickGrammarMistakeDraft(
                originalSentence: original,
                correctedSentence: corrected,
                explanation: reason,
                language: selectedLanguage,
                topic: selectedTopic,
                opensEditorAfterSaving: opensEditorAfterSaving
            )
        )
    }
}

#Preview {
    QuickGrammarMistakeSheet(
        topics: QuickGrammarNoteSheet.mockTopics,
        isCreating: false,
        errorMessage: nil,
        showsTopicPicker: true,
        onCancel: {},
        onSave: { _ in }
    )
}
