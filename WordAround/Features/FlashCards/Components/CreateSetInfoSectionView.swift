import SwiftUI

struct CreateSetInfoSectionView: View {
    @ObservedObject var viewModel: CreateSetViewModel

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isPadLike ? 20 : 14) {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("Set title")

                ZStack(alignment: .leading) {
                    if viewModel.draft.title.isEmpty {
                        Text("e.g. Basic Spanish Words")
                            .foregroundColor(.gray.opacity(0.75)) // ← ось тут темність
                    }

                    TextField("", text: $viewModel.draft.title)
                }
                .createSetFieldStyle(
                    height: isPadLike ? 56 : 48,
                    fontSize: isPadLike ? 16 : 14
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    sectionLabel("Description")
                    optionalText
                }

                ZStack(alignment: .bottomTrailing) {

                    ZStack(alignment: .topLeading) {
                        if viewModel.draft.description.isEmpty {
                            Text("What is this set about?")
                                .foregroundColor(.gray.opacity(0.75))
                                .font(.system(size: isPadLike ? 16 : 14, weight: .semibold))
                                .padding(.top, 12)
                                .padding(.leading, 14)
                        }

                        TextField("", text: $viewModel.draft.description, axis: .vertical)
                            .foregroundColor(AppColors.createSetDarkText)
                            .tint(AppColors.createSetRed)
                            .padding(.top, 12)
                            .padding(.horizontal, 14)
                            .frame(maxHeight: .infinity, alignment: .topLeading)
                    }
                    .frame(height: isPadLike ? 118 : 96)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AppColors.createSetBorder, lineWidth: 1)
                    )

                    Text("\(viewModel.draft.description.count)/200")
                        .font(.system(size: isPadLike ? 14 : 12, weight: .semibold))
                        .foregroundStyle(AppColors.createSetTextMuted)
                        .padding(.trailing, 14)
                        .padding(.bottom, 12)
                }
            }
        }
        .padding(isPadLike ? 22 : 14)
        .background(sectionBackground)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: isPadLike ? 16 : 13, weight: .bold))
            .foregroundStyle(AppColors.createSetDarkRed)
    }

    private var optionalText: some View {
        Text("(optional)")
            .font(.system(size: isPadLike ? 13 : 11, weight: .semibold))
            .foregroundStyle(AppColors.createSetTextMuted)
    }

    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: isPadLike ? 26 : 22, style: .continuous)
            .fill(Color.white.opacity(0.72))
            .overlay(
                RoundedRectangle(cornerRadius: isPadLike ? 26 : 22, style: .continuous)
                    .stroke(AppColors.createSetSoftBorder, lineWidth: 1)
            )
    }
}

#Preview {
    let vm = CreateSetViewModel()
    vm.draft.title = "Spanish Basics"
    vm.draft.description = "Simple words and phrases"

    return CreateSetInfoSectionView(viewModel: vm)
        .padding()
        .background(AppColors.createSetBackground)
}
