import SwiftUI

struct CreateSetPreviewCardView: View {
    @ObservedObject var viewModel: CreateSetViewModel

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("Preview")

            HStack(spacing: isPadLike ? 18 : 12) {
                iconView

                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.draft.title.isEmpty ? "New Set" : viewModel.draft.title)
                        .font(.system(size: isPadLike ? 24 : 18, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.createSetDarkRed)
                        .lineLimit(1)

                    Text("\(viewModel.draft.cards.count) cards")
                        .font(.system(size: isPadLike ? 17 : 14, weight: .semibold))
                        .foregroundStyle(AppColors.createSetTextMuted)
                }

                Spacer()
            }
            .padding(isPadLike ? 16 : 12)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppColors.createSetPreviewBackground)
            )
            .shadow(color: AppColors.createSetShadow, radius: 12, x: 0, y: 6)
        }
    }

    private var iconView: some View {
        Menu {
            ForEach(viewModel.previewIcons, id: \.self) { icon in
                Button {
                    viewModel.selectIcon(icon)
                } label: {
                    Label(icon, systemImage: icon)
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(AppColors.createSetSoftRed)
                    .frame(width: isPadLike ? 76 : 52, height: isPadLike ? 76 : 52)

                Image(systemName: viewModel.draft.selectedIcon)
                    .font(.system(size: isPadLike ? 32 : 22, weight: .bold))
                    .foregroundStyle(AppColors.createSetRed)
            }
        }
        .buttonStyle(.plain)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: isPadLike ? 16 : 13, weight: .bold))
            .foregroundStyle(AppColors.createSetDarkRed)
    }
}

#Preview {
    let vm = CreateSetViewModel()
    vm.draft.title = "French B1"
    vm.draft.cards = [
        CreateFlashcardDraft(),
        CreateFlashcardDraft()
    ]
    vm.draft.selectedIcon = "book.closed.fill"

    return CreateSetPreviewCardView(viewModel: vm)
        .padding()
        .background(AppColors.createSetBackground)
}
