import SwiftUI

struct ReadingSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ReadingSetupViewModel

    init(config: ReadingSetupConfig) {
        _viewModel = StateObject(wrappedValue: ReadingSetupViewModel(config: config))
    }

    private var config: ReadingSetupConfig { viewModel.config }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                    ReadingSetupHeaderView(
                        title: config.title,
                        subtitle: config.subtitle,
                        accent: config.accent, accentDark: config.accentDark,
                        onBack: { dismiss() }
                    )
                    .padding(.bottom, 4)

                    ReadingSetupSectionCard(title: "Language", accentDark: config.accentDark) {
                        LanguageSelectorView(
                            selectedLanguage: viewModel.selectedLanguage,
                            onSelect: { viewModel.selectedLanguage = $0 },
                            accent: config.accent, accentDark: config.accentDark
                        )
                    }

                    ForEach(config.sections) { section in
                        ReadingSetupSectionCard(
                            title: section.title,
                            subtitle: section.subtitle,
                            helper: helperText(for: section),
                            accentDark: config.accentDark
                        ) {
                            sectionContent(section)
                        }
                    }

                    ReadingSetupSectionCard(title: "Preview", accentDark: config.accentDark) {
                        ReadingPreviewCard(
                            title: config.previewTitle,
                            subtitle: config.previewSubtitle,
                            chips: viewModel.previewChips,
                            accent: config.accent, accentDark: config.accentDark,
                            systemImage: config.previewIcon
                        )
                    }

                    Spacer().frame(height: Layout.convSetupStartButtonHeight + 32)
                }
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
            }

            ReadingPrimaryButton(title: config.ctaTitle, icon: config.ctaIcon, accent: config.accent, accentDark: config.accentDark) {
                viewModel.start()
            }
            .frame(maxWidth: Layout.convContentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Section content

    private func helperText(for section: ReadingSetupConfig.Section) -> String? {
        guard let helper = section.helper else { return nil }
        return helper(viewModel.selections[section.id] ?? "")
    }

    @ViewBuilder
    private func sectionContent(_ section: ReadingSetupConfig.Section) -> some View {
        switch section.kind {
        case let .segmented(options, columns, _):
            ReadingSegmentedSelector(
                options: options,
                selection: selectionBinding(section.id),
                accent: config.accent, accentDark: config.accentDark,
                columns: columns
            )
        case let .toggles(specs):
            VStack(spacing: 10) {
                ForEach(specs) { spec in
                    assistToggle(spec.title, isOn: toggleBinding(spec.id))
                }
            }
        case let .infoCard(title, subtitle, systemImage):
            infoCard(title: title, subtitle: subtitle, systemImage: systemImage)
        }
    }

    private func selectionBinding(_ id: String) -> Binding<String> {
        Binding(get: { viewModel.selections[id] ?? "" }, set: { viewModel.selections[id] = $0 })
    }

    private func toggleBinding(_ id: String) -> Binding<Bool> {
        Binding(get: { viewModel.toggles[id] ?? false }, set: { viewModel.toggles[id] = $0 })
    }

    private func assistToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
            Spacer(minLength: 0)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(config.accent)
        }
        .padding(.horizontal, 16)
        .frame(height: Layout.convSetupDurationChipHeight)
        .background(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .stroke(config.accent.opacity(0.16), lineWidth: 1)
        )
    }

    private func infoCard(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(config.accent.opacity(0.14))
                    .frame(width: 48, height: 48)
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(config.accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(config.accentDark)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.mutedText)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .stroke(config.accent.opacity(0.16), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack { ReadingSetupView(config: .generatedReading) }
}
