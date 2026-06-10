import SwiftUI

struct SetsListHeaderView: View {
    let title: String
    let actionTitle: String
    let showsEditButton: Bool
    let isEditing: Bool
    let onToggleEditing: () -> Void
    let onAction: () -> Void
    var showsLayoutToggle: Bool = false
    var layoutMode: Binding<CollectionLayoutMode>? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.system(size: Layout.isPadLike ? 34 : 21, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .layoutPriority(1)

            Spacer(minLength: 8)

            if showsEditButton {
                Button {
                    onToggleEditing()
                } label: {
                    circleIconButton(systemName: isEditing ? "checkmark" : "pencil")
                }
                .buttonStyle(.plain)
            }

            if showsLayoutToggle, let layoutMode {
                LayoutModeToggleButton(mode: layoutMode)
            }

            Button(action: onAction) {
                Text(actionTitle)
                    .font(.system(size: Layout.isPadLike ? 18 : 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlue)
                    .lineLimit(1)
                    .padding(.horizontal, Layout.isPadLike ? 18 : 14)
                    .frame(height: Layout.isPadLike ? 52 : 40)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.98))
                            .shadow(
                                color: AppColors.primaryBlue.opacity(0.10),
                                radius: Layout.isPadLike ? 12 : 8,
                                x: 0,
                                y: Layout.isPadLike ? 6 : 4
                            )
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func circleIconButton(systemName: String) -> some View {
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

            Image(systemName: systemName)
                .font(.system(size: Layout.isPadLike ? 22 : 17, weight: .semibold))
                .foregroundColor(AppColors.primaryBlue)
        }
    }
}

#Preview {
    SetsListHeaderView(
        title: L10n.string("setsListYourSets"),
        actionTitle: "Create",
        showsEditButton: true,
        isEditing: false,
        onToggleEditing: {},
        onAction: {}
    )
    .padding()
    .background(AppColors.appBackground)
}
