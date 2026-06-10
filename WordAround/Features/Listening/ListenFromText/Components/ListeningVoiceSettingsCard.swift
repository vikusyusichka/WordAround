import SwiftUI

struct ListeningVoiceSettingsCard: View {
    @Binding var voiceSpeed: ListeningVoiceSpeed
    @Binding var voiceType: ListeningVoiceType
    @Binding var showTextWhileListening: Bool
    var accent: Color = ListeningTheme.accent
    var accentDark: Color = ListeningTheme.accentDark

    var body: some View {
        ListeningWhiteCard {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.string("listenVoiceSpeed"))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)

                    HStack(spacing: Layout.convSetupGridSpacing) {
                        ForEach(ListeningVoiceSpeed.allCases) { speed in
                            speedPill(speed)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.string("listenVoiceType"))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)

                    HStack(spacing: Layout.convSetupGridSpacing) {
                        ForEach(ListeningVoiceType.allCases) { type in
                            voiceTypePill(type)
                        }
                    }
                }

                Divider().opacity(0.5)

                ListeningToggleRow(
                    title: L10n.string("listenShowText"),
                    isOn: $showTextWhileListening,
                    accent: accent,
                    accentDark: accentDark
                )
            }
        }
    }

    private func speedPill(_ speed: ListeningVoiceSpeed) -> some View {
        let isSelected = voiceSpeed == speed
        return Button {
            withAnimation(.easeInOut(duration: 0.16)) { voiceSpeed = speed }
        } label: {
            Text(speed.rawValue)
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
        }
        .buttonStyle(ListeningSetupPressStyle())
    }

    private func voiceTypePill(_ type: ListeningVoiceType) -> some View {
        let isSelected = voiceType == type
        return Button {
            withAnimation(.easeInOut(duration: 0.16)) { voiceType = type }
        } label: {
            Text(type.title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? .white : accentDark)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? accent : accent.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                        .stroke(isSelected ? Color.clear : accent.opacity(0.22), lineWidth: 1)
                )
        }
        .buttonStyle(ListeningSetupPressStyle())
    }
}
