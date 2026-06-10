import SwiftUI
import AVKit

struct ImportVideoPlayerView: View {
    let player: AVPlayer
    let subtitlesEnabled: Bool
    let hasSubtitles: Bool
    let activeSubtitleText: String?

    var onToggleSubtitles: () -> Void = {}
    var onTapWord: (String) -> Void = { _ in }

    var accent: Color = ListeningTheme.importVideoAccent
    var accentDark: Color = ListeningTheme.importVideoDark

    var body: some View {
        VStack(spacing: 14) {
            VideoPlayer(player: player)
                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

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

    private var subtitleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                subtitleToggleChip
                Spacer(minLength: 0)
            }

            if subtitlesEnabled {
                if !hasSubtitles {
                    Text(L10n.string("listeningNoSubtitles"))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.mutedText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                } else {
                    tappableLine
                }
            }
        }
    }

    private var subtitleToggleChip: some View {
        Button(action: onToggleSubtitles) {
            HStack(spacing: 5) {
                Image(systemName: "captions.bubble.fill").font(.system(size: 12, weight: .semibold))
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

    private var tappableLine: some View {
        VStack(alignment: .leading, spacing: 6) {
            ImportVideoFlowLayout(spacing: 6, lineSpacing: 6) {
                ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                    Button { onTapWord(word) } label: {
                        Text(word)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(accentDark)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous).fill(accent.opacity(0.08))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous)
                    .fill(accent.opacity(0.05))
            )

            Text(L10n.string("listeningTapWordTranslate"))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.mutedText)
        }
    }

    private var words: [String] {
        (activeSubtitleText ?? "")
            .split(whereSeparator: { $0 == " " || $0 == "\n" })
            .map(String.init)
    }
}

struct ImportVideoFlowLayout: SwiftUI.Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0; y += lineHeight + lineSpacing; lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX; y += lineHeight + lineSpacing; lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
