import SwiftUI

struct PracticeLibraryLoadingView: View {
    let message: String
    let accent: Color

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(accent)
            Text(message)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}
