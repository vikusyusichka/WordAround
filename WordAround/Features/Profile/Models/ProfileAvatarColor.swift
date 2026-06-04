import SwiftUI

enum ProfileAvatarColor: String, CaseIterable, Identifiable, Codable {
    case blue
    case purple
    case pink
    case orange
    case green
    case cyan

    var id: String { rawValue }

    var fillColor: Color {
        switch self {
        case .blue:   return Color(red: 0.84, green: 0.88, blue: 1.00)
        case .purple: return Color(red: 0.91, green: 0.86, blue: 1.00)
        case .pink:   return Color(red: 1.00, green: 0.86, blue: 0.93)
        case .orange: return Color(red: 1.00, green: 0.89, blue: 0.78)
        case .green:  return Color(red: 0.85, green: 0.95, blue: 0.87)
        case .cyan:   return Color(red: 0.82, green: 0.94, blue: 0.97)
        }
    }

    var accentColor: Color {
        switch self {
        case .blue:   return Color(red: 0.17, green: 0.36, blue: 0.98)
        case .purple: return Color(red: 0.55, green: 0.30, blue: 0.92)
        case .pink:   return Color(red: 0.93, green: 0.30, blue: 0.62)
        case .orange: return Color(red: 0.95, green: 0.55, blue: 0.10)
        case .green:  return Color(red: 0.13, green: 0.65, blue: 0.34)
        case .cyan:   return Color(red: 0.10, green: 0.62, blue: 0.78)
        }
    }

    static let `default`: ProfileAvatarColor = .blue
}
