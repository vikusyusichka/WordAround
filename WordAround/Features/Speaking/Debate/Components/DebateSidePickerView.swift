import SwiftUI

struct DebateSidePickerView: View {
    let selectedSide: DebateSide
    let onSelect: (DebateSide) -> Void

    private let accent = DebateTheme.accent
    private let accentDark = DebateTheme.accentDark
    private let sides = DebateSide.allCases

    var body: some View {
        VStack(spacing: 10) {
            ForEach(sides) { side in
                row(side)
            }
        }
    }

    private func row(_ side: DebateSide) -> some View {
        let isSelected = selectedSide == side
        return Button {
            withAnimation(.easeInOut(duration: 0.18)) { onSelect(side) }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? accent : accent.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Image(systemName: side.systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? .white : accent)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(side.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(accentDark)
                    Text(side.subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(accent)
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.98 : 0.86))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                    .stroke(isSelected ? accent.opacity(0.45) : accent.opacity(0.10), lineWidth: isSelected ? 1.5 : 1)
            )
            .shadow(color: isSelected ? accent.opacity(0.16) : Color.black.opacity(0.04), radius: isSelected ? 12 : 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .hoverEffect(.lift)
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        DebateSidePickerView(selectedSide: .agree, onSelect: { _ in })
            .padding()
    }
}
