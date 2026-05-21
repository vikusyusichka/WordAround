import SwiftUI

struct WriteWordsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @StateObject private var viewModel: WriteWordsViewModel

    private var metrics: ScreenMetrics {
        ScreenMetrics.current(horizontal: horizontalSizeClass, vertical: verticalSizeClass)
    }

    @MainActor
    init(set: FlashcardSet? = nil) {
        _viewModel = StateObject(wrappedValue: WriteWordsViewModel(set: set))
    }

    var body: some View {
        GeometryReader { proxy in
            let cardHeight = LayoutConstants.WriteWords.exerciseHeight(
                metrics,
                availableHeight: proxy.size.height
            )

            ZStack {
                AppColors.appBackground.ignoresSafeArea()

                VStack(spacing: .zero) {
                    topBar
                        .frame(maxWidth: LayoutConstants.Common.contentMaxWidth(metrics))
                        .padding(.horizontal, LayoutConstants.Common.screenHorizontalPadding(metrics))
                        .padding(.top, LayoutConstants.WriteWords.topBarTopPadding(metrics))

                    WriteWordsProgressView(
                        progress: viewModel.progress,
                        text: viewModel.progressText
                    )
                    .frame(maxWidth: LayoutConstants.Common.contentMaxWidth(metrics))
                    .padding(.horizontal, LayoutConstants.Common.screenHorizontalPadding(metrics))
                    .padding(.top, LayoutConstants.WriteWords.progressTopPadding(metrics))

                    if viewModel.isHardTimerVisible {
                        WriteWordsCountdownTimerView(progress: viewModel.timerProgress)
                            .frame(maxWidth: LayoutConstants.Common.contentMaxWidth(metrics))
                            .padding(.horizontal, LayoutConstants.Common.screenHorizontalPadding(metrics))
                            .padding(.top, 6)
                    }

                    Spacer(minLength: 0)

                    WriteWordsExerciseCardView(
                        viewModel: viewModel,
                        fixedHeight: cardHeight
                    )
                    .frame(maxWidth: LayoutConstants.Common.narrowContentMaxWidth(metrics))
                    .padding(.horizontal, LayoutConstants.Common.screenHorizontalPadding(metrics))
                    .layoutPriority(1)

                    Spacer(minLength: 0)

                    bottomModeBar
                        .frame(maxWidth: LayoutConstants.Common.narrowContentMaxWidth(metrics))
                        .padding(.horizontal, LayoutConstants.Common.screenHorizontalPadding(metrics))
                        .padding(.bottom, LayoutConstants.WriteWords.bottomPadding(metrics))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .contentShape(Rectangle())
                .allowsHitTesting(viewModel.navigationState == .active && !viewModel.isRoundCompleted && !viewModel.isGameOver)
                .onTapGesture { hideKeyboard() }

                if viewModel.navigationState == .lose || viewModel.isRoundCompleted {
                    WriteWordsResultScreenView(
                        resultType: resultType,
                        roundStats: viewModel.roundStats,
                        loseStats: viewModel.loseStats,
                        wrongAnswerDetails: viewModel.wrongAnswerDetails,
                        onTryAgain: {
                            hideKeyboard()
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                                viewModel.restartRound()
                            }
                        },
                        onBack: {
                            hideKeyboard()
                            viewModel.exitRound()
                            dismiss()
                        }
                    )
                    .zIndex(10)
                }
            }
        }
        .onAppear {
            viewModel.startTimerIfNeeded()
        }
        .onDisappear {
            viewModel.stopTimerIfNeeded()
        }
        .onChange(of: viewModel.navigationState) { _, state in
            if state == .lose {
                hideKeyboard()
            }
        }
        .onChange(of: viewModel.isRoundCompleted) { _, isCompleted in
            if isCompleted {
                hideKeyboard()
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: viewModel.navigationState)
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: viewModel.isRoundCompleted)
        .sheet(isPresented: $viewModel.isSettingsPresented) {
            WriteWordsSettingsSheet(viewModel: viewModel)
        }
        .confirmationDialog(
            "Select difficulty",
            isPresented: $viewModel.isDifficultyMenuPresented,
            titleVisibility: .visible
        ) {
            ForEach(WriteWordsDifficulty.allCases) { level in
                Button(level.rawValue) {
                    viewModel.selectDifficulty(level)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Result

    private var resultType: WriteWordsResultType {
        if viewModel.isRoundCompleted {
            return .win
        }

        switch viewModel.gameOverReason {
        case .wrongAnswer:
            return .wrongAnswerLose
        case .timeout, .none:
            return .timeoutLose
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: LayoutConstants.WriteWords.topBarIconSize(metrics), weight: .bold))
                    .foregroundColor(AppColors.primaryBlueDark)
                    .frame(
                        width: LayoutConstants.WriteWords.topBarButtonSize(metrics),
                        height: LayoutConstants.WriteWords.topBarButtonSize(metrics)
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Write Words")
                .font(.system(
                    size: LayoutConstants.WriteWords.topBarTitleSize(metrics),
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundColor(AppColors.primaryBlueDark)

            Spacer()

            Button { viewModel.isSettingsPresented = true } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: LayoutConstants.WriteWords.topBarIconSize(metrics), weight: .bold))
                    .foregroundColor(AppColors.primaryBlueDark)
                    .frame(
                        width: LayoutConstants.WriteWords.topBarButtonSize(metrics),
                        height: LayoutConstants.WriteWords.topBarButtonSize(metrics)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Bottom mode bar

    private var bottomModeBar: some View {
        HStack {
            Text(viewModel.modeTitle)
                .font(.system(
                    size: LayoutConstants.Typography.caption(metrics),
                    weight: .semibold,
                    design: .rounded
                ))
                .foregroundColor(AppColors.textSecondary)

            Spacer()

            Button {
                viewModel.isDifficultyMenuPresented = true
            } label: {
                HStack(spacing: LayoutConstants.WriteWords.modeInlineSpacing(metrics)) {
                    Text(viewModel.difficultyTitle)

                    Image(systemName: "chevron.down")
                        .font(.system(
                            size: LayoutConstants.WriteWords.modeChevronSize(metrics),
                            weight: .bold
                        ))
                }
                .font(.system(
                    size: LayoutConstants.Typography.caption(metrics),
                    weight: .semibold,
                    design: .rounded
                ))
                .foregroundColor(AppColors.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, LayoutConstants.WriteWords.modeBarHorizontalPadding(metrics))
        .frame(height: LayoutConstants.WriteWords.modeBarHeight(metrics))
        .background(Color.white.opacity(0.86))
        .clipShape(RoundedRectangle(
            cornerRadius: LayoutConstants.WriteWords.modeBarCornerRadius(metrics),
            style: .continuous
        ))
        .overlay {
            RoundedRectangle(
                cornerRadius: LayoutConstants.WriteWords.modeBarCornerRadius(metrics),
                style: .continuous
            )
            .stroke(Color.white.opacity(0.95), lineWidth: LayoutConstants.Common.hairline)
        }
        .shadow(
            color: Color.black.opacity(0.04),
            radius: Layout.topPaddingPhone + LayoutConstants.Common.hairline * 2,
            x: 0,
            y: LayoutConstants.Common.smallSpacing(metrics)
        )
    }

    // MARK: - Helpers

    @MainActor
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    WriteWordsView()
}
