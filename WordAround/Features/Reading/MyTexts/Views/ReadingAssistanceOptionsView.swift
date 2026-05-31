import SwiftUI

struct ReadingAssistanceOptionsView: View {
    @Binding var options: ReadingAssistanceOptions
    let sourceLanguage: GrammarLanguage
    let accent: Color
    let accentDark: Color

    var body: some View {
        ReadingSetupSectionCard(title: "Assistance", accentDark: accentDark) {
            VStack(spacing: 10) {
                assistToggle("Highlight words on tap", isOn: $options.highlightUnknownWords)
                assistToggle("Translation on tap", isOn: $options.translationOnTap)
                assistToggle("Vocabulary hints", isOn: $options.vocabularyHints)
                assistToggle("Reading timer", isOn: $options.readingTimer)

                if options.translationOnTap {
                    translationLanguageSection
                }
            }
        }
        .onChange(of: sourceLanguage) { _, language in
            syncTranslationTarget(with: language)
        }
        .onChange(of: options.translationOnTap) { _, isOn in
            if isOn {
                syncTranslationTarget(with: sourceLanguage)
            }
        }
        .onAppear {
            syncTranslationTarget(with: sourceLanguage)
        }
    }

    private var translationLanguageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("From")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                Text(sourceLanguage.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(accentDark)
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppColors.mutedText)
                Text("text language")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.mutedText)
            }
            .padding(.horizontal, 4)

            LanguageSelectorView(
                selectedLanguage: translationTargetLanguage,
                onSelect: { selectTranslationTarget($0) },
                label: "Translate to",
                excludedLanguages: [sourceLanguage],
                accent: accent,
                accentDark: accentDark
            )
        }
    }

    private var translationTargetLanguage: GrammarLanguage {
        options.resolvedTranslationTarget(sourceLanguage: sourceLanguage)
    }

    private func selectTranslationTarget(_ language: GrammarLanguage) {
        options.translationTargetLanguageCode = language.rawValue
    }

    private func syncTranslationTarget(with sourceLanguage: GrammarLanguage) {
        let resolved = options.resolvedTranslationTarget(sourceLanguage: sourceLanguage)
        if resolved == sourceLanguage {
            options.translationTargetLanguageCode = ReadingTranslationService
                .defaultTargetLanguage(for: sourceLanguage)
                .rawValue
        } else if options.translationTargetLanguageCode.isEmpty {
            options.translationTargetLanguageCode = resolved.rawValue
        }
    }

    private func assistToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(accentDark)
            Spacer(minLength: 0)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(accent)
        }
        .padding(.horizontal, 16)
        .frame(height: Layout.convSetupDurationChipHeight)
        .background(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .stroke(accent.opacity(0.16), lineWidth: 1)
        )
    }
}
