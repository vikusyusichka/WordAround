import SwiftUI

struct DebateTopicCardView: View {
    let topicTitle: String
    let topicDescription: String
    let learnerSide: DebateSide
    let isLoading: Bool

    private let accent = DebateTheme.accent
    private let accentDark = DebateTheme.accentDark

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(accent.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(accent)
                }

                Text("Debate topic")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)

                Spacer(minLength: 0)

                sideChip
            }

            if isLoading {
                Text("Generating a topic…")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)
                Text("Picking something debate-worthy for your level.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            } else {
                Text(topicTitle)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(accentDark)
                    .fixedSize(horizontal: false, vertical: true)
                if !topicDescription.isEmpty {
                    Text(topicDescription)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 5)
        )
    }

    private var sideChip: some View {
        HStack(spacing: 5) {
            Image(systemName: learnerSide.systemImage)
                .font(.system(size: 11, weight: .bold))
            Text("You: \(learnerSide.title)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .foregroundColor(accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(accent.opacity(0.10))
        .clipShape(Capsule())
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        VStack(spacing: 16) {
            DebateTopicCardView(
                topicTitle: "Should AI replace teachers?",
                topicDescription: "Argue whether classrooms are better with or without human teachers.",
                learnerSide: .agree,
                isLoading: false
            )
            DebateTopicCardView(topicTitle: "", topicDescription: "", learnerSide: .disagree, isLoading: true)
        }
        .padding()
    }
}
