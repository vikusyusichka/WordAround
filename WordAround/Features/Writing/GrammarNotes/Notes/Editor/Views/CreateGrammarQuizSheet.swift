import SwiftUI

struct CreateGrammarQuizSheet: View {
    let note: GrammarNote
    let blocks: [GrammarNoteBlock]
    let onCreated: () -> Void
    let onCancel: () -> Void

    // MARK: - View model (owns Firebase calls + generators)
    @StateObject private var quizVM: GrammarNoteQuizViewModel

    // MARK: - Form state
    @State private var title = ""
    @State private var mode: GrammarQuizCreationMode = .smartLocal
    @State private var questionCount = 5
    @State private var selectedTypes: Set<GrammarQuizQuestionType> = [.multipleChoice, .shortAnswer, .fillGap]
    @State private var focusInstructions: String = ""
    @State private var hasAppeared = false
    @Namespace private var modePickerNamespace

    // Local-mode preview state
    @State private var previewQuestions: [GrammarQuizQuestion] = []
    @State private var hasPreviewed = false
    @State private var previewError: String?
    @State private var isPreviewing = false

    // Manual-mode state
    @State private var manualQuestions: [GrammarQuizQuestion] = []
    @State private var isAddingQuestion = false

    private let counts = [3, 5, 10]
    private let aiConfigured: Bool

    // MARK: - Init

    /// `@MainActor` because the `aiConfigured` default reads from
    /// `GrammarQuizAIConfiguration.isConfigured`, which is MainActor
    /// (it pokes Apple Intelligence availability). SwiftUI Views are
    /// already MainActor in practice — the annotation just makes it
    /// explicit for Swift 6 strict concurrency.
    @MainActor
    init(
        note: GrammarNote,
        blocks: [GrammarNoteBlock],
        onCreated: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        service: GrammarNoteQuizServicing = GrammarNoteQuizService(),
        aiConfigured: Bool? = nil
    ) {
        self.note = note
        self.blocks = blocks
        self.onCreated = onCreated
        self.onCancel = onCancel
        self.aiConfigured = aiConfigured ?? MainActor.assumeIsolated {
            GrammarQuizAIConfiguration.isConfigured
        }
        _quizVM = StateObject(
            wrappedValue: GrammarNoteQuizViewModel(
                ownerUID: note.ownerUID,
                topicId: note.topicId,
                noteId: note.id,
                service: service
            )
        )
    }

    // MARK: - Derived

    private var allowedTypesArray: [GrammarQuizQuestionType] {
        GrammarQuizQuestionType.allCases.filter { selectedTypes.contains($0) }
    }

