import SwiftUI

struct BaseCardView<Content: View>: View {
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let paddingValue: CGFloat
    let content: Content

    init(
        backgroundColor: Color = .white,
        cornerRadius: CGFloat = Layout.cardCornerRadius,
        paddingValue: CGFloat = Layout.cardInnerPadding,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.paddingValue = paddingValue
        self.content = content()
    }

    var body: some View {
        content
            .padding(paddingValue)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .clipShape(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        BaseCardView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Sample card")
                    .font(.headline)

                Text("Reusable base card")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}
