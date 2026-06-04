import SwiftUI
import PhotosUI

struct EditProfileSheet: View {
    @ObservedObject var viewModel: ProfileViewModel
    let onDismiss: () -> Void

    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        avatarSection
                        colorPicker
                        nameSection

                        if let message = viewModel.errorMessage {
                            Text(message)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
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
            }
            .navigationTitle(L10n.localized(.editProfileTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.localized(.commonCancel)) {
                        viewModel.cancelEditing()
                        onDismiss()
                    }
                    .foregroundColor(AppColors.primaryBlue)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.localized(.commonSave)) {
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
                Text(viewModel.draftAvatarImage == nil
                     ? L10n.localized(.editProfileChangePhoto)
                     : L10n.localized(.editProfileChooseAnother))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlue)
            }
        }
    }

    private var avatarPreview: some View {
        ZStack {
            Circle()
                .fill(viewModel.draftAvatarColor.fillColor)
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
        .animation(.easeInOut(duration: 0.2), value: viewModel.draftAvatarColor)
    }

    private var initialsLabel: some View {
        Text(viewModel.initials.isEmpty ? "?" : viewModel.initials)
            .font(.system(size: 38, weight: .bold, design: .rounded))
            .foregroundColor(viewModel.draftAvatarColor.accentColor)
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.localized(.editProfileAvatarColorLabel))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 4)

            HStack(spacing: 14) {
                ForEach(ProfileAvatarColor.allCases) { color in
                    colorSwatch(color)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func colorSwatch(_ color: ProfileAvatarColor) -> some View {
        let isSelected = viewModel.draftAvatarColor == color

        return Button {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                viewModel.draftAvatarColor = color
            }
        } label: {
            ZStack {
                Circle()
                    .fill(color.fillColor)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(color.accentColor.opacity(0.35), lineWidth: 1)
                    )

                if isSelected {
                    Circle()
                        .stroke(color.accentColor, lineWidth: 3)
                        .frame(width: 46, height: 46)
                }
            }
            .frame(width: 46, height: 46)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(color.rawValue.capitalized)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.localized(.editProfileNameLabel))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 4)

            TextField(L10n.localized(.editProfileNamePlaceholder), text: $viewModel.draftDisplayName)
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
