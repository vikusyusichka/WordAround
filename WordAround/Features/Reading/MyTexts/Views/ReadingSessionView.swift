import SwiftUI

/// Active reading + question session for a saved My Texts entry.
struct ReadingSessionView: View {
    let userText: ReadingUserText
    var focus: ReadingFocus? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var generation = 0

    var body: some View {
        ReadingSessionContentView(
            userText: userText,
            focus: focus,
            onExit: { dismiss() },
            onRestart: { generation += 1 }
        )
        .id(generation)
    }
}

// MARK: - Session content

private struct ReadingSessionContentView: View {
    let userText: ReadingUserText
    let focus: ReadingFocus?
    let onExit: () -> Void
    let onRestart: () -> Void

    @StateObject private var viewModel: ReadingSessionViewModel

    private let accent = ReadingSetupConfig.myTexts.accent
    private let accentDark = ReadingSetupConfig.myTexts.accentDark

    init(userText: ReadingUserText, focus: ReadingFocus?, onExit: @escaping () -> Void, onRestart: @escaping () -> Void) {
        self.userText = userText
        self.focus = focus
        self.onExit = onExit
        self.onRestart = onRestart
        _viewModel = StateObject(wrappedValue: ReadingSessionViewModel(userText: userText, focus: focus))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingSetupHeaderView(
                        title: viewModel.session.title,
                        subtitle: "\(viewModel.session.language.title) • \(viewModel.session.level.title) • ~\(userText.estimatedReadingMinutes) min",
                        accent: accent,
                        accentDark: accentDark,
                        onBack: {
                            viewModel.onDisappear()
                            onExit()
                        }
                    )

                    timerAndProgress
                    sessionTextCard

                    if viewModel.currentPhase == .questions {
                        questionsSection
                    } else if viewModel.currentPhase == .reading && !viewModel.hasQuestions {
                        emptyQuestionsNotice
                    }

                    Spacer().frame(height: Layout.convSetupStartButtonHeight + 24)
                }
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }

            bottomBar
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.bottom, Layout.homeBottomBarBottomPadding)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .navigationDestination(isPresented: $viewModel.navigateToResult) {
            if let result = viewModel.result {
                ReadingResultView(
                    result: result,
                    title: viewModel.session.title,
                    onReadAgain: {
                        viewModel.navigateToResult = false
                        onRestart()
                    },
                    onBackToLibrary: onExit
                )
            }
        }
    }

    private var timerAndProgress: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(viewModel.formattedTime, systemImage: "clock.fill")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)
                Spacer()
                Text(viewModel.progressText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(accent.opacity(0.14))
                    Capsule()
                        .fill(LinearGradient(colors: [accent, accentDark], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(8, geo.size.width * viewModel.readingProgress))
                }
            }
            .frame(height: 8)
        }
        .padding(14)
        .background(cardBackground)
    }

    private var sessionTextCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Text")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(accent)

            Text(viewModel.session.content)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(accentDark)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(cardBackground)
    }

    @ViewBuilder
    private var questionsSection: some View {
        if let question = viewModel.currentQuestion {
            VStack(alignment: .leading, spacing: 12) {
                Text("Questions")
                    .font(.system(size: Layout.homeSectionTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)

                VStack(alignment: .leading, spacing: 10) {
                    Text(question.title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(accent)
                    Text(question.prompt)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(accentDark)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(cardBackground)

                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    answerOption(
                        label: optionLabel(index),
                        text: option,
                        isSelected: viewModel.selectedAnswer == option
                    ) {
                        viewModel.selectAnswer(option)
                    }
                }
            }
        }
    }

    private var emptyQuestionsNotice: some View {
        Text("This text is too short for generated questions. You can still finish the reading session.")
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundColor(AppColors.textSecondary)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
    }

    @ViewBuilder
    private var bottomBar: some View {
        switch viewModel.currentPhase {
        case .reading:
            ReadingPrimaryButton(
                title: viewModel.hasQuestions ? "Start Questions" : "Finish",
                icon: viewModel.hasQuestions ? "questionmark.circle.fill" : "checkmark",
                accent: accent,
                accentDark: accentDark
            ) {
                if viewModel.hasQuestions {
                    viewModel.startQuestions()
                } else {
                    viewModel.finishSession()
                }
            }
        case .questions:
            ReadingPrimaryButton(
                title: viewModel.isLastQuestion ? "Finish" : "Next",
                icon: viewModel.isLastQuestion ? "checkmark" : "arrow.right",
                accent: accent,
                accentDark: accentDark
            ) {
                guard viewModel.selectedAnswer != nil else { return }
                if viewModel.isLastQuestion {
                    viewModel.finishSession()
                } else {
                    viewModel.goToNextQuestion()
                }
            }
            .opacity(viewModel.selectedAnswer == nil ? 0.55 : 1)
            .disabled(viewModel.selectedAnswer == nil)
        case .completed:
            EmptyView()
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.94))
            .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    private func answerOption(label: String, text: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(label)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? .white : accent)
                    .frame(width: 32, height: 32)
                    .background(isSelected ? accent : accent.opacity(0.12))
                    .clipShape(Circle())

                Text(text)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(accentDark)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.94))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                    .stroke(isSelected ? accent : accent.opacity(0.14), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func optionLabel(_ index: Int) -> String {
        ["A", "B", "C", "D", "E", "F"][min(index, 5)]
    }
}

#Preview {
    NavigationStack {
        ReadingSessionView(userText: ReadingMyTextsPreviewData.mediumText)
    }
}
