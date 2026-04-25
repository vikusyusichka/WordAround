import SwiftUI

struct CategorySidebarView: View {
    @Binding var selectedCategory: HomeCategory?
    @State private var pressedCategory: HomeCategory?

    var body: some View {
        VStack(spacing: Layout.categorySidebarSpacing) {
            ForEach(HomeCategory.allCases) { category in
                sidebarItem(for: category)
            }
        }
        .padding(.vertical, Layout.categorySidebarVerticalPadding)
    }

    @ViewBuilder
    private func sidebarItem(for category: HomeCategory) -> some View {
        let isSelected = selectedCategory == category
        let isPressed = pressedCategory == category

        HStack(spacing: Layout.categorySidebarItemSpacing) {
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
                    .frame(
                        width: isSelected
                        ? Layout.categorySidebarIndicatorWidth
                        : max(2, Layout.categorySidebarIndicatorWidth - 1),
                        height: isSelected
                        ? Layout.categorySidebarSelectedIndicatorHeight
                        : Layout.categorySidebarUnselectedIndicatorHeight
                    )
                    .shadow(
                        color: isSelected
                        ? Color(red: 0.22, green: 0.42, blue: 0.96).opacity(0.16)
                        : .clear,
                        radius: Layout.categorySidebarIndicatorShadowRadius,
                        x: 0,
                        y: 0
                    )

                if isSelected {
                    Capsule()
                        .fill(Color.white.opacity(0.55))
                        .frame(
                            width: Layout.categorySidebarHighlightWidth,
                            height: Layout.categorySidebarHighlightHeight
                        )
                        .offset(y: Layout.categorySidebarHighlightOffsetY)
                }
            }
            .frame(width: Layout.categorySidebarIndicatorWidth)

            VStack(spacing: Layout.categorySidebarLabelSpacing) {
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
                        .frame(
                            width: isSelected
                            ? Layout.categorySidebarCircleSize
                            : Layout.categorySidebarUnselectedCircleSize,
                            height: isSelected
                            ? Layout.categorySidebarCircleSize
                            : Layout.categorySidebarUnselectedCircleSize
                        )
                        .shadow(
                            color: isSelected
                            ? Color(red: 0.24, green: 0.44, blue: 0.98).opacity(0.10)
                            : Color.black.opacity(0.02),
                            radius: Layout.categorySidebarCircleShadowRadius,
                            x: 0,
                            y: Layout.categorySidebarCircleShadowY
                        )

                    Image(systemName: category.icon)
                        .font(.system(size: Layout.categorySidebarIconSize, weight: .medium))
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
                        .scaleEffect(isPressed ? 0.88 : (isSelected ? 1.05 : 1.0))
                        .animation(.spring(response: 0.22, dampingFraction: 0.68), value: isPressed)
                        .animation(.spring(response: 0.32, dampingFraction: 0.80), value: isSelected)
                }

                Text(category.title)
                    .font(.system(size: Layout.categorySidebarTextSize, weight: .bold, design: .rounded))
                    .foregroundColor(
                        isSelected
                        ? Color(red: 0.20, green: 0.38, blue: 0.94)
                        : Color(red: 0.62, green: 0.65, blue: 0.73)
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(
                width: Layout.categorySidebarContentWidth,
                height: Layout.categorySidebarContentHeight
            )
            .scaleEffect(isPressed ? 0.975 : 1.0)
            .animation(.spring(response: 0.24, dampingFraction: 0.72), value: isPressed)
            .contentShape(Rectangle())
        }
        .padding(.horizontal, Layout.categorySidebarHorizontalPadding)
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
    CategorySidebarView(selectedCategory: .constant(nil))
        .padding()
        .background(Color(red: 0.965, green: 0.965, blue: 0.985))
}
