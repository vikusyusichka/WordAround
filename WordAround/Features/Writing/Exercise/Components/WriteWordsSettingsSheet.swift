import SwiftUI

struct WriteWordsSettingsSheet: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @ObservedObject var viewModel: WriteWordsViewModel

    private var metrics: ScreenMetrics {
        ScreenMetrics.current(horizontal: horizontalSizeClass, vertical: verticalSizeClass)
    }

    private let hPad: CGFloat = 20
    private let rowHeight: CGFloat = 54
    private let cornerRadius: CGFloat = 16

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(Color(red: 0.86, green: 0.89, blue: 0.96))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
                .padding(.bottom, 28)

            sectionHeader("Training mode")
                .padding(.horizontal, hPad)

            VStack(spacing: 8) {
                ForEach(WriteWordsTrainingMode.allCases) { mode in
                    modeRow(mode)
                }
            }
            .padding(.horizontal, hPad)
            .padding(.top, 10)

            sectionHeader("Difficulty")
                .padding(.horizontal, hPad)
                .padding(.top, 24)

            VStack(spacing: 8) {
                ForEach(WriteWordsDifficulty.allCases) { level in
                    difficultyRow(level)
                }
            }
            .padding(.horizontal, hPad)
            .padding(.top, 10)

            Spacer(minLength: 32)
        }
        .background(AppColors.appBackground)
        .presentationDetents([.height(metrics.isRegular ? 560 : 520)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: metrics.isRegular ? 17 : 15, weight: .bold, design: .rounded))
            .foregroundColor(AppColors.primaryBlueDark)
    }

    private func modeRow(_ mode: WriteWordsTrainingMode) -> some View {
        let isSelected = viewModel.trainingMode == mode

        return Button {
            viewModel.selectTrainingMode(mode)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppColors.primaryBlue : Color(red: 0.90, green: 0.92, blue: 0.97))
                        .frame(width: 30, height: 30)

                    Image(systemName: isSelected ? "checkmark" : (mode == .wordToTranslation ? "arrow.right" : "arrow.left"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isSelected ? .white : AppColors.textSecondary)
                }

                Text(mode.rawValue)
                    .font(.system(size: metrics.isRegular ? 15 : 14, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? AppColors.primaryBlueDark : AppColors.textSecondary)

                Spacer()
            }
            .padding(.horizontal, 14)
            .frame(height: rowHeight)
            .background(isSelected ? Color(red: 0.92, green: 0.94, blue: 1.00) : Color.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        isSelected ? AppColors.primaryBlue.opacity(0.35) : Color(red: 0.86, green: 0.89, blue: 0.96),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.16), value: isSelected)
    }

    private func difficultyRow(_ level: WriteWordsDifficulty) -> some View {
        let isSelected = viewModel.difficulty == level

        return Button {
            viewModel.selectDifficulty(level)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppColors.primaryBlue : Color(red: 0.90, green: 0.92, blue: 0.97))
                        .frame(width: 30, height: 30)

                    Image(systemName: isSelected ? "checkmark" : level.icon)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isSelected ? .white : AppColors.textSecondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(level.rawValue)
                        .font(.system(size: metrics.isRegular ? 15 : 14, weight: .semibold, design: .rounded))
                        .foregroundColor(isSelected ? AppColors.primaryBlueDark : AppColors.textSecondary)

                    Text(level.description)
                        .font(.system(size: metrics.isRegular ? 12 : 11, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.mutedText)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .frame(minHeight: rowHeight)
            .padding(.vertical, 8)
            .background(isSelected ? Color(red: 0.92, green: 0.94, blue: 1.00) : Color.white.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        isSelected ? AppColors.primaryBlue.opacity(0.35) : Color(red: 0.86, green: 0.89, blue: 0.96),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.16), value: isSelected)
    }
}

#Preview {
    Text("Settings")
        .sheet(isPresented: .constant(true)) {
            WriteWordsSettingsSheet(viewModel: WriteWordsViewModel())
        }
}
