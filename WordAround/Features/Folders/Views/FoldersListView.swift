import SwiftUI
import UniformTypeIdentifiers

struct FolderListView: View {
    let folders: [Folder]
    let setsCount: (Folder) -> Int
    let onCreate: () -> Void
    let onSelect: (Folder) -> Void
    let onDelete: (Folder) -> Void
    let onMove: (IndexSet, Int) -> Void

    @State private var isEditing = false
    @State private var draggingFolder: Folder?

    private var isMac: Bool {
        #if os(macOS)
        true
        #else
        ProcessInfo.processInfo.isMacCatalystApp
        #endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
            header

            if folders.isEmpty {
                emptyCard
            } else {
                foldersList
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("Your folders")
                .font(.system(size: Layout.isPadLike ? 34 : 21, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .layoutPriority(1)

            Spacer(minLength: 8)

            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    isEditing.toggle()
                }
            } label: {
                circleIconButton(systemName: isEditing ? "checkmark" : "pencil")
            }
            .buttonStyle(.plain)

            Button {
                onCreate()
            } label: {
                Text("Create")
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

    private var foldersList: some View {
        List {
            ForEach(folders) { folder in
                FolderListRowView(
                    folder: folder,
                    setsCount: setsCount(folder),
                    isEditing: isEditing,
                    isMac: isMac,
                    draggingFolder: $draggingFolder,
                    onSelect: {
                        onSelect(folder)
                    },
                    onDelete: {
                        onDelete(folder)
                    }
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            }
            .onMove(perform: onMove)
            .onDelete { indexSet in
                guard let index = indexSet.first else { return }
                onDelete(folders[index])
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .frame(height: rowHeight * CGFloat(folders.count))
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
    }

    private var rowHeight: CGFloat {
        140
    }

    private var emptyCard: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.white.opacity(0.92))
            .overlay(
                VStack(alignment: .leading, spacing: 10) {
                    Text("No folders yet")
                        .font(.system(size: Layout.homeEmptySetTitleSize, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)

                    Text("Create your first folder using the Create button.")
                        .font(.system(size: Layout.homePlaceholderSubtitleSize, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(Layout.homePlaceholderPadding),
                alignment: .topLeading
            )
            .frame(height: Layout.homeEmptySetHeight)
    }
}

private struct FolderListRowView: View {
    let folder: Folder
    let setsCount: Int
    let isEditing: Bool
    let isMac: Bool

    @Binding var draggingFolder: Folder?

    let onSelect: () -> Void
    let onDelete: () -> Void

    var body: some View {
        rowContent
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                if !isMac {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image (systemName: "trash.fill")
                    }
                }
            }
            .animation(.spring(response: 0.32, dampingFraction: 0.86), value: isEditing)
    }

    private var rowContent: some View {
        HStack(alignment: .center, spacing: 14) {
            Button {
                guard !isEditing else { return }
                onSelect()
            } label: {
                FolderCardView(
                    title: folder.title,
                    setsCount: setsCount,
                    colorHex: folder.colorHex
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

    private var editActions: some View {
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
                    draggingFolder = folder
                    return NSItemProvider(object: folder.id as NSString)
                }
        }
    }
}

#Preview {
    FolderListView(
        folders: [
            Folder(
                id: "1",
                ownerUID: "test",
                title: "Learning",
                description: "Spanish words",
                colorHex: "#AFC8FF",
                createdAt: Date(),
                updatedAt: Date()
            ),
            Folder(
                id: "2",
                ownerUID: "test",
                title: "Kids",
                description: "Simple words",
                colorHex: "#FFE3A8",
                createdAt: Date(),
                updatedAt: Date()
            )
        ],
        setsCount: { _ in 0 },
        onCreate: {},
        onSelect: { _ in },
        onDelete: { _ in },
        onMove: { _, _ in }
    )
    .padding()
    .background(AppColors.appBackground)
}
