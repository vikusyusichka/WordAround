import SwiftUI

struct CreateGrammarTopicSheet: View {
    let isCreating: Bool
    let onCancel: () -> Void
    let onCreate: (_ title: String, _ description: String, _ languageCode: String, _ languageName: String, _ icon: String, _ colorHex: String) -> Void

    @State private var title = ""
    @State private var description = ""
    @State private var selectedLanguage = GrammarTopicLanguage.english
    @State private var selectedIcon = "book.fill"
    @State private var selectedColor: SetColor = .blue

    private let icons = [
        "book.fill",
        "text.book.closed.fill",
        "pencil",
        "quote.bubble.fill",
        "lightbulb.fill",
        "graduationcap.fill",
        "character.book.closed.fill"
    ]

    private var theme: CreateSetTheme {
        CreateSetTheme.theme(for: selectedColor)
    }

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedDescription: String {
        description.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canCreate: Bool {
        !trimmedTitle.isEmpty && trimmedTitle.count <= 40 && trimmedDescription.count <= 120
    }

    var body: some View {
        ZStack {
            theme.screenBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: isPadLike ? 18 : 14) {
                    headerView
                    infoSection
                    languageSection
                    iconSection
                    colorSection
                    previewSection
                    actionButtons
                }
                .padding(.horizontal, isPadLike ? 28 : 20)
                .padding(.top, isPadLike ? 22 : 18)
                .padding(.bottom, 30)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var headerView: some View {
        VStack(spacing: isPadLike ? 18 : 14) {
            HStack {
                Button(action: onCancel) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: isPadLike ? 18 : 16, weight: .semibold))
                        .foregroundStyle(theme.mutedTextColor)
                        .frame(width: isPadLike ? 50 : 44, height: isPadLike ? 50 : 44)
                        .background(theme.fieldBackground)
                        .clipShape(Circle())
                        .shadow(color: theme.shadowColor, radius: 12, x: 0, y: 7)
                }
                .buttonStyle(.plain)

                Spacer()

                HStack(spacing: 10) {
                    Text("Choose icon")
                        .font(.system(size: isPadLike ? 15 : 13, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.accent)

                    ZStack {
                        Circle()
                            .fill(theme.softAccent)
                            .frame(width: isPadLike ? 42 : 36, height: isPadLike ? 42 : 36)

                        Image(systemName: selectedIcon)
                            .font(.system(size: isPadLike ? 18 : 16, weight: .bold))
                            .foregroundStyle(theme.accent)
                    }
                }
            }

            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("New Grammar Topic")
                        .font(.system(size: isPadLike ? 34 : 28, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.titleColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text("Create a container for rules, examples and future notes.")
                        .font(.system(size: isPadLike ? 16 : 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.mutedTextColor)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: isPadLike ? 16 : 14) {
            titleField
            descriptionField
        }
        .grammarCreateSetSection(theme: theme, padding: isPadLike ? 20 : 16)
    }

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Topic title")

            ZStack(alignment: .leading) {
                if title.isEmpty {
                    Text("e.g. Spanish tenses")
                        .foregroundStyle(theme.mutedTextColor.opacity(0.55))
                }

                TextField("", text: $title)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .onChange(of: title) { newValue in
                        if newValue.count > 40 {
                            title = String(newValue.prefix(40))
                        }
                    }
            }
            .createSetFieldStyle(height: isPadLike ? 58 : 52, fontSize: isPadLike ? 17 : 15, theme: theme)

            counterText("\(trimmedTitle.count)/40")
        }
    }

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                sectionLabel("Description")

                Text("(optional)")
                    .font(.system(size: isPadLike ? 13 : 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.mutedTextColor)
            }

            ZStack(alignment: .bottomTrailing) {
                ZStack(alignment: .topLeading) {
                    if description.isEmpty {
                        Text("What should this topic collect?")
                            .font(.system(size: isPadLike ? 16 : 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.mutedTextColor.opacity(0.55))
                            .padding(.top, 12)
                            .padding(.leading, 14)
                    }

                    TextField("", text: $description, axis: .vertical)
                        .font(.system(size: isPadLike ? 16 : 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.textColor)
                        .tint(theme.accent)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .padding(.top, 12)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 28)
                        .onChange(of: description) { newValue in
                            if newValue.count > 120 {
                                description = String(newValue.prefix(120))
                            }
                        }
                }
                .frame(minHeight: isPadLike ? 96 : 86, alignment: .topLeading)
                .background(theme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(theme.borderColor, lineWidth: 1)
                )

                counterText("\(trimmedDescription.count)/120")
                    .padding(.trailing, 14)
                    .padding(.bottom, 10)
            }
        }
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Language")

            Menu {
                ForEach(GrammarTopicLanguage.allCases) { language in
                    Button {
                        selectedLanguage = language
                    } label: {
                        Label(language.name, systemImage: selectedLanguage == language ? "checkmark" : "globe")
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: isPadLike ? 21 : 19, weight: .semibold))
                        .foregroundStyle(theme.mutedTextColor)

                    Text(selectedLanguage.name)
                        .font(.system(size: isPadLike ? 18 : 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.textColor)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: isPadLike ? 16 : 14, weight: .bold))
                        .foregroundStyle(theme.mutedTextColor)
                }
                .padding(.horizontal, isPadLike ? 18 : 14)
                .frame(height: isPadLike ? 64 : 56)
                .background(theme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: isPadLike ? 20 : 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: isPadLike ? 20 : 16, style: .continuous)
                        .stroke(theme.softBorderColor, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .grammarCreateSetSection(theme: theme, padding: isPadLike ? 20 : 16)
    }

