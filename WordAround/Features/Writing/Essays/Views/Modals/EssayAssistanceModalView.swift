import SwiftUI

struct EssayAssistanceModalView: View {
    let type: EssayAssistanceModalType
    @Binding var inputText: String

    let selectedTargetLanguage: GrammarLanguage
    let selectedSourceLanguage: GrammarLanguage
    let sourceLanguages: [GrammarLanguage]

    let resultItems: [EssayAssistanceItem]
    let resultMessage: String?
    let usageText: String
    let isLoading: Bool

    let onSelectSourceLanguage: (GrammarLanguage) -> Void
    let onSubmit: () -> Void
    let onClose: () -> Void

    @State private var isLoadingCircleActive = false

    private var title: String {
        switch type {
        case .translate:
            return "Translate"
        case .synonym:
            return "Synonyms"
        }
    }

    private var buttonTitle: String {
        switch type {
        case .translate:
            return isLoading ? "Translating..." : "Translate"
        case .synonym:
            return isLoading ? "Searching..." : "Find synonyms"
        }
    }

    private var placeholder: String {
        switch type {
        case .translate:
            return "Enter a word or short phrase"
        case .synonym:
            return "Enter a word"
        }
    }

    private var icon: String {
        switch type {
        case .translate:
            return "character.book.closed.fill"
        case .synonym:
            return "textformat.abc.dottedunderline"
        }
    }

    private var modalMaxWidth: CGFloat {
        switch type {
        case .translate:
            return Layout.isPadLike ? 560 : 420
        case .synonym:
            return Layout.isPadLike ? 640 : 430
        }
    }

