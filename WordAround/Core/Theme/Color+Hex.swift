import SwiftUI

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
