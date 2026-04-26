import SwiftUI

struct CreateFolderView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CreateFolderViewModel()

    var body: some View {
        ZStack {
            viewModel.theme.screenBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    formCard
                    previewCard
                    createButton
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 36)
            }
        }
        .tint(viewModel.theme.accent)
        .onChange(of: viewModel.didCreateFolder) { created in
            if created {
                dismiss()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(viewModel.theme.accent)
                        .frame(width: 38, height: 38)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: viewModel.theme.shadowColor, radius: 10, x: 0, y: 6)
                }

                Text("Create Folder")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(viewModel.theme.titleColor)

                Text("Organize your flashcard sets")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(viewModel.theme.mutedTextColor)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 70, height: 70)
                    .shadow(color: viewModel.theme.shadowColor, radius: 16, x: 0, y: 8)

                Image(systemName: "folder.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(viewModel.theme.accent)
            }
            .padding(.top, 58)
        }
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            fieldTitle("Folder name")

            TextField("e.g. Languages", text: $viewModel.title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(viewModel.theme.titleColor)
                .tint(viewModel.theme.accent)
                .padding(.horizontal, 16)
                .frame(height: 54)
                .background(viewModel.theme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(viewModel.theme.softBorderColor, lineWidth: 1)
                )

            HStack(spacing: 4) {
                fieldTitle("Description")

                Text("(optional)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(viewModel.theme.mutedTextColor)
            }

            ZStack(alignment: .bottomTrailing) {
                TextEditor(text: $viewModel.description)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(viewModel.theme.titleColor)
                    .tint(viewModel.theme.accent)
                    .padding(12)
                    .frame(height: 120)
                    .scrollContentBackground(.hidden)
                    .background(viewModel.theme.fieldBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(viewModel.theme.softBorderColor, lineWidth: 1)
                    )

                Text("\(viewModel.description.count)/120")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(viewModel.theme.mutedTextColor)
                    .padding(.trailing, 12)
                    .padding(.bottom, 10)
            }

            fieldTitle("Choose color")

            HStack(spacing: 18) {
                ForEach(viewModel.availableColors) { color in
                    Button {
                        viewModel.selectColor(color)
                    } label: {
                        Circle()
                            .fill(color.color)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(
                                        viewModel.selectedColor == color ? viewModel.theme.accent : Color.clear,
                                        lineWidth: 4
                                    )
                                    .padding(-6)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.red)
                    .padding(.top, 2)
            }
        }
        .padding(18)
        .background(viewModel.theme.sectionBackground)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: viewModel.theme.shadowColor, radius: 18, x: 0, y: 10)
    }

    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Preview")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(viewModel.theme.mutedTextColor)
                .frame(maxWidth: .infinity, alignment: .center)

            FolderCardView(
                title: viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "New Folder" : viewModel.title,
                setsCount: 0,
                colorHex: viewModel.selectedColor.hex
            )
        }
    }

    private var createButton: some View {
        Button {
            Task {
                await viewModel.createFolder()
            }
        } label: {
            HStack {
                Spacer()

                if viewModel.isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Create Folder")
                        .font(.system(size: 16, weight: .bold, design: .rounded))

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 22)
            .frame(height: 56)
            .background(viewModel.theme.accent)
            .clipShape(Capsule())
            .shadow(color: viewModel.theme.shadowColor, radius: 16, x: 0, y: 8)
        }
        .disabled(viewModel.isSaving)
        .buttonStyle(.plain)
    }

    private func fieldTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundColor(viewModel.theme.titleColor)
    }
}

#Preview {
    CreateFolderView()
}
