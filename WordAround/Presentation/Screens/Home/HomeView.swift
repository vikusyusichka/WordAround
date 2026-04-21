import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("WordAround")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Learn words in a fun way")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

#Preview {
    HomeView()
}
