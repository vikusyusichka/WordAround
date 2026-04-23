import SwiftUI
import Combine
import FirebaseAuth

struct VerifyEmailView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @StateObject private var viewModel = VerifyEmailViewModel()

    @State private var animateHeroPulse = false
    @State private var animateBadges = false

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 56)

                heroSection

                contentSection
                    .padding(.top, 26)

                actionSection
                    .padding(.top, 28)

                Spacer(minLength: 36)
            }
            .padding(.horizontal, 28)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            animateHeroPulse = true
            animateBadges = true
        }
    }
}

private extension VerifyEmailView {
    var backgroundLayer: some View {
        ZStack {
            Color(red: 0.96, green: 0.96, blue: 0.985)
                .ignoresSafeArea()

            BlobShape()
                .fill(Color(red: 0.95, green: 0.86, blue: 0.63))
                .frame(width: 250, height: 285)
                .rotationEffect(.degrees(16))
                .offset(x: 180, y: -320)

            BlobShape()
                .fill(Color(red: 0.82, green: 0.89, blue: 0.85).opacity(0.55))
                .frame(width: 150, height: 170)
                .rotationEffect(.degrees(-12))
                .offset(x: 175, y: 305)

            BlobShape()
                .fill(Color(red: 0.83, green: 0.87, blue: 0.96).opacity(0.50))
                .frame(width: 155, height: 175)
                .rotationEffect(.degrees(18))
                .offset(x: -178, y: 250)

            BlobShape()
                .fill(Color(red: 0.92, green: 0.82, blue: 0.87).opacity(0.42))
                .frame(width: 125, height: 145)
                .rotationEffect(.degrees(-20))
                .offset(x: -170, y: -45)
        }
    }

