import SwiftUI

/// Shows the pronunciation assessment for an attempt: Pronunciation /
/// Accuracy / Fluency / Completeness scores, recognized text and weak
/// words/sounds. When the result is an estimate (no acoustic engine), an
/// honest warning is shown — we never pretend transcript similarity is real
/// pronunciation analysis.
///
/// Presentation only.
struct PronunciationAssessmentCardView: View {
    let assessment: PronunciationAssessmentResult?
    let isAssessing: Bool

    private let accent = PronunciationTrainerTheme.accent
    private let accentDark = PronunciationTrainerTheme.accentDark

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isAssessing {
                assessingState
            } else if let assessment {
                scoreGrid(assessment)
                recognizedSection(assessment)
                weakWordsSection(assessment)
                retrySuggestion(for: assessment)
                if assessment.isEstimate { estimateWarning }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.96))
                .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 6)
        )
    }

    private var assessingState: some View {
        HStack(spacing: 12) {
            ProgressView().tint(accent)
            Text("Assessing pronunciation…")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(accentDark)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }

    private func scoreGrid(_ a: PronunciationAssessmentResult) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                scoreCell("Pronunciation", a.pronunciationScore, primary: true)
                scoreCell("Accuracy", a.accuracyScore)
            }
            HStack(spacing: 10) {
                scoreCell("Fluency", a.fluencyScore)
                scoreCell("Completeness", a.completenessScore)
            }
        }
    }

    private func scoreCell(_ title: String, _ value: Double, primary: Bool = false) -> some View {
        let pct = Int(value.rounded())
        let color = scoreColor(pct)
        return VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
            Text("\(pct)%")
                .font(.system(size: primary ? 26 : 22, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(color.opacity(0.10)))
    }

    private func recognizedSection(_ a: PronunciationAssessmentResult) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Recognized")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(accentDark)
            Text(a.recognizedText.isEmpty ? "—" : a.recognizedText)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func weakWordsSection(_ a: PronunciationAssessmentResult) -> some View {
        let weak = a.weakWords
        if !weak.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.93, green: 0.45, blue: 0.30))
                    Text("Weak word / sound")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(accentDark)
                }
                FlexibleWrap(spacing: 6, lineSpacing: 6) {
                    ForEach(weak) { w in
                        Text(w.word)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.86, green: 0.34, blue: 0.22))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.93, green: 0.45, blue: 0.30).opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func retrySuggestion(for a: PronunciationAssessmentResult) -> some View {
        let text: String
        switch Int(a.pronunciationScore.rounded()) {
        case 85...:   text = "Excellent — that sound is clear. Try the next item."
        case 65..<85: text = "Close. Replay the model and focus on the weak sound."
        default:      text = "Listen again, then repeat slowly and exaggerate the sound."
        }
        return HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(accent)
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(accentDark)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(accent.opacity(0.08)))
    }

    private var estimateWarning: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.mutedText)
            Text("Pronunciation assessment unavailable. Showing a transcript-based estimate — not real acoustic analysis.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.mutedText)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private func scoreColor(_ pct: Int) -> Color {
        switch pct {
        case 80...:   return Color(red: 0.20, green: 0.70, blue: 0.45)
        case 55..<80: return accent
        default:      return Color(red: 0.93, green: 0.45, blue: 0.30)
        }
    }
}

/// Lightweight flow layout (iOS 16+ `Layout`). Fully qualified because the app
/// defines its own `Layout` enum which would otherwise shadow SwiftUI's.
private struct FlexibleWrap: SwiftUI.Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth { x = 0; y += lineHeight + lineSpacing; lineHeight = 0 }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: maxWidth == .infinity ? x : maxWidth, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX, y: CGFloat = bounds.minY, lineHeight: CGFloat = 0
        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > bounds.minX + maxWidth { x = bounds.minX; y += lineHeight + lineSpacing; lineHeight = 0 }
            sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        ScrollView {
            VStack(spacing: 16) {
                PronunciationAssessmentCardView(
                    assessment: PronunciationAssessmentResult(
                        pronunciationScore: 84, accuracyScore: 79, fluencyScore: 88, completenessScore: 92,
                        recognizedText: "perro",
                        wordResults: [PronunciationWordResult(word: "rr", accuracyScore: 40, errorType: "Mispronunciation")],
                        isEstimate: true
                    ),
                    isAssessing: false
                )
                PronunciationAssessmentCardView(assessment: nil, isAssessing: true)
            }
            .padding()
        }
    }
}
