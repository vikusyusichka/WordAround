import SwiftUI

// MARK: - Shared building blocks for the Speaking setup screens
//
// AI Conversation, Free Speaking, Describe Picture and Debate Mode all share
// the same setup layout: a themed top bar, section titles, a session-length
// picker and a gradient start button. These views capture that shared chrome
// once and are themed per mode via `accent` / `accentDark` — exactly the same
// pattern already used by `LanguageSelectorView` / `DifficultySelectorView`.
//
// Nothing here is mode-specific: each screen still owns its own preview card,
// extra sections (e.g. Debate's "Your side", AI Conversation's "Scenario") and
// navigation.

/// Subtle scale-down on press, shared by all Speaking setup controls.
struct SpeakingSetupPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Back button + title + subtitle, themed per mode.
struct SpeakingSetupTopBar: View {
    let title: String
    let subtitle: String
    var accent: Color = AppColors.primaryBlue
    var accentDark: Color = AppColors.primaryBlueDark
    let onBack: () -> Void

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: Layout.homeHeaderTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)

                Text(subtitle)
                    .font(.system(size: Layout.homeHeaderSubtitleSize, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.mutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, Layout.flashcardDetailTopButtonSize + 10)
            .padding(.trailing, 10)

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: Layout.flashcardDetailTopButtonIconSize, weight: .bold))
                        .foregroundColor(accentDark)
                        .frame(
                            width: Layout.flashcardDetailTopButtonSize,
                            height: Layout.flashcardDetailTopButtonSize
                        )
                        .background(accent.opacity(0.10))
                        .overlay(Circle().stroke(accent.opacity(0.22), lineWidth: 1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .hoverEffect(.lift)

                Spacer()
            }
        }
    }
}

/// Section heading ("Language", "Level", …), themed per mode.
struct SpeakingSetupSectionTitle: View {
    let title: String
    var accentDark: Color = AppColors.primaryBlueDark

    init(_ title: String, accentDark: Color = AppColors.primaryBlueDark) {
        self.title = title
        self.accentDark = accentDark
    }

    var body: some View {
        Text(title)
            .font(.system(size: Layout.homeSectionTitleSize, weight: .bold, design: .rounded))
            .foregroundColor(accentDark)
            .padding(.top, Layout.homeSectionTitleTopPadding)
    }
}

/// 5 / 10 / 15-minute session-length chips, themed per mode.
struct SpeakingSetupDurationPicker: View {
    @Binding var selection: ConversationLength
    var accent: Color = AppColors.primaryBlue
    var accentDark: Color = AppColors.primaryBlueDark

    private let lengths = ConversationLength.allCases

    var body: some View {
        HStack(spacing: Layout.convSetupGridSpacing) {
            ForEach(lengths) { length in
                let isSelected = selection == length
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { selection = length }
                } label: {
                    Text(length.title)
                        .font(.system(size: Layout.convSetupDurationChipTextSize, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .white : accentDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: Layout.convSetupDurationChipHeight)
                        .background(isSelected ? accent : accent.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                                .stroke(isSelected ? Color.clear : accent.opacity(0.22), lineWidth: 1)
                        )
                        .shadow(
                            color: isSelected ? accent.opacity(0.22) : Color.clear,
                            radius: isSelected ? 10 : 0,
                            x: 0,
                            y: isSelected ? 4 : 0
                        )
                }
                .buttonStyle(SpeakingSetupPressStyle())
                .hoverEffect(.lift)
            }
        }
    }
}

/// Full-width gradient start button, themed per mode.
struct SpeakingSetupStartButton: View {
    let title: String
    let icon: String
    var accent: Color = AppColors.primaryBlue
    var accentDark: Color = AppColors.primaryBlueDark
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: Layout.convSetupStartButtonTextSize - 2, weight: .bold))
                Text(title)
                    .font(.system(size: Layout.convSetupStartButtonTextSize, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: Layout.convSetupStartButtonHeight + (Layout.isPadLike ? 6 : 0))
            .background(
                LinearGradient(colors: [accent, accentDark], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: Layout.convSetupStartButtonCornerRadius, style: .continuous))
            .shadow(color: accent.opacity(0.30), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(SpeakingSetupPressStyle())
        .hoverEffect(.lift)
        .speakingActionBarWidth()
    }
}

// MARK: - Adaptive width

extension View {
    /// Centers and width-constrains a bottom action bar (Start button, mic bar,
    /// banners) to the same `convContentMaxWidth` used by the scroll content,
    /// so controls don't stretch edge-to-edge on iPad / large screens while the
    /// content above stays centered.
    ///
    /// No-op on iPhone: there `convContentMaxWidth` is `.infinity`, so the
    /// compact layout is byte-for-byte unchanged. Only iPad / regular-width
    /// screens are affected.
    func speakingActionBarWidth() -> some View {
        self
            .frame(maxWidth: Layout.convContentMaxWidth)
            .frame(maxWidth: .infinity)
    }
}
