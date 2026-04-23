import SwiftUI

struct BottomNavigationBar: View {
    @Binding var selectedTab: HomeTab
    @State private var pressedTab: HomeTab?

    var body: some View {
        HStack(spacing: 0) {
            ForEach(HomeTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 100)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.06), radius: 18, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(Color.white.opacity(0.9), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func tabButton(for tab: HomeTab) -> some View {
        let isSelected = selectedTab == tab
        let isPressed = pressedTab == tab

        Button {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.92, green: 0.94, blue: 1.0),
                                        Color(red: 0.95, green: 0.97, blue: 1.0)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 46, height: 46)
                            .shadow(
                                color: Color(red: 0.20, green: 0.38, blue: 0.94).opacity(0.10),
                                radius: 10,
                                x: 0,
                                y: 4
                            )
                            .transition(.scale.combined(with: .opacity))
                    }

                    Image(systemName: tab.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(
                            isSelected
                            ? LinearGradient(
                                colors: [
                                    Color(red: 0.20, green: 0.38, blue: 0.94),
                                    Color(red: 0.30, green: 0.48, blue: 0.99)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [
                                    Color(red: 0.62, green: 0.65, blue: 0.73),
                                    Color(red: 0.62, green: 0.65, blue: 0.73)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isPressed ? 0.88 : (isSelected ? 1.05 : 1.0))
                        .animation(.spring(response: 0.22, dampingFraction: 0.68), value: isPressed)
                        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: isSelected)
                }
                .frame(height: 46)

                Circle()
                    .fill(
                        isSelected
                        ? Color(red: 0.20, green: 0.38, blue: 0.94)
                        : Color.clear
                    )
                    .frame(width: isSelected ? 10 : 8, height: isSelected ? 10 : 8)
                    .scaleEffect(isSelected ? 1.0 : 0.6)
                    .animation(.spring(response: 0.34, dampingFraction: 0.8), value: isSelected)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 74)
            .offset(y: isSelected ? -1 : 0)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.24, dampingFraction: 0.72), value: isPressed)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selectedTab)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: 30, pressing: { pressing in
            withAnimation(.easeOut(duration: 0.14)) {
                pressedTab = pressing ? tab : nil
            }
        }, perform: {})
    }
}

#Preview {
    BottomNavigationBar(selectedTab: .constant(.flashcards))
        .padding()
        .background(Color(red: 0.965, green: 0.965, blue: 0.985))
}
