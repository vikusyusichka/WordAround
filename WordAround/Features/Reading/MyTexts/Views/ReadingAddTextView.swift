import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct ReadingAddTextView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ReadingAddTextViewModel()

    var onSavedAndStart: (ReadingUserText) -> Void = { _ in }

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showPDFImporter = false

    private let accent = ReadingMyTextsTheme.accent
    private let accentDark = ReadingMyTextsTheme.accentDark

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    header
                    statisticsRow
                    if let validation = viewModel.validationMessage {
                        messageBanner(validation, isError: true)
                    }
                    if let importError = viewModel.importErrorMessage {
                        messageBanner(importError, isError: true)
                    }
                    ReadingImportSourceSelector(
                        selection: $viewModel.importSourceTitle,
                        accent: accent,
                        accentDark: accentDark
                    )
                    importActions
                    titleField
                    textEditor
                    languageSection
                    difficultySection
                    ReadingReadingFocusSelector(
                        selection: $viewModel.readingFocusTitle,
                        accent: accent,
                        accentDark: accentDark
                    )
                    ReadingQuestionOptionsView(
                        enabledTypes: $viewModel.enabledQuestionTypes,
                        accent: accent,
                        accentDark: accentDark,
                        onToggle: { viewModel.toggleQuestionType($0) }
                    )
                    ReadingAssistanceOptionsView(
                        options: $viewModel.assistance,
                        sourceLanguage: viewModel.selectedLanguage,
                        accent: accent,
                        accentDark: accentDark
                    )
                    Spacer().frame(height: Layout.convSetupStartButtonHeight + 40)
                }
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
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
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task { await viewModel.importPhoto(item) }
        }
        .fileImporter(
            isPresented: $showPDFImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first { viewModel.importPDF(url: url) }
            case .failure:
                viewModel.importErrorMessage = "Import cancelled."
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraImagePicker { image in
                Task { await viewModel.importCameraImage(image) }
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            ReadingSetupHeaderView(
                title: "Add Text",
                subtitle: "Paste, import, generate, or explore texts",
                accent: accent,
                accentDark: accentDark,
                onBack: { dismiss() }
            )
            if let status = viewModel.saveStatusMessage {
                Text(status)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(accent)
            }
        }
    }

    private var statisticsRow: some View {
        HStack(spacing: 8) {
            ReadingMetadataChip(text: "\(viewModel.wordCount) words", accent: accent)
            ReadingMetadataChip(text: "\(viewModel.characterCount) chars", accent: accent)
            ReadingMetadataChip(text: "~\(viewModel.estimatedMinutes) min", accent: accent)
            if ReadingMyTextsDifficultyMode.from(title: viewModel.difficultyModeTitle) == .autoDetect {
                ReadingMetadataChip(text: viewModel.detectedLevel.title, accent: accent)
            }
        }
    }

    @ViewBuilder
    private var importActions: some View {
        switch viewModel.currentSource {
        case .pasteText:
            EmptyView()
        case .photo:
            HStack(spacing: 10) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    importButtonLabel("Photo Library", icon: "photo.on.rectangle")
                }
                .buttonStyle(.plain)
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button {
                        showCamera = true
                    } label: {
                        importButtonLabel("Camera", icon: "camera.fill")
                    }
                    .buttonStyle(.plain)
                }
            }
            if viewModel.isImporting {
                ProgressView().tint(accent)
            }
        case .pdf:
            Button {
                showPDFImporter = true
            } label: {
                importButtonLabel("Choose PDF", icon: "doc.fill")
            }
            .buttonStyle(.plain)
            if viewModel.isImporting {
                ProgressView().tint(accent)
            }
        case .generate:
            generateSection
        case .explore:
            exploreSection
        }
    }

    // MARK: - Generate Text section

    private var generateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Generate Text", subtitle: "Create a reading text from a topic.")

            textInputField(
                placeholder: "Topic — e.g. coral reefs, the printing press, a day at the market",
                text: $viewModel.generateTopic
            )

            ReadingSetupSectionCard(title: "Style", accentDark: accentDark) {
                ReadingSegmentedSelector(
                    options: MyTextsAIGenerationRequest.Style.titles,
                    selection: $viewModel.generateStyleTitle,
                    accent: accent,
                    accentDark: accentDark,
                    columns: 2
                )
            }

            ReadingSetupSectionCard(title: "Length", accentDark: accentDark) {
                ReadingSegmentedSelector(
                    options: ReadingLength.titles,
                    selection: $viewModel.generateLengthTitle,
                    accent: accent,
                    accentDark: accentDark
                )
            }

            if let error = viewModel.generateErrorMessage {
                messageBanner(error, isError: true)
            }

            Button {
                Task { await viewModel.generateText() }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isGenerating {
                        ProgressView().tint(accent)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    Text(viewModel.isGenerating ? "Generating…" : "Generate Text")
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)
                .padding(.horizontal, 14)
                .frame(height: 44)
                .frame(maxWidth: .infinity)
                .background(accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canGenerate)
            .opacity(viewModel.canGenerate ? 1 : 0.55)
        }
    }

    // MARK: - Explore Reading section

    private var exploreSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Explore Reading", subtitle: "Find or fetch a text from a topic.")

            textInputField(
                placeholder: "Topic or keyword — e.g. Marie Curie, Venice, photosynthesis",
                text: $viewModel.exploreTopic
            )

            ReadingSetupSectionCard(title: "Source", accentDark: accentDark) {
                ReadingSegmentedSelector(
                    options: MyTextsExploreRequest.SourcePreference.titles,
                    selection: $viewModel.exploreSourceTitle,
                    accent: accent,
                    accentDark: accentDark,
                    columns: 3
                )
            }

            ReadingSetupSectionCard(title: "Length", accentDark: accentDark) {
                ReadingSegmentedSelector(
                    options: ReadingLength.titles,
                    selection: $viewModel.exploreLengthTitle,
                    accent: accent,
                    accentDark: accentDark
                )
            }

            if let error = viewModel.exploreErrorMessage {
                messageBanner(error, isError: true)
            }

            if let label = viewModel.exploreSourceLabel {
                exploreSourceBanner(
                    label: label,
                    isPlaceholder: viewModel.exploreResultIsPlaceholder
                )
            }

            Button {
                Task { await viewModel.exploreReading() }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isExploring {
                        ProgressView().tint(accent)
                    } else {
                        Image(systemName: "safari")
                    }
                    Text(viewModel.isExploring ? "Fetching…" : "Fetch Article")
                }
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)
                .padding(.horizontal, 14)
                .frame(height: 44)
                .frame(maxWidth: .infinity)
                .background(accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.canExplore)
            .opacity(viewModel.canExplore ? 1 : 0.55)
        }
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)
            Text(subtitle)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
    }

    private func textInputField(placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundColor(accentDark)
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(fieldBackground)
    }

    // MARK: - Editor / standard sections

    private var titleField: some View {
        ReadingSetupSectionCard(title: "Title", accentDark: accentDark) {
            TextField("Optional — we can suggest one", text: $viewModel.title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(accentDark)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(fieldBackground)
        }
    }

    private var textEditor: some View {
        ReadingSetupSectionCard(title: editorTitle, accentDark: accentDark) {
            ZStack(alignment: .topLeading) {
                if viewModel.editorText.isEmpty {
                    Text(editorPlaceholder)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary.opacity(0.65))
                        .padding(.top, 12)
                        .padding(.horizontal, 10)
                }
                TextEditor(text: $viewModel.editorText)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(accentDark)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: Layout.isPadLike ? 220 : 180)
                    .padding(8)
            }
            .background(fieldBackground)
        }
    }

    private var editorTitle: String {
        switch viewModel.currentSource {
        case .generate, .explore: return "Text — edit before saving"
        default: return "Text"
        }
    }

    private var editorPlaceholder: String {
        switch viewModel.currentSource {
        case .pasteText: return "Paste your text here..."
        case .photo:     return "Pick a photo to extract text."
        case .pdf:       return "Choose a PDF to extract text."
        case .generate:  return "Tap Generate Text to create a passage you can edit."
        case .explore:   return "Tap Fetch Article to pull a passage you can edit."
        }
    }

    private var languageSection: some View {
        ReadingSetupSectionCard(title: "Language", accentDark: accentDark) {
            LanguageSelectorView(
                selectedLanguage: viewModel.selectedLanguage,
                onSelect: { viewModel.selectedLanguage = $0 },
                accent: accent,
                accentDark: accentDark
            )
        }
    }

    private var difficultySection: some View {
        ReadingSetupSectionCard(title: "Difficulty", accentDark: accentDark) {
            VStack(alignment: .leading, spacing: 12) {
                ReadingSegmentedSelector(
                    options: ReadingMyTextsDifficultyMode.titles,
                    selection: $viewModel.difficultyModeTitle,
                    accent: accent,
                    accentDark: accentDark
                )
                if ReadingMyTextsDifficultyMode.from(title: viewModel.difficultyModeTitle) == .manual {
                    ReadingSegmentedSelector(
                        options: ReadingManualLevel.titles,
                        selection: $viewModel.manualLevelTitle,
                        accent: accent,
                        accentDark: accentDark,
                        columns: Layout.isPadLike ? 5 : 3
                    )
                } else {
                    Text("Detected: \(viewModel.detectedLevel.title)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }

    private var bottomBar: some View {
        ReadingPrimaryButton(
            title: "Save & Start",
            icon: "play.fill",
            accent: accent,
            accentDark: accentDark
        ) {
            Task { await saveAndStart() }
        }
        .opacity(viewModel.canSave ? 1 : 0.55)
        .disabled(!viewModel.canSave || viewModel.isSaving)
    }

    // MARK: - Helpers

    private func saveAndStart() async {
        await viewModel.save(startSession: true)
        guard let saved = viewModel.savedText else { return }
        onSavedAndStart(saved)
    }

    private func importButtonLabel(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(title)
        }
        .font(.system(size: 14, weight: .bold, design: .rounded))
        .foregroundColor(accentDark)
        .padding(.horizontal, 14)
        .frame(height: 40)
        .background(accent.opacity(0.12))
        .clipShape(Capsule())
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.94))
            .overlay(
                RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                    .stroke(accent.opacity(0.14), lineWidth: 1)
            )
    }

    private func exploreSourceBanner(label: String, isPlaceholder: Bool) -> some View {
        let tint = isPlaceholder ? Color.orange : accent
        let message = isPlaceholder
            ? "Starter draft — edit before saving."
            : "Source: \(label)."
        return HStack(spacing: 8) {
            Image(systemName: isPlaceholder ? "pencil.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(tint)
            Text(message)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(accentDark)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.94))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .stroke(tint.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
    }

    private func messageBanner(_ text: String, isError: Bool) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(isError ? Color(red: 0.85, green: 0.25, blue: 0.25) : accentDark)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.94))
            .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        ReadingAddTextView()
    }
}
