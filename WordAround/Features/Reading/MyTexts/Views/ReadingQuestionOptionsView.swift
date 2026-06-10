import SwiftUI

struct ReadingQuestionOptionsView: View {
    @Binding var enabledTypes: Set<ReadingQuestionType>
    let accent: Color
    let accentDark: Color
    let onToggle: (ReadingQuestionType) -> Void

    var body: some View {
        ReadingSetupSectionCard(
            title: L10n.string("listenQuestionTypes"),
            subtitle: L10n.string("readingQTypesSubtitle"),
            accentDark: accentDark
        ) {
            VStack(spacing: 8) {
                ForEach(ReadingQuestionType.allCases, id: \.self) { type in
                    questionToggle(type)
                }
            }
        }
    }

    private func questionToggle(_ type: ReadingQuestionType) -> some View {
        let isOn = enabledTypes.contains(type)
        return Button {
            onToggle(type)
        } label: {
            HStack(spacing: 12) {
                Text(type.displayTitle)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(accentDark)
                Spacer(minLength: 0)
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isOn ? accent : AppColors.mutedText)
            }
            .padding(.horizontal, 16)
            .frame(height: Layout.convSetupDurationChipHeight)
            .background(
                RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.94))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                    .stroke(isOn ? accent.opacity(0.35) : accent.opacity(0.14), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
