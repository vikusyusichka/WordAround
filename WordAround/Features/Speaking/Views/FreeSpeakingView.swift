import SwiftUI

struct FreeSpeakingView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var isRecording = false
    @State private var isPaused = false
    @State private var showEditSheet = false

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, Layout.homeHorizontalPadding)
                    .padding(.top, Layout.homeTopSpacing)
                    .padding(.bottom, 14)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        FreeSpeakingTopicCardView(
                            title: "Morning routine",
                            description: "Talk about what you do every morning before work or school.",
                            chips: ["A2", "5 min", "Daily life"],
                            onEdit: { showEditSheet = true }
                        )
                        .padding(.horizontal, Layout.homeHorizontalPadding)
                        .padding(.bottom, 20)

                        transcriptSection
                            .padding(.horizontal, Layout.homeHorizontalPadding)
                    }
                    .frame(maxWidth: Layout.convContentMaxWidth)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, Layout.convMicBarHeight + Layout.convMicBarBottomPadding + 60)
                }
            }

            FreeSpeakingMicBarView(
                isRecording: isRecording,
                isPaused: isPaused,
                onEnd: { dismiss() },
                onMicTap: {
                    if isRecording { isPaused = false }
                    isRecording.toggle()
                },
                onPause: { isPaused.toggle() }
            )
            .padding(.horizontal, Layout.homeBottomBarHorizontalPadding)
            .padding(.bottom, Layout.homeBottomBarBottomPadding)
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showEditSheet) {
            topicEditSheet
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Free Speaking")
                    .font(.system(
                        size: Layout.homeHeaderTitleSize,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.primaryBlueDark)

                Text("Speak freely about a topic and get feedback.")
                    .font(.system(
                        size: Layout.homeHeaderSubtitleSize,
                        weight: .medium,
                        design: .rounded
                    ))
                    .foregroundColor(AppColors.mutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, Layout.flashcardDetailTopButtonSize + 10)
            .padding(.trailing, 124)

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

                VStack(alignment: .trailing, spacing: 4) {
                    Text("English · A2")
                        .font(.system(
                            size: Layout.convScenarioChipTextSize + 1,
                            weight: .bold,
                            design: .rounded
                        ))
                        .foregroundColor(AppColors.greenAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.greenAccent.opacity(0.09))
                        .clipShape(Capsule())

                    timerChip
                }
            }
        }
    }

    private var timerChip: some View {
        HStack(spacing: 5) {
            Image(systemName: "timer")
                .font(.system(size: 11, weight: .semibold))
            Text("05:00 left")
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .foregroundColor(AppColors.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(AppColors.textSecondary.opacity(0.10))
        .clipShape(Capsule())
    }

    // MARK: - Transcript Section

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transcript")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)

            emptyTranscriptState
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyTranscriptState: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppColors.greenAccent.opacity(0.10))
                    .frame(width: 54, height: 54)
                Image(systemName: "waveform")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(AppColors.greenAccent)
            }
            .padding(.top, 12)

            Text("Start speaking")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)

            Text("Your transcript will appear here\nwhile you speak.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)

            VStack(spacing: 8) {
                FreeSpeakingTranscriptCardView(
                    text: "I wake up at seven.",
                    isPlaceholder: true
                )
                FreeSpeakingTranscriptCardView(
                    text: "Then I have breakfast.",
                    isPlaceholder: true
                )
            }
            .padding(.top, 4)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.72))
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
        )
    }

    // MARK: - Edit Topic Placeholder Sheet

    private var topicEditSheet: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.secondary.opacity(0.35))
                .frame(width: 36, height: 5)
                .padding(.top, 14)

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppColors.greenAccent.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColors.greenAccent)
                }
                Text("Choose Topic")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)
            }

            Text("Topic selection coming soon.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)

            Spacer()
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

#Preview {
    NavigationStack {
        FreeSpeakingView()
    }
}
