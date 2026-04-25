import SwiftUI

struct CreateSetHeaderView: View {
    @ObservedObject var viewModel: CreateSetViewModel
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: Layout.createSetHeaderSpacing) {
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
                    .font(.system(size: Layout.createSetBackButtonIconSize, weight: .semibold))
                    .foregroundStyle(viewModel.theme.mutedTextColor)
                    .frame(
                        width: Layout.createSetBackButtonSize,
                        height: Layout.createSetBackButtonSize
                    )
                    .background(viewModel.theme.fieldBackground)
                    .clipShape(Circle())
                    .shadow(color: viewModel.theme.shadowColor, radius: 12, x: 0, y: 7)
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
                        .font(.system(size: Layout.createSetChooseIconTextSize, weight: .bold))
                        .foregroundStyle(viewModel.theme.accent)

                    ZStack {
                        Circle()
                            .fill(viewModel.theme.softAccent)
                            .frame(
                                width: Layout.createSetHeaderIconCircleSize,
                                height: Layout.createSetHeaderIconCircleSize
                            )

                        Image(systemName: viewModel.draft.selectedIcon)
                            .font(.system(size: Layout.createSetHeaderIconSize, weight: .bold))
                            .foregroundStyle(viewModel.theme.accent)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var headerContent: some View {
        HStack(alignment: .center, spacing: Layout.createSetHeaderContentSpacing) {
            VStack(alignment: .leading, spacing: Layout.createSetHeaderTitleStackSpacing) {
                Text("Create Set")
                    .font(.system(
                        size: Layout.createSetHeaderTitleSize,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundStyle(viewModel.theme.titleColor)
                    .lineLimit(1)

                Text("Add a new flashcard set")
                    .font(.system(size: Layout.createSetHeaderSubtitleSize, weight: .semibold))
                    .foregroundStyle(viewModel.theme.mutedTextColor)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            privacyControl
        }
    }

    private var privacyControl: some View {
        HStack(spacing: Layout.createSetPrivacySpacing) {
            if Layout.isPadLike {
                Text("Privacy")
                    .font(.system(size: Layout.createSetPrivacyLabelSize, weight: .semibold))
                    .foregroundStyle(viewModel.theme.mutedTextColor)
            }

            ForEach(FlashcardSetPrivacy.allCases) { privacy in
                Button {
                    viewModel.draft.privacy = privacy
                } label: {
                    HStack(spacing: Layout.createSetPrivacyInnerSpacing) {
                        Image(systemName: privacy.iconName)
                            .font(.system(size: Layout.createSetPrivacyIconSize, weight: .bold))

                        Text(privacy.rawValue)
                            .font(.system(size: Layout.createSetPrivacyTextSize, weight: .bold))
                            .lineLimit(1)
                    }
                    .foregroundStyle(
                        viewModel.draft.privacy == privacy
                        ? viewModel.theme.accent
                        : viewModel.theme.mutedTextColor
                    )
                    .padding(.horizontal, Layout.createSetPrivacyHorizontalPadding)
                    .frame(height: Layout.createSetPrivacyButtonHeight)
                    .background(
                        RoundedRectangle(
                            cornerRadius: Layout.createSetPrivacyCornerRadius,
                            style: .continuous
                        )
                        .fill(
                            viewModel.draft.privacy == privacy
                            ? viewModel.theme.softAccent
                            : viewModel.theme.fieldBackground
                        )
                    )
                    .overlay(
                        RoundedRectangle(
                            cornerRadius: Layout.createSetPrivacyCornerRadius,
                            style: .continuous
                        )
                        .stroke(viewModel.theme.borderColor, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    let vm: CreateSetViewModel = {
        let vm = CreateSetViewModel()
        vm.draft.title = "Spanish A1"
        vm.selectColor(.blue)
        return vm
    }()

    CreateSetHeaderView(
        viewModel: vm,
        onBack: {}
    )
    .padding()
    .background(vm.theme.screenBackground)
}
