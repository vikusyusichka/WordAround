import SwiftUI

struct CreateSetHeaderView: View {
    @ObservedObject var viewModel: CreateSetViewModel
    let onBack: () -> Void

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    var body: some View {
        VStack(spacing: isPadLike ? 20 : 16) {
            topBar
            headerContent
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                onBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: isPadLike ? 22 : 16, weight: .semibold))
                    .foregroundStyle(AppColors.createSetTextMuted)
                    .frame(width: isPadLike ? 56 : 42, height: isPadLike ? 56 : 42)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: AppColors.createSetShadow, radius: 12, x: 0, y: 7)
            }
            .buttonStyle(.plain)

            Spacer()

            Menu {
                ForEach(viewModel.previewIcons, id: \.self) { icon in
                    Button {
                        viewModel.selectIcon(icon)
                    } label: {
                        Label(icon, systemImage: icon)
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Text("Choose icon")
                        .font(.system(size: isPadLike ? 16 : 13, weight: .bold))
                        .foregroundStyle(AppColors.createSetRed)

                    ZStack {
                        Circle()
                            .fill(AppColors.createSetSoftRed)
                            .frame(width: isPadLike ? 74 : 48, height: isPadLike ? 74 : 48)

                        Image(systemName: viewModel.draft.selectedIcon)
                            .font(.system(size: isPadLike ? 30 : 21, weight: .bold))
                            .foregroundStyle(AppColors.createSetRed)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var headerContent: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: isPadLike ? 8 : 4) {
                Text("Create Set")
                    .font(.system(size: isPadLike ? 38 : 26, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.createSetDarkRed)
                    .lineLimit(1)

                Text("Add a new flashcard set")
                    .font(.system(size: isPadLike ? 20 : 13, weight: .semibold))
                    .foregroundStyle(AppColors.createSetTextMuted)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            privacyControl
        }
    }

    private var privacyControl: some View {
        HStack(spacing: isPadLike ? 8 : 4) {
            if isPadLike {
                Text("Privacy")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppColors.createSetTextMuted)
            }

            ForEach(FlashcardSetPrivacy.allCases) { privacy in
                Button {
                    viewModel.draft.privacy = privacy
                } label: {
                    HStack(spacing: isPadLike ? 7 : 4) {
                        Image(systemName: privacy.iconName)
                            .font(.system(size: isPadLike ? 14 : 10, weight: .bold))

                        Text(privacy.rawValue)
                            .font(.system(size: isPadLike ? 14 : 10, weight: .bold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(
                        viewModel.draft.privacy == privacy
                        ? AppColors.createSetRed
                        : AppColors.createSetTextMuted
                    )
                    .padding(.horizontal, isPadLike ? 14 : 7)
                    .frame(height: isPadLike ? 42 : 30)
                    .background(
                        RoundedRectangle(cornerRadius: isPadLike ? 13 : 10, style: .continuous)
                            .fill(
                                viewModel.draft.privacy == privacy
                                ? AppColors.createSetSoftRed
                                : Color.white
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: isPadLike ? 13 : 10, style: .continuous)
                            .stroke(AppColors.createSetBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    CreateSetHeaderView(
        viewModel: {
            let vm = CreateSetViewModel()
            vm.draft.title = "Spanish A1"
            return vm
        }(),
        onBack: {}
    )
    .padding()
    .background(AppColors.createSetBackground)
}
