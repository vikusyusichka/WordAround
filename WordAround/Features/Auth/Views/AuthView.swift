import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var sessionStore: SessionStore
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 50)

                headerSection

                formSection
                    .padding(.top, 36)

                actionSection
                    .padding(.top, 28)

                Spacer()
            }
            .padding(.horizontal, 28)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BackButton()
            }
        }
        .onAppear {
            viewModel.attachSessionStore(sessionStore)
        }
    }
}

private extension AuthView {
    var backgroundLayer: some View {
        ZStack {
            Color(red: 0.96, green: 0.96, blue: 0.985)
                .ignoresSafeArea()

            BlobShape()
                .fill(Color(red: 0.95, green: 0.86, blue: 0.63))
                .frame(width: 240, height: 270)
                .rotationEffect(.degrees(18))
                .offset(x: 180, y: -320)

            BlobShape()
                .fill(Color(red: 0.82, green: 0.89, blue: 0.85).opacity(0.55))
                .frame(width: 150, height: 170)
                .rotationEffect(.degrees(-14))
                .offset(x: 180, y: 300)

            BlobShape()
                .fill(Color(red: 0.83, green: 0.87, blue: 0.96).opacity(0.50))
                .frame(width: 150, height: 170)
                .rotationEffect(.degrees(20))
                .offset(x: -180, y: 250)

            BlobShape()
                .fill(Color(red: 0.92, green: 0.82, blue: 0.87).opacity(0.42))
                .frame(width: 120, height: 140)
                .rotationEffect(.degrees(-18))
                .offset(x: -175, y: -40)
        }
    }

    var headerSection: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 110, height: 110)
                    .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)

                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
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
            }

            VStack(spacing: 10) {
                Text(L10n.string("authWelcomeBack"))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.24, green: 0.32, blue: 0.60))

                Text(L10n.string("authSignInSubtitle"))
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.51, green: 0.55, blue: 0.67))
            }
            .multilineTextAlignment(.center)
        }
    }

    var formSection: some View {
        VStack(spacing: 18) {
            AuthInputField(
                title: L10n.string("authEmail"),
                text: $viewModel.email,
                placeholder: L10n.string("authEmailPlaceholder"),
                systemImage: "envelope.fill"
            )

            AuthSecureField(
                title: L10n.string("authPassword"),
                text: $viewModel.password,
                placeholder: L10n.string("authPasswordPlaceholder"),
                systemImage: "lock.fill"
            )

            HStack {
                Spacer()

                Button(L10n.string("authForgotPassword")) {
                    Task {
                        await viewModel.resetPassword()
                    }
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Color(red: 0.25, green: 0.56, blue: 0.97))
            }
            .padding(.top, 4)
        }
    }

    var actionSection: some View {
        VStack(spacing: 18) {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            if let infoMessage = viewModel.infoMessage {
                Text(infoMessage)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
            }

            Button(action: {
                Task {
                    await viewModel.signIn()
                }
            }) {
                ZStack {
                    Text(viewModel.isLoading ? L10n.string("authSigningIn") : L10n.string("authSignIn"))
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

            Button(action: {
                Task {
                    await viewModel.signInWithGoogle()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 18, weight: .semibold))

                    Text(L10n.string("authContinueWithGoogle"))
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.white.opacity(0.95))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color(red: 0.86, green: 0.89, blue: 0.95), lineWidth: 1)
                )
            }
            .disabled(viewModel.isLoading)
            .buttonStyle(.plain)

            Button(action: {
                Task {
                    await viewModel.signUp()
                }
            }) {
                Text(L10n.string("authCreateAccount"))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.25, green: 0.56, blue: 0.97))
            }
            .disabled(viewModel.isLoading)
        }
    }

    private struct AuthInputField: View {
        let title: String
        @Binding var text: String
        let placeholder: String
        let systemImage: String

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.35, green: 0.39, blue: 0.49))

                HStack(spacing: 12) {
                    Image(systemName: systemImage)
                        .foregroundColor(Color(red: 0.44, green: 0.58, blue: 0.95))
                        .frame(width: 20)

                    TextField(placeholder, text: $text)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                }
                .padding(.horizontal, 18)
                .frame(height: 58)
                .background(Color.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(red: 0.86, green: 0.89, blue: 0.95), lineWidth: 1)
                )
            }
        }
    }

    private struct AuthSecureField: View {
        let title: String
        @Binding var text: String
        let placeholder: String
        let systemImage: String

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.35, green: 0.39, blue: 0.49))

                HStack(spacing: 12) {
                    Image(systemName: systemImage)
                        .foregroundColor(Color(red: 0.44, green: 0.58, blue: 0.95))
                        .frame(width: 20)

                    SecureField(placeholder, text: $text)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .textContentType(.password)
                }
                .padding(.horizontal, 18)
                .frame(height: 58)
                .background(Color.white.opacity(0.9))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(red: 0.86, green: 0.89, blue: 0.95), lineWidth: 1)
                )
            }
        }
    }

    private struct BackButton: View {
        @Environment(\.dismiss) private var dismiss

        var body: some View {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 0.24, green: 0.32, blue: 0.60))
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.9))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AuthView()
            .environmentObject(SessionStore())
    }
}
