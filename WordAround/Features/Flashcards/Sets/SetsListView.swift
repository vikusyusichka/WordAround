import SwiftUI

struct SetsListView: View {
    let title: String
    let actionTitle: String
    let sets: [HomeSetPreviewItem]
    let isLoading: Bool
    let errorMessage: String?
    let showsEditButton: Bool
    let onAction: () -> Void
    let onSelect: (HomeSetPreviewItem) -> Void
    var onDelete: ((HomeSetPreviewItem) async -> Bool)? = nil
    var onMove: ((IndexSet, Int) -> Void)? = nil
    var onUpdate: ((HomeSetPreviewItem, String, String) async -> Bool)? = nil
    var showsLayoutToggle: Bool = false

    @State private var isEditing = false
    @State private var visibleSets: [HomeSetPreviewItem] = []
    @State private var draggingSet: HomeSetPreviewItem?
    @State private var setBeingEdited: HomeSetPreviewItem?
    @State private var isSavingEditedSet = false

    @AppStorage("setsLayoutMode") private var layoutModeRaw: String = CollectionLayoutMode.list.rawValue

    private var layoutMode: CollectionLayoutMode {
        CollectionLayoutMode(rawValue: layoutModeRaw) ?? .list
    }

    private var layoutModeBinding: Binding<CollectionLayoutMode> {
        Binding(
            get: { layoutMode },
            set: { layoutModeRaw = $0.rawValue }
        )
    }

    private var isMac: Bool {
        #if os(macOS)
        true
        #else
        ProcessInfo.processInfo.isMacCatalystApp
        #endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
            SetsListHeaderView(
                title: title,
                actionTitle: actionTitle,
                showsEditButton: showsEditButton,
                isEditing: isEditing,
                onToggleEditing: toggleEditing,
                onAction: onAction,
                showsLayoutToggle: showsLayoutToggle,
                layoutMode: showsLayoutToggle ? layoutModeBinding : nil
            )

            content

            if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: Layout.homeErrorTextSize, weight: .semibold, design: .rounded))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 4)
            }
        }
        .onAppear {
            syncVisibleSets()
        }
        .onChange(of: sets.map(\.id)) { _, _ in
            syncVisibleSets()
        }
        .sheet(item: $setBeingEdited) { set in
            let theme = setTheme(for: set)
            EditSetSheet(
                initialTitle: set.sourceSet?.title ?? set.title,
                initialDescription: set.sourceSet?.description ?? "",
                theme: theme,
                isSaving: isSavingEditedSet
            ) { title, description in
                guard let onUpdate else { return false }
                isSavingEditedSet = true
                let success = await onUpdate(set, title, description)
                isSavingEditedSet = false
                return success
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private func setTheme(for set: HomeSetPreviewItem) -> CreateSetTheme {
        if let hex = set.sourceSet?.colorHex {
            return CreateSetTheme.theme(forHex: hex)
        }
        return CreateSetTheme.theme(forHex: SetColor.blue.hex)
    }
}

private extension SetsListView {
    @ViewBuilder
    var content: some View {
        if isLoading {
            placeholderCard(
                title: "Loading",
                subtitle: "Loading your flashcard sets...",
                height: Layout.homePlaceholderHeight
            )
        } else if visibleSets.isEmpty {
            placeholderCard(
                title: "No sets yet",
                subtitle: "Create your first flashcard set using the Create button.",
                height: Layout.homeEmptySetHeight
            )
        } else if showsLayoutToggle && layoutMode == .grid {
            setsGrid
        } else if showsEditButton {
            editableSetsList
        } else {
            regularSetsList
        }
    }

    var regularSetsList: some View {
        LazyVStack(spacing: Layout.homeSetsListSpacing) {
            ForEach(visibleSets) { set in
                Button {
                    onSelect(set)
                } label: {
                    setCard(for: set)
                }
                .buttonStyle(.plain)
            }
        }
    }

    var editableSetsList: some View {
        List {
            ForEach(visibleSets) { set in
                SetListRowView(
                    set: set,
                    isEditing: isEditing,
                    isMac: isMac,
                    draggingSet: $draggingSet,
                    onSelect: {
                        onSelect(set)
                    },
                    onDelete: {
                        delete(set)
                    }
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
            }
            .onMove(perform: move)
            .onDelete { indexSet in
                guard let index = indexSet.first else { return }
                delete(visibleSets[index])
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .frame(height: rowHeight * CGFloat(visibleSets.count))
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
    }

    var setsGrid: some View {
        let columnCount = Layout.isPadLike ? 4 : 2
        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columnCount),
            spacing: 12
        ) {
            ForEach(visibleSets) { set in
                SetGridCellView(
                    set: set,
                    onSelect: { onSelect(set) },
                    onEdit: {
                        guard onUpdate != nil else { return }
                        setBeingEdited = set
                    },
                    onDelete: { delete(set) }
                )
            }
        }
    }

    var rowHeight: CGFloat {
        112
    }

    func setCard(for set: HomeSetPreviewItem) -> some View {
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

    func placeholderCard(title: String, subtitle: String, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.white.opacity(0.92))
            .overlay(
                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.system(size: Layout.homeEmptySetTitleSize, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)

                    Text(subtitle)
                        .font(.system(size: Layout.homePlaceholderSubtitleSize, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(Layout.homePlaceholderPadding),
                alignment: .topLeading
            )
            .frame(height: height)
    }

    func toggleEditing() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            isEditing.toggle()
        }
    }

    func syncVisibleSets() {
        let incomingIDs = sets.map(\.id)
        let currentIDs = visibleSets.map(\.id)

        guard incomingIDs != currentIDs else { return }
        visibleSets = sets
    }

    func delete(_ set: HomeSetPreviewItem) {
        let oldSets = visibleSets

        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            visibleSets.removeAll { $0.id == set.id }
        }

        guard let onDelete else { return }

        Task {
            let didDelete = await onDelete(set)

            if !didDelete {
                await MainActor.run {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        visibleSets = oldSets
                    }
                }
            }
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            visibleSets.move(fromOffsets: source, toOffset: destination)
        }

        onMove?(source, destination)
    }
}

private struct SetGridCellView: View {
    let set: HomeSetPreviewItem
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Color.clear
            .aspectRatio(5.0 / 3.0, contentMode: .fit)
            .overlay {
                GeometryReader { proxy in
                    ZStack(alignment: .topTrailing) {
                        Button {
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
                                blobColor: set.blobColor,
                                height: proxy.size.height
                            )
                        }
                        .buttonStyle(.plain)

                        Menu {
                            Button {
                                onEdit()
                            } label: {
                                Label("Edit name", systemImage: "pencil")
                            }

                            Button {
                                onEdit()
                            } label: {
                                Label("Edit description", systemImage: "text.alignleft")
                            }

                            Button(role: .destructive) {
                                onDelete()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.94))
                                    .frame(width: 32, height: 32)
                                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)

                                Image(systemName: "ellipsis")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(set.accentColor)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.trailing, 10)
                    }
                }
            }
    }
}

#Preview {
    SetsListView(
        title: "Your sets",
        actionTitle: "Create",
        sets: [],
        isLoading: false,
        errorMessage: nil,
        showsEditButton: true,
        onAction: {},
        onSelect: { _ in }
    )
    .padding()
    .background(AppColors.appBackground)
}
