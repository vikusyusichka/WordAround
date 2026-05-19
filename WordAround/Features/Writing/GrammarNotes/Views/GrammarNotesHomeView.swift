import SwiftUI
import FirebaseAuth

struct GrammarNotesHomeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: GrammarNotesHomeViewModel
    @State private var isCreateSheetPresented = false
    @State private var isSettingsPresented = false

    private let theme: CreateSetTheme = .blue

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    init(ownerUID: String? = Auth.auth().currentUser?.uid) {
        _viewModel = StateObject(
            wrappedValue: GrammarNotesHomeViewModel(ownerUID: ownerUID ?? "")
        )
    }

    init(viewModel: GrammarNotesHomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            theme.screenBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: isPadLike ? 22 : 18) {
                    headerView
                    searchBar
                    sectionHeader
                    contentView
                }
                .padding(.horizontal, isPadLike ? 28 : 20)
                .padding(.top, isPadLike ? 22 : 16)
                .padding(.bottom, 96)
            }

            floatingAddButton
                .padding(.trailing, isPadLike ? 34 : 24)
                .padding(.bottom, isPadLike ? 34 : 26)
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $isSettingsPresented) {
            GrammarNotesSettingsView()
        }
        .sheet(isPresented: $isCreateSheetPresented) {
            CreateGrammarTopicSheet(
                onCancel: { isCreateSheetPresented = false },
                onCreate: { title, description, languageCode, languageName, icon, colorHex in
                    Task {
                        let didCreate = await viewModel.createTopic(
                            title: title,
                            description: description,
                            languageCode: languageCode,
                            languageName: languageName,
                            icon: icon,
                            colorHex: colorHex
                        )

                        if didCreate {
                            isCreateSheetPresented = false
                        }
                    }
                }
            )
        }
        .task {
            if viewModel.topics.isEmpty {
                await viewModel.loadTopics()
            }
        }
    }

    private var headerView: some View {
        VStack(spacing: isPadLike ? 18 : 14) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: isPadLike ? 18 : 16, weight: .semibold))
                        .foregroundStyle(theme.mutedTextColor)
                        .frame(width: isPadLike ? 50 : 44, height: isPadLike ? 50 : 44)
                        .background(theme.fieldBackground)
                        .clipShape(Circle())
                        .shadow(color: theme.shadowColor, radius: 12, x: 0, y: 7)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    isSettingsPresented = true
                } label: {
                    HStack(spacing: 10) {
                        Text("Settings")
                            .font(.system(size: isPadLike ? 15 : 13, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.accent)
                            .lineLimit(1)

                        ZStack {
                            Circle()
                                .fill(theme.softAccent)
                                .frame(width: isPadLike ? 42 : 36, height: isPadLike ? 42 : 36)

                            Image(systemName: "gearshape.fill")
                                .font(.system(size: isPadLike ? 18 : 16, weight: .bold))
                                .foregroundStyle(theme.accent)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Grammar Notes")
                        .font(.system(size: isPadLike ? 34 : 28, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.titleColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text("Organize grammar rules, examples and corrections.")
                        .font(.system(size: isPadLike ? 16 : 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.mutedTextColor)
                        .lineSpacing(2)
                }

                Spacer(minLength: 8)
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: isPadLike ? 17 : 15, weight: .semibold))
                .foregroundStyle(theme.mutedTextColor)

            TextField("Search topics", text: $viewModel.searchText)
                .font(.system(size: isPadLike ? 17 : 15, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textColor)
                .tint(theme.accent)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.mutedTextColor.opacity(0.78))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, isPadLike ? 18 : 14)
        .frame(height: isPadLike ? 64 : 56)
        .background(theme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: isPadLike ? 22 : 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: isPadLike ? 22 : 18, style: .continuous)
                .stroke(theme.softBorderColor, lineWidth: 1)
        )
        .shadow(color: theme.shadowColor, radius: 14, x: 0, y: 8)
    }

    private var sectionHeader: some View {
        HStack {
            Text("My Topics")
                .font(.system(size: isPadLike ? 21 : 18, weight: .bold, design: .rounded))
                .foregroundStyle(theme.titleColor)

            Spacer()

            Button {
                isCreateSheetPresented = true
            } label: {
                Text("+ New Topic")
                    .font(.system(size: isPadLike ? 14 : 12, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(theme.fieldBackground)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(theme.softBorderColor, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            loadingCard
        } else if let errorMessage = viewModel.errorMessage {
            errorCard(message: errorMessage)
        } else {
            VStack(spacing: isPadLike ? 16 : 12) {
                ForEach(viewModel.filteredTopics) { topic in
                    NavigationLink {
                        GrammarNotesTopicView(topic: topic)
                    } label: {
                        GrammarNoteTopicCardView(topic: topic)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        if !topic.isMistakesTopic {
                            Button(role: .destructive) {
                                Task { await viewModel.deleteTopic(topic) }
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                        }
                    }
                }

                if viewModel.hasOnlyMistakesTopic && viewModel.searchText.isEmpty {
                    emptyState
                }
            }
        }
    }

    private var loadingCard: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(theme.accent)
                .scaleEffect(1.08)

            Text("Loading topics...")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.mutedTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isPadLike ? 36 : 30)
        .background(sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: theme.shadowColor, radius: 14, x: 0, y: 8)
    }

    private func errorCard(message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(CreateSetTheme.red.accent)

                Text("Something went wrong")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.titleColor)
            }

            Text(message)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.mutedTextColor)

            Button {
                Task { await viewModel.loadTopics() }
            } label: {
                Text("Retry")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(theme.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: theme.shadowColor, radius: 14, x: 0, y: 8)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle()
                    .fill(theme.softAccent)
                    .frame(width: 54, height: 54)

                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(theme.accent)
            }

            Text("Create your first grammar topic")
                .font(.system(size: isPadLike ? 18 : 16, weight: .bold, design: .rounded))
                .foregroundStyle(theme.titleColor)

            Text("Start with verbs, tenses, articles or your own custom topic.")
                .font(.system(size: isPadLike ? 14 : 12, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.mutedTextColor)
                .lineSpacing(2)

            Button {
                isCreateSheetPresented = true
            } label: {
                Text("New Topic")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 11)
                    .background(theme.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: theme.shadowColor, radius: 14, x: 0, y: 8)
    }

    private var floatingAddButton: some View {
        Button {
            isCreateSheetPresented = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: isPadLike ? 26 : 23, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(width: isPadLike ? 66 : 58, height: isPadLike ? 66 : 58)
                .background(theme.accent)
                .clipShape(Circle())
                .shadow(color: theme.shadowColor, radius: 18, x: 0, y: 10)
        }
        .buttonStyle(.plain)
    }

    private var sectionBackground: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(theme.sectionBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(theme.softBorderColor, lineWidth: 1)
            )
    }
}

#Preview {
    NavigationStack {
        GrammarNotesHomeView(ownerUID: "preview-user")
    }
}