    private var resultsMaxHeight: CGFloat {
        switch type {
        case .translate:
            return resultItems.count <= 1 ? 92 : 180
        case .synonym:
            return Layout.isPadLike ? 360 : 430
        }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(Layout.essayModalDimOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    onClose()
                }

            VStack(alignment: .leading, spacing: Layout.essayModalSpacing) {
                header
                languagePicker
                input
                resultContent
                actions
            }
            .padding(Layout.essayModalPadding)
            .frame(maxWidth: modalMaxWidth)
            .fixedSize(horizontal: false, vertical: true)
            .background(Color.white.opacity(0.97))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Layout.essayModalCornerRadius,
                    style: .continuous
                )
            )
            .shadow(color: Color.black.opacity(0.12), radius: 28, x: 0, y: 18)
            .padding(.horizontal, Layout.essayScreenHorizontalPadding)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
        .onChange(of: isLoading) { _, newValue in
            isLoadingCircleActive = newValue
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            RoundedRectangle(
                cornerRadius: Layout.essayModalIconCornerRadius,
                style: .continuous
            )
            .fill(AppColors.primaryBlue.opacity(0.10))
            .frame(
                width: Layout.essayModalIconBoxSize,
                height: Layout.essayModalIconBoxSize
            )
            .overlay {
                Image(systemName: icon)
                    .font(.system(size: Layout.essayModalIconSize, weight: .semibold))
                    .foregroundColor(AppColors.primaryBlue)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: Layout.essayModalTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)

                Text(usageText)
                    .font(.system(size: Layout.essayModalSubtitleSize, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer(minLength: 0)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: Layout.essayModalCloseIconSize, weight: .bold))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(
                        width: Layout.essayModalCloseButtonSize,
                        height: Layout.essayModalCloseButtonSize
                    )
                    .background(AppColors.primaryBlue.opacity(0.06))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var languagePicker: some View {
        HStack(spacing: 10) {
            languagePill(
                title: "From",
                language: selectedSourceLanguage,
                isMenu: true
            )

            Image(systemName: "arrow.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppColors.textSecondary)

            languagePill(
                title: "To",
                language: selectedTargetLanguage,
                isMenu: false
            )
        }
    }

    private func languagePill(
        title: String,
        language: GrammarLanguage,
        isMenu: Bool
    ) -> some View {
        Group {
            if isMenu {
                Menu {
                    ForEach(sourceLanguages) { item in
                        Button(item.title) {
                            onSelectSourceLanguage(item)
                        }
                    }
                } label: {
                    pillContent(
                        title: title,
                        language: language,
                        showsChevron: true
                    )
                }
            } else {
                pillContent(
                    title: title,
                    language: language,
                    showsChevron: false
                )
            }
        }
    }

    private func pillContent(
        title: String,
        language: GrammarLanguage,
        showsChevron: Bool
    ) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)

                Text(language.title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)
            }

            Spacer(minLength: 0)

            Text(language.shortTitle)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlue)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(AppColors.primaryBlue.opacity(0.08))
                .clipShape(Capsule())

            if showsChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(AppColors.primaryBlue.opacity(0.05))
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
    }

    private var input: some View {
        RoundedRectangle(
            cornerRadius: Layout.essayModalInputCornerRadius,
            style: .continuous
        )
        .fill(Color.white.opacity(0.96))
        .overlay {
            RoundedRectangle(
                cornerRadius: Layout.essayModalInputCornerRadius,
                style: .continuous
            )
            .strokeBorder(
                AppColors.primaryBlue.opacity(0.10),
                lineWidth: 1
            )
        }
        .overlay {
            TextField(placeholder, text: $inputText, axis: .vertical)
                .font(.system(
                    size: Layout.essayModalInputTextSize,
                    weight: .semibold,
                    design: .rounded
                ))
                .foregroundColor(AppColors.primaryBlueDark)
                .padding(.horizontal, Layout.essayModalInputHorizontalPadding)
                .padding(.vertical, Layout.essayModalInputVerticalPadding)
                .lineLimit(1...3)
        }
        .frame(minHeight: 58)
        .compositingGroup()
    }

    @ViewBuilder
    private var resultContent: some View {
        Group {
            if isLoading {
                loadingCard
                    .id("loading")
            } else if let resultMessage {
                messageCard(resultMessage)
                    .id("message-\(resultMessage)")
            } else if !resultItems.isEmpty {
                resultsList
                    .id("results-\(resultItems.map(\.result).joined(separator: "-"))")
            }
        }
        .animation(.easeInOut(duration: 0.16), value: isLoading)
        .animation(.easeInOut(duration: 0.16), value: resultMessage)
        .animation(.easeInOut(duration: 0.16), value: resultItems)
    }

    private var loadingCard: some View {
        HStack(spacing: 12) {
            loadingCircle

            Text(type == .translate ? "Translating..." : "Searching...")
                .font(.system(size: Layout.essayModalMessageTextSize, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.essayModalResultPadding)
        .background(AppColors.primaryBlue.opacity(0.06))
        .clipShape(
            RoundedRectangle(
                cornerRadius: Layout.essayModalResultCornerRadius,
                style: .continuous
            )
        )
        .transition(.opacity)
    }

    private var loadingCircle: some View {
        Circle()
            .trim(from: 0.14, to: 0.86)
            .stroke(
                AppColors.primaryBlue.opacity(0.85),
                style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            .frame(width: 22, height: 22)
            .rotationEffect(.degrees(isLoadingCircleActive ? 360 : 0))
            .animation(
                isLoadingCircleActive
                ? .linear(duration: 0.72).repeatForever(autoreverses: false)
                : .default,
                value: isLoadingCircleActive
            )
            .onAppear {
                isLoadingCircleActive = true
            }
            .onDisappear {
                isLoadingCircleActive = false
            }
    }

    private func messageCard(_ message: String) -> some View {
        Text(message)
            .font(.system(size: Layout.essayModalMessageTextSize, weight: .semibold, design: .rounded))
            .foregroundColor(AppColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Layout.essayModalResultPadding)
            .background(AppColors.primaryBlue.opacity(0.06))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Layout.essayModalResultCornerRadius,
                    style: .continuous
                )
            )
            .transition(.opacity)
    }

    private var resultsList: some View {
        ScrollView {
            VStack(spacing: Layout.essayModalResultSpacing) {
                ForEach(resultItems) { item in
                    resultRow(item)
                }
            }
            .padding(.vertical, 1)
        }
        .scrollIndicators(.hidden)
        .clipped()
        .background(Color.clear)
        .frame(maxHeight: resultsMaxHeight)
        .transaction { transaction in
            transaction.animation = nil
        }
    }

    private func resultRow(_ item: EssayAssistanceItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.result)
                .font(.system(size: Layout.essayModalResultTitleSize, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .lineLimit(2)
                .minimumScaleFactor(0.85)

            if let detail = item.detail {
                Text(detail)
                    .font(.system(size: Layout.essayModalResultDetailSize, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.essayModalResultPadding)
        .background(AppColors.primaryBlue.opacity(0.07))
        .clipShape(
            RoundedRectangle(
                cornerRadius: Layout.essayModalResultCornerRadius,
                style: .continuous
            )
        )
        .drawingGroup()
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button(action: onClose) {
                Text("Close")
                    .font(.system(size: Layout.essayButtonTextSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Layout.essayButtonVerticalPadding)
                    .background(AppColors.primaryBlue.opacity(0.08))
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: Layout.essayButtonCornerRadius,
                            style: .continuous
                        )
                    )
            }
            .buttonStyle(.plain)

            Button(action: onSubmit) {
                Text(buttonTitle)
                    .font(.system(size: Layout.essayButtonTextSize, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Layout.essayButtonVerticalPadding)
                    .background(
                        isLoading
                        ? AppColors.primaryBlue.opacity(0.55)
                        : AppColors.primaryBlue
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: Layout.essayButtonCornerRadius,
                            style: .continuous
                        )
                    )
            }
            .disabled(isLoading)
            .buttonStyle(.plain)
        }
    }
}

#Preview("Translate") {
    EssayAssistanceModalView(
        type: .translate,
        inputText: .constant("Hello"),
        selectedTargetLanguage: .french,
        selectedSourceLanguage: .english,
        sourceLanguages: [.english, .spanish, .german],
        resultItems: [
            EssayAssistanceItem(word: "Hello", result: "Bonjour")
        ],
        resultMessage: nil,
        usageText: "Hints: 0  ·  Translations: 1  ·  Synonyms: 0",
        isLoading: false,
        onSelectSourceLanguage: { _ in },
        onSubmit: {},
        onClose: {}
    )
}

#Preview("Synonyms") {
    EssayAssistanceModalView(
        type: .synonym,
        inputText: .constant("feo"),
        selectedTargetLanguage: .english,
        selectedSourceLanguage: .spanish,
        sourceLanguages: [.spanish, .french, .german],
        resultItems: [
            EssayAssistanceItem(word: "feo", result: "ugly"),
            EssayAssistanceItem(word: "feo", result: "unattractive"),
            EssayAssistanceItem(word: "feo", result: "unpleasant")
        ],
        resultMessage: nil,
        usageText: "Hints: 0  ·  Translations: 0  ·  Synonyms: 1",
        isLoading: false,
        onSelectSourceLanguage: { _ in },
        onSubmit: {},
        onClose: {}
    )
}