    private var canSubmit: Bool {
        if quizVM.createState.isBusy { return false }
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return false }
        switch mode {
        case .manual:      return !manualQuestions.isEmpty
        // Require a generated preview before save so the user always sees
        // the exact questions that will be persisted (Preview → Save flow).
        case .smartLocal:  return !selectedTypes.isEmpty && hasPreviewed && !previewQuestions.isEmpty
        case .aiGenerated: return !selectedTypes.isEmpty
        }
    }

    private var errorMessage: String? {
        quizVM.createState.errorMessage ?? previewError
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.appBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 17) {
                        sheetHeader
                            .transition(.move(edge: .top).combined(with: .opacity))

                        titleSection
                            .transition(.move(edge: .top).combined(with: .opacity))

                        modeSection
                            .transition(.move(edge: .top).combined(with: .opacity))

                        modeContent
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                            .id(mode)

                        if let error = errorMessage {
                            errorBanner(error)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            if mode == .aiGenerated && shouldOfferLocalFallback {
                                useLocalFallbackButton
                                    .transition(.scale(scale: 0.96).combined(with: .opacity))
                            }
                        }

                        submitButton
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .padding(.horizontal, Layout.grammarNoteHorizontalPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 34)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 10)
                    .animation(.spring(response: 0.42, dampingFraction: 0.86), value: hasAppeared)
                    .animation(.spring(response: 0.36, dampingFraction: 0.88), value: mode)
                    .animation(.easeInOut(duration: 0.18), value: errorMessage)
                }
            }
            .sheet(isPresented: $isAddingQuestion) {
                AddManualQuizQuestionSheet(order: manualQuestions.count) { question in
                    manualQuestions.append(question)
                    isAddingQuestion = false
                } onCancel: {
                    isAddingQuestion = false
                }
            }
        }
        .onAppear {
            if title.isEmpty {
                title = "Quiz: \(note.title)"
            }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.88)) {
                hasAppeared = true
            }
        }
        .onChange(of: mode) { _, _ in
            // Reset transient state when switching modes so stale errors
            // from another mode never leak.
            previewError = nil
            hasPreviewed = false
            previewQuestions = []
            quizVM.resetCreateState()
        }
    }


    // MARK: - Header

    private var sheetHeader: some View {
        HStack {
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 18)
                    .frame(height: 44)
                    .background(AppColors.primaryBlue)
                    .clipShape(Capsule())
                    .shadow(color: AppColors.primaryBlue.opacity(0.20), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(QuizScaleButtonStyle())
            .disabled(quizVM.createState.isBusy)
            .opacity(quizVM.createState.isBusy ? 0.55 : 1)

            Spacer()

            Text("Create Quiz")
                .font(.system(size: 21, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlue)

            Spacer()

            Button(action: submit) {
                Text("Add")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 24)
                    .frame(height: 44)
                    .background(canSubmit ? AppColors.primaryBlue : AppColors.primaryBlue.opacity(0.45))
                    .clipShape(Capsule())
                    .shadow(color: canSubmit ? AppColors.primaryBlue.opacity(0.20) : Color.clear, radius: 10, x: 0, y: 5)
            }
            .buttonStyle(QuizScaleButtonStyle())
            .disabled(!canSubmit)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Quiz Title")
            TextField("e.g. Quick Review", text: $title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .padding(.horizontal, 14)
                .frame(height: 48)
                .foregroundStyle(AppColors.primaryBlueDark)
                .tint(AppColors.primaryBlue)
                .background(Color.white.opacity(0.96))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppColors.primaryBlue.opacity(0.06), lineWidth: 0.8)
                )
                .shadow(color: AppColors.primaryBlue.opacity(0.04), radius: 12, x: 0, y: 6)
        }
    }

    // MARK: - Mode

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Creation Mode")
            customModePicker

            HStack(spacing: 10) {
                Image(systemName: mode.iconName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppColors.primaryBlue)
                    .frame(width: 30, height: 30)
                    .background(AppColors.primaryBlue.opacity(0.12))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryBlueDark)
                    Text(mode.subtitle)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppColors.primaryBlue.opacity(0.05), lineWidth: 0.8)
            )
        }
    }


    private var customModePicker: some View {
        HStack(spacing: 0) {
            ForEach(GrammarQuizCreationMode.allCases) { item in
                let isSelected = mode == item
                Button {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.84)) {
                        mode = item
                    }
                } label: {
                    ZStack {
                        if isSelected {
                            Capsule()
                                .fill(AppColors.primaryBlue)
                                .matchedGeometryEffect(id: "selectedQuizMode", in: modePickerNamespace)
                                .shadow(color: AppColors.primaryBlue.opacity(0.18), radius: 8, x: 0, y: 4)
                        }

                        Text(item.shortTitle)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(isSelected ? Color.white : AppColors.primaryBlueDark)
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(QuizScaleButtonStyle(scale: 0.985))
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(AppColors.primaryBlue.opacity(0.055))
                .overlay(
                    Capsule()
                        .stroke(AppColors.primaryBlue.opacity(0.12), lineWidth: 0.65)
                )
        )
    }

    // MARK: - Per-mode content

    @ViewBuilder
    private var modeContent: some View {
        switch mode {
        case .manual:      manualSection
        case .smartLocal:  localConfigSection
        case .aiGenerated: aiConfigSection
        }
    }

    // MARK: - Smart Local

    private var localConfigSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            questionCountField
            questionTypesField
            Text("Questions are generated locally from this note's content blocks. If the note is too short, AI fills in the gaps automatically.")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Task { await generatePreview() }
            } label: {
                HStack(spacing: 8) {
                    if isPreviewing {
                        ProgressView()
                            .tint(AppColors.primaryBlue)
                            .scaleEffect(0.85)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text(hasPreviewed ? "Regenerate Preview" : "Preview Questions")
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlue)
                .padding(.horizontal, 18)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity)
                .background(AppColors.primaryBlue.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(QuizScaleButtonStyle())
            .disabled(selectedTypes.isEmpty || isPreviewing)

            if hasPreviewed && !previewQuestions.isEmpty {
                previewQuestionsList
            }
        }
    }

    // MARK: - AI

    private var aiConfigSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            questionCountField
            questionTypesField

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("Focus (optional)")
                TextField("e.g. Focus on common mistakes", text: $focusInstructions, axis: .vertical)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .tint(AppColors.primaryBlue)
                    .lineLimit(3)
                    .padding(12)
                    .background(Color.white.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            // Subtle, low-key status hint — never the loudest element on the
            // screen. Pulls its copy from `GrammarQuizAIConfiguration` so the
            // backend-vs-on-device wording stays consistent across the app.
            HStack(alignment: .center, spacing: 6) {
                Image(systemName: aiConfigured ? "sparkles" : "info.circle")
                    .font(.system(size: 10, weight: .bold))
                Text(GrammarQuizAIConfiguration.statusDescription)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }
            .foregroundStyle(AppColors.textSecondary)
            .padding(.top, 2)
        }
    }

    // MARK: - Manual

    private var manualSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionLabel("Questions (\(manualQuestions.count))")
                Spacer()
                Button {
                    isAddingQuestion = true
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(AppColors.primaryBlue.opacity(0.10))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            if manualQuestions.isEmpty {
                Text("Tap Add to create your first question.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(manualQuestions.enumerated()), id: \.element.id) { index, q in
                        manualQuestionRow(index: index + 1, question: q)
                    }
                }
            }
        }
    }

    private func manualQuestionRow(index: Int, question: GrammarQuizQuestion) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.primaryBlue)
                .frame(width: 22, height: 22)
                .background(AppColors.primaryBlue.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(question.type.title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                Text(question.questionText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .lineLimit(2)
            }

            Spacer()

            Button {
                manualQuestions.removeAll { $0.id == question.id }
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(CreateSetTheme.red.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Shared count + type fields

    private var questionCountField: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Number of Questions")
            HStack(spacing: 10) {
                ForEach(counts, id: \.self) { n in
                    countButton(n)
                }
                Spacer()
            }
        }
    }

    private func countButton(_ n: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                questionCount = n
            }
        } label: {
            Text("\(n)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(questionCount == n ? Color.white : AppColors.primaryBlue)
                .frame(width: 52, height: 40)
                .background(questionCount == n ? AppColors.primaryBlue : AppColors.primaryBlue.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(QuizScaleButtonStyle())
    }

    private var questionTypesField: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Question Types")
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    typeToggle(.multipleChoice)
                    typeToggle(.trueFalse)
                }
                HStack(spacing: 8) {
                    typeToggle(.fillGap)
                    typeToggle(.shortAnswer)
                }
            }
        }
    }

    private func typeToggle(_ type: GrammarQuizQuestionType) -> some View {
        let isOn = selectedTypes.contains(type)
        return Button {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.84)) {
                if isOn {
                    if selectedTypes.count > 1 { selectedTypes.remove(type) }
                } else {
                    selectedTypes.insert(type)
                }
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14, weight: .bold))
                Text(type.title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(isOn ? AppColors.primaryBlue : AppColors.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(isOn ? AppColors.primaryBlue.opacity(0.10) : Color.white.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(QuizScaleButtonStyle())
    }

    // MARK: - Preview list (local mode)

    private var previewQuestionsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("Preview (\(previewQuestions.count))")
            VStack(spacing: 8) {
                ForEach(Array(previewQuestions.enumerated()), id: \.element.id) { index, q in
                    questionPreviewRow(index: index + 1, question: q)
                }
            }
        }
    }

    private func questionPreviewRow(index: Int, question: GrammarQuizQuestion) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.primaryBlue)
                .frame(width: 22, height: 22)
                .background(AppColors.primaryBlue.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: question.type.systemImage)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary)
                    Text(question.type.title)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                }
                Text(question.questionText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button {
            submit()
        } label: {
            ZStack {
                if quizVM.createState.isBusy {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(Color.white)
                            .scaleEffect(0.9)
                        Text(quizVM.createState == .saving ? "Saving…" : "Generating…")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white)
                    }
                } else {
                    Text(mode.ctaTitle)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(canSubmit ? AppColors.primaryBlue : AppColors.primaryBlue.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: canSubmit ? AppColors.primaryBlue.opacity(0.18) : Color.clear, radius: 12, x: 0, y: 6)
        }
        .buttonStyle(QuizScaleButtonStyle())
        .disabled(!canSubmit)
    }

    // MARK: - Error + fallback

    private var shouldOfferLocalFallback: Bool {
        guard let message = errorMessage else { return false }
        // Offer fallback for any AI error except "not configured" which
        // already has its own messaging.
        let lower = message.lowercased()
        return !lower.contains("not configured")
    }

    private var useLocalFallbackButton: some View {
        Button {
            mode = .smartLocal
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                Text("Use Smart Local Instead")
            }
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(AppColors.primaryBlue)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(AppColors.primaryBlue.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(CreateSetTheme.red.accent)
                .font(.system(size: 14, weight: .bold))
            Text(message)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CreateSetTheme.red.accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Actions

    /// Two-step preview generator. Does NOT save and does NOT touch
    /// Firestore. The user always sees a single "Generate Quiz" button —
    /// behind it we try the deterministic local generator first (zero
    /// network), and if it can't produce enough questions we silently
    /// fall back to the AI generator. Either way the user just sees a
    /// preview they can then save.
    private func generatePreview() async {
        guard !isPreviewing else { return }
        previewError = nil
        previewQuestions = []
        hasPreviewed = true
        isPreviewing = true
        defer { isPreviewing = false }
        quizVM.resetCreateState()

        // Step 1 — local first. Deterministic, fast, no network.
        do {
            previewQuestions = try GrammarQuizGenerator.generate(
                from: blocks,
                count: questionCount,
                types: selectedTypes
            )
            if !previewQuestions.isEmpty { return }
        } catch {
            #if DEBUG
            print("[QuizPreview] local failed, trying AI:", error)
            #endif
            // Fall through to AI fallback below.
        }

        // Step 2 — AI fallback. Triggered when the note has too little
        // content for the deterministic rules to produce a usable quiz.
        // We don't expose the mode switch to the user; this is silent.
        let aiGen = AIGrammarQuizQuestionGenerator()
        do {
            let aiQuestions = try await aiGen.generateQuestions(
                from: note,
                questionCount: questionCount,
                allowedTypes: allowedTypesArray,
                focusInstructions: focusInstructions
            )
            if aiQuestions.isEmpty {
                previewError = "Couldn't build a quiz from this note. Add more content (rules, examples, or a comparison)."
            } else {
                previewQuestions = aiQuestions
            }
        } catch {
            // Both generators failed — surface a single friendly error.
            // The local generator's message is more actionable so prefer it.
            previewError = "Couldn't build a quiz from this note. Add a rule, an example, or a few more sentences and try again."
            #if DEBUG
            print("[QuizPreview] AI fallback also failed:", error)
            #endif
        }
    }

    private func submit() {
        previewError = nil
        // Smart Local now persists exactly what the user saw in the preview.
        // We pass the previewed questions through the `manualQuestions` path
        // so the VM skips the generator and validates/saves the same array.
        let effectiveMode: GrammarQuizCreationMode
        let effectiveManualQuestions: [GrammarQuizQuestion]
        if mode == .smartLocal, hasPreviewed, !previewQuestions.isEmpty {
            effectiveMode = .manual
            effectiveManualQuestions = previewQuestions
        } else {
            effectiveMode = mode
            effectiveManualQuestions = manualQuestions
        }

        Task {
            let savedQuiz = await quizVM.createQuiz(
                title: title,
                note: note,
                mode: effectiveMode,
                questionCount: questionCount,
                allowedTypes: allowedTypesArray,
                manualQuestions: effectiveManualQuestions,
                focusInstructions: focusInstructions
            )
            if savedQuiz != nil {
                onCreated()
            }
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .black, design: .rounded))
            .foregroundStyle(AppColors.textSecondary)
            .textCase(.uppercase)
            .tracking(0.6)
    }
}

