import SwiftUI

struct GrammarNoteQuizView: View {
    @ObservedObject var quizVM: GrammarNoteQuizViewModel
    let onFinish: () -> Void
    let onBack: () -> Void

    @State private var currentInput = ""
    @State private var hasSubmitted = false

    private var question: GrammarQuizQuestion? { quizVM.currentQuestion }
    private var totalCount: Int { quizVM.activeQuiz?.questions.count ?? 0 }
    private var progress: Double {
        totalCount > 0 ? Double(quizVM.currentQuestionIndex + 1) / Double(totalCount) : 0
    }

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                quizHeader
                progressBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if let q = question {
                            questionCard(q)
                            answerArea(q)
                            if hasSubmitted {
                                resultFeedback(q)
                                nextButton
                            } else {
                                submitButton
                            }
                        }
                    }
                    .padding(.horizontal, Layout.grammarNoteHorizontalPadding)
                    .padding(.top, 20)
                    .padding(.bottom, 34)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onChange(of: quizVM.currentQuestionIndex) { _, _ in
            currentInput = ""
            hasSubmitted = false
        }
    }

    private var quizHeader: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(quizVM.activeQuiz?.title ?? L10n.string("quizGenericTitle"))
                    .font(.system(size: Layout.value(pad: 18, phone: 15), weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .lineLimit(1)
                Text(String(format: L10n.string("quizQuestionOfFmt"), quizVM.currentQuestionIndex + 1, totalCount))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, Layout.grammarNoteHorizontalPadding)
        .padding(.top, Layout.grammarNoteTopPadding)
        .padding(.bottom, 10)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.primaryBlue.opacity(0.14))
                    .frame(height: 5)
                Capsule()
                    .fill(AppColors.primaryBlue)
                    .frame(width: geo.size.width * progress, height: 5)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: 5)
        .padding(.horizontal, Layout.grammarNoteHorizontalPadding)
        .padding(.bottom, 12)
    }

    private func questionCard(_ q: GrammarQuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: q.type.systemImage)
                    .font(.system(size: 12, weight: .bold))
                Text(q.type.title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(AppColors.primaryBlue)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppColors.primaryBlue.opacity(0.10))
            .clipShape(Capsule())

            Text(q.questionText)
                .font(.system(size: Layout.value(pad: 18, phone: 16), weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: Layout.grammarNoteBlockCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.grammarNoteBlockCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.76), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 7)
    }

    @ViewBuilder
    private func answerArea(_ q: GrammarQuizQuestion) -> some View {
        switch q.type {
        case .multipleChoice:
            multipleChoiceArea(q)
        case .trueFalse:
            trueFalseArea(q)
        case .fillGap, .shortAnswer:
            textInputArea(q)
        }
    }

    private func multipleChoiceArea(_ q: GrammarQuizQuestion) -> some View {
        VStack(spacing: 10) {
            ForEach(q.options, id: \.self) { option in
                optionCard(option, question: q)
            }
        }
    }

    private func optionCard(_ option: String, question: GrammarQuizQuestion) -> some View {
        let isSelected = currentInput == option
        let submitted = hasSubmitted
        let isCorrect = option == question.correctAnswer
        let isWrong = submitted && isSelected && !isCorrect

        return Button {
            if !submitted {
                currentInput = option
                submitAnswer(question)
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(optionCircleColor(isSelected: isSelected, submitted: submitted, isCorrect: isCorrect))
                        .frame(width: 26, height: 26)
                    if submitted && isCorrect {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.white)
                    } else if isWrong {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.white)
                    }
                }

                Text(option)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(optionBackground(isSelected: isSelected, submitted: submitted, isCorrect: isCorrect))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(optionBorder(isSelected: isSelected, submitted: submitted, isCorrect: isCorrect), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(submitted)
    }

    private func optionCircleColor(isSelected: Bool, submitted: Bool, isCorrect: Bool) -> Color {
        if submitted && isCorrect { return .green }
        if submitted && isSelected && !isCorrect { return CreateSetTheme.red.accent }
        if isSelected { return AppColors.primaryBlue }
        return AppColors.primaryBlue.opacity(0.10)
    }

    private func optionBackground(isSelected: Bool, submitted: Bool, isCorrect: Bool) -> Color {
        if submitted && isCorrect { return .green.opacity(0.08) }
        if submitted && isSelected && !isCorrect { return CreateSetTheme.red.accent.opacity(0.08) }
        if isSelected { return AppColors.primaryBlue.opacity(0.08) }
        return Color.white.opacity(0.92)
    }

    private func optionBorder(isSelected: Bool, submitted: Bool, isCorrect: Bool) -> Color {
        if submitted && isCorrect { return .green.opacity(0.4) }
        if submitted && isSelected && !isCorrect { return CreateSetTheme.red.accent.opacity(0.4) }
        if isSelected { return AppColors.primaryBlue.opacity(0.4) }
        return Color.white.opacity(0.72)
    }

    private func trueFalseArea(_ q: GrammarQuizQuestion) -> some View {
        HStack(spacing: 12) {
            ForEach(["True", "False"], id: \.self) { val in
                tfButton(val, question: q)
            }
        }
    }

    private func tfButton(_ value: String, question: GrammarQuizQuestion) -> some View {
        let isSelected = currentInput == value
        let submitted = hasSubmitted
        let isCorrect = value == question.correctAnswer
        let isWrong = submitted && isSelected && !isCorrect

        let bgColor: Color = {
            if submitted && isCorrect { return .green.opacity(0.12) }
            if isWrong { return CreateSetTheme.red.accent.opacity(0.12) }
            if isSelected { return AppColors.primaryBlue.opacity(0.12) }
            return Color.white.opacity(0.92)
        }()
        let fgColor: Color = {
            if submitted && isCorrect { return .green }
            if isWrong { return CreateSetTheme.red.accent }
            if isSelected { return AppColors.primaryBlue }
            return AppColors.primaryBlueDark
        }()

        return Button {
            if !submitted {
                currentInput = value
                submitAnswer(question)
            }
        } label: {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(fgColor)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(bgColor)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(submitted)
    }

    private func textInputArea(_ q: GrammarQuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(
                L10n.string(q.type == .fillGap ? "quizPhFillGap" : "quizPhShortAnswer"),
                text: $currentInput,
                axis: .vertical
            )
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .lineLimit(q.type == .shortAnswer ? 4 : 1)
            .padding(14)
            .background(Color.white.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppColors.primaryBlue.opacity(0.20), lineWidth: 1)
            )
            .disabled(hasSubmitted)
        }
    }

    @ViewBuilder
    private func resultFeedback(_ q: GrammarQuizQuestion) -> some View {
        let answer = quizVM.sessionAnswers[q.id] ?? ""
        let isCorrect = answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            == q.correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(isCorrect ? Color.green : CreateSetTheme.red.accent)
                Text(L10n.string(isCorrect ? "quizFeedbackCorrect" : "quizFeedbackIncorrect"))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(isCorrect ? Color.green : CreateSetTheme.red.accent)
            }

            if !isCorrect {
                HStack(alignment: .top, spacing: 6) {
                    Text(L10n.string("quizCorrectAnswerLabel"))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                    Text(q.correctAnswer)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.primaryBlueDark)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let explanation = q.explanation, !explanation.isEmpty {
                Text(explanation)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isCorrect ? Color.green.opacity(0.07) : CreateSetTheme.red.accent.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var submitButton: some View {
        Button {
            if let q = question { submitAnswer(q) }
        } label: {
            Text(L10n.string("quizSubmitButton"))
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(canSubmit ? AppColors.primaryBlue : AppColors.primaryBlue.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
    }

    private var canSubmit: Bool {
        !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !hasSubmitted
    }

    private var nextButton: some View {
        Button {
            if quizVM.isLastQuestion {
                quizVM.finishQuiz()
                onFinish()
            } else {
                quizVM.nextQuestion()
            }
        } label: {
            HStack(spacing: 8) {
                Text(L10n.string(quizVM.isLastQuestion ? "quizFinishButton" : "quizNextButton"))
                Image(systemName: quizVM.isLastQuestion ? "flag.fill" : "chevron.right")
            }
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(AppColors.primaryBlue)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func submitAnswer(_ q: GrammarQuizQuestion) {
        let answer = currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !answer.isEmpty else { return }
        quizVM.submitAnswer(answer)
        withAnimation(.easeInOut(duration: 0.2)) {
            hasSubmitted = true
        }
    }
}

#Preview {
    struct Wrapper: View {
        @StateObject private var vm = GrammarNoteQuizViewModel(
            ownerUID: "prev", topicId: "prev", noteId: "prev",
            service: MockGrammarNoteQuizService(quizzes: [.preview()])
        )
        var body: some View {
            NavigationStack {
                GrammarNoteQuizView(quizVM: vm, onFinish: {}, onBack: {})
            }
            .onAppear { vm.startQuiz(.preview()) }
        }
    }
    return Wrapper()
}
