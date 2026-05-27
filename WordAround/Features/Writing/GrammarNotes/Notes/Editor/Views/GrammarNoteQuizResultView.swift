import SwiftUI

struct GrammarNoteQuizResultView: View {
    @ObservedObject var quizVM: GrammarNoteQuizViewModel
    let onTryAgain: () -> Void
    let onReviewNote: () -> Void
    let onDismiss: () -> Void

    private var score: Int { quizVM.scorePercentage }
    private var correct: Int { quizVM.correctCount }
    private var total: Int { quizVM.activeQuiz?.questions.count ?? 0 }
    private var answered: [GrammarQuizQuestion] { quizVM.answeredQuestions }
    private var incorrectAnswers: [GrammarQuizQuestion] { answered.filter { !$0.isCorrect } }
    private var correctAnswers: [GrammarQuizQuestion] { answered.filter { $0.isCorrect } }

    private var scoreGrade: (label: String, color: Color) {
        switch score {
        case 90...100: return ("Excellent!", .green)
        case 70..<90:  return ("Good job!", AppColors.primaryBlue)
        case 50..<70:  return ("Keep practicing", Color.orange)
        default:       return ("Review the note", CreateSetTheme.red.accent)
        }
    }

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    scoreCard
                    if !incorrectAnswers.isEmpty { incorrectSection }
                    if !correctAnswers.isEmpty { correctSection }
                    actionButtons
                }
                .padding(.horizontal, Layout.grammarNoteHorizontalPadding)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Score card

    private var scoreCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(scoreGrade.color.opacity(0.14), lineWidth: 8)
                    .frame(width: 110, height: 110)
                Circle()
                    .trim(from: 0, to: Double(score) / 100)
                    .stroke(scoreGrade.color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 110, height: 110)
                    .animation(.easeInOut(duration: 0.8), value: score)

                VStack(spacing: 2) {
                    Text("\(score)%")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(scoreGrade.color)
                    Text("\(correct)/\(total)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            VStack(spacing: 4) {
                Text(scoreGrade.label)
                    .font(.system(size: Layout.value(pad: 22, phone: 18), weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                Text("\(correct) of \(total) questions answered correctly")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: Layout.grammarNoteBlockCornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 7)
    }

    // MARK: - Incorrect

    private var incorrectSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Incorrect", systemImage: "xmark.circle.fill", color: CreateSetTheme.red.accent)
            VStack(spacing: 8) {
                ForEach(incorrectAnswers) { q in
                    resultRow(question: q, isCorrect: false)
                }
            }
        }
    }

    // MARK: - Correct

    private var correctSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Correct", systemImage: "checkmark.circle.fill", color: .green)
            VStack(spacing: 8) {
                ForEach(correctAnswers) { q in
                    resultRow(question: q, isCorrect: true)
                }
            }
        }
    }

    private func sectionHeader(_ title: String, systemImage: String, color: Color) -> some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .textCase(.uppercase)
                .tracking(0.6)
        }
    }

    private func resultRow(question: GrammarQuizQuestion, isCorrect: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question.questionText)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(2)

            if !isCorrect {
                VStack(alignment: .leading, spacing: 4) {
                    if let userAnswer = question.userAnswer, !userAnswer.isEmpty {
                        answerPill("Your answer: \(userAnswer)", color: CreateSetTheme.red.accent)
                    }
                    answerPill("Correct: \(question.correctAnswer)", color: .green)
                }
            }

            if let explanation = question.explanation, !explanation.isEmpty {
                Text(explanation)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isCorrect ? Color.green.opacity(0.05) : CreateSetTheme.red.accent.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isCorrect ? Color.green.opacity(0.18) : CreateSetTheme.red.accent.opacity(0.18), lineWidth: 1)
        )
    }

    private func answerPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.10))
            .clipShape(Capsule())
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(action: onTryAgain) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Try Again")
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppColors.primaryBlue)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: onReviewNote) {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text")
                    Text("Review Note")
                }
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlue)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppColors.primaryBlue.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: onDismiss) {
                Text("Done")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
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
                GrammarNoteQuizResultView(quizVM: vm, onTryAgain: {}, onReviewNote: {}, onDismiss: {})
            }
            .onAppear {
                vm.startQuiz(.preview())
                vm.submitAnswer("ser")
                vm.nextQuestion()
                vm.submitAnswer("True")
                vm.nextQuestion()
                vm.submitAnswer("está")
                vm.finishQuiz()
            }
        }
    }
    return Wrapper()
}
