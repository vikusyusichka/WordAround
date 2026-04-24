import SwiftUI

struct FlashcardSet: Identifiable {
    let id = UUID()

    let title: String
    let subtitle: String
    let iconSystemName: String

    let currentValue: Int
    let totalValue: Int
    let unit: String
    let progress: Double

    let accentColor: Color
    let backgroundColor: Color
    let progressBackgroundColor: Color
    let titleColor: Color
    let valueColor: Color
    let subtitleColor: Color
    let iconBackground: Color
    let blobColor: Color
}
