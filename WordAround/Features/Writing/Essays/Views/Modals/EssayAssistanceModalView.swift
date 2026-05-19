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
        case .hint:
            return "Writing hint"
        case .translate:
            return "Translate"
        case .synonym:
            return "Synonyms"
        }
    }

    private var buttonTitle: String {
        switch type {
        case .hint:
            return isLoading ? "Generating..." : "Generate hint"
        case .translate:
            return isLoading ? "Translating..." : "Translate"
        case .synonym:
            return isLoading ? "Searching..." : "Find synonyms"
        }
    }

    private var placeholder: String {
        switch type {
        case .hint:
            return ""
        case .translate:
            return "Enter a word or short phrase"
        case .synonym:
            return "Enter a word"
        }
    }

    private var icon: String {
        switch type {
        case .hint:
            return "lightbulb.fill"
        case .translate:
            return "character.book.closed.fill"
        case .synonym:
            return "textformat.abc.dottedunderline"
        }
    }

    private var modalMaxWidth: CGFloat {
        switch type {
        case .hint, .translate:
            return Layout.isPadLike ? Layout.essayModalDefaultMaxWidthPad : Layout.essayModalDefaultMaxWidthPhone
        case .synonym:
            return Layout.isPadLike ? Layout.essayModalSynonymMaxWidthPad : Layout.essayModalSynonymMaxWidthPhone
        }
    }

    private var resultsMaxHeight: CGFloat {
        Layout.isPadLike
        ? Layout.essayModalSynonymResultsMaxHeightPad
        : Layout.essayModalSynonymResultsMaxHeightPhone
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

                if type != .hint {
                    languagePicker
                    input
                }

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
        HStack(spacing: Layout.essayModalHeaderSpacing) {
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

            VStack(alignment: .leading, spacing: Layout.essayModalTitleSpacing) {
                Text(title)
                    .font(.system(size: Layout.essayModalTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)

                Text(usageText)
                    .font(.system(size: Layout.essayModalSubtitleSize, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(Layout.essayModalUsageTextLineLimit)
                    .minimumScaleFactor(Layout.essayModalUsageTextScale)
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
        HStack(spacing: Layout.essayModalLanguagePickerSpacing) {
            languagePill(
                title: "From",
                language: selectedSourceLanguage,
                isMenu: true
            )

            Image(systemName: "arrow.right")
                .font(.system(size: Layout.essayModalLanguageArrowSize, weight: .bold))
                .foregroundColor(AppColors.textSecondary)
                .frame(width: Layout.essayModalLanguageArrowWidth)

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
                    pillContent(title: title, language: language, showsChevron: true)
                }
            } else {
                pillContent(title: title, language: language, showsChevron: false)
            }
        }
    }

    private func pillContent(
        title: String,
        language: GrammarLanguage,
        showsChevron: Bool
    ) -> some View {
        HStack(spacing: Layout.essayModalLanguagePillSpacing) {
            VStack(alignment: .leading, spacing: Layout.essayModalLanguagePillTextSpacing) {
                Text(title)
                    .font(.system(size: Layout.essayModalLanguagePillTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)

                Text(language.title)
                    .font(.system(size: Layout.essayModalLanguagePillTextSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)
                    .lineLimit(1)
                    .minimumScaleFactor(Layout.essayModalLanguageTextScale)
                    .allowsTightening(true)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(2)

            Spacer(minLength: Layout.essayModalLanguagePillSpacerMinLength)

            Text(language.shortTitle)
                .font(.system(size: Layout.essayModalLanguagePillCodeSize, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlue)
                .padding(.horizontal, Layout.essayModalLanguagePillCodeHorizontalPadding)
                .padding(.vertical, Layout.essayModalLanguagePillCodeVerticalPadding)
                .background(AppColors.primaryBlue.opacity(0.08))
                .clipShape(Capsule())
                .layoutPriority(1)

            if showsChevron {
                Image(systemName: "chevron.down")
                    .font(.system(size: Layout.essayModalLanguagePillChevronSize, weight: .bold))
                    .foregroundColor(AppColors.textSecondary)
                    .layoutPriority(0)
            }
        }
        .padding(.horizontal, Layout.essayModalLanguagePillHorizontalPadding)
        .padding(.vertical, Layout.essayModalLanguagePillVerticalPadding)
        .frame(maxWidth: .infinity, minHeight: Layout.essayModalLanguagePillMinHeight)
        .background(AppColors.primaryBlue.opacity(0.05))
        .clipShape(
            RoundedRectangle(
                cornerRadius: Layout.essayModalLanguagePillCornerRadius,
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
                lineWidth: Layout.essayModalInputBorderWidth
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
                .lineLimit(Layout.essayModalInputMinLines...Layout.essayModalInputMaxLines)
        }
        .frame(minHeight: Layout.essayModalInputMinHeight)
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
        .clipped()
        .animation(.easeInOut(duration: Layout.essayModalResultAnimationDuration), value: isLoading)
        .animation(.easeInOut(duration: Layout.essayModalResultAnimationDuration), value: resultMessage)
        .animation(.easeInOut(duration: Layout.essayModalResultAnimationDuration), value: resultItems)
    }

    private var loadingCard: some View {
        HStack(spacing: Layout.essayModalLoadingSpacing) {
            loadingCircle

            Text(loadingText)
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

    private var loadingText: String {
        switch type {
        case .hint:
            return "Generating hint..."
        case .translate:
            return "Translating..."
        case .synonym:
            return "Searching..."
        }
    }

    private var loadingCircle: some View {
        Circle()
            .trim(
                from: Layout.essayModalLoadingCircleTrimStart,
                to: Layout.essayModalLoadingCircleTrimEnd
            )
            .stroke(
                AppColors.primaryBlue.opacity(0.85),
                style: StrokeStyle(
                    lineWidth: Layout.essayModalLoadingCircleLineWidth,
                    lineCap: .round
                )
            )
            .frame(
                width: Layout.essayModalLoadingCircleSize,
                height: Layout.essayModalLoadingCircleSize
            )
            .rotationEffect(.degrees(isLoadingCircleActive ? 360 : 0))
            .animation(
                isLoadingCircleActive
                ? .linear(duration: Layout.essayModalLoadingCircleDuration).repeatForever(autoreverses: false)
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
        Group {
            if type == .synonym {
                ScrollView {
                    resultRows
                }
                .frame(height: resultsMaxHeight)
                .scrollIndicators(.hidden)
                .clipped()
            } else {
                resultRows
            }
        }
        .background(Color.clear)
        .transaction { transaction in
            transaction.animation = nil
        }
    }

    private var resultRows: some View {
        VStack(spacing: Layout.essayModalResultSpacing) {
            ForEach(resultItems) { item in
                resultRow(item)
            }
        }
        .padding(.vertical, Layout.essayModalResultListVerticalPadding)
    }

    private func resultRow(_ item: EssayAssistanceItem) -> some View {
        VStack(alignment: .leading, spacing: Layout.essayModalResultRowSpacing) {
            Text(item.result)
                .font(.system(size: Layout.essayModalResultTitleSize, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .lineLimit(Layout.essayModalResultTitleLineLimit)
                .minimumScaleFactor(Layout.essayModalResultTitleScale)

            if let detail = item.detail {
                Text(detail)
                    .font(.system(size: Layout.essayModalResultDetailSize, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(Layout.essayModalResultDetailLineSpacing)
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
        HStack(spacing: Layout.essayModalActionsSpacing) {
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

            if type != .hint {
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
}
