import SwiftUI

struct CategorySidebarView: View {
    @Binding var selectedCategory: HomeCategory
    @State private var pressedCategory: HomeCategory?

    var body: some View {
        VStack(spacing: 20) {
            ForEach(HomeCategory.allCases) { category in
                sidebarItem(for: category)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func sidebarItem(for category: HomeCategory) -> some View {
        let isSelected = selectedCategory == category
        let isPressed = pressedCategory == category

        HStack(spacing: 10) {
            ZStack {
                Capsule()
                    .fill(
                        isSelected
                        ? LinearGradient(
                            colors: [
                                Color(red: 0.24, green: 0.44, blue: 0.99),
                                Color(red: 0.18, green: 0.36, blue: 0.92)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        : LinearGradient(
                            colors: [Color.clear, Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: isSelected ? 5 : 3, height: isSelected ? 110 : 92)
                    .shadow(
                        color: isSelected
                        ? Color(red: 0.22, green: 0.42, blue: 0.96).opacity(0.22)
                        : .clear,
                        radius: 10,
                        x: 0,
                        y: 0
                    )

                if isSelected {
                    Capsule()
                        .fill(Color.white.opacity(0.55))
                        .frame(width: 2, height: 30)
                        .offset(y: -26)
                }
            }
            .frame(width: 8)

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isSelected
                                ? [
                                    Color.white,
                                    Color(red: 0.94, green: 0.97, blue: 1.0)
                                ]
                                : [
                                    Color.white.opacity(0.90),
                                    Color.white.opacity(0.76)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: isSelected ? 72 : 68, height: isSelected ? 72 : 68)
                        .shadow(
                            color: isSelected
                            ? Color(red: 0.24, green: 0.44, blue: 0.98).opacity(0.16)
                            : Color.black.opacity(0.025),
                            radius: isSelected ? 16 : 8,
                            x: 0,
                            y: isSelected ? 7 : 3
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected
                                    ? Color(red: 0.87, green: 0.92, blue: 1.0)
                                    : Color.clear,
                                    lineWidth: 1.4
                                )
                        )
                        .scaleEffect(isPressed ? 0.96 : 1.0)
                        .animation(.spring(response: 0.22, dampingFraction: 0.72), value: isPressed)
                        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: isSelected)

                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    isSelected
                                    ? Color(red: 0.88, green: 0.93, blue: 1.0).opacity(0.85)
                                    : .clear,
                                    .clear
                                ],
                                center: .center,
                                startRadius: 4,
                                endRadius: 36
                            )
                        )
                        .frame(width: 82, height: 82)
                        .opacity(isSelected ? 1 : 0)

                    Image(systemName: category.icon)
                        .font(.system(size: isSelected ? 30 : 28, weight: .medium))
                        .foregroundStyle(
                            isSelected
                            ? LinearGradient(
                                colors: [
                                    Color(red: 0.20, green: 0.38, blue: 0.94),
                                    Color(red: 0.31, green: 0.50, blue: 0.99)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [
                                    Color(red: 0.64, green: 0.67, blue: 0.75),
                                    Color(red: 0.60, green: 0.63, blue: 0.72)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isPressed ? 0.90 : (isSelected ? 1.05 : 1.0))
                        .animation(.spring(response: 0.22, dampingFraction: 0.68), value: isPressed)
                        .animation(.spring(response: 0.32, dampingFraction: 0.80), value: isSelected)
                }

                Text(category.title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(
                        isSelected
                        ? Color(red: 0.20, green: 0.38, blue: 0.94)
                        : Color(red: 0.62, green: 0.65, blue: 0.73)
                    )
                    .tracking(isSelected ? 0.35 : 0)
                    .scaleEffect(isSelected ? 1.03 : 1.0)
                    .animation(.spring(response: 0.34, dampingFraction: 0.82), value: isSelected)
            }
            .frame(width: 102, height: 126)
            .offset(x: isSelected ? -1.5 : 0)
            .scaleEffect(isPressed ? 0.975 : 1.0)
            .animation(.spring(response: 0.24, dampingFraction: 0.72), value: isPressed)
            .contentShape(Rectangle())
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                selectedCategory = category
            }
        }
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: 30,
            pressing: { pressing in
                withAnimation(.easeOut(duration: 0.15)) {
                    pressedCategory = pressing ? category : nil
                }
            },
            perform: {}
        )
    }
}

#Preview {
    CategorySidebarView(selectedCategory: .constant(.speaking))
        .padding()
        .background(Color(red: 0.965, green: 0.965, blue: 0.985))
}
