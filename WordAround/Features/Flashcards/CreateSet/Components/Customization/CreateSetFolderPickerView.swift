import SwiftUI

struct CreateSetFolderPickerView: View {
    let theme: CreateSetTheme
    let folders: [Folder]
    let selectedFolderName: String?
    let isLoading: Bool
    let onSelectFolder: (Folder?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.isPadLike ? 12 : 10) {
            Text("Choose folder")
                .font(.system(size: Layout.isPadLike ? 18 : 16, weight: .bold, design: .rounded))
                .foregroundColor(theme.titleColor)

            Menu {
                Button {
                    onSelectFolder(nil)
                } label: {
                    Label("No folder", systemImage: "folder")
                }

                ForEach(folders) { folder in
                    Button {
                        onSelectFolder(folder)
                    } label: {
                        Label(folder.title, systemImage: "folder.fill")
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: Layout.isPadLike ? 22 : 19, weight: .semibold))
                        .foregroundColor(theme.mutedTextColor)

                    Text(selectedFolderName ?? "No folder")
                        .font(.system(size: Layout.isPadLike ? 18 : 16, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.mutedTextColor)

                    Spacer()

                    trailingIcon
                }
                .padding(.horizontal, Layout.isPadLike ? 18 : 14)
                .frame(height: Layout.isPadLike ? 64 : 56)
                .background(theme.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: Layout.isPadLike ? 20 : 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Layout.isPadLike ? 20 : 16, style: .continuous)
                        .stroke(theme.softBorderColor, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
    }

    @ViewBuilder
    private var trailingIcon: some View {
        if isLoading {
            ProgressView()
                .scaleEffect(0.8)
        } else {
            Image(systemName: "chevron.down")
                .font(.system(size: Layout.isPadLike ? 17 : 15, weight: .bold))
                .foregroundColor(theme.mutedTextColor)
        }
    }
}

#Preview {
    CreateSetFolderPickerView(
        theme: .blue,
        folders: [],
        selectedFolderName: nil,
        isLoading: false,
        onSelectFolder: { _ in }
    )
    .padding()
    .background(CreateSetTheme.blue.screenBackground)
}
