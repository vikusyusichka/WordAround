import SwiftUI

struct CreateGrammarNoteSheet: View {
    let topic: GrammarNoteTopic
    let isCreating: Bool
    let onCancel: () -> Void
    let onCreate: (String, String, GrammarNoteType, [String], Bool) -> Void

    @State private var title = ""
    @State private var previewText = ""
    @State private var selectedType: GrammarNoteType = .standard
    @State private var tagsText = ""
    @State private var hasQuiz = false
    @State private var validationMessage: String?

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: isPadLike ? 18 : 14) {
                        header
                        inputField(title: "Title", placeholder: "Example: Ser vs Estar", text: $title, limit: 60)
                        previewField
                        typePicker
                        inputField(title: "Tags", placeholder: "A1, verbs, articles", text: $tagsText, limit: nil)
                        quizToggle

                        if let validationMessage {
                            Text(validationMessage)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(CreateSetTheme.red.accent)
                                .padding(.horizontal, 2)
                        }

                        actionButtons
                    }
                    .padding(isPadLike ? 28 : 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("New Note")
                        .font(.system(size: isPadLike ? 28 : 24, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryBlueDark)

                    Text(topic.title)
                        .font(.system(size: isPadLike ? 15 : 13, weight: .semibold, design: .rounded))
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
                        .foregroundStyle(text.wrappedValue.count > limit ? CreateSetTheme.red.accent : AppColors.textSecondary)
                }
            }

            TextField(placeholder, text: text)
                .font(.system(size: isPadLike ? 16 : 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .tint(AppColors.primaryBlue)
                .padding(.horizontal, 14)
                .frame(height: isPadLike ? 58 : 52)
                .background(Color.white.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.78), lineWidth: 1)
                )
        }
    }

    private var previewField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Preview")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                Spacer()
                Text("\(previewText.count)/180")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(previewText.count > 180 ? CreateSetTheme.red.accent : AppColors.textSecondary)
            }

            TextEditor(text: $previewText)
                .font(.system(size: isPadLike ? 16 : 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .tint(AppColors.primaryBlue)
                .frame(minHeight: isPadLike ? 112 : 96)
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(Color.white.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.78), lineWidth: 1)
                )
        }
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Note type")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: isPadLike ? 150 : 126), spacing: 10)], spacing: 10) {
                ForEach(GrammarNoteType.allCases) { type in
                    Button {
                        selectedType = type
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: type.systemImage)
                                .font(.system(size: 13, weight: .bold))
                            Text(type.title)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .lineLimit(1)
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

    private var quizToggle: some View {
        Toggle(isOn: $hasQuiz) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Create quick quiz later")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                Text("Adds a small quiz badge to this note.")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .tint(AppColors.primaryBlue)
        .padding(16)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.white.opacity(0.90))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: validateAndCreate) {
                HStack(spacing: 8) {
                    if isCreating {
                        ProgressView()
                            .tint(Color.white)
                    }
                    Text("Create")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(AppColors.primaryBlue)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isCreating)
        }
        .padding(.top, 4)
    }

    private func validateAndCreate() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPreview = previewText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            validationMessage = "Title is required."
            return
        }

        guard trimmedTitle.count <= 60 else {
            validationMessage = "Title must be under 60 characters."
            return
        }

        guard trimmedPreview.count <= 180 else {
            validationMessage = "Preview must be under 180 characters."
            return
        }

        validationMessage = nil
        let tags = tagsText
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        onCreate(trimmedTitle, trimmedPreview, selectedType, tags, hasQuiz)
    }
}

#Preview {
    CreateGrammarNoteSheet(
        topic: .commonMistakes(ownerUID: "preview"),
        isCreating: false,
        onCancel: {},
        onCreate: { _, _, _, _, _ in }
    )
}
