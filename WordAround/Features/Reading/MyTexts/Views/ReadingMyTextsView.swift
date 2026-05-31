import SwiftUI

/// Personal reading library — save, browse, and continue saved texts.
struct ReadingMyTextsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ReadingMyTextsViewModel()

    @State private var sessionText: ReadingUserText?

    private let accent = ReadingSetupConfig.myTexts.accent
    private let accentDark = ReadingSetupConfig.myTexts.accentDark

    private var textColumns: [GridItem] {
        if Layout.isPadLike {
            [
                GridItem(.flexible(), spacing: Layout.readingModeGridSpacing),
                GridItem(.flexible(), spacing: Layout.readingModeGridSpacing)
            ]
        } else {
            [GridItem(.flexible())]
        }
    }

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingSetupHeaderView(
                        title: "My Texts",
                        subtitle: "Practice reading with your own saved texts",
                        accent: accent,
                        accentDark: accentDark,
                        onBack: { dismiss() }
                    )
                    .padding(.bottom, 4)

                    if let error = viewModel.errorMessage {
                        errorBanner(error)
                    }

                    addTextButton

                    if viewModel.isEmpty && !viewModel.isLoading {
                        ReadingMyTextsEmptyStateView {
                            viewModel.showAddTextSheet = true
                        }
                    } else {
                        if let continueText = viewModel.continueReadingText {
                            continueSection(continueText)
                        }
                        savedTextsSection
                    }
                }
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.loadTextsAsync() }
        .sheet(isPresented: $viewModel.showAddTextSheet) {
            AddReadingTextSheet(
                errorMessage: viewModel.errorMessage,
                onCancel: {
                    viewModel.clearError()
                    viewModel.showAddTextSheet = false
                },
                onSave: { title, content, language, manualLevel, useAutoLevel, focus in
                    Task {
                        let saved = await viewModel.addText(
                            title: title,
                            content: content,
                            language: language,
                            manualLevel: manualLevel,
                            useAutoLevel: useAutoLevel,
                            focus: focus
                        )
                        if saved {
                            viewModel.showAddTextSheet = false
                        }
                    }
                }
            )
        }
        .navigationDestination(item: $sessionText) { text in
            ReadingSessionView(userText: text)
        }
        .onChange(of: sessionText) { _, newValue in
            if newValue == nil {
                Task { await viewModel.loadTextsAsync() }
            }
        }
    }

    // MARK: - Sections

    private var addTextButton: some View {
        ReadingPrimaryButton(
            title: "Add Text",
            icon: "plus",
            accent: accent,
            accentDark: accentDark
        ) {
            viewModel.showAddTextSheet = true
        }
    }

    private func continueSection(_ text: ReadingUserText) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Continue reading")
            ReadingContinueTextCardView(
                title: text.title,
                languageTitle: text.languageTitle,
                levelTitle: text.levelTitle,
                progress: text.progress,
                lastOpenedText: text.lastOpenedText,
                onContinue: { openText(text) }
            )
        }
        .padding(.top, Layout.homeSectionTitleTopPadding)
    }

    private var savedTextsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Saved texts")
                .padding(.top, viewModel.continueReadingText == nil ? Layout.homeSectionTitleTopPadding : 4)

            LazyVGrid(columns: textColumns, spacing: Layout.readingModeGridSpacing) {
                ForEach(viewModel.sortedTexts) { text in
                    ReadingMyTextsCardView(
                        title: text.title,
                        preview: text.preview,
                        languageTitle: text.languageTitle,
                        levelTitle: text.levelTitle,
                        wordCount: text.wordCount,
                        progress: text.progress,
                        dateText: text.dateText,
                        actionTitle: text.actionTitle,
                        onAction: { openText(text) },
                        onDelete: { viewModel.deleteText(text) }
                    )
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: Layout.homeSectionTitleSize, weight: .bold, design: .rounded))
            .foregroundColor(accentDark)
    }

    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(AppColors.primaryBlueDark)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.94))
            .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
    }

    private func openText(_ text: ReadingUserText) {
        sessionText = viewModel.text(withId: text.id) ?? text
    }
}

#Preview("With texts") {
    NavigationStack {
        ReadingMyTextsView()
    }
}

#Preview("Empty") {
    NavigationStack {
        ReadingMyTextsView()
    }
}
