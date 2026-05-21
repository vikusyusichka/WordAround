import SwiftUI

struct GrammarNotesFABMenuItem: Identifiable, Equatable {
    let id: String
    let title: String
    let systemImage: String
    let role: GrammarNotesFABMenuRole

    init(
        id: String = UUID().uuidString,
        title: String,
        systemImage: String,
        role: GrammarNotesFABMenuRole
    ) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.role = role
    }
}

enum GrammarNotesFABMenuRole: Equatable {
    case newTopic
    case newNote
    case quickNote
    case quickMistake
}

struct GrammarNotesFABMenu: View {
    let tint: Color
    let items: [GrammarNotesFABMenuItem]
    let onSelect: (GrammarNotesFABMenuItem) -> Void

    @Binding var isExpanded: Bool
    @GestureState private var isPressingFAB = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if isExpanded {
                dimLayer
                    .transition(.opacity)
                    .zIndex(0)
            }

            VStack(alignment: .trailing, spacing: Layout.grammarNotesFABMenuSpacing) {
                if isExpanded {
                    menuCard
                        .transition(
                            .opacity
                                .combined(with: .scale(scale: 0.92, anchor: .bottomTrailing))
                                .combined(with: .move(edge: .bottom))
                        )
                }

                fabButton
            }
            .padding(.trailing, Layout.grammarNotesFABTrailingPadding)
            .padding(.bottom, Layout.grammarNotesFABBottomPadding)
            .zIndex(1)
        }
        .animation(Layout.grammarNotesFABSpring, value: isExpanded)
    }

    private var dimLayer: some View {
        Color.black
            .opacity(Layout.grammarNotesFABDimOpacity)
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation(Layout.grammarNotesFABSpring) {
                    isExpanded = false
                }
            }
    }

    private var menuCard: some View {
        VStack(spacing: Layout.grammarNotesFABMenuItemSpacing) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                menuRow(item)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(
                        Layout.grammarNotesFABSpring.delay(Double(index) * Layout.grammarNotesFABItemDelay),
                        value: isExpanded
                    )
            }
        }
        .padding(Layout.grammarNotesFABMenuPadding)
        .frame(width: Layout.grammarNotesFABMenuWidth)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Layout.grammarNotesFABMenuCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.grammarNotesFABMenuCornerRadius, style: .continuous)
                .stroke(Color.white.opacity(0.58), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 14)
    }

    private func menuRow(_ item: GrammarNotesFABMenuItem) -> some View {
        Button {
            withAnimation(Layout.grammarNotesFABSpring) {
                isExpanded = false
            }
            onSelect(item)
        } label: {
            HStack(spacing: 11) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.13))
                    Image(systemName: item.systemImage)
                        .font(.system(size: Layout.grammarNotesFABMenuIconSize, weight: .bold))
                        .foregroundStyle(tint)
                }
                .frame(width: Layout.grammarNotesFABMenuIconBox, height: Layout.grammarNotesFABMenuIconBox)

                Text(item.title)
                    .font(.system(size: Layout.grammarNotesFABMenuTitleSize, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(height: Layout.grammarNotesFABMenuRowHeight)
            .background(Color.white.opacity(0.62))
            .clipShape(RoundedRectangle(cornerRadius: Layout.grammarNotesFABMenuRowCornerRadius, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: Layout.grammarNotesFABMenuRowCornerRadius, style: .continuous))
        }
        .buttonStyle(GrammarNotesScaleButtonStyle())
    }

    private var fabButton: some View {
        Button {
            withAnimation(Layout.grammarNotesFABSpring) {
                isExpanded.toggle()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [tint, tint.opacity(0.76)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Circle()
                    .stroke(Color.white.opacity(0.36), lineWidth: 1)
                    .padding(1)

                Image(systemName: "plus")
                    .font(.system(size: Layout.grammarNotesFABIconSize, weight: .black))
                    .foregroundStyle(Color.white)
                    .rotationEffect(.degrees(isExpanded ? 45 : 0))
                    .scaleEffect(isExpanded ? 0.92 : 1)
            }
            .frame(width: Layout.grammarNotesFABSize, height: Layout.grammarNotesFABSize)
            .shadow(color: tint.opacity(0.34), radius: 18, x: 0, y: 10)
            .scaleEffect(isPressingFAB ? 0.94 : 1)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressingFAB) { _, state, _ in state = true }
        )
        .accessibilityLabel(isExpanded ? "Close quick actions" : "Open quick actions")
    }
}

struct GrammarNotesScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(.easeInOut(duration: 0.14), value: configuration.isPressed)
    }
}

extension GrammarNotesFABMenuItem {
    static let homeItems: [GrammarNotesFABMenuItem] = [
        GrammarNotesFABMenuItem(title: "New Topic", systemImage: "folder.badge.plus", role: .newTopic),
        GrammarNotesFABMenuItem(title: "Quick Note", systemImage: "square.and.pencil", role: .quickNote),
        GrammarNotesFABMenuItem(title: "Quick Mistake", systemImage: "exclamationmark.bubble.fill", role: .quickMistake)
    ]

    static let topicItems: [GrammarNotesFABMenuItem] = [
        GrammarNotesFABMenuItem(title: "New Note", systemImage: "doc.badge.plus", role: .newNote),
        GrammarNotesFABMenuItem(title: "Quick Note", systemImage: "square.and.pencil", role: .quickNote),
        GrammarNotesFABMenuItem(title: "Quick Mistake", systemImage: "exclamationmark.bubble.fill", role: .quickMistake)
    ]
}

private struct GrammarNotesFABMenuPreview: View {
    @State private var isExpanded = true

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()
            GrammarNotesFABMenu(
                tint: AppColors.primaryBlue,
                items: GrammarNotesFABMenuItem.homeItems,
                onSelect: { _ in },
                isExpanded: $isExpanded
            )
        }
    }
}

#Preview("Home menu") {
    GrammarNotesFABMenuPreview()
}
