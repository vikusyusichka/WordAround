import SwiftUI

struct CreateSetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateSetViewModel()

    private var isPadLike: Bool {
        Layout.isPadLike
    }

    var body: some View {
        ZStack {
            viewModel.theme.screenBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: isPadLike ? 18 : 14) {
                    CreateSetHeaderView(
                        viewModel: viewModel,
                        onBack: {
                            dismiss()
                        }
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
                .padding(.horizontal, isPadLike ? 20 : 16)
                .padding(.top, isPadLike ? 12 : 8)
                .padding(.bottom, 28)
            }
        }
        .onChange(of: viewModel.didCreateSet) { _, didCreate in
            if didCreate {
                dismiss()
            }
        }
    }

    private var createButton: some View {
        Button {
            Task {
                await viewModel.createSet()
            }
        } label: {
            HStack {
                Spacer()

                Text(viewModel.isSaving ? "Saving..." : "Create Set")
                    .font(.system(size: isPadLike ? 21 : 18, weight: .semibold))

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: isPadLike ? 22 : 19, weight: .medium))
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 24)
            .frame(height: isPadLike ? 66 : 56)
            .background(viewModel.theme.accent)
            .clipShape(RoundedRectangle(cornerRadius: isPadLike ? 28 : 24, style: .continuous))
            .shadow(
                color: viewModel.theme.shadowColor,
                radius: 12,
                x: 0,
                y: 8
            )
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSaving)
    }
}

#Preview {
    CreateSetView()
}
