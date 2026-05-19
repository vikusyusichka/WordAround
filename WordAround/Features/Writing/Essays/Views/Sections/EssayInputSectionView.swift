import SwiftUI

struct EssayInputSectionView: View {
    @Binding var essayText: String
    @FocusState.Binding var isEditorFocused: Bool

    let wordCount: Int
    let validationState: EssayPracticeViewModel.ValidationState
    let isLoading: Bool
    let canCheckGrammar: Bool
    let hintsLeft: Int
    let translateLeft: Int
    let synonymLeft: Int
    let canUseHint: Bool
    let canUseTranslation: Bool
    let canUseSynonym: Bool
    let assistanceUsageText: String
    let shownHintItems: [EssaySetHintItem]
    let selectedSetHintItems: [EssaySetHintItem]
    let onRemoveSetHint: (EssaySetHintItem) -> Void
    let onHint: () -> Void
    let onTranslate: () -> Void
    let onSynonym: () -> Void
    let onSets: () -> Void
    let onReset: () -> Void
    let onCheckGrammar: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.essayWritingCardSpacing) {
            header

            EssayHelperToolbarView(
                hintsLeft: hintsLeft,
                translateLeft: translateLeft,
                synonymLeft: synonymLeft,
                canUseHint: canUseHint,
                canUseTranslation: canUseTranslation,
                canUseSynonym: canUseSynonym,
                assistanceUsageText: assistanceUsageText,
                onHint: onHint,
                onTranslate: onTranslate,
                onSynonym: onSynonym,
                setsCount: selectedSetHintItems.count,
                onSets: onSets
            )

            hintItems
            setHintItems
            editor
            validationMessage
            actionButtons
        }
        .padding(Layout.essayCardPadding)
        .background(Color.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: Layout.essayCardCornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 9)
        .animation(.easeInOut(duration: 0.2), value: validationState)
        .animation(.easeInOut(duration: 0.2), value: shownHintItems)
    }

    private var header: some View {
        HStack {
            Text("Your essay")
                .font(.system(size: Layout.essayWritingTitleSize, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)

            Spacer()

            Text("\(wordCount) words")
                .font(.system(size: Layout.essayWordCountSize, weight: .bold, design: .rounded))
                .foregroundColor(wordCountTint)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(wordCountTint.opacity(0.08))
                .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private var hintItems: some View {
        if !shownHintItems.isEmpty {
            VStack(alignment: .leading, spacing: Layout.essayHintListSpacing) {
                ForEach(shownHintItems) { item in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 8) {
                            Text(item.word)
                                .font(.system(size: Layout.essayHintWordSize, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.primaryBlueDark)

                            Text(item.translation)
                                .font(.system(size: Layout.essayHintTranslationSize, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.primaryBlue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.primaryBlue.opacity(0.08))
                                .clipShape(Capsule())
                        }

                        if let example = item.example,
                           !example.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(example)
                                .font(.system(size: Layout.essayHintExampleSize, weight: .medium, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                                .lineSpacing(3)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Layout.essayHintItemPadding)
                    .background(Color.white.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: Layout.essayHintItemCornerRadius, style: .continuous))
                }
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    @ViewBuilder
    private var setHintItems: some View {
        if !selectedSetHintItems.isEmpty {
            VStack(alignment: .leading, spacing: Layout.essayHintListSpacing) {
                ForEach(selectedSetHintItems) { item in
                    HStack(spacing: 8) {
                        Text("\(item.word) — \(item.translation)")
                            .font(.system(size: Layout.essayHintTranslationSize, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.primaryBlueDark)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)

                        Spacer(minLength: 8)

                        Button {
                            onRemoveSetHint(item)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(AppColors.primaryBlue)
                                .frame(width: 22, height: 22)
                                .background(AppColors.primaryBlue.opacity(0.08))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(Color.white.opacity(0.82))
                    .clipShape(RoundedRectangle(cornerRadius: Layout.essayHintItemCornerRadius, style: .continuous))
                }
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: Layout.essayEditorCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.essayEditorCornerRadius, style: .continuous)
                        .stroke(
                            isEditorFocused ? AppColors.primaryBlue.opacity(0.28) : Color.clear,
                            lineWidth: 2
                        )
                )
                .shadow(
                    color: Color.black.opacity(isEditorFocused ? 0.08 : 0.045),
                    radius: isEditorFocused ? 18 : 14,
                    x: 0,
                    y: 8
                )

            if essayText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Write your essay here...")
                    .font(.system(size: Layout.essayEditorPlaceholderSize, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary.opacity(0.65))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 17)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $essayText)
                .font(.system(size: Layout.essayEditorTextSize, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .lineSpacing(4)
                .padding(12)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .focused($isEditorFocused)
        }
        .frame(minHeight: Layout.essayEditorMinHeight)
        .scaleEffect(isEditorFocused ? Layout.essayEditorScaleFocused : 1.0)
        .animation(.easeInOut(duration: 0.18), value: isEditorFocused)
    }

    @ViewBuilder
    private var validationMessage: some View {
        if let message = validationState.message,
           validationState != .empty {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 13, weight: .semibold))

                Text(message)
                    .font(.system(size: Layout.essayValidationTextSize, weight: .semibold, design: .rounded))
            }
            .foregroundColor(wordCountTint)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button {
                onReset()
            } label: {
                Text("Reset")
                    .font(.system(size: Layout.essayButtonTextSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Layout.essayButtonVerticalPadding)
                    .background(AppColors.primaryBlue.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: Layout.essayButtonCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                onCheckGrammar()
            } label: {
                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 14, weight: .semibold))
                    }

                    Text(isLoading ? "Checking" : "Check grammar")
                }
                .font(.system(size: Layout.essayButtonTextSize, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Layout.essayButtonVerticalPadding)
                .background(canCheckGrammar ? AppColors.primaryBlue : AppColors.primaryBlue.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: Layout.essayButtonCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canCheckGrammar)
        }
    }

    private var wordCountTint: Color {
        switch validationState {
        case .valid:
            return AppColors.primaryBlue
        case .empty:
            return AppColors.textSecondary
        case .belowMinimum, .aboveMaximum:
            return Color(red: 0.78, green: 0.55, blue: 0.26)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var text = ""
        @FocusState private var isFocused: Bool

        var body: some View {
            EssayInputSectionView(
                essayText: $text,
                isEditorFocused: $isFocused,
                wordCount: 0,
                validationState: .empty,
                isLoading: false,
                canCheckGrammar: false,
                hintsLeft: 7,
                translateLeft: 5,
                synonymLeft: 3,
                canUseHint: true,
                canUseTranslation: true,
                canUseSynonym: true,
                assistanceUsageText: "Hints: 0  ·  Translations: 0  ·  Synonyms: 0  ·  Sets: 0",
                shownHintItems: [],
                selectedSetHintItems: [],
                onRemoveSetHint: { _ in },
                onHint: {},
                onTranslate: {},
                onSynonym: {},
                onSets: {},
                onReset: {},
                onCheckGrammar: {}
            )
            .padding()
            .background(AppColors.appBackground)
        }
    }

    return PreviewWrapper()
}
