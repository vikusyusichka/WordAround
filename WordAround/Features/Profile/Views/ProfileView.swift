import SwiftUI

/// Account screen. Composes four cards inside a single vertical scroll:
/// Profile, Learning summary, Settings, Account actions.
///
/// Lives inside HomeView's main content area, so the surrounding header /
/// bottom bar / sidebar are still owned by HomeView. Only `signOut` has app-
/// level side effects, and it works because `SessionStore` listens to the
/// Firebase auth-state listener and routes back to the auth flow on its own.
struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var isEditing = false
    @State private var isConfirmingSignOut = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: Layout.profileSectionSpacing) {
                profileCard

                if viewModel.hasAnySummaryStat {
                    summaryCard
                }

                settingsCard
                accountActionsCard
            }
            .frame(maxWidth: Layout.profileContentMaxWidth)
            .frame(maxWidth: .infinity)
            .padding(.bottom, Layout.homeScrollBottomPadding)
        }
        .task { await viewModel.loadProfile() }
        .sheet(isPresented: $isEditing) {
            EditProfileSheet(viewModel: viewModel) {
                isEditing = false
            }
        }
        .confirmationDialog(
            "Sign out of WordAround?",
            isPresented: $isConfirmingSignOut,
            titleVisibility: .visible
        ) {
            Button("Sign out", role: .destructive) {
                viewModel.signOut()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Profile card

private extension ProfileView {
    var profileCard: some View {
        VStack(spacing: 18) {
            avatar
            nameAndEmail
            editButton
        }
        .padding(Layout.profileCardPadding)
        .frame(maxWidth: .infinity)
        .background(cardBackground)
    }

    var avatar: some View {
        ZStack {
            Circle()
                .fill(AppColors.primaryBlue.opacity(0.12))
                .frame(width: Layout.profileAvatarSize, height: Layout.profileAvatarSize)

            if let url = viewModel.photoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        initialsLabel
                    }
                }
                .frame(width: Layout.profileAvatarSize, height: Layout.profileAvatarSize)
                .clipShape(Circle())
            } else {
                initialsLabel
            }
        }
        .overlay(
            Circle().stroke(Color.white, lineWidth: 4)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 6)
    }

    var initialsLabel: some View {
        // Falls back to a person icon when the user has no name or email yet.
        Group {
            if viewModel.initials.isEmpty {
                Image(systemName: "person.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(AppColors.primaryBlue)
            } else {
                Text(viewModel.initials)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlue)
            }
        }
    }

    var nameAndEmail: some View {
        VStack(spacing: 4) {
            if viewModel.hasDisplayName {
                Text(viewModel.displayName)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)
            } else {
                Text("Add your name")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlue.opacity(0.55))
            }

            Text(viewModel.email)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    var editButton: some View {
        Button {
            viewModel.beginEditing()
            isEditing = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .bold))
                Text("Edit Profile")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 22)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppColors.primaryBlue)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Summary card

private extension ProfileView {
    var summaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Learning summary")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                if viewModel.totalWordsWritten > 0 {
                    summaryTile(
                        value: "\(viewModel.totalWordsWritten)",
                        label: "words written"
                    )
                }
                if viewModel.totalPracticeMinutes > 0 {
                    summaryTile(
                        value: "\(viewModel.totalPracticeMinutes)",
                        label: "minutes practiced"
                    )
                }
                if let joined = viewModel.joinedDate {
                    summaryTile(
                        value: Self.joinedDateFormatter.string(from: joined),
                        label: "joined"
                    )
                }
            }
        }
        .padding(Layout.profileCardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackground)
    }

    /// One tile in the 2×2 summary grid. Numbers are blue, labels are muted.
    func summaryTile(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.primaryBlue)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.primaryBlue.opacity(0.06))
        )
    }

    static let joinedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

// MARK: - Settings card

private extension ProfileView {
    var settingsCard: some View {
        VStack(spacing: 0) {
            settingsRow(icon: "globe", title: "App Language")
            divider
            settingsRow(icon: "paintbrush", title: "Appearance")
            divider
            settingsRow(icon: "bell", title: "Notifications")
            divider
            settingsRow(icon: "hand.raised", title: "Privacy Policy")
            divider
            settingsRow(icon: "doc.text", title: "Terms of Use")
        }
        .padding(.vertical, 6)
        .background(cardBackground)
    }

    /// Disabled placeholder rows — the app doesn't have a settings architecture
    /// yet, so we render the structure without faking destinations. The rule:
    /// when settings exist, wire them up here; until then, rows stay inert.
    func settingsRow(icon: String, title: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppColors.primaryBlue.opacity(0.10))
                    .frame(width: 34, height: 34)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.primaryBlue)
            }

            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark.opacity(0.55))

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.textSecondary.opacity(0.6))
        }
        .padding(.horizontal, Layout.profileCardPadding)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    var divider: some View {
        Rectangle()
            .fill(AppColors.primaryBlue.opacity(0.06))
            .frame(height: 1)
            .padding(.leading, Layout.profileCardPadding + 48)
    }
}

// MARK: - Account actions card

private extension ProfileView {
    var accountActionsCard: some View {
        Button {
            isConfirmingSignOut = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.red.opacity(0.12))
                        .frame(width: 34, height: 34)

                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.red)
                }

                Text("Sign Out")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.red)

                Spacer()
            }
            .padding(Layout.profileCardPadding)
            .background(cardBackground)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared chrome

private extension ProfileView {
    var cardBackground: some View {
        RoundedRectangle(cornerRadius: Layout.profileCardCornerRadius, style: .continuous)
            .fill(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.profileCardCornerRadius, style: .continuous)
                    .stroke(AppColors.primaryBlue.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}

#Preview {
    ZStack {
        AppColors.appBackground.ignoresSafeArea()
        ProfileView()
            .padding()
    }
}
