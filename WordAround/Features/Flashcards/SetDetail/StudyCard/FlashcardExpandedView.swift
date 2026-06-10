import SwiftUI

struct FlashcardExpandedView: View {
    @ObservedObject var viewModel: FlashcardSetDetailViewModel
    @Binding var isPresented: Bool

    @GestureState private var dragOffset: CGFloat = 0
    @State private var cardOffset: CGFloat = 0
    @State private var isFlipped = false

    private var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    private var totalCards: Int {
        max(viewModel.roundTotalCount, 1)
    }

    private var currentNumber: Int {
        viewModel.roundCurrentNumber
    }

    private var progress: CGFloat {
        viewModel.roundListingProgress
    }

    private var inProgressCount: Int {
        viewModel.roundLearningCount
    }

    private var knownCount: Int {
        viewModel.roundKnownCount
    }

    var body: some View {
        ZStack {
            viewModel.theme.screenBackground
                .ignoresSafeArea()

            if viewModel.trackProgress && viewModel.isShowingRoundFinish {
                FlashcardRoundFinishView(
                    theme: viewModel.theme,
                    knownCount: viewModel.roundKnownCount,
                    unknownCount: viewModel.roundLearningCount,
                    totalCount: viewModel.roundTotalCount,
                    onRepeatUnknown: {
                        viewModel.repeatUnknownRound()
                    },
                    onRestartAll: {
                        viewModel.restartAllCardsRound()
                    },
                    onClose: {
                        isPresented = false
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, isPadLike ? 38 : 22)
                        .padding(.top, isPadLike ? 20 : 14)

                    Spacer(minLength: isPadLike ? 18 : 12)

                    rotatingCard
                        .padding(.horizontal, isPadLike ? 70 : 24)
                        .offset(x: cardOffset + dragOffset)
                        .rotationEffect(.degrees(Double((cardOffset + dragOffset) / 38)))
                        .highPriorityGesture(swipeGesture)
                        .animation(.interactiveSpring(response: 0.32, dampingFraction: 0.82), value: dragOffset)

                    if viewModel.trackProgress {
                        progressSection
                            .padding(.top, isPadLike ? 34 : 28)
                            .padding(.horizontal, isPadLike ? 88 : 24)
                    }

                    Spacer(minLength: isPadLike ? 34 : 26)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isShowingRoundFinish)
        .onAppear {
            viewModel.prepareExpandedPresentation()
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: isPadLike ? 18 : 15, weight: .bold))
                    .foregroundStyle(viewModel.theme.titleColor)
                    .frame(width: isPadLike ? 48 : 40, height: isPadLike ? 48 : 40)
                    .background(viewModel.theme.fieldBackground.opacity(0.95))
                    .clipShape(Circle())
                    .shadow(color: viewModel.theme.shadowColor.opacity(0.6), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    private var rotatingCard: some View {
        ZStack {
            cardSideView(
                title: viewModel.activeRoundCard?.word ?? L10n.string("flashcardNoCards"),
                subtitle: L10n.string("flashcardCardSubWord"),
                isBackSide: false
            )
            .opacity(isFlipped ? 0 : 1)

            cardSideView(
                title: viewModel.activeRoundCard?.translation ?? "",
                subtitle: L10n.string("flashcardCardSubTranslation"),
                isBackSide: true
            )
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(
                .degrees(180),
                axis: (x: 0, y: 1, z: 0)
            )
        }
        .frame(height: isPadLike ? 720 : 560)
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.75
        )
        .animation(.easeInOut(duration: 0.48), value: isFlipped)
        .contentShape(RoundedRectangle(cornerRadius: isPadLike ? 44 : 34, style: .continuous))
        .onTapGesture {
            guard viewModel.activeRoundCard != nil else { return }

            withAnimation(.easeInOut(duration: 0.48)) {
                isFlipped.toggle()
            }
        }
    }

    private func cardSideView(
        title: String,
        subtitle: String,
        isBackSide: Bool
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: isPadLike ? 44 : 34, style: .continuous)
                .fill(viewModel.theme.sectionBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: isPadLike ? 44 : 34, style: .continuous)
                        .stroke(Color.white.opacity(0.9), lineWidth: isPadLike ? 8 : 6)
                }
                .shadow(color: viewModel.theme.shadowColor.opacity(0.85), radius: 28, x: 0, y: 16)

            decorativeBlobs

            VStack(spacing: 0) {
                VStack(spacing: isPadLike ? 10 : 8) {
                    Text(title.isEmpty ? "No translation" : title)
                        .font(.system(size: isPadLike ? 46 : 34, weight: .bold, design: .rounded))
                        .foregroundStyle(viewModel.theme.titleColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.55)
                        .padding(.horizontal, 34)

                    Text(subtitle)
                        .font(.system(size: isPadLike ? 16 : 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(viewModel.theme.mutedTextColor)
                }
                .padding(.top, isPadLike ? 86 : 68)

                Spacer(minLength: 18)

                cardImageArea

                Spacer(minLength: 40)
            }

            speakButton
                .padding(.trailing, isPadLike ? 34 : 24)
                .padding(.bottom, isPadLike ? 34 : 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
    }

    private var cardImageArea: some View {
        ZStack {
            ExpandedRoundedBlob()
                .fill(viewModel.theme.softAccent.opacity(0.78))
                .frame(width: isPadLike ? 440 : 300, height: isPadLike ? 330 : 245)
                .rotationEffect(.degrees(-8))

            ExpandedSparkleShape()
                .fill(viewModel.theme.accent.opacity(0.26))
                .frame(width: isPadLike ? 28 : 20, height: isPadLike ? 28 : 20)
                .offset(x: isPadLike ? -240 : -158, y: isPadLike ? -190 : -142)

            ExpandedSparkleShape()
                .fill(viewModel.theme.accent.opacity(0.23))
                .frame(width: isPadLike ? 22 : 16, height: isPadLike ? 22 : 16)
                .offset(x: isPadLike ? 246 : 154, y: isPadLike ? -58 : -44)

            cardImage
        }
        .frame(height: isPadLike ? 350 : 260)
    }

    private var cardImage: some View {
        Group {
            if let card = viewModel.activeRoundCard,
               let imageURL = card.imageURL,
               !imageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if imageURL.hasPrefix("http"),
                   let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                        default:
                            imagePlaceholder
                        }
                    }
                } else if let image = LocalImageStorageService().loadImage(fileName: imageURL) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    imagePlaceholder
                }
            } else {
                imagePlaceholder
            }
        }
        .frame(width: isPadLike ? 300 : 210, height: isPadLike ? 300 : 210)
    }

    private var imagePlaceholder: some View {
        Image(systemName: "hand.wave.fill")
            .font(.system(size: isPadLike ? 132 : 92, weight: .regular))
            .foregroundStyle(viewModel.theme.accent.opacity(0.9))
            .shadow(color: viewModel.theme.shadowColor.opacity(0.5), radius: 16, x: 0, y: 8)
    }

    private var speakButton: some View {
        Button {
            viewModel.speakCurrentCard()
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: isPadLike ? 34 : 26, weight: .semibold))
                .foregroundStyle(viewModel.theme.accent)
        }
        .buttonStyle(.plain)
    }

    private var progressSection: some View {
        VStack(spacing: isPadLike ? 16 : 12) {
            Text("\(currentNumber) / \(totalCards)")
                .font(.system(size: isPadLike ? 24 : 19, weight: .bold, design: .rounded))
                .foregroundStyle(viewModel.theme.mutedTextColor)

            HStack(spacing: isPadLike ? 22 : 14) {
                progressCounter(count: inProgressCount, title: L10n.string("flashcardLearning"))

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(viewModel.theme.softAccent.opacity(0.60))

                        Capsule()
                            .fill(viewModel.theme.accent)
                            .frame(width: proxy.size.width * progress)
                            .animation(.easeInOut(duration: 0.25), value: progress)
                    }
                }
                .frame(height: isPadLike ? 14 : 12)
                .frame(maxWidth: .infinity)

                progressCounter(count: knownCount, title: L10n.string("flashcardKnown"))
            }
        }
    }

    private func progressCounter(count: Int, title: String) -> some View {
        VStack(spacing: isPadLike ? 3 : 2) {
            Text("\(count)")
                .font(.system(size: isPadLike ? 18 : 15, weight: .bold, design: .rounded))
                .foregroundStyle(viewModel.theme.titleColor)
                .monospacedDigit()

            Text(title)
                .font(.system(size: isPadLike ? 11 : 9, weight: .semibold, design: .rounded))
                .foregroundStyle(viewModel.theme.mutedTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(width: isPadLike ? 92 : 72, height: isPadLike ? 58 : 48)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.96))
                .overlay {
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.85), lineWidth: 1)
                }
                .shadow(color: viewModel.theme.shadowColor.opacity(0.28), radius: 10, x: 0, y: 5)
        )
    }

    private var decorativeBlobs: some View {
        ZStack {
            ExpandedRoundedBlob()
                .fill(viewModel.theme.softAccent.opacity(0.45))
                .frame(width: isPadLike ? 260 : 190, height: isPadLike ? 220 : 165)
                .rotationEffect(.degrees(18))
                .offset(x: isPadLike ? 300 : 205, y: isPadLike ? -310 : -235)

            ExpandedRoundedBlob()
                .fill(viewModel.theme.softAccent.opacity(0.48))
                .frame(width: isPadLike ? 180 : 130, height: isPadLike ? 145 : 105)
                .rotationEffect(.degrees(-20))
                .offset(x: isPadLike ? -300 : -205, y: isPadLike ? 318 : 235)

            ExpandedSparkleShape()
                .fill(viewModel.theme.accent.opacity(0.24))
                .frame(width: isPadLike ? 30 : 22, height: isPadLike ? 30 : 22)
                .offset(x: isPadLike ? -270 : -175, y: isPadLike ? -260 : -195)

            ExpandedSparkleShape()
                .fill(viewModel.theme.accent.opacity(0.20))
                .frame(width: isPadLike ? 22 : 16, height: isPadLike ? 22 : 16)
                .offset(x: isPadLike ? 280 : 180, y: isPadLike ? 70 : 52)
        }
        .clipShape(RoundedRectangle(cornerRadius: isPadLike ? 44 : 34, style: .continuous))
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .updating($dragOffset) { value, state, _ in
                state = value.translation.width * 0.85
            }
            .onEnded { value in
                let threshold: CGFloat = 80
                let horizontalMovement = value.translation.width
                let verticalMovement = abs(value.translation.height)

                guard abs(horizontalMovement) > verticalMovement else {
                    resetCardPosition()
                    return
                }

                if horizontalMovement > threshold {
                    swipeRight()
                } else if horizontalMovement < -threshold {
                    swipeLeft()
                } else {
                    resetCardPosition()
                }
            }
    }

    private func swipeRight() {
        guard viewModel.roundTotalCount > 0 else { return }

        withAnimation(.easeOut(duration: 0.22)) {
            cardOffset = 460
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            viewModel.handleSwipe(.right)
            isFlipped = false
            cardOffset = -460

            withAnimation(.spring(response: 0.36, dampingFraction: 0.84)) {
                cardOffset = 0
            }
        }
    }

    private func swipeLeft() {
        guard viewModel.roundTotalCount > 0 else { return }

        withAnimation(.easeOut(duration: 0.22)) {
            cardOffset = -460
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            viewModel.handleSwipe(.left)
            isFlipped = false
            cardOffset = 460

            withAnimation(.spring(response: 0.36, dampingFraction: 0.84)) {
                cardOffset = 0
            }
        }
    }

    private func resetCardPosition() {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
            cardOffset = 0
        }
    }
}

