import SwiftUI

struct EditSetSheet: View {
    @Environment(\.dismiss) private var dismiss

    let initialTitle: String
    let initialDescription: String
    let theme: CreateSetTheme
    let isSaving: Bool
    let onSave: (String, String) async -> Bool

    @State private var title: String
    @State private var description: String
    @State private var validationMessage: String?

    init(
        initialTitle: String,
        initialDescription: String,
        theme: CreateSetTheme,
        isSaving: Bool,
        onSave: @escaping (String, String) async -> Bool
    ) {
        self.initialTitle = initialTitle
        self.initialDescription = initialDescription
        self.theme = theme
        self.isSaving = isSaving
        self.onSave = onSave

        _title = State(initialValue: initialTitle)
        _description = State(initialValue: initialDescription)
    }

    var body: some View {
        ZStack {
            theme.screenBackground
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                sheetHeader

                VStack(alignment: .leading, spacing: 14) {
                    inputBlock(
                        title: "Set name",
                        text: $title,
                        placeholder: "Spanish vocabulary"
                    )

                    descriptionBlock
                }
                .padding(18)
                .background(theme.sectionBackground)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(theme.softBorderColor, lineWidth: 1)
                )
                .shadow(color: theme.shadowColor, radius: 18, x: 0, y: 10)

                if let validationMessage {
                    Text(validationMessage)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.red)
                }

                saveButton

                Spacer()
            }
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.top, 24)
        }
    }

    private var sheetHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("Edit set")
                    .font(.system(size: Layout.isPadLike ? 30 : 26, weight: .bold, design: .rounded))
                    .foregroundColor(theme.titleColor)

                Text("Update the name and description.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(theme.mutedTextColor)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.titleColor)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Circle())
            }
        }
    }

    private func inputBlock(
        title: String,
        text: Binding<String>,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(theme.titleColor)

            TextField(placeholder, text: text)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(theme.titleColor)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(theme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(theme.softBorderColor, lineWidth: 1)
                )
        }
    }

    private var descriptionBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(theme.titleColor)

            TextEditor(text: $description)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(theme.titleColor)
                .scrollContentBackground(.hidden)
                .padding(10)
                .frame(height: 96)
                .background(theme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(theme.softBorderColor, lineWidth: 1)
                )
        }
    }

    private var saveButton: some View {
        Button {
            Task {
                let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

                guard !trimmedTitle.isEmpty else {
                    validationMessage = "Set name cannot be empty."
                    return
                }

                validationMessage = nil

                let didSave = await onSave(title, description)

                if didSave {
                    dismiss()
                }
            }
        } label: {
            HStack(spacing: 8) {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                }

                Text(isSaving ? "Saving..." : "Save changes")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: theme.shadowColor, radius: 16, x: 0, y: 8)
        }
        .disabled(isSaving)
        .opacity(isSaving ? 0.75 : 1)
    }
}
