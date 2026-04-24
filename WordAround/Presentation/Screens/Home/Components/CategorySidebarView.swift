import SwiftUI

struct CategorySidebarView: View {
    @Binding var selectedCategory: HomeCategory?
    @State private var pressedCategory: HomeCategory?

    private var isCompact: Bool {
        UIScreen.main.bounds.width < 400
    }

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    private var sidebarSpacing: CGFloat {
        isPadLike ? 16 : 12
    }

    private var indicatorWidth: CGFloat {
        isPadLike ? 4 : 3
    }

    private var selectedIndicatorHeight: CGFloat {
        isPadLike ? 96 : 80
    }

    private var unselectedIndicatorHeight: CGFloat {
        isPadLike ? 82 : 68
    }

    private var circleSize: CGFloat {
        isPadLike ? 58 : 50
    }

    private var unselectedCircleSize: CGFloat {
        isPadLike ? 54 : 46
    }

    private var iconSize: CGFloat {
        isPadLike ? 21 : 18
    }

    private var textSize: CGFloat {
        isPadLike ? 10.5 : 9
    }

    private var contentWidth: CGFloat {
        isPadLike ? 78 : 60
    }

    private var contentHeight: CGFloat {
        isPadLike ? 98 : 78
    }

    private var labelSpacing: CGFloat {
        isPadLike ? 10 : 8
    }

    var body: some View {
        VStack(spacing: sidebarSpacing) {
            ForEach(HomeCategory.allCases) { category in
                sidebarItem(for: category)
            }
        }
        .padding(.vertical, isPadLike ? 6 : 2)
    }

    @ViewBuilder
    private func sidebarItem(for category: HomeCategory) -> some View {
        let isSelected = selectedCategory == category
        let isPressed = pressedCategory == category

        HStack(spacing: isPadLike ? 8 : 6) {
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
                        width: isSelected ? indicatorWidth : max(2, indicatorWidth - 1),
                        height: isSelected ? selectedIndicatorHeight : unselectedIndicatorHeight
                    )
                    .shadow(
                        color: isSelected
                        ? Color(red: 0.22, green: 0.42, blue: 0.96).opacity(0.16)
                        : .clear,
                        radius: isPadLike ? 8 : 6,
                        x: 0,
                        y: 0
                    )

                if isSelected {
                    Capsule()
                        .fill(Color.white.opacity(0.55))
                        .frame(
                            width: isPadLike ? 1.8 : 1.4,
                            height: isPadLike ? 22 : 18
                        )
                        .offset(y: isPadLike ? -18 : -16)
                }
            }
            .frame(width: indicatorWidth)

            VStack(spacing: labelSpacing) {
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
                            width: isSelected ? circleSize : unselectedCircleSize,
                            height: isSelected ? circleSize : unselectedCircleSize
                        )
                        .shadow(
                            color: isSelected
                            ? Color(red: 0.24, green: 0.44, blue: 0.98).opacity(0.10)
                            : Color.black.opacity(0.02),
                            radius: isPadLike ? 9 : 6,
                            x: 0,
                            y: isPadLike ? 4 : 3
                        )

                    Image(systemName: category.icon)
                        .font(.system(size: iconSize, weight: .medium))
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
                    .font(.system(size: textSize, weight: .bold, design: .rounded))
                    .foregroundColor(
                        isSelected
                        ? Color(red: 0.20, green: 0.38, blue: 0.94)
                        : Color(red: 0.62, green: 0.65, blue: 0.73)
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(width: contentWidth, height: contentHeight)
            .scaleEffect(isPressed ? 0.975 : 1.0)
            .animation(.spring(response: 0.24, dampingFraction: 0.72), value: isPressed)
            .contentShape(Rectangle())
        }
        .padding(.horizontal, isPadLike ? 6 : 4)
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
