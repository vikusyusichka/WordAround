import SwiftUI

struct HomeHeaderView: View {
    let title: String
    let subtitle: String

    /// Optional Notes shortcut shown to the left of the profile avatar. On
    /// compact layouts the sidebar (and its Notes entry) is hidden, so Home
    /// surfaces Notes here. When `nil` the trailing area stays profile-only,
    /// preserving the current iPad / Mac header exactly.
    var onNotes: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: Layout.homeHeaderTitleSize, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.primaryBlueDark)

                Text(subtitle)
                    .font(.system(size: Layout.homeHeaderSubtitleSize, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.mutedText)
            }

            Spacer()

            HStack(spacing: Layout.homeHeaderActionSpacing) {
                if let onNotes {
                    notesButton(action: onNotes)
                        .transition(.scale.combined(with: .opacity))
                }

                profileAvatar
            }
        }
    }

    private var profileAvatar: some View {
        ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(AppColors.cardWhite)
                        .frame(
                            width: Layout.homeHeaderAvatarCircleSize,
                            height: Layout.homeHeaderAvatarCircleSize
                        )

                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: Layout.homeHeaderAvatarIconSize,
                            height: Layout.homeHeaderAvatarIconSize
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.70, green: 0.75, blue: 0.85),
                                    Color(red: 0.42, green: 0.48, blue: 0.60)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)

                Circle()
                    .fill(Color(red: 1.0, green: 0.29, blue: 0.24))
                    .frame(
                        width: Layout.homeHeaderNotificationDotSize,
                        height: Layout.homeHeaderNotificationDotSize
                    )
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    .offset(x: 1, y: 1)
            }
        }

    private func notesButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(AppColors.cardWhite)
                    .frame(
                        width: Layout.homeHeaderNotesButtonSize,
                        height: Layout.homeHeaderNotesButtonSize
                    )

                Image(systemName: HomeCategory.notes.icon)
                    .font(.system(size: Layout.homeHeaderNotesIconSize, weight: .semibold))
                    .foregroundColor(AppColors.notesAccent)
            }
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            .contentShape(Circle())
        }
        .buttonStyle(HomeHeaderActionPressStyle())
        .accessibilityLabel(L10n.string("categoryNotes"))
    }
}

private struct HomeHeaderActionPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    HomeHeaderView(title: "Flashcards", subtitle: "Pick a set to practice")
        .padding()
        .background(AppColors.appBackground)
}
