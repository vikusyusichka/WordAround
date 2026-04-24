import SwiftUI

struct HomeHeaderView: View {
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Flashcards")
                    .font(.system(size: 29, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.18, green: 0.33, blue: 0.78))

                Text("Pick a set to practice")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.56, green: 0.60, blue: 0.72))
            }

            Spacer()

            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.95))
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
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .offset(x: 1, y: 1)
            }
        }
    }
}

#Preview {
    HomeHeaderView()
        .padding()
        .background(Color(red: 0.96, green: 0.96, blue: 0.985))
}
