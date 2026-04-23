import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var sessionStore: SessionStore

    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Home Screen")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.black)

                Text("Signed in as")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)

                Text(sessionStore.currentEmail)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Button(action: {
                    sessionStore.signOut()
                }) {
                    Text("Sign Out")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 220, height: 64)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
            }
            .padding()
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(SessionStore())
}
