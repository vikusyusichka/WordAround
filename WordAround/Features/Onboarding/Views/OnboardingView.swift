import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var globeRotation: Double = 0
    @State private var wordsRotation: Double = 0

    private let greetings: [GreetingItem] = [
        .init(text: "Hello", color: Color(red: 0.25, green: 0.56, blue: 0.97), angle: -18),
        .init(text: "Hola", color: Color(red: 0.98, green: 0.74, blue: 0.27), angle: 52),
        .init(text: "Bonjour", color: Color(red: 0.95, green: 0.54, blue: 0.66), angle: 126),
        .init(text: "你好", color: Color(red: 0.42, green: 0.78, blue: 0.58), angle: 198),
        .init(text: "नमस्ते", color: Color(red: 0.55, green: 0.63, blue: 0.97), angle: 272)
    ]

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 105)

                heroSection

                titleSection
                    .padding(.top, 24)

                startButton
                    .padding(.top, 24)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                globeRotation = -360
            }

            withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
                wordsRotation = 360
            }
        }
    }
}

private extension OnboardingView {
    var backgroundLayer: some View {
        ZStack {
            Color(red: 0.96, green: 0.96, blue: 0.985)

            BlobShape()
                .fill(Color(red: 0.95, green: 0.86, blue: 0.63))
                .frame(width: 270, height: 315)
                .rotationEffect(.degrees(14))
                .offset(x: 195, y: -330)

            BlobShape()
                .fill(Color(red: 0.95, green: 0.86, blue: 0.63))
                .frame(width: 270, height: 330)
                .rotationEffect(.degrees(-18))
                .offset(x: -200, y: 360)

            BlobShape()
                .fill(Color(red: 0.92, green: 0.82, blue: 0.87).opacity(0.55))
                .frame(width: 120, height: 135)
                .rotationEffect(.degrees(22))
                .offset(x: -175, y: -40)

            BlobShape()
                .fill(Color(red: 0.83, green: 0.87, blue: 0.96).opacity(0.55))
                .frame(width: 125, height: 140)
                .rotationEffect(.degrees(-18))
                .offset(x: -185, y: 245)

            BlobShape()
                .fill(Color(red: 0.82, green: 0.89, blue: 0.85).opacity(0.60))
                .frame(width: 145, height: 155)
                .rotationEffect(.degrees(16))
                .offset(x: 180, y: 305)

            BlobShape()
                .fill(Color(red: 0.98, green: 0.78, blue: 0.82).opacity(0.32))
                .frame(width: 95, height: 110)
                .rotationEffect(.degrees(-8))
                .offset(x: 170, y: -55)

            BlobShape()
                .fill(Color(red: 0.78, green: 0.89, blue: 0.97).opacity(0.35))
                .frame(width: 105, height: 115)
                .rotationEffect(.degrees(28))
                .offset(x: -150, y: 120)

            BlobShape()
                .fill(Color(red: 0.82, green: 0.93, blue: 0.82).opacity(0.28))
                .frame(width: 110, height: 120)
                .rotationEffect(.degrees(-24))
                .offset(x: 120, y: 160)
        }
    }

    var heroSection: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.91, green: 0.94, blue: 0.985).opacity(0.78))
                .frame(width: 320, height: 320)

            Circle()
                .fill(Color(red: 0.95, green: 0.96, blue: 0.99))
                .frame(width: 238, height: 238)

            Circle()
                .stroke(Color.white.opacity(0.55), lineWidth: 18)
                .frame(width: 268, height: 268)

            Circle()
                .stroke(Color(red: 0.89, green: 0.92, blue: 0.97), lineWidth: 1)
                .frame(width: 292, height: 292)

            rotatingWordsLayer

            FlatBlueGlobe(rotation: globeRotation)
                .frame(width: 150, height: 150)
        }
    }

    var rotatingWordsLayer: some View {
        ZStack {
            ForEach(greetings) { item in
                OrbitingGreeting(item: item)
            }
        }
        .rotationEffect(.degrees(wordsRotation))
    }

    var titleSection: some View {
        VStack(spacing: 16) {
            Text("WordAround")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.24, green: 0.32, blue: 0.60))

            Text(L10n.string("onboardingTagline"))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(Color(red: 0.51, green: 0.55, blue: 0.67))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    var startButton: some View {
        Button {
            hasSeenOnboarding = true
        } label: {
            HStack(spacing: 16) {
                Text(L10n.string("onboardingStart"))
                    .font(.system(size: 24, weight: .bold, design: .rounded))

                Image(systemName: "arrow.right")
                    .font(.system(size: 24, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(width: 305, height: 78)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.16, green: 0.56, blue: 0.97),
                        Color(red: 0.31, green: 0.64, blue: 0.99)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(
                color: Color(red: 0.19, green: 0.58, blue: 0.97).opacity(0.24),
                radius: 18,
                x: 0,
                y: 12
            )
        }
        .buttonStyle(.plain)
    }
}

private struct GreetingItem: Identifiable {
    let id = UUID()
    let text: String
    let color: Color
    let angle: Double
}

private struct OrbitingGreeting: View {
    let item: GreetingItem

    var body: some View {
        Text(item.text)
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundColor(item.color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.72))
            )
            .overlay(
                Capsule()
                    .stroke(item.color.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: item.color.opacity(0.12), radius: 8, x: 0, y: 4)
            .offset(x: 0, y: -132)
            .rotationEffect(.degrees(item.angle))
    }
}

private struct FlatBlueGlobe: View {
    let rotation: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white,
                            Color(red: 0.96, green: 0.97, blue: 0.99),
                            Color(red: 0.91, green: 0.93, blue: 0.97)
                        ],
                        center: UnitPoint(x: 0.35, y: 0.28),
                        startRadius: 4,
                        endRadius: 120
                    )
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.9), lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 14, x: 0, y: 8)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.75),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(x: 0.82, y: 0.68)
                .offset(x: -8, y: -20)
                .blur(radius: 2)

            Image(systemName: "globe.europe.africa.fill")
                .resizable()
                .scaledToFit()
                .padding(22)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.47, green: 0.69, blue: 0.99),
                            Color(red: 0.20, green: 0.50, blue: 0.96)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(rotation))
        }
    }
}

#Preview {
    OnboardingView()
}
