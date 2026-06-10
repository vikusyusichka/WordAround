import SwiftUI

struct GrammarReviewSessionView: View {
    @ObservedObject var viewModel: GrammarReviewSessionViewModel
    let onDismiss: () -> Void
    var onOpenNote: ((GrammarNote) -> Void)? = nil

    @State private var currentInput = ""

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            if viewModel.isFinished {
                GrammarReviewSessionSummaryView(
                    totalReviewed: viewModel.totalReviewed,
                    correctCount: viewModel.correctAnswerCount,
                    incorrectCount: viewModel.incorrectCount,
                    forgotCount: viewModel.forgotCount,
                    hardCount: viewModel.hardCount,
                    goodCount: viewModel.goodCount,
                    easyCount: viewModel.easyCount,
                    onDone: onDismiss
                )
            } else if viewModel.isLoading {
                loadingState
            } else if let error = viewModel.sessionError {
                errorState(error)
            } else if let card = viewModel.currentCard {
                sessionContent(card)
            } else {
                loadingState
            }
        }
    }

    @ViewBuilder
    private func sessionContent(_ card: GrammarReviewSessionCard) -> some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)

            progressSection
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    switch viewModel.phase {
                    case .source:
                        sourcePhase(card)
                    case .question:
                        questionPhase(card)
                    case .result:
                        resultPhase(card)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 20)
            }
        }
        .onChange(of: viewModel.currentIndex) { _, _ in
            currentInput = ""
        }
        .onChange(of: viewModel.phase) { _, newPhase in
            if case .source = newPhase { currentInput = "" }
        }
    }

    private var header: some View {
        HStack {
            Button(action: onDismiss) {
                Text(L10n.string("commonClose"))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(Color.white.opacity(0.92))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            Text(L10n.string("commonReview"))
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)

            Spacer()

            Button {
                viewModel.skipCurrent()
            } label: {
                Text(L10n.string("commonSkip"))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlue)
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(AppColors.primaryBlue.opacity(0.10))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isRating)
            .opacity(viewModel.phase == .result ? 0 : 1)
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(String(format: L10n.string("spkItemOfFmt"), min(viewModel.currentIndex + 1, viewModel.totalCards), viewModel.totalCards))
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .textCase(.uppercase)
                    .tracking(0.6)
                Spacer()
                phaseBadge
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColors.primaryBlue.opacity(0.10))
                    Capsule()
                        .fill(AppColors.primaryBlue)
                        .frame(width: max(8, proxy.size.width * viewModel.progressFraction))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.progressFraction)
                }
            }
            .frame(height: 6)
        }
    }

    private var phaseBadge: some View {
        let (label, color): (String, Color) = {
            switch viewModel.phase {
            case .source:   return ("Study", AppColors.primaryBlue)
            case .question: return (L10n.string("notesQuizAnswer"), Color(red: 0.55, green: 0.35, blue: 0.85))
            case .result:   return ("Rate", CreateSetTheme.green.accent)
            }
        }()
        return Text(label)
            .font(.system(size: 10, weight: .black, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    @ViewBuilder
    private func sourcePhase(_ card: GrammarReviewSessionCard) -> some View {
        badgeRow(card)

        sourceCard(card)

        Button {
            viewModel.continueFromSource()
        } label: {
            HStack(spacing: 8) {
                Text(L10n.string("notesContinueToQuestion"))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(AppColors.primaryBlue)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .shadow(color: AppColors.primaryBlue.opacity(0.20), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }

    private func badgeRow(_ card: GrammarReviewSessionCard) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                badge(
                    text: card.sourcePool.title,
                    systemImage: card.sourcePool.systemImage,
                    tint: sourcePoolTint(card.sourcePool)
                )
                badge(
                    text: card.reviewItem.sourceType.title,
                    systemImage: card.reviewItem.sourceType.systemImage,
                    tint: sourceTint(card.reviewItem.sourceType)
                )
                Spacer(minLength: 0)
            }
            HStack(spacing: 8) {
                if !card.reviewItem.languageName.isEmpty {
                    badge(
                        text: card.reviewItem.languageName,
                        systemImage: "globe",
                        tint: AppColors.textSecondary
                    )
                }
                if let blockType = card.sourceBlockType {
                    badge(
                        text: blockType.title,
                        systemImage: blockType.systemImage,
                        tint: AppColors.primaryBlue.opacity(0.8)
                    )
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func sourcePoolTint(_ pool: GrammarReviewSourcePool) -> Color {
        switch pool {
        case .manual:         return AppColors.primaryBlue
        case .recentlyOpened: return CreateSetTheme.green.accent
        case .recentlyEdited: return Color(red: 0.85, green: 0.55, blue: 0.20)
        }
    }

    private func sourceCard(_ card: GrammarReviewSessionCard) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(card.displayTitle)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .fixedSize(horizontal: false, vertical: true)

            Divider().opacity(0.5)

            Text(card.sourceText)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark.opacity(0.85))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if let secondary = card.sourceSecondaryText, !secondary.isEmpty {
                Text(secondary)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }

            sourceCardFooter(card)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 8)
    }

    private func sourceCardFooter(_ card: GrammarReviewSessionCard) -> some View {
        HStack(spacing: 10) {
            if card.reviewItem.reviewCount > 0 {
                Label("\(card.reviewItem.reviewCount) review\(card.reviewItem.reviewCount == 1 ? "" : "s")", systemImage: "clock")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            }
            if card.reviewItem.correctStreak > 0 {
                Label("Streak \(card.reviewItem.correctStreak)", systemImage: "flame.fill")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(CreateSetTheme.green.accent)
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func questionPhase(_ card: GrammarReviewSessionCard) -> some View {
        let question = card.question
        questionCard(question)
        answerArea(question)

        if question.type != .multipleChoice && question.type != .trueFalse {
            submitButton(question)
        }
    }

    private func questionCard(_ question: GrammarQuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: question.type.systemImage)
                    .font(.system(size: 11, weight: .bold))
                Text(question.type.title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Color(red: 0.55, green: 0.35, blue: 0.85))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(red: 0.55, green: 0.35, blue: 0.85).opacity(0.10))
            .clipShape(Capsule())

            Text(question.questionText)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.76), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
    }

    @ViewBuilder
    private func answerArea(_ question: GrammarQuizQuestion) -> some View {
        switch question.type {
        case .multipleChoice:
            multipleChoiceArea(question)
        case .trueFalse:
            trueFalseArea(question)
        case .fillGap, .shortAnswer:
            textInputArea(question)
        }
    }

    private func multipleChoiceArea(_ question: GrammarQuizQuestion) -> some View {
        VStack(spacing: 10) {
            ForEach(question.options, id: \.self) { option in
                optionButton(option, question: question)
            }
        }
    }

    private func optionButton(_ option: String, question: GrammarQuizQuestion) -> some View {
        Button {
            currentInput = option
            viewModel.submitAnswer(option)
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .fill(AppColors.primaryBlue.opacity(0.12))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(AppColors.primaryBlue.opacity(0.25), lineWidth: 1)
                    )

                Text(option)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.72), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func trueFalseArea(_ question: GrammarQuizQuestion) -> some View {
        HStack(spacing: 12) {
            ForEach(["True", "False"], id: \.self) { value in
                Button {
                    currentInput = value
                    viewModel.submitAnswer(value)
                } label: {
                    Text(value)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryBlueDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.white.opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.72), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func textInputArea(_ question: GrammarQuizQuestion) -> some View {
        TextField(
            question.type == .fillGap ? L10n.string("notesTypeMissingWord") : L10n.string("notesTypeYourAnswer"),
            text: $currentInput,
            axis: .vertical
        )
        .font(.system(size: 15, weight: .semibold, design: .rounded))
        .foregroundStyle(AppColors.primaryBlueDark)
        .tint(AppColors.primaryBlue)
        .lineLimit(question.type == .shortAnswer ? 5 : 2)
        .padding(14)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(AppColors.primaryBlue.opacity(0.20), lineWidth: 1)
        )
    }

    private func submitButton(_ question: GrammarQuizQuestion) -> some View {
        let canSubmit = !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        return Button {
            viewModel.submitAnswer(currentInput)
        } label: {
            Text(question.type == .shortAnswer ? L10n.string("notesShowAnswer") : L10n.string("notesSubmitAnswer"))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(canSubmit ? AppColors.primaryBlue : AppColors.primaryBlue.opacity(0.40))
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
    }

    @ViewBuilder
    private func resultPhase(_ card: GrammarReviewSessionCard) -> some View {
        resultFeedbackCard(question: card.question, card: card)

        if let onOpenNote {
            openFullNoteButton(card: card, onOpenNote: onOpenNote)
        }

        ratingRow
    }

    private func openFullNoteButton(
        card: GrammarReviewSessionCard,
        onOpenNote: @escaping (GrammarNote) -> Void
    ) -> some View {
        Button {
            onOpenNote(card.note)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .font(.system(size: 12, weight: .bold))
                Text(L10n.string("notesOpenFullNote"))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .foregroundStyle(AppColors.primaryBlue)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(AppColors.primaryBlue.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func resultFeedbackCard(question: GrammarQuizQuestion, card: GrammarReviewSessionCard) -> some View {
        let isShortAnswer = question.type == .shortAnswer
        let isCorrect = viewModel.lastAnswerCorrect
        let userAnswer = viewModel.lastUserAnswer

        return VStack(alignment: .leading, spacing: 12) {
            if isShortAnswer {
                HStack(spacing: 8) {
                    Image(systemName: "text.magnifyingglass")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColors.primaryBlue)
                    Text(L10n.string("notesCompareAnswer"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryBlueDark)
                }

                if !userAnswer.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.string("notesYourAnswer"))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.textSecondary)
                        Text(userAnswer)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppColors.primaryBlueDark)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.string("notesReferenceAnswer"))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                    Text(question.correctAnswer)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.primaryBlueDark)
                        .fixedSize(horizontal: false, vertical: true)
                }

            } else {
                HStack(spacing: 8) {
                    Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(isCorrect ? CreateSetTheme.green.accent : CreateSetTheme.red.accent)
                    Text(isCorrect ? "Correct!" : "Incorrect")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(isCorrect ? CreateSetTheme.green.accent : CreateSetTheme.red.accent)
                }

                if !isCorrect {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.string("notesCorrectAnswerLabel"))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.textSecondary)
                        Text(question.correctAnswer)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppColors.primaryBlueDark)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if let explanation = question.explanation, !explanation.isEmpty {
                Divider().opacity(0.5)
                Text(explanation)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }

            Divider().opacity(0.5)

            Text(L10n.string("notesHowWellRecall"))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(resultBackground(isShortAnswer: isShortAnswer, isCorrect: isCorrect))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
    }

    private func resultBackground(isShortAnswer: Bool, isCorrect: Bool) -> Color {
        if isShortAnswer { return Color.white.opacity(0.92) }
        return isCorrect
            ? CreateSetTheme.green.accent.opacity(0.07)
            : CreateSetTheme.red.accent.opacity(0.07)
    }

    private var ratingRow: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ratingButton(.forgot, tint: CreateSetTheme.red.accent)
                ratingButton(.hard,   tint: Color(red: 0.85, green: 0.55, blue: 0.20))
            }
            HStack(spacing: 10) {
                ratingButton(.good, tint: AppColors.primaryBlue)
                ratingButton(.easy, tint: CreateSetTheme.green.accent)
            }
        }
        .opacity(viewModel.isRating ? 0.55 : 1)
        .animation(.easeInOut(duration: 0.18), value: viewModel.isRating)
    }

    private func ratingButton(_ result: GrammarReviewResult, tint: Color) -> some View {
        Button {
            Task { await viewModel.rate(result) }
        } label: {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: result.systemImage)
                        .font(.system(size: 12, weight: .bold))
                    Text(result.title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                Text(result.nextIntervalLabel)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .opacity(0.80)
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(tint)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isRating)
    }

    private func badge(text: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(tint.opacity(0.12))
        .clipShape(Capsule())
    }

    private func sourceTint(_ type: GrammarReviewSourceType) -> Color {
        switch type {
        case .note:    return AppColors.primaryBlue
        case .mistake: return CreateSetTheme.red.accent
        case .quiz:    return Color(red: 0.55, green: 0.35, blue: 0.85)
        }
    }

    private var loadingState: some View {
        VStack(spacing: 14) {
            ProgressView().tint(AppColors.primaryBlue).scaleEffect(1.1)
            Text(L10n.string("notesPreparingQueue"))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(CreateSetTheme.red.accent)
            Text(message)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button(action: onDismiss) {
                Text(L10n.string("commonClose"))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 20)
                    .frame(height: 44)
                    .background(AppColors.primaryBlue)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private extension GrammarReviewResult {
    var nextIntervalLabel: String {
        switch self {
        case .forgot: return "+4 hours"
        case .hard:   return "+1 day"
        case .good:   return "+3 days"
        case .easy:   return "+7 days"
        }
    }
}

#Preview("Loading state") {
    let vm = GrammarReviewSessionViewModel(
        ownerUID: "preview",
        reviewService: MockGrammarReviewService(items: [])
    )
    GrammarReviewSessionView(viewModel: vm, onDismiss: {})
}
