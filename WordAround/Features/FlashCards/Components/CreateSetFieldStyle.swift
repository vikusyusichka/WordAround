import SwiftUI

struct CreateSetFieldStyle: ViewModifier {
    let height: CGFloat
    let fontSize: CGFloat

    func body(content: Content) -> some View {
        content
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundColor(AppColors.createSetDarkText)
            .tint(AppColors.createSetRed)
            .padding(.horizontal, 14)
            .frame(minHeight: height)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppColors.createSetBorder, lineWidth: 1)
            )
    }
}

extension View {
    func createSetFieldStyle(height: CGFloat, fontSize: CGFloat) -> some View {
        modifier(CreateSetFieldStyle(height: height, fontSize: fontSize))
    }
}

#Preview {
    TextField("Example", text: .constant(""))
        .createSetFieldStyle(height: 48, fontSize: 14)
        .padding()
        .background(AppColors.createSetBackground)
}
