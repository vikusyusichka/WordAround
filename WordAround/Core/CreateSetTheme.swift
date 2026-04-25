import SwiftUI

struct CreateSetTheme {
    let accent: Color
    let screenBackground: Color
    let sectionBackground: Color
    let fieldBackground: Color
    let previewBackground: Color
    let imageBackground: Color

    let titleColor: Color
    let textColor: Color
    let mutedTextColor: Color

    let borderColor: Color
    let softBorderColor: Color
    let softAccent: Color
    let shadowColor: Color
}

extension CreateSetTheme {
    static let red = CreateSetTheme(
        accent: AppColors.createSetRed,
        screenBackground: Color(red: 1.00, green: 0.96, blue: 0.96),
        sectionBackground: Color.white.opacity(0.74),
        fieldBackground: Color.white,
        previewBackground: Color(red: 1.00, green: 0.94, blue: 0.94),
        imageBackground: Color(red: 1.00, green: 0.95, blue: 0.96),
        titleColor: Color(red: 0.58, green: 0.02, blue: 0.12),
        textColor: AppColors.createSetDarkText,
        mutedTextColor: AppColors.createSetTextMuted,
        borderColor: Color(red: 0.98, green: 0.78, blue: 0.82),
        softBorderColor: Color(red: 0.98, green: 0.82, blue: 0.86),
        softAccent: AppColors.createSetRed.opacity(0.14),
        shadowColor: AppColors.createSetRed.opacity(0.18)
    )

    static let blue = CreateSetTheme(
        accent: AppColors.createSetBlue,
        screenBackground: Color(red: 0.94, green: 0.97, blue: 1.00),
        sectionBackground: Color.white.opacity(0.78),
        fieldBackground: Color.white,
        previewBackground: Color(red: 0.93, green: 0.96, blue: 1.00),
        imageBackground: Color(red: 0.95, green: 0.97, blue: 1.00),
        titleColor: Color(red: 0.10, green: 0.24, blue: 0.76),
        textColor: AppColors.createSetDarkText,
        mutedTextColor: AppColors.createSetTextMuted,
        borderColor: AppColors.createSetBlue.opacity(0.35),
        softBorderColor: AppColors.createSetBlue.opacity(0.24),
        softAccent: AppColors.createSetBlue.opacity(0.16),
        shadowColor: AppColors.createSetBlue.opacity(0.18)
    )

    static let yellow = CreateSetTheme(
        accent: AppColors.createSetYellow,
        screenBackground: Color(red: 1.00, green: 0.98, blue: 0.92),
        sectionBackground: Color.white.opacity(0.78),
        fieldBackground: Color.white,
        previewBackground: Color(red: 1.00, green: 0.96, blue: 0.86),
        imageBackground: Color(red: 1.00, green: 0.97, blue: 0.89),
        titleColor: Color(red: 0.62, green: 0.38, blue: 0.02),
        textColor: AppColors.createSetDarkText,
        mutedTextColor: AppColors.createSetTextMuted,
        borderColor: AppColors.createSetYellow.opacity(0.42),
        softBorderColor: AppColors.createSetYellow.opacity(0.28),
        softAccent: AppColors.createSetYellow.opacity(0.20),
        shadowColor: AppColors.createSetYellow.opacity(0.20)
    )

    static let green = CreateSetTheme(
        accent: AppColors.createSetGreen,
        screenBackground: Color(red: 0.94, green: 0.99, blue: 0.96),
        sectionBackground: Color.white.opacity(0.78),
        fieldBackground: Color.white,
        previewBackground: Color(red: 0.92, green: 0.98, blue: 0.95),
        imageBackground: Color(red: 0.94, green: 0.99, blue: 0.96),
        titleColor: Color(red: 0.10, green: 0.48, blue: 0.30),
        textColor: AppColors.createSetDarkText,
        mutedTextColor: AppColors.createSetTextMuted,
        borderColor: AppColors.createSetGreen.opacity(0.38),
        softBorderColor: AppColors.createSetGreen.opacity(0.26),
        softAccent: AppColors.createSetGreen.opacity(0.18),
        shadowColor: AppColors.createSetGreen.opacity(0.18)
    )

    static let purple = CreateSetTheme(
        accent: AppColors.createSetPurple,
        screenBackground: Color(red: 0.97, green: 0.95, blue: 1.00),
        sectionBackground: Color.white.opacity(0.78),
        fieldBackground: Color.white,
        previewBackground: Color(red: 0.96, green: 0.93, blue: 1.00),
        imageBackground: Color(red: 0.97, green: 0.95, blue: 1.00),
        titleColor: Color(red: 0.42, green: 0.20, blue: 0.72),
        textColor: AppColors.createSetDarkText,
        mutedTextColor: AppColors.createSetTextMuted,
        borderColor: AppColors.createSetPurple.opacity(0.38),
        softBorderColor: AppColors.createSetPurple.opacity(0.26),
        softAccent: AppColors.createSetPurple.opacity(0.18),
        shadowColor: AppColors.createSetPurple.opacity(0.18)
    )

    static let cyan = CreateSetTheme(
        accent: AppColors.createSetCyan,
        screenBackground: Color(red: 0.93, green: 0.99, blue: 1.00),
        sectionBackground: Color.white.opacity(0.78),
        fieldBackground: Color.white,
        previewBackground: Color(red: 0.91, green: 0.98, blue: 1.00),
        imageBackground: Color(red: 0.94, green: 0.99, blue: 1.00),
        titleColor: Color(red: 0.08, green: 0.44, blue: 0.56),
        textColor: AppColors.createSetDarkText,
        mutedTextColor: AppColors.createSetTextMuted,
        borderColor: AppColors.createSetCyan.opacity(0.38),
        softBorderColor: AppColors.createSetCyan.opacity(0.26),
        softAccent: AppColors.createSetCyan.opacity(0.18),
        shadowColor: AppColors.createSetCyan.opacity(0.18)
    )

    static func theme(for color: SetColor) -> CreateSetTheme {
        switch color {
        case .red:
            return .red
        case .blue:
            return .blue
        case .yellow:
            return .yellow
        case .green:
            return .green
        case .purple:
            return .purple
        case .cyan:
            return .cyan
        }
    }

    static func theme(forHex hex: String) -> CreateSetTheme {
        let normalized = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        switch normalized {
        case SetColor.red.hex.uppercased():
            return .red
        case SetColor.blue.hex.uppercased():
            return .blue
        case SetColor.yellow.hex.uppercased():
            return .yellow
        case SetColor.green.hex.uppercased():
            return .green
        case SetColor.purple.hex.uppercased():
            return .purple
        case SetColor.cyan.hex.uppercased():
            return .cyan
        default:
            return .red
        }
    }
}
