import SwiftUI

enum GrammarSearchBarAppearance {
    case standard
    case elevated
}

struct GrammarSearchBar: View {
    let placeholder: String
    @Binding var text: String
    let theme: CreateSetTheme
    let isPadLike: Bool
    var appearance: GrammarSearchBarAppearance = .standard

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: isPadLike ? 17 : 15, weight: .semibold))
                .foregroundStyle(iconColor)

            TextField(placeholder, text: $text)
                .font(.system(size: isPadLike ? 17 : 15, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textColor)
                .tint(theme.accent)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(iconColor.opacity(0.78))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, isPadLike ? 18 : 14)
        .frame(height: isPadLike ? 56 : 50)
        .background(fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: isPadLike ? 18 : 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: isPadLike ? 18 : 16, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .shadow(color: shadowColor, radius: appearance == .elevated ? 8 : 14, x: 0, y: appearance == .elevated ? 4 : 8)
    }

    private var fieldBackground: Color {
        switch appearance {
        case .standard: return theme.fieldBackground
        case .elevated: return Color.white
        }
    }

    private var borderColor: Color {
        switch appearance {
        case .standard: return theme.softBorderColor
        case .elevated: return theme.softBorderColor.opacity(0.65)
        }
    }

    private var iconColor: Color {
        switch appearance {
        case .standard: return theme.mutedTextColor
        case .elevated: return AppColors.textSecondary
        }
    }

    private var shadowColor: Color {
        switch appearance {
        case .standard: return theme.shadowColor
        case .elevated: return Color.black.opacity(0.06)
        }
    }
}
