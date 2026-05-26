import SwiftUI
import UIKit

enum AppColors {
    static let appBackground = Color(red: 0.965, green: 0.965, blue: 0.985)

    static let primaryBlue = Color(red: 0.17, green: 0.36, blue: 0.98)
    static let primaryBlueDark = Color(red: 0.13, green: 0.29, blue: 0.82)

    static let textSecondary = Color(red: 0.51, green: 0.55, blue: 0.67)
    static let mutedText = Color(red: 0.56, green: 0.60, blue: 0.72)

    static let cardWhite = Color.white.opacity(0.95)

    static let blobBlue = Color(red: 0.84, green: 0.88, blue: 0.98)
    static let blobYellow = Color(red: 0.95, green: 0.86, blue: 0.63)
    static let blobGreen = Color(red: 0.82, green: 0.89, blue: 0.85)
    static let blobPink = Color(red: 0.92, green: 0.82, blue: 0.87)

    static let goalBackground = Color(red: 0.95, green: 0.96, blue: 1.0)
    static let goalProgressBackground = Color(red: 0.85, green: 0.88, blue: 0.97)

    static let foodAccent = Color(red: 1.0, green: 0.45, blue: 0.46)
    static let foodBackground = Color(red: 1.0, green: 0.94, blue: 0.95)
    static let foodTitle = Color(red: 0.63, green: 0.11, blue: 0.21)

    static let orangeAccent = Color(red: 0.97, green: 0.64, blue: 0.06)
    static let orangeTitle = Color(red: 0.67, green: 0.39, blue: 0.02)

    static let greenAccent = Color(red: 0.16, green: 0.73, blue: 0.40)
    static let greenTitle = Color(red: 0.07, green: 0.55, blue: 0.28)
    
    static let createSetBackground = Color(red: 1.00, green: 0.98, blue: 0.99)

    static let createSetRed = Color(red: 1.00, green: 0.34, blue: 0.35)
    static let createSetDarkRed = Color(red: 0.55, green: 0.02, blue: 0.12)
    static let createSetSoftRed = Color(red: 1.00, green: 0.91, blue: 0.92)

    static let createSetTextMuted = Color(red: 0.48, green: 0.52, blue: 0.66)
    static let createSetDarkText = Color(red: 0.13, green: 0.22, blue: 0.28)

    static let createSetBorder = Color(red: 0.95, green: 0.88, blue: 0.90)
    static let createSetSoftBorder = Color(red: 1.00, green: 0.88, blue: 0.92)
    static let createSetBorderRed = Color(red: 1.00, green: 0.76, blue: 0.77)

    static let createSetPreviewBackground = Color(red: 1.00, green: 0.95, blue: 0.96)
    static let createSetImageBackground = Color(red: 1.00, green: 0.96, blue: 0.97)

    static let createSetBlue = Color(red: 0.55, green: 0.63, blue: 0.96)
    static let createSetYellow = Color(red: 1.00, green: 0.78, blue: 0.38)
    static let createSetGreen = Color(red: 0.55, green: 0.82, blue: 0.61)
    static let createSetPurple = Color(red: 0.73, green: 0.51, blue: 0.91)
    static let createSetCyan = Color(red: 0.42, green: 0.79, blue: 0.85)

    static let createSetShadow = Color.black.opacity(0.06)
}

extension Color {
    func toHex() -> String? {
        let uiColor = UIColor(self)

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }

        return String(
            format: "#%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
    }
}

extension AppColors {
    static let flashcardDetailTitle = Color(red: 0.08, green: 0.20, blue: 0.72)
    static let flashcardDetailText = Color(red: 0.42, green: 0.46, blue: 0.62)
    static let flashcardDetailMutedText = Color(red: 0.52, green: 0.56, blue: 0.70)

    static let flashcardDetailCardBackground = Color(red: 0.95, green: 0.96, blue: 1.00)
    static let flashcardDetailSoftBlue = Color(red: 0.86, green: 0.89, blue: 1.00)
    static let flashcardDetailDivider = Color(red: 0.88, green: 0.90, blue: 0.96)

    static let flashcardDetailShadow = Color.black.opacity(0.055)
}
