import SwiftUI

struct BottomNavigationBar: View {
    @Binding var selectedTab: HomeTab?
    @Binding var selectedCategory: HomeCategory?
    @State private var pressedTab: HomeTab?

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    private var isCompact: Bool {
        !isPadLike && UIScreen.main.bounds.width < 390
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(HomeTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, isPadLike ? 16 : (isCompact ? 8 : 10))
        .frame(height: isPadLike ? 110 : (isCompact ? 76 : 84))
        .background(
            RoundedRectangle(cornerRadius: isPadLike ? 34 : 26, style: .continuous)
                .fill(Color.white.opacity(0.96))
                .shadow(
                    color: Color.black.opacity(0.04),
                    radius: isPadLike ? 18 : 12,
                    x: 0,
                    y: isPadLike ? 8 : 5
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: isPadLike ? 34 : 26, style: .continuous)
                .stroke(Color.white.opacity(0.95), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func tabButton(for tab: HomeTab) -> some View {
        let isSelected = (selectedTab ?? .home) == tab
        let isPressed = pressedTab == tab

        Button {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                selectedTab = tab

                if tab == .home {
                    selectedCategory = nil
                }
            }
        } label: {
            VStack(spacing: isPadLike ? 8 : 5) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color(red: 0.92, green: 0.94, blue: 1.0))
                            .frame(
                                width: isPadLike ? 50 : (isCompact ? 36 : 40),
                                height: isPadLike ? 50 : (isCompact ? 36 : 40)
                            )
                    }

                    Image(systemName: iconName(for: tab, isSelected: isSelected))
                        .font(.system(size: isPadLike ? 26 : (isCompact ? 18 : 20), weight: .medium))
                        .foregroundColor(
                            isSelected
                            ? Color(red: 0.17, green: 0.36, blue: 0.98)
                            : Color(red: 0.58, green: 0.62, blue: 0.71)
                        )
                        .scaleEffect(isPressed ? 0.92 : 1.0)
                }
                .frame(height: isPadLike ? 52 : (isCompact ? 36 : 40))

                Circle()
                    .fill(
                        isSelected
                        ? Color(red: 0.17, green: 0.36, blue: 0.98)
                        : Color.clear
                    )
                    .frame(
                        width: isPadLike ? 8 : 6,
                        height: isPadLike ? 8 : 6
                    )
                    .scaleEffect(isSelected ? 1.0 : 0.5)
                    .animation(.spring(response: 0.34, dampingFraction: 0.8), value: isSelected)
            }
            .frame(maxWidth: .infinity)
            .frame(height: isPadLike ? 82 : (isCompact ? 56 : 60))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: 30,
            pressing: { pressing in
                withAnimation(.easeOut(duration: 0.14)) {
                    pressedTab = pressing ? tab : nil
                }
            },
            perform: {}
        )
    }

    private func iconName(for tab: HomeTab, isSelected: Bool) -> String {
        switch tab {
        case .home:
            return isSelected ? "house.fill" : "house"
        case .flashcards:
            return "square.stack.3d.up"
        case .create:
            return "square.and.pencil"
        case .profile:
            return "person"
        }
    }
}

#Preview {
    ZStack {
        Color(red: 0.965, green: 0.965, blue: 0.985)
            .ignoresSafeArea()

        VStack {
            Spacer()

            BottomNavigationBar(
                selectedTab: .constant(.home),
                selectedCategory: .constant(nil)
            )
            .padding()
        }
    }
}
