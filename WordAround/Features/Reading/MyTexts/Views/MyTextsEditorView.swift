import SwiftUI

struct MyTextsEditorView: View {
    let setup: ReadingSessionSetup
    var onExitToSetup: () -> Void
    var onExitToReading: () -> Void

    @StateObject private var viewModel: MyTextsSessionViewModel
    @State private var showSession = false

    init(setup: ReadingSessionSetup, onExitToSetup: @escaping () -> Void, onExitToReading: @escaping () -> Void) {
        self.setup = setup
        self.onExitToSetup = onExitToSetup
        self.onExitToReading = onExitToReading
        _viewModel = StateObject(wrappedValue: MyTextsSessionViewModel(setup: setup))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingSessionHeaderView(
                        title: "Your Text",
                        subtitle: "Paste, import, or choose a saved text.",
                        accent: setup.accent,
                        accentDark: setup.accentDark,
                        onBack: onExitToSetup
                    )

                    editorCard

                    assistRow

                    Spacer().frame(height: Layout.convSetupStartButtonHeight + 24)
                }
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }

            ReadingContinueButton(
                title: "Create Practice",
                icon: "doc.text.fill",
                accent: setup.accent,
                accentDark: setup.accentDark
            ) {
                showSession = true
            }
            .frame(maxWidth: Layout.convContentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showSession) {
            MyTextsSessionView(
                setup: setup,
                viewModel: viewModel,
                onExitToSetup: onExitToSetup,
                onExitToReading: onExitToReading
            )
        }
    }

    private var editorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(viewModel.wordCount) words")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                Text("•")
                    .foregroundColor(AppColors.mutedText)
                Text("Est. \(viewModel.estimatedLevel)")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(setup.accent)
                Spacer()
                Button("Clear") { viewModel.clearText() }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(setup.accentDark)
            }

            ZStack(alignment: .topLeading) {
                if viewModel.editorText.isEmpty {
                    Text("Paste your reading text here...")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary.opacity(0.65))
                        .padding(.top, 8)
                        .padding(.horizontal, 4)
                }

                TextEditor(text: $viewModel.editorText)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 220)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .stroke(setup.accent.opacity(0.14), lineWidth: 1)
        )
    }

    private var assistRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(["Highlight words", "Generate questions", "Translate difficult words"], id: \.self) { label in
                    Button {} label: {
                        Text(label)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(setup.accentDark)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(setup.accent.opacity(0.10))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MyTextsEditorView(
            setup: ReadingSetupViewModel(config: .myTexts).makeSessionSetup(),
            onExitToSetup: {},
            onExitToReading: {}
        )
    }
}
