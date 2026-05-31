import SwiftUI

struct ReadingReadingToolbarView: View {
    let content: String
    let highlightOnTap: Bool
    let showVocabularyHints: Bool
    let translationOnTap: Bool
    let sourceLanguage: GrammarLanguage
    let translationTargetLanguage: GrammarLanguage
    let selectedWord: String?
    let translatedWord: String?
    let selectedWordRange: NSRange?
    let isTranslatingWord: Bool
    let translationError: String?
    let accent: Color
    let accentDark: Color
    let onWordTap: (String, NSRange) -> Void
    let onSelectTranslationTarget: (GrammarLanguage) -> Void

    private var isInteractive: Bool { highlightOnTap || translationOnTap }

    private var paragraphs: [String] {
        ReadingTextNormalizationService.paragraphs(from: content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            textCard

            if translationOnTap {
                translationLanguageCard
            }

            if showsTranslationResult {
                translationResultCard
            }
        }
    }

    private var textCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Text")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(accent)

            if isInteractive {
                ReadingTappableTextView(
                    content: content,
                    selectedWordRange: selectedWordRange,
                    accent: UIColor(accent),
                    baseTextColor: UIColor(accentDark),
                    onWordTap: onWordTap
                )
                .frame(maxWidth: .infinity, alignment: .topLeading)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(paragraphs, id: \.self) { paragraph in
                        Text(paragraph)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(accentDark)
                            .lineSpacing(6)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }

            ForEach(assistanceHints, id: \.self) { hint in
                Text(hint)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.mutedText)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(cardBackground)
    }

    private var translationLanguageCard: some View {
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
            }
            .padding(.horizontal, 4)

            LanguageSelectorView(
                selectedLanguage: translationTargetLanguage,
                onSelect: onSelectTranslationTarget,
                label: "Translate to",
                excludedLanguages: [sourceLanguage],
                accent: accent,
                accentDark: accentDark
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    private var translationResultCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.14))
                        .frame(width: 36, height: 36)
                    Image(systemName: "character.book.closed.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Translation")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(accentDark)
                    Text("\(sourceLanguage.title) → \(translationTargetLanguage.title)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.mutedText)
                }

                Spacer(minLength: 0)
            }

            if isTranslatingWord {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(accent)
                    Text("Translating…")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if let selectedWord {
                VStack(alignment: .leading, spacing: 10) {
                    Text(selectedWord)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(accentDark)
                        .fixedSize(horizontal: false, vertical: true)

                    if let translatedWord {
                        Rectangle()
                            .fill(accent.opacity(0.14))
                            .frame(height: 1)

                        Text(translatedWord)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(accent)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if let translationError {
                Text(translationError)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.85, green: 0.25, blue: 0.25))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .stroke(accent.opacity(0.22), lineWidth: 1)
        )
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.94))
            .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    private var showsTranslationResult: Bool {
        translationOnTap && (selectedWord != nil || isTranslatingWord || translationError != nil)
    }

    private var assistanceHints: [String] {
        var hints: [String] = []
        if isInteractive {
            if translationOnTap {
                hints.append("Tap a word to highlight it and see a translation.")
            } else if highlightOnTap {
                hints.append("Tap a word to highlight it.")
            }
        }
        if showVocabularyHints && translationOnTap {
            hints.append("Question hints stay available in the quiz section.")
        }
        return hints
    }
}
