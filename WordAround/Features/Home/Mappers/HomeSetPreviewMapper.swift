import SwiftUI

enum HomeSetPreviewMapper {
    static func map(_ set: FlashcardSet) -> HomeSetPreviewItem {
        let accentColor = Color(hex: set.colorHex) ?? AppColors.primaryBlue

        return HomeSetPreviewItem(
            sourceSet: set,
            title: set.title,
            subtitle: "\(set.cards.count) words",
            iconSystemName: iconName(from: set.icon),
            currentValue: set.cards.count,
            totalValue: max(set.cards.count, 1),
            unit: "words",
            progress: 1.0,
            accentColor: accentColor,
            backgroundColor: accentColor.opacity(0.12),
            progressBackgroundColor: accentColor.opacity(0.22),
            titleColor: accentColor,
            valueColor: accentColor,
            subtitleColor: AppColors.textSecondary,
            iconBackground: accentColor,
            blobColor: accentColor.opacity(0.25)
        )
    }

    private static func iconName(from icon: SetIconType) -> String {
        switch icon {
        case .systemName(let name):
            return name
        case .emoji:
            return "sparkles"
        case .customImageURL:
            return "photo.fill"
        }
    }
}

extension Color {
    init?(hex: String) {
        let cleanedHex = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        guard cleanedHex.count == 6,
              let rgbValue = UInt64(cleanedHex, radix: 16) else {
            return nil
        }

        let red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue = Double(rgbValue & 0x0000FF) / 255.0

        self = Color(red: red, green: green, blue: blue)
    }
}
