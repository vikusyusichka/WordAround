import SwiftUI

enum CollectionLayoutMode: String {
    case list
    case grid
}

struct LayoutModeToggleButton: View {
    @Binding var mode: CollectionLayoutMode

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                mode = mode == .list ? .grid : .list
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.98))
                    .frame(
                        width: Layout.isPadLike ? 52 : 40,
                        height: Layout.isPadLike ? 52 : 40
                    )
                    .shadow(
                        color: AppColors.primaryBlue.opacity(0.10),
                        radius: Layout.isPadLike ? 12 : 8,
                        x: 0,
                        y: Layout.isPadLike ? 6 : 4
                    )

                Image(systemName: mode == .list ? "square.grid.2x2" : "list.bullet")
                    .font(.system(size: Layout.isPadLike ? 20 : 16, weight: .semibold))
                    .foregroundColor(AppColors.primaryBlue)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mode == .list ? "Switch to grid layout" : "Switch to list layout")
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var mode: CollectionLayoutMode = .list
        var body: some View {
            HStack {
                LayoutModeToggleButton(mode: $mode)
                Text(mode.rawValue)
            }
        }
    }
    return PreviewWrapper()
}
