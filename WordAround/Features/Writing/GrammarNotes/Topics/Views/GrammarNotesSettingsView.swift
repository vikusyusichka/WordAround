import SwiftUI

struct GrammarNotesSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("grammarNotes.saveMistakesAutomatically") private var saveMistakesAutomatically = true
    @AppStorage("grammarNotes.askBeforeSavingMistakes") private var askBeforeSavingMistakes = true
    @AppStorage("grammarNotes.createMistakeNotesWithExplanation") private var createMistakeNotesWithExplanation = true
    @AppStorage("grammarNotes.groupMistakesByTopic") private var groupMistakesByTopic = true
    @AppStorage("grammarNotes.includeOriginalSentence") private var includeOriginalSentence = true
    @AppStorage("grammarNotes.includeCorrectedSentence") private var includeCorrectedSentence = true
    @AppStorage("grammarNotes.includeAIExplanation") private var includeAIExplanation = true
    @AppStorage("grammarNotes.allowQuickQuizzes") private var allowQuickQuizzes = false
    @AppStorage("grammarNotes.enableReviewReminders") private var enableReviewReminders = false

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad || UIScreen.main.bounds.width >= 700
    }

    var body: some View {
        ZStack {
            AppColors.appBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: isPadLike ? 18 : 14) {
                    headerView

                    settingsSection(
                        title: "Mistake Saving",
                        subtitle: "Control how corrections from essays and writing practice will become notes."
                    ) {
                        settingToggle("Save grammar mistakes automatically", isOn: $saveMistakesAutomatically)
                        settingDivider
                        settingToggle("Ask before saving mistakes", isOn: $askBeforeSavingMistakes)
                        settingDivider
                        settingToggle("Create mistake notes with explanation", isOn: $createMistakeNotesWithExplanation)
                        settingDivider
                        settingToggle("Group mistakes by topic", isOn: $groupMistakesByTopic)
                    }

                    settingsSection(
                        title: "Saved Content",
                        subtitle: "Choose what information should be included inside future mistake notes."
                    ) {
                        settingToggle("Include original sentence", isOn: $includeOriginalSentence)
                        settingDivider
                        settingToggle("Include corrected sentence", isOn: $includeCorrectedSentence)
                        settingDivider
                        settingToggle("Include AI explanation", isOn: $includeAIExplanation)
                    }

                    settingsSection(
                        title: "Review",
                        subtitle: "Prepare settings for future grammar review and quick practice."
                    ) {
                        settingToggle("Allow quick quizzes", isOn: $allowQuickQuizzes)
                        settingDivider
                        settingToggle("Enable review reminders", isOn: $enableReviewReminders)
                    }
                }
                .padding(.horizontal, isPadLike ? 28 : 20)
                .padding(.top, isPadLike ? 22 : 16)
                .padding(.bottom, 36)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var headerView: some View {
        HStack(alignment: .center) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppColors.primaryBlue)
                    .frame(width: isPadLike ? 62 : 58, height: isPadLike ? 62 : 58)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.96))
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Settings")
                .font(.system(size: isPadLike ? 34 : 28, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlue)
                .lineLimit(1)
                .minimumScaleFactor(0.82)

            Spacer()

            Color.clear
                .frame(width: isPadLike ? 62 : 58, height: isPadLike ? 62 : 58)
        }
    }

    private func settingsSection<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: isPadLike ? 14 : 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: isPadLike ? 18 : 16, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)

                Text(subtitle)
                    .font(.system(size: isPadLike ? 14 : 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineSpacing(2)
            }

            VStack(spacing: 0) {
                content()
            }
        }
        .padding(isPadLike ? 20 : 16)
        .background(Color.white.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: isPadLike ? 28 : 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.045), radius: 16, x: 0, y: 8)
    }

    private func settingToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .font(.system(size: isPadLike ? 16 : 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .toggleStyle(SwitchToggleStyle(tint: AppColors.primaryBlue))
        .padding(.vertical, isPadLike ? 12 : 10)
    }

    private var settingDivider: some View {
        Rectangle()
            .fill(AppColors.primaryBlue.opacity(0.08))
            .frame(height: 1)
    }
}

#Preview {
    NavigationStack {
        GrammarNotesSettingsView()
    }
}
