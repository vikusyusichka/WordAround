import SwiftUI

struct BottomNavigationBar: View {
    @Binding var selectedTab: HomeTab?
    @Binding var selectedCategory: HomeCategory?
    @Binding var isCreateMenuPresented: Bool

    @State private var pressedTab: HomeTab?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(HomeTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, Layout.bottomNavHorizontalPadding)
        .frame(height: Layout.bottomNavHeight)
        .background(
            RoundedRectangle(cornerRadius: Layout.bottomNavCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.96))
                .shadow(
                    color: Color.black.opacity(0.04),
                    radius: Layout.bottomNavShadowRadius,
                    x: 0,
                    y: Layout.bottomNavShadowY
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: Layout.bottomNavCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.95), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func tabButton(for tab: HomeTab) -> some View {
        if tab == .create {
            createTabButton(for: tab)
        } else {
            regularTabButton(for: tab)
        }
    }

    private func regularTabButton(for tab: HomeTab) -> some View {
        let isSelected = (selectedTab ?? .home) == tab
        let isPressed = pressedTab == tab

        return Button {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                selectedTab = tab
                isCreateMenuPresented = false

                if tab == .home {
                    selectedCategory = nil
                }
            }
        } label: {
            VStack(spacing: Layout.bottomNavRegularStackSpacing) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color(red: 0.92, green: 0.94, blue: 1.0))
                            .frame(
                                width: Layout.bottomNavSelectedCircleSize,
                                height: Layout.bottomNavSelectedCircleSize
                            )
                    }

                    Image(systemName: iconName(for: tab, isSelected: isSelected))
                        .font(.system(size: Layout.bottomNavIconSize, weight: .medium))
                        .foregroundColor(
                            isSelected
                            ? Color(red: 0.17, green: 0.36, blue: 0.98)
                            : Color(red: 0.58, green: 0.62, blue: 0.71)
                        )
                        .scaleEffect(isPressed ? 0.92 : 1.0)
                }
                .frame(height: Layout.bottomNavIconFrameHeight)

                Circle()
                    .fill(
                        isSelected
                        ? Color(red: 0.17, green: 0.36, blue: 0.98)
                        : Color.clear
                    )
                    .frame(
                        width: Layout.bottomNavIndicatorSize,
                        height: Layout.bottomNavIndicatorSize
                    )
                    .scaleEffect(isSelected ? 1.0 : 0.5)
                    .animation(.spring(response: 0.34, dampingFraction: 0.8), value: isSelected)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Layout.bottomNavButtonHeight)
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

    private func createTabButton(for tab: HomeTab) -> some View {
        let isPressed = pressedTab == tab

        return Button {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                isCreateMenuPresented.toggle()
                selectedCategory = nil
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color(red: 0.17, green: 0.36, blue: 0.98))
                    .frame(
                        width: Layout.bottomNavCreateCircleSize,
                        height: Layout.bottomNavCreateCircleSize
                    )
                    .shadow(
                        color: Color(red: 0.17, green: 0.36, blue: 0.98).opacity(0.24),
                        radius: Layout.bottomNavCreateShadowRadius,
                        x: 0,
                        y: Layout.bottomNavCreateShadowY
                    )

                Image(systemName: "plus")
                    .font(.system(size: Layout.bottomNavCreateIconSize, weight: .regular))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isCreateMenuPresented ? 45 : 0))
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isCreateMenuPresented)
            }
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .frame(maxWidth: .infinity)
            .frame(height: Layout.bottomNavButtonHeight)
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
        case .folders:
            return isSelected ? "folder.fill" : "folder"
        case .flashcards:
            return "square.stack.3d.up"
        case .create:
            return "plus"
        case .profile:
            return isSelected ? "person.fill" : "person"
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
                selectedCategory: .constant(nil),
                isCreateMenuPresented: .constant(false)
            )
            .padding()
        }
    }
}
