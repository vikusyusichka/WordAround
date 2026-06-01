import SwiftUI

/// The Video Listening player card.
///
/// Architecture note: this view is structured so a native `AVPlayer`-based
/// player can drop into `previewArea` later. Today YouTube sources aren't
/// natively playable, so the external branch (preview + "Open in YouTube" +
/// "I watched this video") is shown. The native control bar (play/pause,
/// progress, replay) is rendered only for natively-playable URLs and is the
/// placeholder for that future player. The view is purely presentational — all
/// state and actions are owned by `VideoListeningSessionViewModel`.
struct VideoListeningPlayerView: View {
    let video: ListeningVideoItem
    let requiresExternalPlayback: Bool

    // Native player placeholder state
    let isPlaying: Bool
    let progress: Double
    let currentTimeText: String
    let durationText: String

    // Watch completion
    let isWatched: Bool

    // Subtitles
    let subtitlesEnabled: Bool
    let subtitleLoadState: ListeningSubtitleLoadState
    let activeSubtitleText: String?

    // Translation
    let selectedSubtitleText: String?
    let translatedSubtitleText: String?
    let isTranslating: Bool
    let translationError: String?
    let canTranslate: Bool

    // Callbacks
    var onPlayPause: () -> Void = {}
    var onReplay: () -> Void = {}
    var onToggleSubtitles: () -> Void = {}
    var onTapSubtitle: () -> Void = {}
    var onTranslate: () -> Void = {}
    var onOpenExternal: () -> Void = {}
    var onMarkWatched: () -> Void = {}

    var accent: Color = ListeningTheme.videoListeningAccent
    var accentDark: Color = ListeningTheme.videoListeningDark

    var body: some View {
        VStack(spacing: 14) {
            previewArea

            if requiresExternalPlayback {
                externalControls
            } else {
                nativeControls
            }

            Text(video.channel)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            subtitleSection
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
        )
    }

    // MARK: - Preview area (future AVPlayer mount point)

    private var previewArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(accent.opacity(0.10))
                .frame(height: 200)

            // Future: replace this thumbnail with an AVPlayerLayer-backed view
            // for natively-playable sources.
            if let urlString = video.thumbnailURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        placeholderArt
                    }
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                placeholderArt
            }

            // Play overlay
            Button {
                requiresExternalPlayback ? onOpenExternal() : onPlayPause()
            } label: {
                ZStack {
                    Circle().fill(Color.black.opacity(0.35)).frame(width: 60, height: 60)
                    Image(systemName: requiresExternalPlayback ? "play.fill" : (isPlaying ? "pause.fill" : "play.fill"))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)

            if isWatched {
                VStack {
                    HStack {
                        Spacer()
                        Label("Watched", systemImage: "checkmark.seal.fill")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(accent)
                            .clipShape(Capsule())
                            .padding(10)
                    }
                    Spacer()
                }
            }
        }
        .frame(height: 200)
    }

    private var placeholderArt: some View {
        Image(systemName: "play.rectangle.fill")
            .font(.system(size: 48, weight: .semibold))
            .foregroundColor(accent.opacity(0.7))
    }

    // MARK: - External controls (YouTube fallback)

    private var externalControls: some View {
        VStack(spacing: 10) {
            Button(action: onOpenExternal) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right.square")
                    Text("Open in YouTube")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundColor(accentDark)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)

            if !isWatched {
                Button(action: onMarkWatched) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("I watched this video")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(accent)
                    .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Native controls (placeholder for future AVPlayer)

    private var nativeControls: some View {
        HStack(spacing: 14) {
            Button(action: onPlayPause) {
                ZStack {
                    Circle().fill(accent).frame(width: 48, height: 48)
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                ReadingProgressBar(progress: progress, accent: accent)
                HStack {
                    Text(currentTimeText)
                    Spacer()
                    Text(durationText)
                }
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
            }

            Button(action: onReplay) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(accentDark)
                    .frame(width: 40, height: 40)
                    .background(accent.opacity(0.10))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Subtitles + translation

    private var subtitleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                subtitleToggleChip
                translateChip
                Spacer(minLength: 0)
            }

            if subtitlesEnabled {
                subtitleContent
            }
        }
    }

    private var subtitleToggleChip: some View {
        Button(action: onToggleSubtitles) {
            HStack(spacing: 5) {
                Image(systemName: "captions.bubble.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text(subtitlesEnabled ? "Subtitles on" : "Subtitles")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .foregroundColor(subtitlesEnabled ? .white : accentDark)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(subtitlesEnabled ? accent : accent.opacity(0.10))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var translateChip: some View {
        Button(action: onTranslate) {
            HStack(spacing: 5) {
                if isTranslating {
                    ProgressView().controlSize(.mini).tint(accentDark)
                } else {
                    Image(systemName: "character.book.closed.fill")
                        .font(.system(size: 12, weight: .semibold))
                }
                Text("Translate")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .foregroundColor(canTranslate ? accentDark : AppColors.mutedText)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background((canTranslate ? accent : AppColors.mutedText).opacity(0.10))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!canTranslate)
    }

    @ViewBuilder
    private var subtitleContent: some View {
        switch subtitleLoadState {
        case .loading:
            ListeningLoadingRow(message: "Loading subtitles…", accent: accent)
        case .unavailable, .failed:
            Text("No subtitles available for this video.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.mutedText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 6)
        case .idle, .loaded:
            subtitleLineBox
        }
    }

    private var subtitleLineBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Tap the current line to select it for translation.
            Button(action: onTapSubtitle) {
                Text(activeSubtitleText ?? "…")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(accentDark)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                            .fill(accent.opacity(0.08))
                    )
            }
            .buttonStyle(.plain)

            if let selected = selectedSubtitleText {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Selected: \(selected)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                    if let translated = translatedSubtitleText {
                        Text(translated)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(accent)
                    }
                    if let error = translationError {
                        Text(error)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 0.95, green: 0.42, blue: 0.40))
                    }
                }
            } else {
                Text("Tap a subtitle line, then Translate.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.mutedText)
            }
        }
    }
}
