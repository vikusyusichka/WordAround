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

                ForEach(viewModel.videos) { video in
                    videoCard(video)
                }
            }
            .frame(maxWidth: Layout.convContentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Layout.homeHorizontalPadding)
            .padding(.top, Layout.homeTopSpacing)
            .padding(.bottom, Layout.homeBottomSafeSpacing)
        }
        .background(AppColors.appBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
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

    private func videoCard(_ video: ListeningVideoItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(accent.opacity(0.14))
                        .frame(width: 96, height: 64)
                    Image(systemName: video.thumbnailSystemImage)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(accent)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(video.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(accentDark)
                        .lineLimit(2)

                    Text(video.channel)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)

                    HStack(spacing: 6) {
                        ListeningMetadataChip(text: video.durationText, accent: accent)
                        ListeningMetadataChip(text: video.difficultyTitle, accent: accent)
                        ListeningMetadataChip(
                            text: video.hasCaptions ? "Captions available" : "Practice only",
                            accent: video.hasCaptions ? accent : AppColors.mutedText
                        )
                    }
                }
            }

            Button {
                viewModel.selectVideo(video)
            } label: {
                Text(video.hasCaptions ? "Start Practice" : "Watch Only")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(accent)
                    .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)

            if !video.hasCaptions {
                Text("Questions need captions or transcript.")
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
}

#Preview {
    NavigationStack {
        VideoListeningResultsView(
            setup: ListeningVideoSetup(
                language: .english,
                level: .b1,
                topic: "Travel",
                length: .medium
            )
        )
    }
}
