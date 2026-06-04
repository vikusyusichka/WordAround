import SwiftUI

struct SaveGrammarMistakeConfirmationSheet: View {
    enum SaveState: Equatable {
        case idle
        case saving
        case saved
        case duplicate
        case failed(String)
    }

    let originalSentence: String
    let correctedSentence: String
    let explanation: String
    let state: SaveState
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            VStack(alignment: .leading, spacing: Layout.grammarQuickSheetSectionSpacing) {
                header
                previewSection
                stateView
                actions
            }
            .padding(Layout.grammarQuickSheetPadding)
            .frame(maxWidth: Layout.grammarQuickSheetMaxWidth)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .presentationDetents([.height(Layout.grammarQuickMistakeSheetHeight), .large])
        .presentationDragIndicator(.hidden)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(GrammarNoteType.mistake.tintColor.opacity(0.13))
                Image(systemName: "square.and.arrow.down.fill")
                    .font(.system(size: Layout.grammarQuickHeaderIconSize, weight: .bold))
                    .foregroundStyle(GrammarNoteType.mistake.tintColor)
            }
            .frame(width: Layout.grammarQuickHeaderIconBox, height: Layout.grammarQuickHeaderIconBox)

            VStack(alignment: .leading, spacing: 4) {
                Text("Save mistake")
                    .font(.system(size: Layout.grammarQuickTitleSize, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)

                Text("Confirm this correction before saving it to Notes.")
                    .font(.system(size: Layout.grammarQuickSubtitleSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(2)
            }

            Spacer(minLength: 0)

            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(state == .saving)
        }
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            previewRow(title: "Original", text: originalSentence, icon: "quote.bubble.fill", tint: GrammarNoteType.mistake.tintColor)
            previewRow(title: "Correction", text: correctedSentence, icon: "checkmark.bubble.fill", tint: CreateSetTheme.green.accent)

            if !explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                previewRow(title: "Why", text: explanation, icon: "lightbulb.fill", tint: CreateSetTheme.yellow.accent)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: Layout.grammarQuickSectionCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.grammarQuickSectionCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.56), lineWidth: 1)
        )
    }

    private func previewRow(title: String, text: String, icon: String, tint: Color) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                Text(text.isEmpty ? "Empty" : text)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .lineSpacing(3)
            }
        }
    }

    @ViewBuilder
    private var stateView: some View {
        switch state {
        case .idle:
            EmptyView()
        case .saving:
            statusCard(text: "Saving mistake...", icon: "arrow.triangle.2.circlepath", tint: AppColors.primaryBlue)
        case .saved:
            statusCard(text: "Saved to Grammar Notes.", icon: "checkmark.circle.fill", tint: CreateSetTheme.green.accent)
        case .duplicate:
            statusCard(text: "Already saved. Duplicate was skipped.", icon: "doc.on.doc.fill", tint: CreateSetTheme.yellow.accent)
        case .failed(let message):
            statusCard(text: message, icon: "exclamationmark.triangle.fill", tint: GrammarNoteType.mistake.tintColor)
        }
    }

    private func statusCard(text: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
            Text(text)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(tint.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var actions: some View {
        HStack(spacing: 10) {
            Button("Cancel", action: onCancel)
                .buttonStyle(.plain)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: Layout.grammarQuickActionHeight)
                .background(Color.white.opacity(0.78))
                .clipShape(RoundedRectangle(cornerRadius: Layout.grammarQuickActionCornerRadius, style: .continuous))
                .disabled(state == .saving)

            Button(action: onSave) {
                if state == .saving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Save")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: Layout.grammarQuickActionHeight)
            .background(GrammarNoteType.mistake.tintColor)
            .clipShape(RoundedRectangle(cornerRadius: Layout.grammarQuickActionCornerRadius, style: .continuous))
            .disabled(state == .saving || state == .saved || state == .duplicate)
        }
    }
}

#Preview {
    SaveGrammarMistakeConfirmationSheet(
        originalSentence: "I am agree with you",
        correctedSentence: "I agree with you",
        explanation: "Agree is already a verb, so it does not need am.",
        state: .idle,
        onCancel: {},
        onSave: {}
    )
}
