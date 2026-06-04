import SwiftUI

struct DeleteAccountConfirmationSheet: View {
    @ObservedObject var viewModel: ProfileViewModel
    let onCancel: () -> Void
    let onDeleted: () -> Void

    @State private var confirmationText: String = ""
    @State private var isDeleting = false

    private let requiredText = "DELETE"

    private var matches: Bool {
        confirmationText.trimmingCharacters(in: .whitespaces).uppercased() == requiredText
    }

    var body: some View {
        ZStack {
            AppColors.appBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                header
                warningCard
                inputField

                if let error = viewModel.errorMessage {
                    errorRow(error)
                }

                Spacer(minLength: 0)

                actions
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 24)
        }
        .interactiveDismissDisabled(isDeleting)
        .presentationDetents([.medium, .large])
    }

    // MARK: - Components

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(red: 1.00, green: 0.92, blue: 0.91))
                    .frame(width: 72, height: 72)
                Image(systemName: "trash.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Color(red: 0.85, green: 0.30, blue: 0.30))
            }

            Text(L10n.localized(.deleteAccountTitle))
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .multilineTextAlignment(.center)
        }
    }

    private var warningCard: some View {
        Text(L10n.localized(.deleteAccountSecondMessage))
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(AppColors.textSecondary)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 1.00, green: 0.95, blue: 0.94))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(red: 0.95, green: 0.78, blue: 0.78).opacity(0.50), lineWidth: 1)
            )
    }

    private var inputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.localized(.deleteAccountConfirmField))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textSecondary)
                .padding(.horizontal, 4)

            TextField(
                L10n.localized(.deleteAccountConfirmFieldPlaceholder),
                text: $confirmationText
            )
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(AppColors.primaryBlueDark)
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        matches
                            ? Color(red: 0.85, green: 0.30, blue: 0.30).opacity(0.5)
                            : AppColors.primaryBlue.opacity(0.10),
                        lineWidth: 1
                    )
            )
        }
    }

    private func errorRow(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color(red: 0.85, green: 0.30, blue: 0.30))

            Text(message)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.primaryBlueDark)
                .lineLimit(4)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 1.00, green: 0.95, blue: 0.94))
        )
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    isDeleting = true
                    let success = await viewModel.deleteAccount()
                    isDeleting = false
                    if success { onDeleted() }
                }
            } label: {
                ZStack {
                    Text(L10n.localized(.deleteAccountConfirmButton))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .opacity(isDeleting ? 0 : 1)

                    if isDeleting {
                        ProgressView()
                            .tint(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Color(red: 0.85, green: 0.30, blue: 0.30)
                        .opacity(matches ? 1.0 : 0.40)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!matches || isDeleting)

            Button(action: onCancel) {
                Text(L10n.localized(.commonCancel))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.primaryBlue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .buttonStyle(.plain)
            .disabled(isDeleting)
        }
    }
}
