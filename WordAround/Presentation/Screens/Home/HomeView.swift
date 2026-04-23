import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @State private var selectedCategory: HomeCategory = .speaking
    @State private var selectedTab: HomeTab = .flashcards

    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundLayer

            VStack(spacing: 0) {
                HomeHeaderView()
                    .padding(.top, 10)
                    .padding(.horizontal, 20)

                HStack(alignment: .top, spacing: 10) {
                    CategorySidebarView(selectedCategory: $selectedCategory)
                        .frame(width: 94)

                    contentPlaceholder
                }
                .padding(.top, 18)
                .padding(.leading, 8)

                Spacer(minLength: 104)
            }

            BottomNavigationBar(selectedTab: $selectedTab)
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

private extension HomeView {
    var backgroundLayer: some View {
        ZStack {
            Color(red: 0.96, green: 0.96, blue: 0.985)
                .ignoresSafeArea()

            BlobShape()
                .fill(Color(red: 0.83, green: 0.87, blue: 0.96).opacity(0.28))
                .frame(width: 120, height: 145)
                .rotationEffect(.degrees(14))
                .offset(x: -175, y: 310)

            BlobShape()
                .fill(Color(red: 0.82, green: 0.93, blue: 0.82).opacity(0.18))
                .frame(width: 95, height: 115)
                .rotationEffect(.degrees(-18))
                .offset(x: 165, y: 340)
        }
    }

    var contentPlaceholder: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.78))
                .frame(height: 185)
                .overlay(
                    Text("Flashcard cards will be here")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.58, green: 0.62, blue: 0.73))
                )

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.78))
                .frame(height: 185)

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.78))
                .frame(height: 185)
        }
        .padding(.trailing, 18)
    }
}

#Preview {
    HomeView()
        .environmentObject(SessionStore())
}
