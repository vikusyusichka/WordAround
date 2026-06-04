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
                Text("Notes")
                    .font(.system(size: Layout.grammarSettingsTitleSize, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)

                Text("Settings")
                    .font(.system(size: Layout.grammarSettingsSubtitleSize, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.bottom, 4)
    }

    private var quickCaptureSection: some View {
        settingsSection(
            title: "Quick capture",
            subtitle: "Make fast notes and mistakes feel instant, not like filling tax forms with vowels.",
            icon: "bolt.fill",
            tint: AppColors.primaryBlue
        ) {
            settingsToggleRow(
                title: "Open editor after quick save",
                subtitle: "After saving a quick note, jump straight into the full editor.",
                icon: "arrow.up.forward.app.fill",
                tint: AppColors.primaryBlue,
                isOn: $settings.opensEditorAfterQuickSave
            )

            settingsToggleRow(
                title: "Highlight mistake notes",
                subtitle: "Use a subtle warm tint for mistake cards and quick mistake blocks.",
                icon: "exclamationmark.triangle.fill",
                tint: GrammarNoteType.mistake.tintColor,
                isOn: $settings.showsMistakeHighlights
            )
        }
    }

    private var mistakeNotesSection: some View {
        settingsSection(
            title: "Mistake notes",
            subtitle: "Control what gets saved when you capture a quick mistake.",
            icon: "exclamationmark.bubble.fill",
            tint: GrammarNoteType.mistake.tintColor
        ) {
            settingsToggleRow(
                title: "Include original sentence",
                subtitle: "Save the wrong version as a quote block in the note.",
                icon: "quote.bubble.fill",
                tint: GrammarNoteType.mistake.tintColor,
                isOn: $settings.includeOriginalSentence
            )

            settingsToggleRow(
                title: "Include corrected sentence",
                subtitle: "Save the fixed version as an example block.",
                icon: "checkmark.bubble.fill",
                tint: CreateSetTheme.green.accent,
                isOn: $settings.includeCorrectedSentence
            )

            settingsToggleRow(
                title: "Include explanation",
                subtitle: "Add your explanation as a paragraph block below.",
                icon: "lightbulb.fill",
                tint: CreateSetTheme.yellow.accent,
                isOn: $settings.createMistakeNotesWithExplanation
            )

            settingsToggleRow(
                title: "Group mistakes by topic",
                subtitle: "Save quick mistakes to the chosen topic instead of Common Mistakes.",
                icon: "folder.fill",
                tint: CreateSetTheme.purple.accent,
                isOn: $settings.groupMistakesByTopic
            )
        }
    }

    private var notesAppearanceSection: some View {
        settingsSection(
            title: "Notes appearance",
            subtitle: "Tune the list so it looks like an app, not a spreadsheet having a bad day.",
            icon: "rectangle.stack.fill",
            tint: CreateSetTheme.purple.accent
        ) {
            settingsToggleRow(
                title: "Pinned notes first",
                subtitle: "Keep important rules at the top of each topic.",
                icon: "pin.fill",
                tint: CreateSetTheme.purple.accent,
                isOn: $settings.groupsPinnedNotesFirst
            )

            settingsToggleRow(
                title: "Compact note cards",
                subtitle: "Show tighter cards when you want more notes visible on screen.",
                icon: "rectangle.compress.vertical",
                tint: CreateSetTheme.cyan.accent,
                isOn: $settings.usesCompactCards
            )
        }
    }

    private var defaultTypeSection: some View {
        settingsSection(
            title: "Quick Note Type",
            subtitle: "Choose what type Quick Notes create by default.",
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
            title: "Learning helpers",
            subtitle: "Small nudges inside empty states and quick sheets.",
            icon: "lightbulb.fill",
            tint: CreateSetTheme.yellow.accent
        ) {
            settingsToggleRow(
                title: "Show helper tips",
                subtitle: "Display short contextual hints while creating notes.",
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
                Text("Quick tip preview")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)

                Text("Use quick mistakes for sentences you actually wrote wrong. Those are more useful than textbook-perfect examples, naturally.")
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
