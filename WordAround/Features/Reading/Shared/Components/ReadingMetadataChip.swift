import SwiftUI

struct ReadingMetadataChip: View {
    let text: String
    var accent: Color = AppColors.primaryBlue

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(accent)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(accent.opacity(0.12))
            .clipShape(Capsule())
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        HStack {
            ReadingMetadataChip(text: "B1")
            ReadingMetadataChip(text: "8 questions", accent: AppColors.orangeAccent)
        }
        .padding()
    }
}
