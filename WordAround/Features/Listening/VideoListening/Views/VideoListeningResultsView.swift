import SwiftUI

struct VideoListeningResultsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: VideoListeningResultsViewModel

    var onExitToSetup: (() -> Void)? = nil
    var onExitToListening: (() -> Void)? = nil

    private let accent = ListeningTheme.videoListeningAccent
    private let accentDark = ListeningTheme.videoListeningDark

    init(
        setup: ListeningVideoSetup,
        onExitToSetup: (() -> Void)? = nil,
        onExitToListening: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: VideoListeningResultsViewModel(setup: setup))
        self.onExitToSetup = onExitToSetup
        self.onExitToListening = onExitToListening
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: Layout.homeContentSpacing) {
                ListeningSetupTopBar(
                    title: "Choose Video",
                    subtitle: "Pick a video for listening practice.",
                    accent: accent,
                    accentDark: accentDark,
                    onBack: { dismiss() }
                )

                searchField

                switch viewModel.state {
                case .loading:
                    ListeningLoadingRow(message: "Finding videos…", accent: accent)
                case .empty:
                    emptyState
                case .error(let message):
                    errorState(message)
                case .loaded(let videos):
                    ForEach(videos) { video in
                        videoCard(video)
                    }
                }
            }
            .frame(maxWidth: Layout.convContentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.top, Layout.homeTopSpacing)
            .padding(.bottom, Layout.homeBottomSafeSpacing)
        }
        .background(AppColors.appBackground.ignoresSafeArea())
        .tint(accentDark)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { viewModel.load() }
        .navigationDestination(isPresented: $viewModel.showSession) {
            if let video = viewModel.selectedVideo {
                VideoListeningSessionView(
                    setup: viewModel.setup,
                    video: video,
                    onExitToResults: { viewModel.showSession = false },
                    onExitToListening: onExitToListening
                )
            }
        }
    }

    // MARK: - Search field

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)

            TextField("Search videos...", text: $viewModel.searchQuery)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(accentDark)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.mutedText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }

    // MARK: - Empty / error states

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "video.slash")
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(accent.opacity(0.6))
            Text("No videos found")
                .font(.system(size: Layout.homeSectionTitleSize, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)
            Text(viewModel.searchQuery.isEmpty
                 ? "Try a different language or level."
                 : "No results for \"\(viewModel.searchQuery)\". Try another search.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
            Button { viewModel.retrySearch() } label: {
                Text("Search again")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .frame(height: 42)
                    .background(accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
        )
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            ListeningInlineErrorView(message: message, accent: accent)
            Button { viewModel.retrySearch() } label: {
                Text("Try again")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .frame(height: 42)
                    .background(accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Video card

    private func videoCard(_ video: ListeningVideoItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row: thumbnail + info
            HStack(alignment: .top, spacing: 12) {
                thumbnailView(video)
                    .frame(width: 108, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 5) {
                    Text(video.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(accentDark)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(video.channel)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)

                    HStack(spacing: 5) {
                        if !video.durationText.isEmpty {
                            ListeningMetadataChip(text: video.durationText, accent: accent)
                        }
                        ListeningMetadataChip(text: video.difficultyTitle, accent: accent)
                        ListeningMetadataChip(
                            text: video.supportsQuestions ? "Questions" : "Watch only",
                            accent: video.supportsQuestions ? accent : AppColors.mutedText
                        )
                    }
                }
            }

            // Full-width action button
            Button {
                viewModel.selectVideo(video)
            } label: {
                Text(video.supportsQuestions ? "Start Practice" : "Watch Only")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(accent)
                    .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)

            if !video.supportsQuestions {
                Text("No transcript available — this is a watch-only session.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.mutedText)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - Thumbnail

    @ViewBuilder
    private func thumbnailView(_ video: ListeningVideoItem) -> some View {
        if let urlString = video.thumbnailURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure, .empty:
                    thumbnailPlaceholder
                @unknown default:
                    thumbnailPlaceholder
                }
            }
        } else {
            thumbnailPlaceholder
        }
    }

    private var thumbnailPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(accent.opacity(0.12))
            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(accent.opacity(0.7))
        }
    }
}

#Preview {
    NavigationStack {
        VideoListeningResultsView(
            setup: ListeningVideoSetup(
                language: .english,
                level: .b1,
                length: .medium
            )
        )
    }
}
