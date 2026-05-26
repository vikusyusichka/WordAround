import SwiftUI

struct FlashcardRoundFinishView: View {
    let theme: CreateSetTheme
    let knownCount: Int
    let unknownCount: Int
    let totalCount: Int
    let onRepeatUnknown: () -> Void
    let onRestartAll: () -> Void
    let onClose: () -> Void

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var hasUnknownWords: Bool {
        unknownCount > 0
    }

    var body: some View {
        ZStack {
            theme.screenBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, isPadLike ? 38 : 22)
                    .padding(.top, isPadLike ? 20 : 14)

                Spacer(minLength: isPadLike ? 36 : 28)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: isPadLike ? 34 : 26) {
                        headerSection
                        statsCard
                        actionButtons
                    }
                    .padding(.horizontal, isPadLike ? 70 : 24)
                    .padding(.bottom, isPadLike ? 44 : 34)
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: isPadLike ? 18 : 15, weight: .bold))
                    .foregroundStyle(theme.titleColor)
                    .frame(width: isPadLike ? 48 : 40, height: isPadLike ? 48 : 40)
                    .background(theme.fieldBackground.opacity(0.95))
                    .clipShape(Circle())
                    .shadow(color: theme.shadowColor.opacity(0.6), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    private var headerSection: some View {
        VStack(spacing: isPadLike ? 22 : 18) {
            ZStack {
                Circle()
                    .fill(theme.softAccent.opacity(0.42))
                    .frame(width: isPadLike ? 142 : 112, height: isPadLike ? 142 : 112)

                Circle()
                    .fill(theme.softAccent.opacity(0.38))
                    .frame(width: isPadLike ? 104 : 82, height: isPadLike ? 104 : 82)

                Image(systemName: "party.popper.fill")
                    .font(.system(size: isPadLike ? 48 : 38, weight: .semibold))
                    .foregroundStyle(theme.accent)
                    .rotationEffect(.degrees(-12))
            }

            VStack(spacing: isPadLike ? 12 : 8) {
                Text("Round completed!")
                    .font(.system(size: isPadLike ? 42 : 32, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.titleColor)
                    .multilineTextAlignment(.center)

                Text("Great work. You finished this round. Here is what you know and what still needs practice.")
                    .font(.system(size: isPadLike ? 18 : 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.mutedTextColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: isPadLike ? 520 : 330)
            }
        }
    }

    private var statsCard: some View {
        HStack(spacing: 0) {
            statItem(
                count: knownCount,
                title: "Known",
                systemImage: "checkmark"
            )

            divider

            statItem(
                count: totalCount,
                title: "Total",
                systemImage: "book.closed"
            )

            divider

            statItem(
                count: unknownCount,
                title: "Learning",
                systemImage: "xmark"
            )
        }
        .frame(maxWidth: isPadLike ? 680 : .infinity)
        .padding(.vertical, isPadLike ? 34 : 26)
        .padding(.horizontal, isPadLike ? 24 : 14)
        .background(
            RoundedRectangle(cornerRadius: isPadLike ? 36 : 28, style: .continuous)
                .fill(theme.sectionBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: isPadLike ? 36 : 28, style: .continuous)
                        .stroke(Color.white.opacity(0.9), lineWidth: 1)
                }
                .shadow(color: theme.shadowColor.opacity(0.55), radius: 24, x: 0, y: 12)
        )
    }

    private func statItem(count: Int, title: String, systemImage: String) -> some View {
        VStack(spacing: isPadLike ? 13 : 10) {
            Text("\(count)")
                .font(.system(size: isPadLike ? 36 : 28, weight: .bold, design: .rounded))
                .foregroundStyle(title == "Total" ? theme.mutedTextColor : theme.titleColor)
                .monospacedDigit()

            Text(title)
                .font(.system(size: isPadLike ? 15 : 13, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.mutedTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            ZStack {
                Circle()
                    .fill(theme.softAccent.opacity(0.55))
                    .frame(width: isPadLike ? 48 : 40, height: isPadLike ? 48 : 40)

                Image(systemName: systemImage)
                    .font(.system(size: isPadLike ? 20 : 16, weight: .bold))
                    .foregroundStyle(title == "Total" ? theme.mutedTextColor : theme.accent)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(theme.softBorderColor.opacity(0.75))
            .frame(width: 1, height: isPadLike ? 92 : 76)
    }

    private var actionButtons: some View {
        VStack(spacing: isPadLike ? 18 : 14) {
            finishActionButton(
                title: "Review learning words",
                subtitle: hasUnknownWords
                    ? "Go through only the words you marked as learning"
                    : "No learning words left, so a full round will open",
                systemImage: "arrow.triangle.2.circlepath",
                isPrimary: true,
                action: onRepeatUnknown
            )

            finishActionButton(
                title: "Restart all words",
                subtitle: "Start a new round with every word",
                systemImage: "arrow.clockwise",
                isPrimary: false,
                action: onRestartAll
            )
        }
        .frame(maxWidth: isPadLike ? 680 : .infinity)
    }

    private func finishActionButton(
        title: String,
        subtitle: String,
        systemImage: String,
        isPrimary: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: isPadLike ? 20 : 16) {
                ZStack {
                    Circle()
                        .fill(isPrimary ? theme.softAccent.opacity(0.70) : Color.white.opacity(0.80))
                        .frame(width: isPadLike ? 58 : 48, height: isPadLike ? 58 : 48)

                    Image(systemName: systemImage)
                        .font(.system(size: isPadLike ? 24 : 20, weight: .semibold))
                        .foregroundStyle(isPrimary ? theme.accent : theme.mutedTextColor)
                }

                VStack(alignment: .leading, spacing: isPadLike ? 7 : 5) {
                    Text(title)
                        .font(.system(size: isPadLike ? 22 : 18, weight: .bold, design: .rounded))
                        .foregroundStyle(isPrimary ? theme.titleColor : theme.mutedTextColor)
                        .multilineTextAlignment(.leading)

                    Text(subtitle)
                        .font(.system(size: isPadLike ? 15 : 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.mutedTextColor)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }

                Spacer(minLength: 10)

                Image(systemName: "chevron.right")
                    .font(.system(size: isPadLike ? 22 : 18, weight: .bold))
                    .foregroundStyle(isPrimary ? theme.titleColor : theme.mutedTextColor)
            }
            .padding(.horizontal, isPadLike ? 28 : 20)
            .padding(.vertical, isPadLike ? 24 : 20)
            .background(
                RoundedRectangle(cornerRadius: isPadLike ? 30 : 24, style: .continuous)
                    .fill(isPrimary ? theme.sectionBackground : theme.fieldBackground.opacity(0.72))
                    .overlay {
                        RoundedRectangle(cornerRadius: isPadLike ? 30 : 24, style: .continuous)
                            .stroke(isPrimary ? theme.softBorderColor.opacity(0.95) : theme.softBorderColor.opacity(0.55), lineWidth: 1.3)
                    }
                    .shadow(color: isPrimary ? theme.shadowColor.opacity(0.32) : theme.shadowColor.opacity(0.16), radius: 16, x: 0, y: 8)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FlashcardRoundFinishView(
        theme: .red,
        knownCount: 12,
        unknownCount: 8,
        totalCount: 20,
        onRepeatUnknown: {},
        onRestartAll: {},
        onClose: {}
    )
}
