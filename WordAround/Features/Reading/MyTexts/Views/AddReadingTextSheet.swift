import SwiftUI

/// Sheet for adding a new text to the My Texts library.
struct AddReadingTextSheet: View {
    var errorMessage: String? = nil
    var onCancel: () -> Void
    var onSave: (
        _ title: String,
        _ content: String,
        _ language: GrammarLanguage,
        _ manualLevel: EssayDifficulty?,
        _ useAutoLevel: Bool,
        _ focus: ReadingFocus
    ) -> Void

    @State private var title = ""
    @State private var textContent = ""
    @State private var selectedLanguage: GrammarLanguage = .english
    @State private var difficultyMode = ReadingMyTextsDifficultyMode.autoDetect.rawValue
    @State private var selectedLevel = ReadingLevel.b1.title
    @State private var readingFocus = ReadingFocus.mainIdea.title
    @State private var isSaving = false

    private let accent = ReadingSetupConfig.myTexts.accent
    private let accentDark = ReadingSetupConfig.myTexts.accentDark
    private let analyzer = ReadingTextAnalyzerService.shared

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !textContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isSaving
    }

    private var wordCount: Int {
        analyzer.wordCount(for: textContent)
    }

    private var estimatedMinutes: Int {
        analyzer.estimatedReadingMinutes(wordCount: wordCount)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.appBackground.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                        if let errorMessage, !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.25))
                                .padding(.horizontal, 4)
                        }

                        titleField
                        contentEditor
                        languageSection
                        difficultySection
                        focusSection
                        actionButtons
                    }
                    .frame(maxWidth: Layout.convContentMaxWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Layout.homeHorizontalPadding)
                    .padding(.top, 8)
                    .padding(.bottom, Layout.homeBottomSafeSpacing)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Add Text")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(accentDark)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(accentDark)
                        .disabled(isSaving)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isSaving)
    }

    // MARK: - Fields

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Title")
            TextField("Give your text a name", text: $title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(accentDark)
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(fieldBackground)
        }
    }

    private var contentEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            fieldLabel("Text content")

            ZStack(alignment: .topLeading) {
                if textContent.isEmpty {
                    Text("Paste your reading text here…")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary.opacity(0.65))
                        .padding(.top, 10)
                        .padding(.horizontal, 8)
                }

                TextEditor(text: $textContent)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(accentDark)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: Layout.isPadLike ? 160 : 130)
            }
            .padding(10)
            .background(fieldBackground)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(wordCount) words • \(textContent.count) characters • ~\(estimatedMinutes) min read")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.mutedText)
                if wordCount > 0 && wordCount < 30 {
                    Text("Tip: longer texts work better for practice (30+ words).")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }

    private var languageSection: some View {
        ReadingSetupSectionCard(title: "Language", accentDark: accentDark) {
            LanguageSelectorView(
                selectedLanguage: selectedLanguage,
                onSelect: { selectedLanguage = $0 },
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
                    selection: $difficultyMode,
                    accent: accent,
                    accentDark: accentDark,
                    columns: 2
                )

                if difficultyMode == ReadingMyTextsDifficultyMode.chooseManually.rawValue {
                    ReadingSegmentedSelector(
                        options: ReadingLevel.titles,
                        selection: $selectedLevel,
                        accent: accent,
                        accentDark: accentDark
                    )
                }
            }
        }
    }

    private var focusSection: some View {
        ReadingSetupSectionCard(title: "Reading focus", accentDark: accentDark) {
            ReadingSegmentedSelector(
                options: ReadingFocus.titles,
                selection: $readingFocus,
                accent: accent,
                accentDark: accentDark,
                columns: 0
            )
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: Layout.convSetupStartButtonHeight)
                    .background(Color.white.opacity(0.94))
                    .clipShape(RoundedRectangle(cornerRadius: Layout.convSetupStartButtonCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isSaving)

            Button(action: save) {
                Group {
                    if isSaving {
                        ProgressView().tint(.white)
                    } else {
                        Text("Save")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: Layout.convSetupStartButtonHeight)
                .background(
                    LinearGradient(
                        colors: canSave ? [accent, accentDark] : [AppColors.mutedText.opacity(0.35), AppColors.mutedText.opacity(0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: Layout.convSetupStartButtonCornerRadius, style: .continuous))
                .shadow(color: canSave ? accent.opacity(0.24) : .clear, radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(!canSave)
        }
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: Layout.homeSectionTitleSize, weight: .bold, design: .rounded))
            .foregroundColor(accentDark)
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.94))
            .overlay(
                RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                    .stroke(accent.opacity(0.14), lineWidth: 1)
            )
    }

    private func save() {
        guard canSave else { return }
        isSaving = true
        let useAutoLevel = difficultyMode == ReadingMyTextsDifficultyMode.autoDetect.rawValue
        let manualLevel = EssayDifficulty(rawValue: selectedLevel)
        let focus = ReadingFocus.from(title: readingFocus)
        onSave(title, textContent, selectedLanguage, manualLevel, useAutoLevel, focus)
        isSaving = false
    }
}

private enum ReadingMyTextsDifficultyMode: String, CaseIterable {
    case autoDetect = "Auto detect"
    case chooseManually = "Choose manually"

    static var titles: [String] { allCases.map(\.rawValue) }
}

#Preview {
    AddReadingTextSheet(onCancel: {}, onSave: { _, _, _, _, _, _ in })
}