    var heroSection: some View {
        VStack(spacing: 18) {
            ZStack {
                animatedBadge(
                    text: "Check inbox",
                    color: Color(red: 0.98, green: 0.79, blue: 0.50),
                    x: -140,
                    y: -14,
                    delay: 0.0
                )

                animatedBadge(
                    text: "Confirm",
                    color: Color(red: 0.66, green: 0.84, blue: 0.72),
                    x: 108,
                    y: -22,
                    delay: 0.45
                )

                animatedBadge(
                    text: "Done",
                    color: Color(red: 0.72, green: 0.79, blue: 0.98),
                    x: 82,
                    y: 72,
                    delay: 0.9
                )

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.88))
                        .frame(width: 130, height: 130)
                        .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 8)

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.88, green: 0.94, blue: 1.0),
                                    Color.white
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateHeroPulse ? 1.04 : 0.96)
                        .animation(
                            .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                            value: animateHeroPulse
                        )

                    Circle()
                        .stroke(Color.white.opacity(0.8), lineWidth: 2)
                        .frame(width: 112, height: 112)
                        .scaleEffect(animateHeroPulse ? 1.10 : 0.92)
                        .opacity(animateHeroPulse ? 0.25 : 0.55)
                        .animation(
                            .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                            value: animateHeroPulse
                        )

                    Image(systemName: "envelope.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
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
                        .scaleEffect(animateHeroPulse ? 1.05 : 0.95)
                        .animation(
                            .easeInOut(duration: 1.6).repeatForever(autoreverses: true),
                            value: animateHeroPulse
                        )
                }
                .offset(x: -6)
            }
            .frame(height: 182)

            VStack(spacing: 10) {
                Text("Verify Your Email")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.24, green: 0.32, blue: 0.60))
                    .multilineTextAlignment(.center)

                Text("One more step before you start learning")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.51, green: 0.55, blue: 0.67))
                    .multilineTextAlignment(.center)
            }
        }
    }

    var contentSection: some View {
        VStack(spacing: 18) {
            VStack(spacing: 14) {
                Text("We sent a verification link to")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.51, green: 0.55, blue: 0.67))
                    .multilineTextAlignment(.center)

                Text(displayEmail)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                VStack(spacing: 8) {
                    verificationStep(number: "1", text: "Open the email in your inbox")
                    verificationStep(number: "2", text: "Tap the confirmation link")
                    verificationStep(number: "3", text: "Return here and continue")
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color(red: 0.86, green: 0.89, blue: 0.95), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 6)

            if let errorMessage = viewModel.errorMessage {
                statusCard(
                    text: errorMessage,
                    tint: .red.opacity(0.12),
                    stroke: .red.opacity(0.18),
                    foreground: .red
                )
            }

            if let infoMessage = viewModel.infoMessage {
                statusCard(
                    text: infoMessage,
                    tint: Color(red: 0.42, green: 0.78, blue: 0.58).opacity(0.14),
                    stroke: Color(red: 0.42, green: 0.78, blue: 0.58).opacity(0.22),
                    foreground: Color(red: 0.22, green: 0.58, blue: 0.38)
                )
            }
        }
    }

    var actionSection: some View {
        VStack(spacing: 16) {
            Button {
                Task {
                    await viewModel.checkVerificationStatus(sessionStore: sessionStore)
                }
            } label: {
                ZStack {
                    Text(viewModel.isLoading ? "Checking..." : "I Verified My Email")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
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
                            color: Color(red: 0.19, green: 0.58, blue: 0.97).opacity(0.22),
                            radius: 14,
                            x: 0,
                            y: 10
                        )

                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                }
            }
            .disabled(viewModel.isLoading)
            .buttonStyle(.plain)

            Button {
                Task {
                    await viewModel.resendVerificationEmail()
                }
            } label: {
                Text("Resend Email")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.25, green: 0.56, blue: 0.97))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white.opacity(0.94))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color(red: 0.86, green: 0.89, blue: 0.95), lineWidth: 1)
                    )
            }
            .disabled(viewModel.isLoading)
            .buttonStyle(.plain)

            Button {
                sessionStore.signOut()
            } label: {
                Text("Use Another Account")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.25, green: 0.56, blue: 0.97))
            }
            .padding(.top, 4)
        }
    }

    var displayEmail: String {
        if let email = Auth.auth().currentUser?.email, !email.isEmpty {
            return email
        }

        if !sessionStore.currentEmail.isEmpty, sessionStore.currentEmail != "Unknown account" {
            return sessionStore.currentEmail
        }

        return "your email"
    }

    func animatedBadge(
        text: String,
        color: Color,
        x: CGFloat,
        y: CGFloat,
        delay: Double
    ) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(color)
            .clipShape(Capsule())
            .shadow(color: color.opacity(0.22), radius: 8, x: 0, y: 5)
            .offset(
                x: animateBadges ? x : 0,
                y: animateBadges ? y : 6
            )
            .scaleEffect(animateBadges ? 1.0 : 0.82)
            .opacity(animateBadges ? 1.0 : 0.15)
            .animation(
                .easeInOut(duration: 1.9)
                    .delay(delay)
                    .repeatForever(autoreverses: true),
                value: animateBadges
            )
    }

    func verificationStep(number: String, text: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.88, green: 0.94, blue: 1.0))
                    .frame(width: 28, height: 28)

                Text(number)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.24, green: 0.48, blue: 0.90))
            }

            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(Color(red: 0.36, green: 0.40, blue: 0.50))

            Spacer()
        }
    }

    func statusCard(
        text: String,
        tint: Color,
        stroke: Color,
        foreground: Color
    ) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(foreground)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(tint)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(stroke, lineWidth: 1)
            )
    }
}

@MainActor
final class VerifyEmailViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?

    func resendVerificationEmail() async {
        clearMessages()
        isLoading = true
        defer { isLoading = false }

        guard let user = Auth.auth().currentUser else {
            errorMessage = "No active account found"
            return
        }

        do {
            try await user.sendEmailVerification()
            infoMessage = "Verification email sent again"
        } catch {
            errorMessage = (error as NSError).localizedDescription
        }
    }

    func checkVerificationStatus(sessionStore: SessionStore) async {
        clearMessages()
        isLoading = true
        defer { isLoading = false }

        do {
            guard let user = Auth.auth().currentUser else {
                errorMessage = "No active account found"
                return
            }

            try await user.reload()

            if user.isEmailVerified {
                await sessionStore.refreshAuthState()
            } else {
                errorMessage = "Email is not verified yet"
            }
        } catch {
            errorMessage = (error as NSError).localizedDescription
        }
    }

    private func clearMessages() {
        errorMessage = nil
        infoMessage = nil
    }
}

#Preview {
    VerifyEmailView()
        .environmentObject(SessionStore())
}
