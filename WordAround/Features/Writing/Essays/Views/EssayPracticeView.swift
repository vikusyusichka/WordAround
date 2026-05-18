import SwiftUI

struct EssayPracticeView: View {
    @StateObject private var viewModel = EssayPracticeViewModel()
    @FocusState private var isEditorFocused: Bool

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Layout.essayMainSpacing) {
                EssayTopicCardView(
                    topic: viewModel.currentTopic,
                    onRefresh: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.selectRandomTopic()
                        }
                    }
                )

                configurationSection

                writingArea

                EssayFeedbackSectionView(
                    state: viewModel.feedbackState,
                    issues: viewModel.grammarIssues,
                    onRetry: {
                        await viewModel.retryGrammarCheck()
                    }
                )
            }
            .frame(maxWidth: Layout.essayContentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Layout.essayScreenHorizontalPadding)
            .padding(.vertical, Layout.essayScreenVerticalPadding)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(AppColors.appBackground.ignoresSafeArea())
        .navigationTitle("Essay Practice")
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            isEditorFocused = false
        }
    }

    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: isPadLike ? 12 : 10) {
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars.inverse")
                    .font(.system(size: isPadLike ? 15 : 13, weight: .semibold))
                    .foregroundColor(AppColors.primaryBlue)

                Text("Writing setup")
                    .font(.system(size: isPadLike ? 16 : 15, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)

                Spacer(minLength: 0)

                Text("Hints left: \(viewModel.hintsLeft)")
                    .font(.system(size: isPadLike ? 12 : 11, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppColors.primaryBlue.opacity(0.08))
                    .clipShape(Capsule())
            }

            if isPadLike {
                HStack(alignment: .top, spacing: 12) {
                    LanguageSelectorView(
                        selectedLanguage: viewModel.selectedLanguage,
                        onSelect: { language in
                            viewModel.selectLanguage(language)
                        }
                    )

                    DifficultySelectorView(
                        selectedDifficulty: viewModel.selectedDifficulty,
                        onSelect: { difficulty in
                            viewModel.selectDifficulty(difficulty)
                        }
                    )
                }
            } else {
                VStack(spacing: 10) {
                    LanguageSelectorView(
                        selectedLanguage: viewModel.selectedLanguage,
                        onSelect: { language in
                            viewModel.selectLanguage(language)
                        }
                    )

                    DifficultySelectorView(
                        selectedDifficulty: viewModel.selectedDifficulty,
                        onSelect: { difficulty in
                            viewModel.selectDifficulty(difficulty)
                        }
                    )
                }
            }

            Text(viewModel.privacyNoticeText)
                .font(.system(size: isPadLike ? 12 : 11, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(3)
                .padding(.top, 2)
        }
        .padding(Layout.essayCardPadding)
        .background(Color.white.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: Layout.essayCardCornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.035), radius: 14, x: 0, y: 8)
    }

    private var writingArea: some View {
        VStack(alignment: .leading, spacing: Layout.essayWritingCardSpacing) {
            HStack {
                Text("Your essay")
                    .font(.system(size: Layout.essayWritingTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)

                Spacer()

                Text("\(viewModel.wordCount) words")
                    .font(.system(size: Layout.essayWordCountSize, weight: .bold, design: .rounded))
                    .foregroundColor(wordCountTint)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(wordCountTint.opacity(0.08))
                    .clipShape(Capsule())
            }

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

                if viewModel.essayText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Write your essay here...")
                        .font(.system(size: Layout.essayEditorPlaceholderSize, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary.opacity(0.65))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 17)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $viewModel.essayText)
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

            if let message = viewModel.validationState.message,
               viewModel.validationState != .empty {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 13, weight: .semibold))

                    Text(message)
                        .font(.system(size: Layout.essayValidationTextSize, weight: .semibold, design: .rounded))
                }
                .foregroundColor(wordCountTint)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            HStack(spacing: 10) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.resetEssay()
                        isEditorFocused = false
                    }
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
                    isEditorFocused = false

                    Task {
                        await viewModel.checkGrammar()
                    }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14, weight: .semibold))
                        }

                        Text(viewModel.isLoading ? "Checking" : "Check grammar")
                    }
                    .font(.system(size: Layout.essayButtonTextSize, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Layout.essayButtonVerticalPadding)
                    .background(
                        viewModel.canCheckGrammar
                        ? AppColors.primaryBlue
                        : AppColors.primaryBlue.opacity(0.35)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Layout.essayButtonCornerRadius, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canCheckGrammar)
            }
        }
        .padding(Layout.essayCardPadding)
        .background(Color.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: Layout.essayCardCornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 9)
        .animation(.easeInOut(duration: 0.2), value: viewModel.validationState)
    }

    private var wordCountTint: Color {
        switch viewModel.validationState {
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
    NavigationStack {
        EssayPracticeView()
    }
}
