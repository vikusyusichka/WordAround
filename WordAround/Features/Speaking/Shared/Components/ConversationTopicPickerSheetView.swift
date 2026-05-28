import SwiftUI

struct ConversationTopicPickerSheetView<VM: SpeakingTopicPickable>: View {
    @ObservedObject var viewModel: VM

    private let scenarios = ConversationScenario.allScenarios

    private var scenarioColumns: [GridItem] {
        let count = Layout.isPadLike ? 2 : 1
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: count)
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    aiTopicCard

                    sectionTitle("Standard topics")

                    LazyVGrid(columns: scenarioColumns, spacing: 10) {
                        ForEach(scenarios) { scenario in
                            standardTopicCard(scenario)
                        }
                    }
                }
                .frame(maxWidth: Layout.convContentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, Layout.homeHorizontalPadding)
                .padding(.top, 14)
                .padding(.bottom, 28)
                .animation(.easeInOut(duration: 0.2), value: viewModel.generatedTopic)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isGeneratingTopic)
            }
            .background(AppColors.appBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { viewModel.showTopicPicker = false }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlue)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear {
            #if DEBUG
            print("[TopicPicker] sheet opened")
            #endif
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Choose a topic")
                .font(.system(size: Layout.isPadLike ? 28 : 24, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)

            Text("Switching topic will reset the current conversation.")
                .font(.system(size: Layout.isPadLike ? 15 : 13, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .lineSpacing(2)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: Layout.isPadLike ? 20 : 17, weight: .bold, design: .rounded))
            .foregroundColor(AppColors.primaryBlueDark)
            .padding(.top, 6)
    }

    @ViewBuilder
    private var aiTopicCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            aiCardHeader

            if viewModel.isGeneratingTopic {
                aiGeneratingBody
            } else if let topic = viewModel.generatedTopic {
                aiTopicBody(topic)
            } else {
                aiEmptyBody
            }

            if let error = viewModel.topicGenerationError {
                aiInfoBanner(error)
            }
        }
        .padding(Layout.isPadLike ? 20 : 16)
        .background(
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppColors.goalBackground)

                ProgressBlobShape()
                    .fill(AppColors.blobBlue.opacity(0.55))
                    .frame(width: 130, height: 110)
                    .padding(.trailing, -22)
                    .padding(.top, 6)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.85), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 6)
    }

    private var aiCardHeader: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryBlue.opacity(0.14))
                    .frame(width: 36, height: 36)
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.primaryBlue)
            }

            Text("AI-generated topic")
                .font(.system(size: Layout.isPadLike ? 18 : 15, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)

            Spacer(minLength: 0)
        }
    }

    private var aiEmptyBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Generate fresh topic")
                    .font(.system(size: Layout.isPadLike ? 18 : 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)

                Text("AI will create a topic for your level.")
                    .font(.system(size: Layout.isPadLike ? 14 : 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }

            primaryButton("Generate", icon: "sparkles") {
                viewModel.generateFreshTopic(forceRefresh: false)
            }
        }
    }

    private var aiGeneratingBody: some View {
        HStack(alignment: .center, spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(AppColors.primaryBlue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Generating topic…")
                    .font(.system(size: Layout.isPadLike ? 17 : 15, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)

                Text("Picking something for your level.")
                    .font(.system(size: Layout.isPadLike ? 14 : 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
    }

    private func aiTopicBody(_ topic: GeneratedConversationTopic) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(topic.title)
                    .font(.system(size: Layout.isPadLike ? 19 : 17, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)
                    .fixedSize(horizontal: false, vertical: true)

                Text(topic.description)
                    .font(.system(size: Layout.isPadLike ? 14 : 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 6) {
                topicChip(viewModel.setup.level.title)
                topicChip(viewModel.setup.length.title)
                topicChip(topic.category)
            }

            HStack(spacing: 8) {
                secondaryButton("Regenerate", icon: "arrow.clockwise") {
                    viewModel.generateFreshTopic(forceRefresh: true)
                }
                primaryButton("Use topic", icon: "checkmark") {
                    viewModel.applyGeneratedTopic()
                }
            }
            .padding(.top, 2)
        }
    }

    private func topicChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: Layout.isPadLike ? 12 : 11, weight: .bold, design: .rounded))
            .foregroundColor(AppColors.primaryBlue)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(AppColors.primaryBlue.opacity(0.10))
            .clipShape(Capsule())
    }

    private func aiInfoBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.foodAccent)
            Text(message)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.85))
        )
    }

    private func primaryButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .font(.system(size: Layout.isPadLike ? 15 : 14, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity)
            .background(AppColors.primaryBlue)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func secondaryButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .font(.system(size: Layout.isPadLike ? 15 : 14, weight: .bold, design: .rounded))
            }
            .foregroundColor(AppColors.primaryBlue)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity)
            .background(AppColors.primaryBlue.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func standardTopicCard(_ scenario: ConversationScenario) -> some View {
        let isSelected = viewModel.selectedScenario?.id == scenario.id

        return Button {
            viewModel.applyStandardScenario(scenario)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected
                              ? AppColors.primaryBlue
                              : AppColors.primaryBlue.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: scenario.systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? .white : AppColors.primaryBlue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(scenario.title)
                        .font(.system(size: Layout.isPadLike ? 16 : 15, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.primaryBlueDark)
                        .lineLimit(1)

                    Text(scenario.description)
                        .font(.system(size: Layout.isPadLike ? 13 : 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppColors.primaryBlue)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(
                isSelected
                ? AppColors.primaryBlue.opacity(0.06)
                : Color.white.opacity(0.92)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isSelected
                        ? AppColors.primaryBlue.opacity(0.35)
                        : Color.white.opacity(0.85),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .shadow(color: Color.black.opacity(isSelected ? 0.07 : 0.04), radius: 10, x: 0, y: 4)
            .animation(.easeInOut(duration: 0.18), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ConversationTopicPickerSheetView(
        viewModel: AIConversationViewModel(
            setup: SpeakingConversationSetup(
                language: .english,
                level: .b1,
                scenario: ConversationScenario.allScenarios[0],
                length: .medium
            )
        )
    )
}
