import SwiftUI

/// Redesigned "Continue learning" tile.
///
/// Shows the most relevant flashcard set (chosen by `SetsListViewModel`) with a
/// progress bar and a Continue action, or a calm empty state when the user has
/// no sets yet. Blue is the Home accent throughout; the whole card is the tap
/// target so tapping anywhere — or the Continue label — opens the set.
struct ContinueLearningSetCardView: View {
    let set: HomeSetPreviewItem?
    let onContinue: () -> Void
    let onCreate: () -> Void

    var body: some View {
        if let set {
            filledCard(set)
        } else {
            emptyCard
        }
    }

    // MARK: - Filled state

    private func filledCard(_ set: HomeSetPreviewItem) -> some View {
        Button(action: onContinue) {
            VStack(alignment: .leading, spacing: Layout.homeContinueSpacing) {
                header(set)
                progressSection(set)
                continueLabel(set.accentColor)
            }
            .padding(Layout.homeContinueCardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
        }
        .buttonStyle(.plain)
    }

    private func header(_ set: HomeSetPreviewItem) -> some View {
        HStack(alignment: .top, spacing: 14) {
            iconChip(set)

            VStack(alignment: .leading, spacing: 6) {
                Text(set.title)
                    .font(.system(size: Layout.homeContinueTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(set.titleColor)
                    .lineLimit(2)

                flashcardsChip(set.accentColor)
            }

            Spacer(minLength: 0)
        }
    }

    private func progressSection(_ set: HomeSetPreviewItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(set.currentValue) / \(set.totalValue) cards")
                .font(.system(size: Layout.homeContinueProgressTextSize, weight: .semibold, design: .rounded))
                .foregroundColor(set.subtitleColor)

            progressBar(progress: set.progress, track: set.progressBackgroundColor, fill: set.accentColor)
        }
    }

    private func progressBar(progress: Double, track: Color, fill: Color) -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(track)

                Capsule()
                    .fill(fill)
                    .frame(width: max(0, min(1, progress)) * proxy.size.width)
            }
        }
        .frame(height: Layout.homeContinueProgressBarHeight)
    }

    /// Visual only — the enclosing card Button drives `onContinue`, so this is a
    /// styled label (avoids a button-inside-button hit-testing conflict).
    private func continueLabel(_ accent: Color) -> some View {
        HStack(spacing: 8) {
            Text("Continue")
                .font(.system(size: Layout.homeContinueButtonFontSize, weight: .bold, design: .rounded))

            Image(systemName: "arrow.right")
                .font(.system(size: Layout.homeContinueButtonFontSize, weight: .bold))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: Layout.homeContinueButtonHeight)
        .background(
            RoundedRectangle(cornerRadius: Layout.homeContinueButtonCornerRadius, style: .continuous)
                .fill(accent)
        )
    }

    // MARK: - Empty state

    private var emptyCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryBlue.opacity(0.12))
                    .frame(
                        width: Layout.homeContinueIconCircleSize,
                        height: Layout.homeContinueIconCircleSize
                    )

                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: Layout.homeContinueIconSize, weight: .semibold))
                    .foregroundColor(AppColors.primaryBlue)
            }

            VStack(spacing: 4) {
                Text("No sets yet")
                    .font(.system(size: Layout.homeContinueTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)

                Text("Create your first set to start learning.")
                    .font(.system(size: Layout.homeContinueMetaSize, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: onCreate) {
                Text("Create first set")
                    .font(.system(size: Layout.homeContinueButtonFontSize, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .frame(height: Layout.homeContinueButtonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: Layout.homeContinueButtonCornerRadius, style: .continuous)
                            .fill(AppColors.primaryBlue)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: Layout.homeContinueEmptyHeight)
        .padding(Layout.homeContinueCardPadding)
        .background(cardBackground)
    }

    // MARK: - Shared chrome

    /// Mirrors the set's own theme: a soft-accent tile with the accent-coloured
    /// icon, matching how the set looks elsewhere in the app.
    private func iconChip(_ set: HomeSetPreviewItem) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: Layout.homeContinueIconCornerRadius, style: .continuous)
                .fill(set.iconBackground)
                .frame(
                    width: Layout.homeContinueIconCircleSize,
                    height: Layout.homeContinueIconCircleSize
                )

            Image(systemName: set.iconSystemName)
                .font(.system(size: Layout.homeContinueIconSize, weight: .semibold))
                .foregroundColor(set.accentColor)
        }
    }

    private func flashcardsChip(_ accent: Color) -> some View {
        Text("Flashcards")
            .font(.system(size: Layout.homeContinueChipSize, weight: .bold, design: .rounded))
            .foregroundColor(accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(accent.opacity(0.12)))
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: Layout.homeContinueCardCornerRadius, style: .continuous)
            .fill(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.homeContinueCardCornerRadius, style: .continuous)
                    .stroke(AppColors.primaryBlue.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.07), radius: 16, x: 0, y: 8)
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()

        VStack(spacing: 20) {
            ContinueLearningSetCardView(
                set: HomeSetPreviewItem(
                    sourceSet: nil,
                    title: "Travel Vocabulary",
                    subtitle: "",
                    iconSystemName: "airplane",
                    currentValue: 12,
                    totalValue: 30,
                    unit: "cards",
                    progress: 0.4,
                    accentColor: AppColors.primaryBlue,
                    backgroundColor: .white,
                    progressBackgroundColor: AppColors.primaryBlue.opacity(0.12),
                    titleColor: AppColors.primaryBlueDark,
                    valueColor: AppColors.primaryBlueDark,
                    subtitleColor: AppColors.textSecondary,
                    iconBackground: AppColors.primaryBlue.opacity(0.12),
                    blobColor: AppColors.primaryBlue.opacity(0.12)
                ),
                onContinue: {},
                onCreate: {}
            )

            ContinueLearningSetCardView(set: nil, onContinue: {}, onCreate: {})
        }
        .padding()
    }
}