    private var iconSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Icon")

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: isPadLike ? 7 : 4), spacing: 10) {
                ForEach(icons, id: \.self) { icon in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedIcon = icon
                        }
                    } label: {
                        Image(systemName: icon)
                            .font(.system(size: isPadLike ? 21 : 18, weight: .semibold))
                            .foregroundStyle(selectedIcon == icon ? Color.white : theme.accent)
                            .frame(height: isPadLike ? 54 : 48)
                            .frame(maxWidth: .infinity)
                            .background(selectedIcon == icon ? theme.accent : theme.softAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(selectedIcon == icon ? theme.accent : theme.softBorderColor, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .grammarCreateSetSection(theme: theme, padding: isPadLike ? 20 : 16)
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Choose color")

            HStack {
                ForEach(SetColor.allCases) { setColor in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedColor = setColor
                        }
                    } label: {
                        Circle()
                            .fill(setColor.color.opacity(0.75))
                            .frame(width: isPadLike ? 38 : 34, height: isPadLike ? 38 : 34)
                            .overlay {
                                if selectedColor == setColor {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)

                                    Circle()
                                        .stroke(setColor.color, lineWidth: 2)
                                        .frame(width: isPadLike ? 46 : 42, height: isPadLike ? 46 : 42)
                                }
                            }
                    }
                    .buttonStyle(.plain)

                    if setColor != SetColor.allCases.last {
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, isPadLike ? 10 : 4)
        }
        .grammarCreateSetSection(theme: theme, padding: isPadLike ? 20 : 16)
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Preview")

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(theme.softAccent)
                        .frame(width: isPadLike ? 58 : 50, height: isPadLike ? 58 : 50)

                    Image(systemName: selectedIcon)
                        .font(.system(size: isPadLike ? 23 : 20, weight: .bold))
                        .foregroundStyle(theme.accent)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(trimmedTitle.isEmpty ? "Grammar topic" : trimmedTitle)
                        .font(.system(size: isPadLike ? 18 : 16, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.titleColor)
                        .lineLimit(1)

                    Text(trimmedDescription.isEmpty ? "Rules, examples and corrections." : trimmedDescription)
                        .font(.system(size: isPadLike ? 14 : 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.mutedTextColor)
                        .lineLimit(2)
                }

                Spacer()
            }
            .padding(isPadLike ? 18 : 16)
            .background(theme.previewBackground)
            .clipShape(RoundedRectangle(cornerRadius: isPadLike ? 24 : 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: isPadLike ? 24 : 20, style: .continuous)
                    .stroke(theme.softBorderColor, lineWidth: 1)
            )
        }
        .grammarCreateSetSection(theme: theme, padding: isPadLike ? 20 : 16)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("Cancel", action: onCancel)
                .font(.system(size: isPadLike ? 16 : 15, weight: .bold, design: .rounded))
                .foregroundStyle(theme.accent)
                .frame(maxWidth: .infinity)
                .frame(height: isPadLike ? 58 : 52)
                .background(theme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(theme.softBorderColor, lineWidth: 1)
                )
                .disabled(isCreating)

            Button {
                onCreate(trimmedTitle, trimmedDescription, selectedLanguage.code, selectedLanguage.name, selectedIcon, selectedColor.hex)
            } label: {
                HStack(spacing: 8) {
                    if isCreating {
                        ProgressView()
                            .tint(Color.white)
                            .scaleEffect(0.85)
                    }
                    Text("Create")
                        .font(.system(size: isPadLike ? 16 : 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: isPadLike ? 58 : 52)
                .background(canCreate && !isCreating ? theme.accent : theme.accent.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .disabled(!canCreate || isCreating)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: isPadLike ? 16 : 14, weight: .bold, design: .rounded))
            .foregroundStyle(theme.titleColor)
    }

    private func counterText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: isPadLike ? 12 : 11, weight: .semibold, design: .rounded))
            .foregroundStyle(theme.mutedTextColor)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

private enum GrammarTopicLanguage: String, CaseIterable, Identifiable {
    case english
    case spanish
    case french
    case german
    case italian
    case other

    var id: String { rawValue }

    var name: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .german: return "German"
        case .italian: return "Italian"
        case .other: return "Other"
        }
    }

    var code: String {
        switch self {
        case .english: return "en"
        case .spanish: return "es"
        case .french: return "fr"
        case .german: return "de"
        case .italian: return "it"
        case .other: return "other"
        }
    }
}

private extension View {
    func grammarCreateSetSection(theme: CreateSetTheme, padding: CGFloat) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(theme.sectionBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(theme.softBorderColor, lineWidth: 1)
                    )
            )
    }
}

#Preview {
    CreateGrammarTopicSheet(isCreating: false, onCancel: {}, onCreate: { _, _, _, _, _, _ in })
}
