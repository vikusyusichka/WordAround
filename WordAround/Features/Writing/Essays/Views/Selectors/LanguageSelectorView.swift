import SwiftUI

struct LanguageSelectorView: View {
    let selectedLanguage: GrammarLanguage
    let onSelect: (GrammarLanguage) -> Void

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
                Image(systemName: "globe.europe.africa.fill")
                    .font(.system(size: isPadLike ? 15 : 13, weight: .semibold))
                    .foregroundColor(AppColors.primaryBlue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Language")
                        .font(.system(size: isPadLike ? 11 : 10, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)

                    Text(selectedLanguage.title)
                        .font(.system(size: isPadLike ? 14 : 13, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)
                        .lineLimit(1)
                }

                Spacer(minLength: 6)

                Text(selectedLanguage.shortTitle)
                    .font(.system(size: isPadLike ? 12 : 11, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlue)
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
            ForEach(GrammarLanguage.allCases) { language in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onSelect(language)
                        isExpanded = false
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text(language.shortTitle)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(
                                selectedLanguage == language
                                ? .white
                                : AppColors.primaryBlue
                            )
                            .frame(width: 34, height: 26)
                            .background(
                                selectedLanguage == language
                                ? AppColors.primaryBlue
                                : AppColors.primaryBlue.opacity(0.08)
                            )
                            .clipShape(Capsule())

                        Text(language.title)
                            .font(.system(size: isPadLike ? 14 : 13, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.primaryBlueDark)

                        Spacer(minLength: 0)

                        if selectedLanguage == language {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppColors.primaryBlue)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        selectedLanguage == language
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
    LanguageSelectorView(
        selectedLanguage: .english,
        onSelect: { _ in }
    )
    .padding()
    .background(AppColors.appBackground)
}
