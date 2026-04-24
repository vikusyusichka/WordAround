import SwiftUI

struct HomeHeaderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 29, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)

                Text(subtitle)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.mutedText)
            }

            Spacer()

            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(AppColors.cardWhite)
                        .frame(width: 54, height: 54)

                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 42, height: 42)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.70, green: 0.75, blue: 0.85),
                                    Color(red: 0.42, green: 0.48, blue: 0.60)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)

                Circle()
                    .fill(Color(red: 1.0, green: 0.29, blue: 0.24))
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .offset(x: 1, y: 1)
            }
        }
    }
}

#Preview {
    HomeHeaderView(title: "Flashcards", subtitle: "Pick a set to practice")
        .padding()
        .background(AppColors.appBackground)
}
