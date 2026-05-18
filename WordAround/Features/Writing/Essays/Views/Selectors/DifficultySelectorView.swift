import SwiftUI

struct DifficultySelectorView: View {
    let selectedDifficulty: EssayDifficulty
    let onSelect: (EssayDifficulty) -> Void

    @State private var isExpanded = false

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            selectorButton

            if isExpanded {
                optionsList
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: isExpanded)
    }

    private var selectorButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 9) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: isPadLike ? 15 : 13, weight: .semibold))
                    .foregroundColor(AppColors.primaryBlue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Level")
                        .font(.system(size: isPadLike ? 11 : 10, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)

                    Text(selectedDifficulty.title)
                        .font(.system(size: isPadLike ? 14 : 13, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)
                }

                Spacer(minLength: 6)

                Text(selectedDifficulty.helperIntensityTitle)
                    .font(.system(size: isPadLike ? 12 : 11, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(AppColors.primaryBlue.opacity(0.08))
                    .clipShape(Capsule())

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppColors.textSecondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .padding(.horizontal, isPadLike ? 16 : 14)
            .padding(.vertical, isPadLike ? 13 : 12)
            .background(Color.white.opacity(0.86))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppColors.primaryBlue.opacity(isExpanded ? 0.18 : 0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.035), radius: 12, x: 0, y: 7)
        }
        .buttonStyle(.plain)
    }

    private var optionsList: some View {
        VStack(spacing: 6) {
            ForEach(EssayDifficulty.allCases) { difficulty in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onSelect(difficulty)
                        isExpanded = false
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text(difficulty.title)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(
                                selectedDifficulty == difficulty
                                ? .white
                                : AppColors.primaryBlue
                            )
                            .frame(width: 46, height: 26)
                            .background(
                                selectedDifficulty == difficulty
                                ? AppColors.primaryBlue
                                : AppColors.primaryBlue.opacity(0.08)
                            )
                            .clipShape(Capsule())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(difficulty.helperIntensityTitle)
                                .font(.system(size: isPadLike ? 14 : 13, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.primaryBlueDark)

                            Text("\(difficulty.hintsLimit) hints • \(difficulty.allowsTranslation ? "translation" : "no translation")")
                                .font(.system(size: isPadLike ? 12 : 11, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }

                        Spacer(minLength: 0)

                        if selectedDifficulty == difficulty {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppColors.primaryBlue)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        selectedDifficulty == difficulty
                        ? AppColors.primaryBlue.opacity(0.07)
                        : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 8)
    }
}

#Preview {
    DifficultySelectorView(
        selectedDifficulty: .b1,
        onSelect: { _ in }
    )
    .padding()
    .background(AppColors.appBackground)
}
