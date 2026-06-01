import SwiftUI

struct ListeningMetadataChip: View {
    let text: String
    var accent: Color = ListeningTheme.accent

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(accent)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(accent.opacity(0.12))
            .clipShape(Capsule())
    }
}
