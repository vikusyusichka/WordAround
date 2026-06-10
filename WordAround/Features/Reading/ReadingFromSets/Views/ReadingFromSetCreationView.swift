import SwiftUI

struct ReadingFromSetCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ReadingFromSetCreationViewModel

    init(mode: ReadingMode) {
        _viewModel = StateObject(wrappedValue: ReadingFromSetCreationViewModel(mode: mode))
    }

    init(viewModel: ReadingFromSetCreationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var accent: Color { viewModel.accent }
    private var accentDark: Color { viewModel.accentDark }

    private var chipColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 78), spacing: 6, alignment: .leading)]
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingSetupHeaderView(
                        title: L10n.string("rfsCreateFromSet"),
                        subtitle: L10n.string("rfsSubtitle"),
                        accent: accent,
                        accentDark: accentDark,
                        onBack: { dismiss() }
                    )
                    .padding(.bottom, 4)

                    if let error = viewModel.errorMessage {
                        errorBanner(error)
                    }

                    setCard

                    if viewModel.hasSet {
                        vocabularyPreview
                        configSection
                    }

                    Spacer().frame(height: Layout.convSetupStartButtonHeight + 32)
                }
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }

            if viewModel.hasSet {
                ReadingPrimaryButton(
                    title: viewModel.isGenerating ? L10n.string("rfsCreating") : L10n.string("rfsGenerate"),
                    icon: viewModel.isGenerating ? nil : "sparkles",
                    accent: accent,
                    accentDark: accentDark
                ) {
                    viewModel.generate()
                }
                .opacity(viewModel.canGenerate ? 1 : 0.6)
                .disabled(!viewModel.canGenerate)
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.bottom, Layout.homeBottomBarBottomPadding)
            }

            if viewModel.isGenerating { generatingOverlay }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.loadSets() }
        .sheet(isPresented: $viewModel.isShowingSetPicker) {
            WritingSetSelectionView(sets: viewModel.availableSets) { set in
                viewModel.handleSetSelected(set)
            }
        }
        .navigationDestination(item: $viewModel.createdItem) { item in
            ReadingSessionView(item: item)
        }
    }

    private var setCard: some View {
        Button {
            viewModel.presentSetPicker()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(accent.opacity(0.14))
                        .frame(width: 48, height: 48)
                    if viewModel.isLoadingSets {
                        ProgressView().tint(accent)
                    } else {
                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(accent)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.hasSet ? viewModel.setTitle : L10n.string("rfsChooseSet"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(accentDark)
                        .lineLimit(1)
                    Text(viewModel.hasSet ? String(format: L10n.string("rfsWordsTapHint"), viewModel.wordCount) : L10n.string("rfsPickSetHint"))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.mutedText)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.94))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                    .stroke(accent.opacity(0.16), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var vocabularyPreview: some View {
        sectionCard(title: L10n.string("rfsVocabulary")) {
            VStack(alignment: .leading, spacing: 10) {
                Text(String(format: L10n.string("rfsWordsFromFmt"), viewModel.wordCount, viewModel.setTitle))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)

                LazyVGrid(columns: chipColumns, alignment: .leading, spacing: 6) {
                    ForEach(viewModel.previewTerms, id: \.self) { term in
                        ReadingMetadataChip(text: term, accent: accent)
                    }
                }

                if viewModel.wordCount > viewModel.previewTerms.count {
                    Text(String(format: L10n.string("rfsMoreCountFmt"), viewModel.wordCount - viewModel.previewTerms.count))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.mutedText)
                }
            }
        }
    }

    private var configSection: some View {
        VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
            sectionCard(title: L10n.string("rfsGenerationMode")) {
                segmented(
                    options: viewModel.generationModeOptions.map(\.title),
                    selection: viewModel.generationMode.title
                ) { title in
                    viewModel.generationMode = ReadingGenerationStyle.from(title: title)
                }
                Text(viewModel.generationMode.helperText)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.mutedText)
                    .padding(.top, 6)
            }

            sectionCard(title: L10n.string("rfsDifficulty")) {
                segmented(
                    options: viewModel.difficultyOptions.map(\.rawValue),
                    selection: viewModel.difficulty.rawValue
                ) { raw in
                    if let d = EssayDifficulty(rawValue: raw) { viewModel.difficulty = d }
                }
            }

            sectionCard(title: L10n.string("rfsLength")) {
                segmented(
                    options: viewModel.lengthOptions.map(\.title),
                    selection: viewModel.length.title
                ) { title in
                    if let l = viewModel.lengthOptions.first(where: { $0.title == title }) { viewModel.length = l }
                }
            }
        }
    }

    @ViewBuilder
    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .stroke(accent.opacity(0.12), lineWidth: 1)
        )
    }

    private func segmented(options: [String], selection: String, onSelect: @escaping (String) -> Void) -> some View {
        ReadingSegmentedSelector(
            options: options,
            selection: Binding(get: { selection }, set: { onSelect($0) }),
            accent: accent,
            accentDark: accentDark,
            columns: options.count > 3 ? 0 : options.count
        )
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.orange)
            Text(message)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(accentDark)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
    }

    private var generatingOverlay: some View {
        ZStack {
            Color.black.opacity(0.12).ignoresSafeArea()
            VStack(spacing: 14) {
                ProgressView().scaleEffect(1.2)
                Text(L10n.string("rfsCreating"))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                    .fill(Color.white)
            )
            .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 8)
        }
    }
}

#Preview {
    NavigationStack {
        ReadingFromSetCreationView(
            viewModel: ReadingFromSetCreationViewModel(
                mode: ReadingMode(
                    id: "reading-from-sets",
                    title: "Reading From Sets",
                    subtitle: "Build a reading from your flashcard sets.",
                    systemImage: "rectangle.stack.fill",
                    accentColor: ReadingSetupConfig.readingFromSets.accent,
                    blobColor: AppColors.blobYellow
                ),
                generator: MockReadingFromSetGenerationService(),
                currentUserId: { "preview" }
            )
        )
    }
}
