import SwiftUI
import PhotosUI

/// Modal editor for the user's display name + avatar.
///
/// The sheet writes to a local draft on the VM (`draftDisplayName`,
/// `draftAvatarImage`) so Cancel is genuinely non-destructive. Save delegates
/// to `ProfileViewModel.saveProfile()`, which handles Auth + Firestore +
/// Storage and reports failures via `errorMessage` (kept inside the sheet so
/// users see what went wrong before dismissing).
struct EditProfileSheet: View {
    @ObservedObject var viewModel: ProfileViewModel
    let onDismiss: () -> Void

    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    avatarSection
                    nameSection

                    if let message = viewModel.errorMessage {
                        Text(message)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }

                    Spacer(minLength: 24)
                }
                .padding(24)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
            .background(AppColors.appBackground.ignoresSafeArea())
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelEditing()
                        onDismiss()
                    }
                    .foregroundColor(AppColors.primaryBlue)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            let success = await viewModel.saveProfile()
                            if success { onDismiss() }
                        }
                    }
                    .foregroundColor(AppColors.primaryBlue)
                    .disabled(!viewModel.hasUnsavedChanges || viewModel.isSaving)
                }
            }
            .overlay {
                if viewModel.isSaving {
                    ZStack {
                        Color.black.opacity(0.05).ignoresSafeArea()
                        ProgressView()
                            .tint(AppColors.primaryBlue)
                    }
                }
            }
            .onChange(of: pickerItem) { _, newItem in
                Task { await loadPickedImage(newItem) }
            }
        }
    }

    // MARK: - Sections

    private var avatarSection: some View {
        VStack(spacing: 14) {
            avatarPreview

            PhotosPicker(
                selection: $pickerItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Text(viewModel.draftAvatarImage == nil ? "Change photo" : "Choose another")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlue)
            }
        }
    }

    private var avatarPreview: some View {
        ZStack {
            Circle()
                .fill(AppColors.primaryBlue.opacity(0.12))
                .frame(width: 112, height: 112)

            if let image = viewModel.draftAvatarImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 112, height: 112)
                    .clipShape(Circle())
            } else if let url = viewModel.photoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        initialsLabel
                    }
                }
                .frame(width: 112, height: 112)
                .clipShape(Circle())
            } else {
                initialsLabel
            }
        }
        .overlay(
            Circle().stroke(Color.white, lineWidth: 4)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    }

    private var initialsLabel: some View {
        Text(viewModel.initials.isEmpty ? "?" : viewModel.initials)
            .font(.system(size: 38, weight: .bold, design: .rounded))
            .foregroundColor(AppColors.primaryBlue)
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Display name")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 4)

            TextField("Your name", text: $viewModel.draftDisplayName)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.primaryBlueDark)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppColors.primaryBlue.opacity(0.08), lineWidth: 1)
                )
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        }
    }

    // MARK: - Picker

    private func loadPickedImage(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { return }
            viewModel.draftAvatarImage = image
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }
}
