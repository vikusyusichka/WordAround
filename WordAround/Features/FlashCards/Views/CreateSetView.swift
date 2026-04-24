import SwiftUI

struct CreateSetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateSetViewModel()

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    var body: some View {
        ZStack {
            AppColors.createSetBackground
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
                }
                .padding(.horizontal, isPadLike ? 20 : 16)
                .padding(.top, isPadLike ? 12 : 8)
                .padding(.bottom, 28)
            }
        }
    }

    private var createButton: some View {
        Button {
            viewModel.createSet()
        } label: {
            HStack {
                Spacer()

                Text("Create Set")
                    .font(.system(size: isPadLike ? 21 : 18, weight: .semibold))

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: isPadLike ? 22 : 19, weight: .medium))
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 24)
            .frame(height: isPadLike ? 66 : 56)
            .background(AppColors.createSetRed)
            .clipShape(RoundedRectangle(cornerRadius: isPadLike ? 28 : 24, style: .continuous))
            .shadow(color: AppColors.createSetRed.opacity(0.25), radius: 12, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CreateSetView()
}
