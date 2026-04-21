import SwiftUI

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""

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
                Text("Welcome")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.24, green: 0.32, blue: 0.60))

                Text("Sign in to continue learning")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundColor(Color(red: 0.51, green: 0.55, blue: 0.67))
            }
            .multilineTextAlignment(.center)
        }
    }

    var formSection: some View {
        VStack(spacing: 18) {
            AuthInputField(
                title: "Email",
                text: $email,
                placeholder: "Enter your email",
                systemImage: "envelope.fill"
            )

            AuthSecureField(
                title: "Password",
                text: $password,
                placeholder: "Enter your password",
                systemImage: "lock.fill"
            )

            HStack {
                Spacer()

                Button("Forgot password?") {
                    print("Forgot password tapped")
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(Color(red: 0.25, green: 0.56, blue: 0.97))
            }
            .padding(.top, 4)
        }
    }

    var actionSection: some View {
        VStack(spacing: 18) {
            Button(action: {
                print("Sign In tapped")
            }) {
                Text("Sign In")
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
            }
            .buttonStyle(.plain)

            HStack(spacing: 6) {
                Text("Don’t have an account?")
                    .foregroundColor(Color(red: 0.51, green: 0.55, blue: 0.67))

                Button("Sign Up") {
                    print("Sign Up tapped")
                }
                .foregroundColor(Color(red: 0.25, green: 0.56, blue: 0.97))
            }
            .font(.system(size: 15, weight: .semibold, design: .rounded))
        }
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

#Preview {
    NavigationStack {
        AuthView()
    }
}
