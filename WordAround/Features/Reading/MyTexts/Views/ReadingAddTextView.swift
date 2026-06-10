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
                viewModel.importErrorMessage = L10n.string("readingImportCancelled")
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraImagePicker { image in
                Task { await viewModel.importCameraImage(image) }
            }
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            ReadingSetupHeaderView(
                title: L10n.string("readingAddTextTitle"),
                subtitle: L10n.string("readingAddTextSubtitle"),
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
            ReadingMetadataChip(text: String(format: L10n.string("readingWordsCountFmt"), viewModel.wordCount), accent: accent)
            ReadingMetadataChip(text: String(format: L10n.string("readingCharsCountFmt"), viewModel.characterCount), accent: accent)
            ReadingMetadataChip(text: String(format: L10n.string("readingApproxMinFmt"), viewModel.estimatedMinutes), accent: accent)
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
                    importButtonLabel(L10n.string("readingPhotoLibrary"), icon: "photo.on.rectangle")
                }
                .buttonStyle(.plain)
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button {
                        showCamera = true
                    } label: {
                        importButtonLabel(L10n.string("readingCamera"), icon: "camera.fill")
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
                importButtonLabel(L10n.string("readingChoosePDF"), icon: "doc.fill")
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

    private var generateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: L10n.string("readingGenerateText"), subtitle: L10n.string("readingGenerateSubtitle"))

            textInputField(
                placeholder: L10n.string("readingGeneratePlaceholder"),
                text: $viewModel.generateTopic
            )

            ReadingSetupSectionCard(title: L10n.string("readingStyle"), accentDark: accentDark) {
                ReadingSegmentedSelector(
                    options: MyTextsAIGenerationRequest.Style.titles,
                    selection: $viewModel.generateStyleTitle,
                    accent: accent,
                    accentDark: accentDark,
                    columns: 2
                )
            }

            ReadingSetupSectionCard(title: L10n.string("essayScoreLength"), accentDark: accentDark) {
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
                    Text(viewModel.isGenerating ? L10n.string("readingGenerating") : L10n.string("readingGenerateText"))
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

    private var exploreSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: L10n.string("readingExploreTitle"), subtitle: L10n.string("readingExploreSubtitle"))

            textInputField(
                placeholder: L10n.string("readingExplorePlaceholder"),
                text: $viewModel.exploreTopic
            )

            ReadingSetupSectionCard(title: L10n.string("readingSource"), accentDark: accentDark) {
                ReadingSegmentedSelector(
                    options: MyTextsExploreRequest.SourcePreference.titles,
                    selection: $viewModel.exploreSourceTitle,
                    accent: accent,
                    accentDark: accentDark,
                    columns: 3
                )
            }

            ReadingSetupSectionCard(title: L10n.string("essayScoreLength"), accentDark: accentDark) {
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
                    Text(viewModel.isExploring ? L10n.string("readingFetching") : L10n.string("readingFetchArticle"))
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

    private var titleField: some View {
        ReadingSetupSectionCard(title: L10n.string("commonTitle"), accentDark: accentDark) {
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
        case .generate, .explore: return L10n.string("readingTextEditBeforeSaving")
        default: return L10n.string("homeCreateText")
        }
    }

    private var editorPlaceholder: String {
        switch viewModel.currentSource {
        case .pasteText: return L10n.string("readingPastePlaceholder")
        case .photo:     return L10n.string("readingPhotoPlaceholder")
        case .pdf:       return L10n.string("readingPdfPlaceholder")
        case .generate:  return L10n.string("readingGeneratePromptHint")
        case .explore:   return L10n.string("readingExplorePromptHint")
        }
    }

    private var languageSection: some View {
        ReadingSetupSectionCard(title: L10n.string("profileRowLanguage"), accentDark: accentDark) {
            LanguageSelectorView(
                selectedLanguage: viewModel.selectedLanguage,
                onSelect: { viewModel.selectedLanguage = $0 },
                accent: accent,
                accentDark: accentDark
            )
        }
    }

    private var difficultySection: some View {
        ReadingSetupSectionCard(title: L10n.string("writeWordsDifficulty"), accentDark: accentDark) {
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
                    Text(String(format: L10n.string("readingDetectedFmt"), viewModel.detectedLevel.title))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }

    private var bottomBar: some View {
        ReadingPrimaryButton(
            title: L10n.string("readingSaveAndStart"),
            icon: "play.fill",
            accent: accent,
            accentDark: accentDark
        ) {
            Task { await saveAndStart() }
        }
        .opacity(viewModel.canSave ? 1 : 0.55)
        .disabled(!viewModel.canSave || viewModel.isSaving)
    }

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
            ? L10n.string("readingStarterDraftHint")
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
