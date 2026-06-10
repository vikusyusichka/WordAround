import SwiftUI

struct DescribePicturePromptCardView: View {
    private let orange = AppColors.orangeAccent

    private let hints: [(icon: String, text: String)] = [
        ("person.2.fill", "people"),
        ("cube.box.fill", "objects"),
        ("figure.walk", "actions"),
        ("paintpalette.fill", "colors"),
        ("heart.fill", "emotions")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(orange.opacity(0.14))
                        .frame(width: 34, height: 34)
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(orange)
                }

                Text(L10n.string("spkDescribeWhatYouSee"))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.orangeTitle)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(L10n.string("spkTryToMention"))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)

            FlowChips(items: hints, accent: orange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                .fill(orange.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.cardCornerRadius, style: .continuous)
                        .stroke(orange.opacity(0.18), lineWidth: 1)
                )
        )
    }
}

private struct FlowChips: View {
    let items: [(icon: String, text: String)]
    let accent: Color

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { chips }
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) { chip(items[0]); chip(items[1]); chip(items[2]) }
                HStack(spacing: 8) { chip(items[3]); chip(items[4]) }
            }
        }
    }

    private var chips: some View {
        ForEach(items, id: \.text) { chip($0) }
    }

    private func chip(_ item: (icon: String, text: String)) -> some View {
        HStack(spacing: 5) {
            Image(systemName: item.icon)
                .font(.system(size: 11, weight: .semibold))
            Text(item.text)
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .foregroundColor(accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.9))
        .clipShape(Capsule())
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        DescribePicturePromptCardView()
            .padding(20)
    }
}
