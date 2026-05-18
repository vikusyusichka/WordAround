import SwiftUI

struct WriteWordsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @StateObject private var viewModel: WriteWordsViewModel

    private var metrics: ScreenMetrics {
        ScreenMetrics.current(horizontal: horizontalSizeClass, vertical: verticalSizeClass)
    }

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
                .allowsHitTesting(viewModel.navigationState == .active)
                .onTapGesture { hideKeyboard() }

                if viewModel.navigationState == .lose {
                    WriteWordsLoseScreenView(
                        stats: viewModel.loseStats,
                        onTryAgain: {
                            hideKeyboard()
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                                viewModel.retryAfterLose()
                            }
                        },
                        onBack: {
                            hideKeyboard()
                            viewModel.closeLoseScreen()
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
        .onChange(of: viewModel.navigationState) { state in
            if state == .lose {
                hideKeyboard()
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: viewModel.navigationState)
        .sheet(isPresented: $viewModel.isSettingsPresented) {
            WriteWordsSettingsSheet(viewModel: viewModel)
        }
        // Difficulty inline picker sheet
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
    // Mic icon removed.
    // Difficulty tapped → shows inline confirmationDialog with 3 levels.

    private var bottomModeBar: some View {
        HStack {
            // Left: training mode label
            Text(viewModel.modeTitle)
                .font(.system(
                    size: LayoutConstants.Typography.caption(metrics),
                    weight: .semibold,
                    design: .rounded
                ))
                .foregroundColor(AppColors.textSecondary)

            Spacer()

            // Right: difficulty picker button
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

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    WriteWordsView()
}
