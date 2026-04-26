import SwiftUI

struct CreateSetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateSetViewModel()

    var body: some View {
        ZStack {
            viewModel.theme.screenBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Layout.isPadLike ? 18 : 14) {
                    CreateSetHeaderView(
                        viewModel: viewModel,
                        onBack: { dismiss() }
                    )

                    CreateSetInfoSectionView(viewModel: viewModel)
                    CreateSetCustomizationSectionView(viewModel: viewModel)
                    CreateSetPreviewCardView(viewModel: viewModel)
                    CreateSetCardsSectionView(viewModel: viewModel)

                    createButton

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }
                }
                .padding(.horizontal, Layout.isPadLike ? 20 : 16)
                .padding(.top, Layout.isPadLike ? 12 : 8)
                .padding(.bottom, 28)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onChange(of: viewModel.didCreateSet) { didCreate in
            if didCreate { dismiss() }
        }
        .task {
            await viewModel.loadFolders()
        }
    }

    private var createButton: some View {
        Button {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                            to: nil, from: nil, for: nil)
            Task {
                await viewModel.createSet()
            }
        } label: {
            HStack {
                Spacer()

                Text(viewModel.isSaving ? "Saving..." : "Create Set")
                    .font(.system(size: Layout.isPadLike ? 21 : 18, weight: .semibold))

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: Layout.isPadLike ? 22 : 19, weight: .medium))
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 24)
            .frame(height: Layout.isPadLike ? 66 : 56)
            .background(viewModel.theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: Layout.isPadLike ? 28 : 24, style: .continuous))
            .shadow(color: viewModel.theme.shadowColor, radius: 12, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSaving)
    }
}

#Preview {
    CreateSetView()
}
