import SwiftUI

struct StatCardItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let subtitle: String
    let iconSystemName: String
    let accentColor: Color
    let titleColor: Color
    let valueColor: Color
    let subtitleColor: Color
    let backgroundColor: Color
    let blobColor: Color
}