// MARK: - Supporting Shapes

private struct ExpandedRoundedBlob: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.34))

        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.44, y: rect.minY + rect.height * 0.05),
            control1: CGPoint(x: rect.minX + rect.width * 0.20, y: rect.minY + rect.height * 0.14),
            control2: CGPoint(x: rect.minX + rect.width * 0.30, y: rect.minY + rect.height * 0.02)
        )

        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.88, y: rect.minY + rect.height * 0.28),
            control1: CGPoint(x: rect.minX + rect.width * 0.62, y: rect.minY + rect.height * 0.08),
            control2: CGPoint(x: rect.minX + rect.width * 0.78, y: rect.minY + rect.height * 0.08)
        )

        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.76, y: rect.minY + rect.height * 0.82),
            control1: CGPoint(x: rect.minX + rect.width * 1.00, y: rect.minY + rect.height * 0.50),
            control2: CGPoint(x: rect.minX + rect.width * 0.96, y: rect.minY + rect.height * 0.72)
        )

        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.86),
            control1: CGPoint(x: rect.minX + rect.width * 0.58, y: rect.minY + rect.height * 0.94),
            control2: CGPoint(x: rect.minX + rect.width * 0.38, y: rect.minY + rect.height * 0.96)
        )

        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.34),
            control1: CGPoint(x: rect.minX + rect.width * 0.06, y: rect.minY + rect.height * 0.72),
            control2: CGPoint(x: rect.minX + rect.width * 0.02, y: rect.minY + rect.height * 0.46)
        )

        path.closeSubpath()
        return path
    }
}

