import SwiftUI

struct SpeakingSetupPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

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

extension View {
    func speakingActionBarWidth() -> some View {
        self
            .frame(maxWidth: Layout.convContentMaxWidth)
            .frame(maxWidth: .infinity)
    }
}