// MARK: - Press animation

private struct QuizScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.18, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

// MARK: - Add Manual Question Sheet

private struct AddManualQuizQuestionSheet: View {
    let order: Int
    let onAdd: (GrammarQuizQuestion) -> Void
    let onCancel: () -> Void

    @State private var type: GrammarQuizQuestionType = .shortAnswer
    @State private var questionText = ""
    @State private var option1 = ""
    @State private var option2 = ""
    @State private var option3 = ""
    @State private var option4 = ""
    @State private var correctAnswer = ""
    @State private var explanation = ""
    @State private var tfAnswer = "True"
    @State private var didAttemptSubmit = false
    @FocusState private var focusedField: ManualQuestionField?

    private enum ManualQuestionField: Hashable {
        case question, option(Int), correctAnswer, explanation
    }

    private var canAdd: Bool { validationError == nil }

    /// Inline validation message tailored to the current question type.
    /// `nil` means the form is valid. Only surfaces after the user taps Add.
    private var validationError: String? {
        let trimmedQuestion = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedQuestion.isEmpty { return "Question text is required." }

        switch type {
        case .multipleChoice:
            let opts = [option1, option2, option3, option4]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if opts.count < 2 {
                return "Multiple choice needs at least 2 options."
            }
            let trimmedAnswer = correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedAnswer.isEmpty {
                return "Pick the correct answer."
            }
            if !opts.contains(where: { $0.caseInsensitiveCompare(trimmedAnswer) == .orderedSame }) {
                return "Correct answer must match one of the options."
            }
        case .trueFalse:
            // tfAnswer always carries True / False, never empty.
            break
        case .fillGap:
            if !trimmedQuestion.contains("_") {
                return "Add a blank (e.g. _____) inside the question."
            }
            if correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "Enter the missing word."
            }
        case .shortAnswer:
            if correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "Enter the correct answer."
            }
        }
        return nil
    }

    private var effectiveCorrectAnswer: String {
        switch type {
        case .trueFalse:    return tfAnswer
        case .multipleChoice, .fillGap, .shortAnswer: return correctAnswer
        }
    }

    private var options: [String] {
        switch type {
        case .multipleChoice:
            return [option1, option2, option3, option4].map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }.filter { !$0.isEmpty }
        case .trueFalse:
            return ["True", "False"]
        case .fillGap, .shortAnswer:
            return []
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.appBackground.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        typePicker
                        questionTextField
                        if type == .multipleChoice { optionFields }
                        if type == .trueFalse { tfPicker }
                        if type != .trueFalse { correctAnswerField }
                        explanationField
                        if didAttemptSubmit, let message = validationError {
                            validationBanner(message)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    .animation(.easeInOut(duration: 0.18), value: didAttemptSubmit)
                    .animation(.easeInOut(duration: 0.18), value: type)
                }
                // Interactive keyboard dismissal stops the suggestion bar
                // from floating over inputs while the user scrolls the form.
                .scrollDismissesKeyboard(.interactively)
            }
            .safeAreaInset(edge: .top) {
                manualQuestionHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
                    .background(AppColors.appBackground)
            }
            // Keyboard accessory: gives the user a one-tap way to dismiss
            // the keyboard so the autocomplete strip never blocks the
            // explanation field at the bottom of the form.
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
            }
        }
        .presentationDetents([.large])
        .onChange(of: type) { _, _ in
            // Switching type retires the previous validation surface so the
            // user is not shown stale "missing option" errors after they
            // moved to e.g. short-answer mode.
            didAttemptSubmit = false
        }
    }

    private func validationBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 12, weight: .bold))
            Text(message)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .foregroundStyle(CreateSetTheme.red.accent)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CreateSetTheme.red.accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }


    private var manualQuestionHeader: some View {
        HStack {
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 18)
                    .frame(height: 42)
                    .background(AppColors.primaryBlue)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Add Question")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlue)

            Spacer()

            Button {
                didAttemptSubmit = true
                guard validationError == nil else { return }
                let q = GrammarQuizQuestion(
                    type: type,
                    questionText: questionText.trimmingCharacters(in: .whitespacesAndNewlines),
                    options: options,
                    correctAnswer: effectiveCorrectAnswer.trimmingCharacters(in: .whitespacesAndNewlines),
                    explanation: explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : explanation,
                    order: order
                )
                onAdd(q)
            } label: {
                Text("Add")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 24)
                    .frame(height: 42)
                    .background(AppColors.primaryBlue)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("Question Type")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(GrammarQuizQuestionType.allCases) { t in
                        Button { type = t } label: {
                            Label(t.title, systemImage: t.systemImage)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(type == t ? Color.white : AppColors.primaryBlue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(type == t ? AppColors.primaryBlue : AppColors.primaryBlue.opacity(0.10))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var questionTextField: some View {
        VStack(alignment: .leading, spacing: 6) {
            label("Question")
            TextField(placeholderFor(type), text: $questionText, axis: .vertical)
                .focused($focusedField, equals: .question)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .tint(AppColors.primaryBlue)
                .lineLimit(3...6)
                .padding(12)
                .background(Color.white.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            if type == .fillGap {
                Text("Use ___ inside the sentence to mark the blank.")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }

    private var optionFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("Options (up to 4)")
            ForEach(0..<4, id: \.self) { i in
                let binding = [
                    $option1, $option2, $option3, $option4
                ][i]
                TextField("Option \(i + 1)", text: binding)
                    .focused($focusedField, equals: .option(i))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .tint(AppColors.primaryBlue)
                    .padding(.horizontal, 12)
                    .frame(height: 44)
                    .background(Color.white.opacity(0.92))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var tfPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("Correct Answer")
            HStack(spacing: 10) {
                ForEach(["True", "False"], id: \.self) { val in
                    Button { tfAnswer = val } label: {
                        Text(val)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(tfAnswer == val ? Color.white : AppColors.primaryBlueDark)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(tfAnswer == val ? AppColors.primaryBlue : Color.white.opacity(0.92))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var correctAnswerField: some View {
        VStack(alignment: .leading, spacing: 8) {
            label(correctAnswerLabel)
            TextField(correctAnswerPlaceholder, text: $correctAnswer)
                .focused($focusedField, equals: .correctAnswer)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .tint(AppColors.primaryBlue)
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(Color.white.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var correctAnswerLabel: String {
        switch type {
        case .multipleChoice: return "Correct Option"
        case .fillGap:        return "Missing Word"
        case .shortAnswer:    return "Correct Answer"
        case .trueFalse:      return "Correct Answer"
        }
    }

    private var correctAnswerPlaceholder: String {
        switch type {
        case .multipleChoice: return "Must match one of the options"
        case .fillGap:        return "The word that fills the blank"
        case .shortAnswer:    return "Enter the correct answer"
        case .trueFalse:      return "True / False"
        }
    }

    private var explanationField: some View {
        VStack(alignment: .leading, spacing: 8) {
            label("Explanation (optional)")
            TextField("Why is this the correct answer?", text: $explanation, axis: .vertical)
                .focused($focusedField, equals: .explanation)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .tint(AppColors.primaryBlue)
                .lineLimit(2...4)
                .padding(12)
                .background(Color.white.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .black, design: .rounded))
            .foregroundStyle(AppColors.textSecondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }

    private func placeholderFor(_ t: GrammarQuizQuestionType) -> String {
        switch t {
        case .fillGap:        return "e.g. Fill in the gap: She _____ to school."
        case .shortAnswer:    return "e.g. Explain when to use 'ser'."
        case .multipleChoice: return "e.g. Which verb describes permanent states?"
        case .trueFalse:      return "e.g. Estar is used for temporary conditions."
        }
    }
}

// MARK: - Previews

#Preview("Create Quiz – Smart Local") {
    CreateGrammarQuizSheet(
        note: .preview(),
        blocks: [
            GrammarNoteBlock(type: .rule, text: "Use ser for identity and permanent traits.", secondaryText: "Ser + noun/adjective", order: 0),
            GrammarNoteBlock(type: .example, text: "Soy estudiante.", secondaryText: "Estoy cansado.", order: 1),
            GrammarNoteBlock(type: .warning, text: "Don't use estar to describe nationality.", order: 2)
        ],
        onCreated: {},
        onCancel: {},
        service: MockGrammarNoteQuizService(),
        aiConfigured: false
    )
}

#Preview("Create Quiz – Manual") {
    CreateGrammarQuizSheet(
        note: .preview(),
        blocks: [],
        onCreated: {},
        onCancel: {},
        service: MockGrammarNoteQuizService(),
        aiConfigured: false
    )
}

#Preview("Create Quiz – AI") {
    CreateGrammarQuizSheet(
        note: .preview(),
        blocks: [
            GrammarNoteBlock(type: .rule, text: "Use ser for identity and permanent traits.", order: 0),
            GrammarNoteBlock(type: .example, text: "Soy estudiante.", order: 1)
        ],
        onCreated: {},
        onCancel: {},
        service: MockGrammarNoteQuizService(),
        aiConfigured: false
    )
}

#Preview("Add Manual Question") {
    AddManualQuizQuestionSheet(order: 0, onAdd: { _ in }, onCancel: {})
}