private struct ExpandedSparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let center = CGPoint(x: rect.midX, y: rect.midY)

        path.move(to: CGPoint(x: center.x, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: center.y), control: center)
        path.addQuadCurve(to: CGPoint(x: center.x, y: rect.maxY), control: center)
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: center.y), control: center)
        path.addQuadCurve(to: CGPoint(x: center.x, y: rect.minY), control: center)

        return path
    }
}

#Preview {
    let mockSet = FlashcardSet(
        id: "1",
        ownerUID: "preview",
        ownerEmail: "test@test.com",
        title: "Test",
        description: "Preview set",
        privacy: "private",
        folderID: nil,
        folderName: nil,
        colorHex: "#A855F7",
        icon: .systemName("rectangle.stack.fill"),
        cards: [
            Flashcard(
                id: "1",
                word: "Hola",
                translation: "Привіт",
                example: "Hola, ¿cómo estás?",
                imageURL: nil
            ),
            Flashcard(
                id: "2",
                word: "Gracias",
                translation: "Дякую",
                example: "Gracias por todo",
                imageURL: nil
            )
        ],
        createdAt: Date(),
        updatedAt: Date()
    )

    FlashcardExpandedView(
        viewModel: FlashcardSetDetailViewModel(set: mockSet),
        isPresented: .constant(true)
    )
}
