import SwiftUI

struct GrammarIssueCardView: View {
    let issue: GrammarIssue
    var saveState: SaveGrammarMistakeConfirmationSheet.SaveState = .idle
    var onSave: (() -> Void)? = nil

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isPadLike ? 14 : 12) {
            feedbackRow(
                title: "Original",
                text: issue.incorrectText,
                systemImage: "exclamationmark.circle.fill",
                tint: Color(red: 0.78, green: 0.55, blue: 0.26),
                background: Color(red: 1.00, green: 0.95, blue: 0.88)
            )

            if issue.hasSuggestion, let suggestion = issue.suggestedCorrection {
                feedbackRow(
                    title: "Suggestion",
                    text: suggestion,
                    systemImage: "checkmark.circle.fill",
                    tint: AppColors.primaryBlue,
                    background: AppColors.primaryBlue.opacity(0.08)
                )
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Reason")
                    .font(.system(size: isPadLike ? 13 : 12, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)

                Text(issue.message)
                    .font(.system(size: isPadLike ? 14 : 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(3)
            }

            if onSave != nil || saveState != .idle {
                saveButton
            }
        }
        .padding(isPadLike ? 18 : 15)
        .background(Color.white.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.045), radius: 14, x: 0, y: 8)
    }

    private var saveButton: some View {
        Button(action: {
            guard saveState != .saving, saveState != .saved, saveState != .duplicate else { return }
            onSave?()
        }) {
            HStack(spacing: 8) {
                switch saveState {
                case .saving:
                    ProgressView()
                        .tint(.white)
                case .saved:
                    Image(systemName: "checkmark.circle.fill")
                case .duplicate:
                    Image(systemName: "doc.on.doc.fill")
                case .failed:
                    Image(systemName: "exclamationmark.triangle.fill")
                case .idle:
                    Image(systemName: "square.and.arrow.down.fill")
                }

                Text(saveButtonTitle)
                    .font(.system(size: isPadLike ? 14 : 13, weight: .black, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: isPadLike ? 44 : 40)
            .background(saveButtonTint)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(saveState == .saving || saveState == .saved || saveState == .duplicate)
    }

    private var saveButtonTitle: String {
        switch saveState {
        case .idle: return "Save to Grammar Notes"
        case .saving: return "Saving..."
        case .saved: return "Saved"
        case .duplicate: return "Already saved"
        case .failed: return "Try saving again"
        }
    }

    private var saveButtonTint: Color {
        switch saveState {
        case .failed:
            return Color(red: 0.78, green: 0.55, blue: 0.26)
        default:
            return AppColors.primaryBlue
        }
    }

    private func feedbackRow(
        title: String,
        text: String,
        systemImage: String,
        tint: Color,
        background: Color
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: isPadLike ? 16 : 14, weight: .semibold))
                .foregroundColor(tint)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: isPadLike ? 12 : 11, weight: .bold, design: .rounded))
                    .foregroundColor(tint)

                Text(text)
                    .font(.system(size: isPadLike ? 15 : 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)
                    .textSelection(.enabled)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview("Idle (no save)") {
    GrammarIssueCardView(
        issue: GrammarIssue(
            message: "Use the past tense form here.",
            incorrectText: "go",
            suggestedCorrection: "went",
            offset: 0,
            length: 2
        )
    )
    .padding()
    .background(AppColors.appBackground)
}

#Preview("Idle (with save button)") {
    GrammarIssueCardView(
        issue: GrammarIssue(
            message: "Use the past tense form here.",
            incorrectText: "go",
            suggestedCorrection: "went",
            offset: 0,
            length: 2
        ),
        saveState: .idle,
        onSave: {}
    )
    .padding()
    .background(AppColors.appBackground)
}

#Preview("Saving") {
    GrammarIssueCardView(
        issue: GrammarIssue(
            message: "Use the past tense form here.",
            incorrectText: "go",
            suggestedCorrection: "went",
            offset: 0,
            length: 2
        ),
        saveState: .saving,
        onSave: {}
    )
    .padding()
    .background(AppColors.appBackground)
}

#Preview("Saved") {
    GrammarIssueCardView(
        issue: GrammarIssue(
            message: "Use the past tense form here.",
            incorrectText: "go",
            suggestedCorrection: "went",
            offset: 0,
            length: 2
        ),
        saveState: .saved,
        onSave: {}
    )
    .padding()
    .background(AppColors.appBackground)
}

#Preview("Already saved") {
    GrammarIssueCardView(
        issue: GrammarIssue(
            message: "Use the past tense form here.",
            incorrectText: "go",
            suggestedCorrection: "went",
            offset: 0,
            length: 2
        ),
        saveState: .duplicate,
        onSave: {}
    )
    .padding()
    .background(AppColors.appBackground)
}

#Preview("Failed") {
    GrammarIssueCardView(
        issue: GrammarIssue(
            message: "Use the past tense form here.",
            incorrectText: "go",
            suggestedCorrection: "went",
            offset: 0,
            length: 2
        ),
        saveState: .failed("Network error"),
        onSave: {}
    )
    .padding()
    .background(AppColors.appBackground)
}
