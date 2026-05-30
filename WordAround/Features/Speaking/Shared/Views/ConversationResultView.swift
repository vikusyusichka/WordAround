import SwiftUI

struct ConversationResultView<VM: SpeakingResultProvidable>: View {

    @ObservedObject var viewModel: VM

    var completionTitle: String = "Conversation completed"
    let onPracticeAgain: () -> Void
    let onBackToSpeaking: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isTranscriptExpanded = false

    private var feedback: SpeakingConversationFeedback? { viewModel.conversationFeedback }
    private var isLoading: Bool { viewModel.isGeneratingFeedback && feedback == nil }

    private var metricColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)
    }

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: Layout.essayMainSpacing) {
                    topBar
                        .padding(.bottom, 4)

                    if let fb = feedback {
                        scoreSection(fb)

                        if let banner = viewModel.feedbackError {
                            fallbackBanner(banner)
                        }

                        sectionTitle("Metrics")
                        metricsGrid(fb.metrics)

                        sectionTitle("Corrections")
                        correctionsSection(fb.corrections)

                        transcriptToggle

                        if isTranscriptExpanded {
                            transcriptContent
                        }
                    } else {
                        loadingSection
                    }

                    actionButtons
                }
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, Layout.homeTopSpacing)
                .padding(.bottom, Layout.homeBottomSafeSpacing)
                .animation(.easeInOut(duration: 0.25), value: feedback != nil)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func scoreSection(_ fb: SpeakingConversationFeedback) -> some View {
        ConversationScoreCardView(
            score: fb.overallScore,
            summary: fb.summary
        )
    }

    private func metricsGrid(_ metrics: [SpeakingFeedbackMetric]) -> some View {
        LazyVGrid(columns: metricColumns, spacing: 10) {
            ForEach(metrics) { metric in
                ConversationMetricCardView(
                    metric: Self.viewMetric(from: metric)
                )
            }
        }
    }

    private static func viewMetric(from metric: SpeakingFeedbackMetric) -> ConversationMetric {
        let (accent, blob) = Self.colours(for: metric.title)
        return ConversationMetric(
            title: metric.title,
            rating: metric.rating,
            score: metric.score,
            icon: metric.iconName,
            accentColor: accent,
            blobColor: blob
        )
    }

    private static func colours(for title: String) -> (Color, Color) {
        switch title.lowercased() {
        case "grammar":
            return (AppColors.primaryBlue, AppColors.blobBlue)
        case "pronunciation":
            return (AppColors.greenAccent, AppColors.blobGreen)
        case "vocabulary":
            return (AppColors.orangeAccent, AppColors.blobYellow)
        case "fluency":
            return (
                Color(red: 0.54, green: 0.36, blue: 0.88),
                Color(red: 0.90, green: 0.84, blue: 0.98)
            )
        case "argument quality":
            return (Color(red: 0.93, green: 0.40, blue: 0.60), AppColors.blobPink)
        case "persuasiveness":
            return (Color(red: 0.85, green: 0.28, blue: 0.52), AppColors.blobPink)
        case "structure":
            return (
                Color(red: 0.62, green: 0.30, blue: 0.66),
                Color(red: 0.92, green: 0.84, blue: 0.95)
            )
        default:
            return (AppColors.primaryBlue, AppColors.blobBlue)
        }
    }

    @ViewBuilder
    private func correctionsSection(_ corrections: [SpeakingCorrection]) -> some View {
        if corrections.isEmpty {
            emptyCorrectionsCard
        } else {
            VStack(spacing: 12) {
                ForEach(corrections) { correction in
                    ConversationCorrectionCardView(
                        correction: ConversationCorrection(
                            youSaid: correction.originalText,
                            better: correction.correctedText,
                            explanation: correction.explanation
                        )
                    )
                }
            }
        }
    }

    private var emptyCorrectionsCard: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.greenAccent.opacity(0.14))
                    .frame(width: 38, height: 38)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.greenAccent)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Great job")
                    .font(.system(size: Layout.isPadLike ? 16 : 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)

                Text("No major corrections found.")
                    .font(.system(size: Layout.isPadLike ? 14 : 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(2)
            }

            Spacer(minLength: 0)
        }
        .padding(Layout.isPadLike ? 18 : 15)
        .background(Color.white.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.045), radius: 14, x: 0, y: 8)
    }

    private var loadingSection: some View {
        VStack(spacing: 14) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(AppColors.primaryBlue)
                .scaleEffect(1.1)

            Text("Analyzing your conversation…")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .multilineTextAlignment(.center)

            Text("Reading your answers and preparing personalised feedback.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 18)
        .background(Color.white.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 4)
    }

    private func fallbackBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.foodAccent)

            Text(message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .lineLimit(3)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.96))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 3)
        )
    }

    private var topBar: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(completionTitle)
                    .font(.system(
                        size: Layout.homeHeaderTitleSize,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.primaryBlueDark)

                Text("Here is your speaking feedback.")
                    .font(.system(
                        size: Layout.homeHeaderSubtitleSize,
                        weight: .medium,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.mutedText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, Layout.flashcardDetailTopButtonSize + 10)
            .padding(.trailing, 10)

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(
                            size: Layout.flashcardDetailTopButtonIconSize,
                            weight: .bold
                        ))
                        .foregroundColor(AppColors.primaryBlueDark)
                        .frame(
                            width: Layout.flashcardDetailTopButtonSize,
                            height: Layout.flashcardDetailTopButtonSize
                        )
                        .background(Color.white.opacity(0.82))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
    }

    private var transcriptToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                isTranscriptExpanded.toggle()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "doc.text")
                    .font(.system(size: 15, weight: .semibold))

                Text(isTranscriptExpanded ? "Hide transcript" : "View transcript")
                    .font(.system(
                        size: Layout.isPadLike ? 16 : 14,
                        weight: .bold,
                        design: .rounded
                    ))

                Spacer(minLength: 0)

                Image(systemName: isTranscriptExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(AppColors.primaryBlue)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(AppColors.primaryBlue.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var transcriptContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if viewModel.messages.isEmpty {
                Text("No conversation recorded yet.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.mutedText)
            } else {
                ForEach(viewModel.messages) { msg in
                    HStack(alignment: .top, spacing: 8) {
                        Text(msg.role == .ai ? "AI" : "You")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(
                                msg.role == .ai
                                ? AppColors.primaryBlue
                                : AppColors.greenAccent
                            )
                            .frame(width: 28, alignment: .leading)

                        Text(msg.text)
                            .font(.system(
                                size: Layout.isPadLike ? 14 : 13,
                                weight: .medium,
                                design: .rounded
                            ))
                            .foregroundColor(AppColors.textSecondary)
                            .lineSpacing(2)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: Layout.smallCardCornerRadius, style: .continuous))
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button {
                onPracticeAgain()
            } label: {
                Text("Practice Again")
                    .font(.system(
                        size: Layout.convResultActionTextSize,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: Layout.convResultActionHeight)
                    .background(AppColors.primaryBlue)
                    .clipShape(RoundedRectangle(
                        cornerRadius: Layout.convResultActionCornerRadius,
                        style: .continuous
                    ))
            }
            .buttonStyle(.plain)

            Button {
                onBackToSpeaking()
            } label: {
                Text("Back to Speaking")
                    .font(.system(
                        size: Layout.convResultActionTextSize,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.primaryBlue)
                    .frame(maxWidth: .infinity)
                    .frame(height: Layout.convResultActionHeight)
                    .background(AppColors.primaryBlue.opacity(0.09))
                    .clipShape(RoundedRectangle(
                        cornerRadius: Layout.convResultActionCornerRadius,
                        style: .continuous
                    ))
            }
            .buttonStyle(.plain)

            Button {  } label: {
                Text("Save mistakes")
                    .font(.system(
                        size: Layout.isPadLike ? 15 : 13,
                        weight: .semibold,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.textSecondary)
            }
            .buttonStyle(.plain)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(
                size: Layout.homeSectionTitleSize,
                weight: .bold,
                design: .rounded
            ))
            .foregroundColor(AppColors.primaryBlueDark)
            .padding(.top, Layout.homeSectionTitleTopPadding)
    }
}

#Preview {
    NavigationStack {
        ConversationResultView(
            viewModel: AIConversationViewModel(
                setup: SpeakingConversationSetup(
                    language: .english,
                    level: .b1,
                    scenario: ConversationScenario.allScenarios[0],
                    length: .short
                )
            ),
            onPracticeAgain: {},
            onBackToSpeaking: {}
        )
    }
}
