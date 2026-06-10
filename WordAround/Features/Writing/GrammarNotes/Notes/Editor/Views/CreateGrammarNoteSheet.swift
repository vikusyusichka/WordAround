import SwiftUI

struct CreateGrammarNoteSheet: View {
    let topic: GrammarNoteTopic
    let isCreating: Bool
    let errorMessage: String?
    let onCancel: () -> Void
    let onCreate: (String, String, GrammarNoteType, [String], Bool, GrammarNoteTemplate?) -> Void

    @State private var title = ""
    @State private var previewText = ""
    @State private var selectedType: GrammarNoteType = .standard
    @State private var tagsText = ""
    @State private var validationMessage: String?
    @State private var didSubmit = false

    init(
        topic: GrammarNoteTopic,
        isCreating: Bool,
        errorMessage: String? = nil,
        onCancel: @escaping () -> Void,
        onCreate: @escaping (String, String, GrammarNoteType, [String], Bool, GrammarNoteTemplate?) -> Void
    ) {
        self.topic = topic
        self.isCreating = isCreating
        self.errorMessage = errorMessage
        self.onCancel = onCancel
        self.onCreate = onCreate
    }

    private var effectiveIsCreating: Bool { isCreating || didSubmit }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Layout.grammarNoteCreateSpacing) {
                        header
                        inputField(title: L10n.string("createNoteFieldTitle"), placeholder: L10n.string("createNoteFieldTitlePh"), text: $title, limit: 60)
                        previewField
                        typePicker
                        inputField(title: L10n.string("editorTagsTitle"), placeholder: L10n.string("editorTagsPlaceholder"), text: $tagsText, limit: nil)

                        if let validationMessage {
                            Text(validationMessage)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(CreateSetTheme.red.accent)
                                .padding(.horizontal, 2)
                        }

                        if let errorMessage, !errorMessage.isEmpty {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(CreateSetTheme.red.accent)
                                Text(errorMessage)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(AppColors.primaryBlueDark)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(CreateSetTheme.red.accent.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        actionButtons
                    }
                    .padding(Layout.grammarNoteCreatePadding)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onChange(of: isCreating) { _, creating in
            if !creating { didSubmit = false }
        }
        .onChange(of: errorMessage) { _, message in
            guard message != nil else { return }
            didSubmit = false
        }
        .task(id: didSubmit) {
            guard didSubmit else { return }
            try? await Task.sleep(nanoseconds: 12_000_000_000)
            if didSubmit { didSubmit = false }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(L10n.string("createNoteTitle"))
                    .font(.system(size: Layout.grammarNoteCreateTitleSize, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                Text(topic.title)
                    .font(.system(size: Layout.grammarNoteCreateSubtitleSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            }
            Spacer()
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.92))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private func inputField(title: String, placeholder: String, text: Binding<String>, limit: Int?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                Spacer()
                if let limit {
                    Text("\(text.wrappedValue.count)/\(limit)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            text.wrappedValue.count > limit ? CreateSetTheme.red.accent : AppColors.textSecondary
                        )
                }
            }
            TextField(placeholder, text: text)
                .font(.system(size: Layout.grammarNoteCreateFieldFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .tint(AppColors.primaryBlue)
                .padding(.horizontal, 14)
                .frame(height: Layout.grammarNoteCreateFieldHeight)
                .background(Color.white.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.78), lineWidth: 1))
        }
    }

    private var previewField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L10n.string("commonPreview"))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                Spacer()
                Text("\(previewText.count)/180")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        previewText.count > 180 ? CreateSetTheme.red.accent : AppColors.textSecondary
                    )
            }
            TextEditor(text: $previewText)
                .font(.system(size: Layout.grammarNoteCreateFieldFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .tint(AppColors.primaryBlue)
                .frame(minHeight: Layout.grammarNoteCreatePreviewMinHeight)
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(Color.white.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.78), lineWidth: 1))
        }
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.string("createNoteType"))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: Layout.grammarNoteCreateTypeMinWidth), spacing: 10)],
                spacing: 10
            ) {
                ForEach(GrammarNoteType.allCases) { type in
                    Button { selectedType = type } label: {
                        HStack(spacing: 8) {
                            Image(systemName: type.systemImage).font(.system(size: 13, weight: .bold))
                            Text(type.title).font(.system(size: 12, weight: .bold, design: .rounded)).lineLimit(1)
                        }
                        .foregroundStyle(selectedType == type ? Color.white : type.tintColor)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(selectedType == type ? type.tintColor : type.tintColor.opacity(0.11))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                didSubmit = false
                onCancel()
            } label: {
                Text(L10n.localized(.commonCancel))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.white.opacity(0.90))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(effectiveIsCreating)

            Button(action: validateAndCreate) {
                HStack(spacing: 8) {
                    if effectiveIsCreating { ProgressView().tint(Color.white) }
                    Text(L10n.string("quizCreateButton")).font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(AppColors.primaryBlue)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(effectiveIsCreating)
        }
        .padding(.top, 4)
    }

    private func validateAndCreate() {
        guard !effectiveIsCreating else { return }

        let cleanTitle   = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPreview = previewText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanTitle.isEmpty          else { validationMessage = L10n.string("createNoteErrTitleRequired"); return }
        guard cleanTitle.count   <= 60     else { validationMessage = L10n.string("createNoteErrTitleLong");    return }
        guard cleanPreview.count <= 180    else { validationMessage = L10n.string("createNoteErrPreviewLong");  return }

        validationMessage = nil
        didSubmit = true
        onCreate(cleanTitle, cleanPreview, selectedType, parsedTags(from: tagsText), false, nil)
    }

    private func parsedTags(from raw: String) -> [String] {
        raw.split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

#Preview {
    CreateGrammarNoteSheet(
        topic: .commonMistakes(ownerUID: "preview"),
        isCreating: false,
        errorMessage: nil,
        onCancel: {},
        onCreate: { _, _, _, _, _, _ in }
    )
}
