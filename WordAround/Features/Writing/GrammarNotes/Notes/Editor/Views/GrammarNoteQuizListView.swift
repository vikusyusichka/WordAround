import SwiftUI

struct GrammarNoteQuizListView: View {
    let note: GrammarNote
    let ownerUID: String
    let allowsCreation: Bool
    let onAllDeleted: () -> Void
    let onDismiss: () -> Void

    @StateObject private var quizVM: GrammarNoteQuizViewModel
    @State private var screen: Screen = .list
    @State private var isCreateSheetPresented = false
    @State private var deleteTarget: GrammarNoteQuiz?

    enum Screen { case list, taking, result }

    init(
        note: GrammarNote,
        ownerUID: String,
        allowsCreation: Bool = true,
        onAllDeleted: @escaping () -> Void = {},
        onDismiss: @escaping () -> Void
    ) {
        self.note = note
        self.ownerUID = ownerUID
        self.allowsCreation = allowsCreation
        self.onAllDeleted = onAllDeleted
        self.onDismiss = onDismiss
        _quizVM = StateObject(
            wrappedValue: GrammarNoteQuizViewModel(
                ownerUID: ownerUID,
                topicId: note.topicId,
                noteId: note.id
            )
        )
    }

    var body: some View {
        ZStack {
            switch screen {
            case .list:
                NavigationStack {
                    listScreen
                        .sheet(isPresented: $isCreateSheetPresented) {
                            CreateGrammarQuizSheet(
                                note: note,
                                blocks: note.contentBlocks,
                                onCreated: {
                                    isCreateSheetPresented = false
                                    Task { await quizVM.loadQuizzes() }
                                },
                                onCancel: { isCreateSheetPresented = false }
                            )
                        }
                }

            case .taking:
                NavigationStack {
                    GrammarNoteQuizView(
                        quizVM: quizVM,
                        onFinish: { withAnimation { screen = .result } },
                        onBack: {
                            quizVM.clearSession()
                            withAnimation { screen = .list }
                        }
                    )
                }
                .transition(.move(edge: .trailing))

            case .result:
                NavigationStack {
                    GrammarNoteQuizResultView(
                        quizVM: quizVM,
                        onTryAgain: {
                            quizVM.resetSession()
                            withAnimation { screen = .taking }
                        },
                        onReviewNote: { onDismiss() },
                        onDismiss: {
                            quizVM.clearSession()
                            withAnimation { screen = .list }
                        }
                    )
                }
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.26), value: screen)
        .task { await quizVM.loadQuizzes() }
        .onChange(of: quizVM.quizzes) { _, quizzes in
            if quizzes.isEmpty && quizVM.hasLoaded { onAllDeleted() }
        }
    }

    private var listScreen: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                modalHeader
                    .padding(.horizontal, Layout.grammarNoteHorizontalPadding)
                    .padding(.top, 18)

                listContent
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var modalHeader: some View {
        HStack(spacing: 12) {
            headerButton(title: "Done", systemImage: nil, action: onDismiss)

            Spacer()

            Text("Quizzes")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlue)
                .lineLimit(1)

            Spacer()

            if allowsCreation {
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                        isCreateSheetPresented = true
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .frame(width: 56, height: 56)
                        .background(AppColors.primaryBlue)
                        .clipShape(Circle())
                        .shadow(color: AppColors.primaryBlue.opacity(0.18), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(ScaleButtonStyle())
            } else {
                Color.clear.frame(width: 56, height: 56)
            }
        }
    }

    private func headerButton(title: String, systemImage: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 7) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 18)
            .frame(height: 48)
            .background(AppColors.primaryBlue)
            .clipShape(Capsule())
            .shadow(color: AppColors.primaryBlue.opacity(0.16), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    @ViewBuilder
    private var listContent: some View {
        if quizVM.isLoading {
            loadingState
        } else if let error = quizVM.listError {
            errorState(error)
        } else if quizVM.quizzes.isEmpty {
            emptyState
        } else {
            quizList
        }
    }

    private var quizList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                noteInfoBanner
                ForEach(quizVM.quizzes) { quiz in
                    quizCard(quiz)
                        .transition(.scale(scale: 0.98).combined(with: .opacity))
                }
            }
            .padding(.horizontal, Layout.grammarNoteHorizontalPadding)
            .padding(.bottom, 34)
        }
    }

    private var noteInfoBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: note.noteType.systemImage)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(note.noteType.tintColor)
            Text(note.title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(note.noteType.tintColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func quizCard(_ quiz: GrammarNoteQuiz) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppColors.primaryBlue.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(AppColors.primaryBlue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(quiz.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryBlueDark)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        metaPill("\(quiz.questions.count) questions", systemImage: "list.bullet")
                        metaPill(relativeDate(quiz.updatedAt), systemImage: "clock")
                    }
                }

                Spacer()

                Button {
                    deleteTarget = quiz
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(CreateSetTheme.red.accent)
                        .frame(width: 34, height: 34)
                        .background(CreateSetTheme.red.accent.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(ScaleButtonStyle())
            }

            Button {
                startQuiz(quiz)
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "play.fill")
                    Text("Start Quiz")
                }
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(AppColors.primaryBlue)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: AppColors.primaryBlue.opacity(0.14), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(16)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: Layout.grammarNoteCardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.grammarNoteCardCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.76), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 7)
        .confirmationDialog(
            "Delete \"\(quiz.title)\"?",
            isPresented: Binding(
                get: { deleteTarget?.id == quiz.id },
                set: { if !$0 { deleteTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task { await quizVM.deleteQuiz(quiz) }
                deleteTarget = nil
            }
            Button("Cancel", role: .cancel) { deleteTarget = nil }
        }
    }

    private func metaPill(_ text: String, systemImage: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage).font(.system(size: 9, weight: .bold))
            Text(text).lineLimit(1)
        }
        .font(.system(size: 10, weight: .bold, design: .rounded))
        .foregroundStyle(AppColors.textSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.72))
        .clipShape(Capsule())
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(AppColors.primaryBlue)
                .scaleEffect(1.1)
            Text("Loading quizzes…")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryBlue.opacity(0.10))
                    .frame(width: 72, height: 72)
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(AppColors.primaryBlue)
            }
            Text("No quizzes yet")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
            Text("Create a quiz from this note to start practising.")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if allowsCreation {
                Button { isCreateSheetPresented = true } label: {
                    Text("Create Quiz")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 22)
                        .frame(height: 44)
                        .background(AppColors.primaryBlue)
                        .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(CreateSetTheme.red.accent)
            Text(message)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                Task { await quizVM.loadQuizzes() }
            } label: {
                Text("Retry")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 20)
                    .frame(height: 40)
                    .background(AppColors.primaryBlue)
                    .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func startQuiz(_ quiz: GrammarNoteQuiz) {
        guard !quiz.questions.isEmpty else { return }
        quizVM.startQuiz(quiz)
        withAnimation { screen = .taking }
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview("Quiz List") {
    GrammarNoteQuizListView(
        note: .preview(hasQuiz: true),
        ownerUID: "preview-user",
        onDismiss: {}
    )
}
