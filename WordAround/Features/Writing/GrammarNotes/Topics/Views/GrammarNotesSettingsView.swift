import SwiftUI

struct GrammarNotesSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = GrammarNotesSettingsStore()

    @MainActor init() {}

    var body: some View {
        ZStack {
            AppColors.appBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.grammarSettingsSectionSpacing) {
                    header
                    quickCaptureSection
                    mistakeNotesSection
                    notesAppearanceSection
                    defaultTypeSection
                    helperSection
                }
                .padding(.horizontal, Layout.grammarSettingsHorizontalPadding)
                .padding(.top, Layout.grammarSettingsTopPadding)
                .padding(.bottom, Layout.grammarSettingsBottomPadding)
                .frame(maxWidth: Layout.grammarSettingsContentMaxWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .animation(Layout.grammarQuickSheetAnimation, value: settings.opensEditorAfterQuickSave)
        .animation(Layout.grammarQuickSheetAnimation, value: settings.showsMistakeHighlights)
        .animation(Layout.grammarQuickSheetAnimation, value: settings.showsHelperTips)
        .animation(Layout.grammarQuickSheetAnimation, value: settings.groupsPinnedNotesFirst)
        .animation(Layout.grammarQuickSheetAnimation, value: settings.usesCompactCards)
        .animation(Layout.grammarQuickSheetAnimation, value: settings.groupMistakesByTopic)
        .animation(Layout.grammarQuickSheetAnimation, value: settings.quickNoteType)
    }

    private var header: some View {
        HStack(spacing: 13) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: Layout.grammarSettingsBackIconSize, weight: .black))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .frame(
                        width: Layout.grammarSettingsBackButtonSize,
                        height: Layout.grammarSettingsBackButtonSize
                    )
                    .background(Color.white.opacity(0.88))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.string("categoryNotes"))
                    .font(.system(size: Layout.grammarSettingsTitleSize, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)

                Text(L10n.string("commonSettings"))
                    .font(.system(size: Layout.grammarSettingsSubtitleSize, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.bottom, 4)
    }

    private var quickCaptureSection: some View {
        settingsSection(
            title: L10n.string("notesSetQuickCapture"),
            subtitle: L10n.string("notesSetQuickCaptureSub"),
            icon: "bolt.fill",
            tint: AppColors.primaryBlue
        ) {
            settingsToggleRow(
                title: L10n.string("notesSetOpenEditor"),
                subtitle: L10n.string("notesSetOpenEditorSub"),
                icon: "arrow.up.forward.app.fill",
                tint: AppColors.primaryBlue,
                isOn: $settings.opensEditorAfterQuickSave
            )

            settingsToggleRow(
                title: L10n.string("notesSetHighlight"),
                subtitle: L10n.string("notesSetHighlightSub"),
                icon: "exclamationmark.triangle.fill",
                tint: GrammarNoteType.mistake.tintColor,
                isOn: $settings.showsMistakeHighlights
            )
        }
    }

    private var mistakeNotesSection: some View {
        settingsSection(
            title: L10n.string("notesSetMistakeNotes"),
            subtitle: L10n.string("notesSetMistakeNotesSub"),
            icon: "exclamationmark.bubble.fill",
            tint: GrammarNoteType.mistake.tintColor
        ) {
            settingsToggleRow(
                title: L10n.string("notesSetIncludeOriginal"),
                subtitle: L10n.string("notesSetIncludeOriginalSub"),
                icon: "quote.bubble.fill",
                tint: GrammarNoteType.mistake.tintColor,
                isOn: $settings.includeOriginalSentence
            )

            settingsToggleRow(
                title: L10n.string("notesSetIncludeCorrected"),
                subtitle: L10n.string("notesSetIncludeCorrectedSub"),
                icon: "checkmark.bubble.fill",
                tint: CreateSetTheme.green.accent,
                isOn: $settings.includeCorrectedSentence
            )

            settingsToggleRow(
                title: L10n.string("notesSetIncludeExplanation"),
                subtitle: L10n.string("notesSetIncludeExplanationSub"),
                icon: "lightbulb.fill",
                tint: CreateSetTheme.yellow.accent,
                isOn: $settings.createMistakeNotesWithExplanation
            )

            settingsToggleRow(
                title: L10n.string("notesSetGroupByTopic"),
                subtitle: L10n.string("notesSetGroupByTopicSub"),
                icon: "folder.fill",
                tint: CreateSetTheme.purple.accent,
                isOn: $settings.groupMistakesByTopic
            )
        }
    }

    private var notesAppearanceSection: some View {
        settingsSection(
            title: L10n.string("notesSetAppearance"),
            subtitle: L10n.string("notesSetAppearanceSub"),
            icon: "rectangle.stack.fill",
            tint: CreateSetTheme.purple.accent
        ) {
            settingsToggleRow(
                title: L10n.string("notesSetPinnedFirst"),
                subtitle: L10n.string("notesSetPinnedFirstSub"),
                icon: "pin.fill",
                tint: CreateSetTheme.purple.accent,
                isOn: $settings.groupsPinnedNotesFirst
            )

            settingsToggleRow(
                title: L10n.string("notesSetCompact"),
                subtitle: L10n.string("notesSetCompactSub"),
                icon: "rectangle.compress.vertical",
                tint: CreateSetTheme.cyan.accent,
                isOn: $settings.usesCompactCards
            )
        }
    }

    private var defaultTypeSection: some View {
        settingsSection(
            title: L10n.string("notesSetQuickNoteType"),
            subtitle: L10n.string("notesSetQuickNoteTypeSub"),
            icon: "doc.text.fill",
            tint: settings.quickNoteType.tintColor
        ) {
            LazyVGrid(
                columns: [
                    GridItem(
                        .adaptive(minimum: Layout.grammarSettingsTypeMinWidth),
                        spacing: 10
                    )
                ],
                spacing: 10
            ) {
                ForEach(GrammarNoteType.allCases) { type in
                    defaultTypeButton(type)
                }
            }
        }
    }

    private var helperSection: some View {
        settingsSection(
            title: L10n.string("notesSetHelpers"),
            subtitle: L10n.string("notesSetHelpersSub"),
            icon: "lightbulb.fill",
            tint: CreateSetTheme.yellow.accent
        ) {
            settingsToggleRow(
                title: L10n.string("notesSetShowTips"),
                subtitle: L10n.string("notesSetShowTipsSub"),
                icon: "lightbulb.fill",
                tint: CreateSetTheme.yellow.accent,
                isOn: $settings.showsHelperTips
            )

            helperPreviewCard
        }
    }

    private func settingsSection<Content: View>(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Layout.grammarSettingsCardInnerSpacing) {
            HStack(alignment: .top, spacing: 11) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.12))

                    Image(systemName: icon)
                        .font(.system(size: Layout.grammarSettingsSectionIconSize, weight: .bold))
                        .foregroundStyle(tint)
                }
                .frame(
                    width: Layout.grammarSettingsSectionIconBox,
                    height: Layout.grammarSettingsSectionIconBox
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: Layout.grammarSettingsSectionTitleSize, weight: .black, design: .rounded))
                        .foregroundStyle(AppColors.primaryBlueDark)

                    Text(subtitle)
                        .font(.system(size: Layout.grammarSettingsSectionSubtitleSize, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                        .lineSpacing(3)
                }

                Spacer(minLength: 0)
            }

            content()
        }
        .padding(Layout.grammarSettingsCardPadding)
        .background(sectionBackground(tint: tint))
        .clipShape(
            RoundedRectangle(
                cornerRadius: Layout.grammarSettingsCardCornerRadius,
                style: .continuous
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: Layout.grammarSettingsCardCornerRadius,
                style: .continuous
            )
            .stroke(Color.white.opacity(0.62), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.045), radius: 18, x: 0, y: 10)
    }

    private func settingsToggleRow(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.10))

                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(tint)
            }
            .frame(
                width: Layout.grammarSettingsRowIconBox,
                height: Layout.grammarSettingsRowIconBox
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: Layout.grammarSettingsRowTitleSize, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)

                Text(subtitle)
                    .font(.system(size: Layout.grammarSettingsRowSubtitleSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(2)
            }

            Spacer(minLength: 0)

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(tint)
        }
        .padding(Layout.grammarSettingsRowPadding)
        .background(Color.white.opacity(0.68))
        .clipShape(
            RoundedRectangle(
                cornerRadius: Layout.grammarSettingsRowCornerRadius,
                style: .continuous
            )
        )
    }

    private func defaultTypeButton(_ type: GrammarNoteType) -> some View {
        let isSelected = settings.quickNoteType == type

        return Button {
            settings.quickNoteType = type
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill((isSelected ? Color.white : type.tintColor).opacity(isSelected ? 0.22 : 0.12))

                    Image(systemName: type.systemImage)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(isSelected ? Color.white : type.tintColor)
                }
                .frame(width: 38, height: 38)

                Text(type.title)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(isSelected ? Color.white : AppColors.primaryBlueDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Layout.grammarSettingsTypeButtonHeight)
            .background(isSelected ? type.tintColor : Color.white.opacity(0.68))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isSelected ? Color.white.opacity(0.34) : type.tintColor.opacity(0.08),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(GrammarNotesScaleButtonStyle())
    }

    private var helperPreviewCard: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppColors.primaryBlue)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.string("notesSetTipPreview"))
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)

                Text(L10n.string("notesSetTipPreviewText"))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(3)
            }

            Spacer(minLength: 0)
        }
        .padding(Layout.grammarSettingsRowPadding)
        .background(AppColors.primaryBlue.opacity(0.07))
        .clipShape(
            RoundedRectangle(
                cornerRadius: Layout.grammarSettingsRowCornerRadius,
                style: .continuous
            )
        )
        .opacity(settings.showsHelperTips ? 1 : 0.45)
    }

    private func sectionBackground(tint: Color) -> some View {
        ZStack(alignment: .topTrailing) {
            Color.white.opacity(0.84)

            BlobShape()
                .fill(tint.opacity(0.09))
                .frame(
                    width: Layout.isPadLike ? 150 : 110,
                    height: Layout.isPadLike ? 120 : 90
                )
                .rotationEffect(.degrees(-9))
                .offset(
                    x: Layout.isPadLike ? 48 : 36,
                    y: Layout.isPadLike ? -40 : -28
                )
        }
    }
}

#Preview {
    NavigationStack {
        GrammarNotesSettingsView()
    }
}
