import SwiftUI

struct GrammarTemplateCardView: View {
    let title: String
    let description: String
    let iconName: String
    let tint: Color
    let difficulty: String
    let estimatedMinutes: Int
    let tags: [String]
    let includedNotesCount: Int?
    let isSelected: Bool

    init(
        title: String,
        description: String,
        iconName: String,
        tint: Color,
        difficulty: String,
        estimatedMinutes: Int,
        tags: [String] = [],
        includedNotesCount: Int? = nil,
        isSelected: Bool = false
    ) {
        self.title = title
        self.description = description
        self.iconName = iconName
        self.tint = tint
        self.difficulty = difficulty
        self.estimatedMinutes = estimatedMinutes
        self.tags = tags
        self.includedNotesCount = includedNotesCount
        self.isSelected = isSelected
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.16))
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(tint)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlueDark)
                    .lineLimit(2)

                Text(description)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                metaRow
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isSelected ? tint.opacity(0.85) : Color.white.opacity(0.72),
                        lineWidth: isSelected ? 2 : 1)
        )
        .shadow(color: Color.black.opacity(0.045), radius: 12, x: 0, y: 6)
    }

    private var metaRow: some View {
        HStack(spacing: 6) {
            badge(text: difficulty, systemImage: "graduationcap.fill", tint: tint)
            badge(text: "\(estimatedMinutes) min", systemImage: "clock.fill", tint: AppColors.textSecondary)
            if let count = includedNotesCount {
                badge(text: "\(count) notes", systemImage: "doc.text.fill", tint: AppColors.primaryBlue)
            }
            ForEach(tags.prefix(2), id: \.self) { tag in
                Text("#\(tag)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.72))
                    .clipShape(Capsule())
            }
        }
    }

    private func badge(text: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemImage)
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .lineLimit(1)
        }
        .font(.system(size: 10, weight: .bold, design: .rounded))
        .foregroundStyle(tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.10))
        .clipShape(Capsule())
    }
}

#Preview("Topic template card") {
    VStack(spacing: 12) {
        GrammarTemplateCardView(
            title: "Spanish A1 Essentials",
            description: "The grammar core every Spanish beginner trips on.",
            iconName: "text.book.closed.fill",
            tint: Color(red: 1.00, green: 0.48, blue: 0.33),
            difficulty: "A1",
            estimatedMinutes: 45,
            tags: ["spanish", "A1"],
            includedNotesCount: 5,
            isSelected: true
        )
        GrammarTemplateCardView(
            title: "Grammar Rule Template",
            description: "Rule, examples, warning and practice.",
            iconName: "text.book.closed.fill",
            tint: AppColors.primaryBlue,
            difficulty: "A1",
            estimatedMinutes: 8,
            tags: ["rule"]
        )
    }
    .padding()
    .background(AppColors.appBackground)
}
