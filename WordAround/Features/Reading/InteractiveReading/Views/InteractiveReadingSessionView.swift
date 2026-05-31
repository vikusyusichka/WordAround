import SwiftUI

struct InteractiveReadingSessionView: View {
    let setup: ReadingSessionSetup
    var onExitToSetup: () -> Void
    var onExitToReading: () -> Void

    @StateObject private var viewModel: InteractiveReadingSessionViewModel
    @State private var showTask = false

    init(setup: ReadingSessionSetup, onExitToSetup: @escaping () -> Void, onExitToReading: @escaping () -> Void) {
        self.setup = setup
        self.onExitToSetup = onExitToSetup
        self.onExitToReading = onExitToReading
        _viewModel = StateObject(wrappedValue: InteractiveReadingSessionViewModel(setup: setup))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingSessionHeaderView(
                        title: "Interactive Reading",
                        subtitle: viewModel.sessionSubtitle,
                        progressText: viewModel.progressText,
                        accent: setup.accent,
                        accentDark: setup.accentDark,
                        onBack: onExitToSetup
                    )

                    interactiveTextCard

                    if let word = viewModel.selectedWord {
                        wordDetailCard(word: word)
                    }

                    Spacer().frame(height: Layout.convSetupStartButtonHeight + 24)
                }
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }

            ReadingContinueButton(
                title: "Continue",
                icon: "arrow.right",
                accent: setup.accent,
                accentDark: setup.accentDark
            ) {
                viewModel.goNextInteraction()
                showTask = true
            }
            .frame(maxWidth: Layout.convContentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showTask) {
            InteractiveReadingTaskView(
                setup: setup,
                viewModel: viewModel,
                onExitToSetup: onExitToSetup,
                onExitToReading: onExitToReading
            )
        }
    }

    private var interactiveTextCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            ReadingWordFlowLayout(spacing: 8) {
                ForEach(ReadingPlaceholderData.interactiveParagraph.split(separator: " ").map(String.init), id: \.self) { word in
                    let cleaned = word.trimmingCharacters(in: .punctuationCharacters)
                    let isTappable = ReadingPlaceholderData.tappableWords.contains(cleaned)

                    ReadingWordChip(
                        word: word,
                        isSelected: viewModel.selectedWord == cleaned,
                        isTappable: isTappable,
                        accent: setup.accent
                    ) {
                        if isTappable {
                            viewModel.selectWord(cleaned)
                        }
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
    }

    private func wordDetailCard(word: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(word)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(setup.accentDark)
            Text(viewModel.selectedWordMeaning)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(setup.accent)
            Text(viewModel.selectedWordExample)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .italic()

            Button("Add to review") {}
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(setup.accentDark)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(setup.accent.opacity(0.10))
                .clipShape(Capsule())
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
    }
}

private struct ReadingWordFlowLayout: SwiftUI.Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}

#Preview {
    NavigationStack {
        InteractiveReadingSessionView(
            setup: ReadingSetupViewModel(config: .interactiveReading).makeSessionSetup(),
            onExitToSetup: {},
            onExitToReading: {}
        )
    }
}
