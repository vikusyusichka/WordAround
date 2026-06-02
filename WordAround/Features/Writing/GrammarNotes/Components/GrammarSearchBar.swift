import SwiftUI

struct GrammarSearchBar: View {
    let placeholder: String
    @Binding var text: String
    let theme: CreateSetTheme
    let isPadLike: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: isPadLike ? 17 : 15, weight: .semibold))
                .foregroundStyle(theme.mutedTextColor)

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
                        .foregroundStyle(theme.mutedTextColor.opacity(0.78))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, isPadLike ? 18 : 14)
        .frame(height: isPadLike ? 64 : 56)
        .background(theme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: isPadLike ? 22 : 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: isPadLike ? 22 : 18, style: .continuous)
                .stroke(theme.softBorderColor, lineWidth: 1)
        )
        .shadow(color: theme.shadowColor, radius: 14, x: 0, y: 8)
    }
}
