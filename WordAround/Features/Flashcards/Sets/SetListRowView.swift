import SwiftUI
import UniformTypeIdentifiers

struct SetListRowView: View {
    let set: HomeSetPreviewItem
    let isEditing: Bool
    let isMac: Bool

    @Binding var draggingSet: HomeSetPreviewItem?

    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        rowContent
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                if !isMac {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash.fill")
                    }
                }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.86), value: isEditing)
    }
}

private extension SetListRowView {
    var rowContent: some View {
        HStack(alignment: .center, spacing: 14) {
            Button {
                guard !isEditing else { return }
                onSelect()
            } label: {
                SetItemView(
                    title: set.title,
                    subtitle: set.subtitle,
                    iconSystemName: set.iconSystemName,
                    accentColor: set.accentColor,
                    titleColor: set.titleColor,
                    backgroundColor: set.backgroundColor,
                    trailingText: "Review",
                    blobColor: set.blobColor
                )
            }
            .buttonStyle(.plain)
            .allowsHitTesting(!isEditing)

            if isEditing {
                editActions
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .background(AppColors.appBackground)
    }

    var editActions: some View {
        HStack(spacing: 12) {
            Button {
                onDelete()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(red: 1.0, green: 0.87, blue: 0.90))
                        .frame(width: 52, height: 52)

                    Image(systemName: "trash.fill")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.20, blue: 0.27))
                }
            }
            .buttonStyle(.plain)

            Image(systemName: "line.3.horizontal")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.textSecondary.opacity(0.95))
                .frame(width: 40, height: 52)
                .contentShape(Rectangle())
                .onDrag {
                    draggingSet = set
                    return NSItemProvider(object: String(describing: set.id) as NSString)
                }
        }
    }
}
