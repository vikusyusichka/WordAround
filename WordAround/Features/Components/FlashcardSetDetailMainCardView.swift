import SwiftUI

struct FlashcardSetDetailMainCardView: View {
    let theme: CreateSetTheme
    let card: Flashcard?
    let currentIndex: Int
    let cardsCount: Int
    let isShowingTranslation: Bool
    let onTap: () -> Void
    let onSpeak: () -> Void

    var body: some View {
        ZStack {
            cardBackground
            cardBlobs

            if let card {
                ZStack {
                    cardSide(text: card.word)
                        .opacity(isShowingTranslation ? 0 : 1)

                    cardSide(text: card.translation)
                        .opacity(isShowingTranslation ? 1 : 0)
                        .rotation3DEffect(
                            .degrees(180),
                            axis: (x: 0, y: 1, z: 0)
                        )
                }
            }

            overlayContent
        }
        .frame(height: Layout.flashcardDetailCardHeight)
        .rotation3DEffect(
            .degrees(isShowingTranslation ? 180 : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.75
        )
        .animation(.easeInOut(duration: 0.45), value: isShowingTranslation)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: Layout.flashcardDetailCardCornerRadius, style: .continuous)
            .fill(theme.sectionBackground)
            .overlay {
                RoundedRectangle(cornerRadius: Layout.flashcardDetailCardCornerRadius, style: .continuous)
                    .stroke(theme.fieldBackground.opacity(0.95), lineWidth: 3)
            }
            .shadow(color: theme.shadowColor, radius: 14, x: 0, y: 8)
    }

    private func cardSide(text: String) -> some View {
        HStack(alignment: .center, spacing: 10) {
            Text(text)
                .font(.system(
                    size: Layout.flashcardDetailWordSize,
                    weight: .semibold,
                    design: .rounded
                ))
                .foregroundStyle(theme.titleColor)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)

            Button(action: onSpeak) {
                Image(systemName: "speaker.wave.2")
                    .font(.system(size: Layout.flashcardDetailSpeakerSize, weight: .bold))
                    .foregroundStyle(theme.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 28)
    }

    private var overlayContent: some View {
        VStack {
            HStack {
                sparkle(size: Layout.flashcardDetailCardSparkleSize)
                Spacer()
            }

            Spacer()

            HStack(alignment: .bottom) {
                Text("\(currentIndex + 1) / \(max(cardsCount, 1))")
                    .font(.system(
                        size: Layout.flashcardDetailCounterTextSize,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundStyle(theme.mutedTextColor)
                    .padding(.horizontal, Layout.flashcardDetailCounterHorizontalPadding)
                    .padding(.vertical, Layout.flashcardDetailCounterVerticalPadding)
                    .background(theme.fieldBackground, in: Capsule())

                Spacer()

                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: Layout.flashcardDetailExpandIconSize, weight: .bold))
                    .foregroundStyle(theme.mutedTextColor)
            }
        }
        .padding(Layout.flashcardDetailCardOverlayPadding)
        .rotation3DEffect(
            .degrees(isShowingTranslation ? 180 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
    }

    private var cardBlobs: some View {
        GeometryReader { proxy in
            ZStack {
                bottomLeftBlob(in: proxy.size)
                topRightBlob(in: proxy.size)

                sparkle(size: Layout.flashcardDetailCardSparkleSize)
                    .offset(
                        x: proxy.size.width * 0.32,
                        y: proxy.size.height * 0.29
                    )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Layout.flashcardDetailCardCornerRadius,
                    style: .continuous
                )
            )
        }
    }

    private func bottomLeftBlob(in size: CGSize) -> some View {
        TopRightWaveShape()
            .fill(theme.softAccent)
            .frame(
                width: size.width * 0.42,
                height: size.height * 0.42
            )
            .scaleEffect(x: -1, y: -1)
            .offset(
                x: -size.width * 0.33,
                y: size.height * 0.33
            )
    }

    private func topRightBlob(in size: CGSize) -> some View {
        TopRightWaveShape()
            .fill(theme.softAccent)
            .frame(
                width: size.width * 0.42,
                height: size.height * 0.42
            )
            .offset(
                x: size.width * 0.33,
                y: -size.height * 0.33
            )
    }

    private func sparkle(size: CGFloat) -> some View {
        Image(systemName: "sparkle")
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(theme.accent.opacity(0.3))
    }
}

private struct TopRightWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.width * 0.24, y: 0))

        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))

        path.addCurve(
            to: CGPoint(x: rect.width * 0.64, y: rect.height * 0.78),
            control1: CGPoint(x: rect.width * 0.86, y: rect.height),
            control2: CGPoint(x: rect.width * 0.70, y: rect.height * 0.98)
        )

        path.addCurve(
            to: CGPoint(x: rect.width * 0.38, y: rect.height * 0.64),
            control1: CGPoint(x: rect.width * 0.58, y: rect.height * 0.58),
            control2: CGPoint(x: rect.width * 0.48, y: rect.height * 0.72)
        )

        path.addCurve(
            to: CGPoint(x: rect.width * 0.24, y: 0),
            control1: CGPoint(x: rect.width * 0.20, y: rect.height * 0.48),
            control2: CGPoint(x: rect.width * 0.28, y: rect.height * 0.22)
        )

        path.closeSubpath()

        return path
    }
}

#Preview {
    ZStack {
        CreateSetTheme.yellow.screenBackground
            .ignoresSafeArea()

        FlashcardSetDetailMainCardView(
            theme: .yellow,
            card: Flashcard(
                id: UUID().uuidString,
                word: "Hola",
                translation: "Hello",
                example: "Hola, ¿cómo estás?",
                imageURL: nil
            ),
            currentIndex: 0,
            cardsCount: 15,
            isShowingTranslation: false,
            onTap: {},
            onSpeak: {}
        )
        .padding(.horizontal, 20)
    }
}
