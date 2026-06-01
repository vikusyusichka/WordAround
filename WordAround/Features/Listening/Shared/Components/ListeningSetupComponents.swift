import SwiftUI

struct ListeningSetupPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct ListeningSetupTopBar: View {
    let title: String
    let subtitle: String
    var accent: Color = ListeningTheme.accent
    var accentDark: Color = ListeningTheme.accentDark
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
                    .lineLimit(2)
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
                        .background(Color.white.opacity(0.82))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .hoverEffect(.lift)

                Spacer()
            }
        }
    }
}

struct ListeningSetupSectionTitle: View {
    let title: String
    var accentDark: Color = ListeningTheme.accentDark

    init(_ title: String, accentDark: Color = ListeningTheme.accentDark) {
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

struct ListeningSetupStartButton: View {
    let title: String
    let icon: String
    var accent: Color = ListeningTheme.accent
    var accentDark: Color = ListeningTheme.accentDark
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
        .buttonStyle(ListeningSetupPressStyle())
        .hoverEffect(.lift)
        .listeningActionBarWidth()
    }
}

extension View {
    func listeningActionBarWidth() -> some View {
        self
            .frame(maxWidth: Layout.convContentMaxWidth)
            .frame(maxWidth: .infinity)
    }
}

struct ListeningWhiteCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.94))
                    .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
            )
    }
}

struct ListeningToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    var accent: Color = ListeningTheme.accent
    var accentDark: Color = ListeningTheme.accentDark

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(accentDark)
        }
        .tint(accent)
    }
}
