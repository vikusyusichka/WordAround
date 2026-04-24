import SwiftUI

enum Layout {
    static var isPadLike: Bool {
        UIDevice.current.userInterfaceIdiom == .pad ||
        UIScreen.main.bounds.width >= 700
    }

    static var isCompactPhone: Bool {
        !isPadLike && UIScreen.main.bounds.width < 390
    }

    static let screenHorizontalPaddingPhone: CGFloat = 16
    static let screenHorizontalPaddingPad: CGFloat = 28

    static let topPaddingPhone: CGFloat = 12
    static let topPaddingPad: CGFloat = 20

    static let sectionSpacingPhone: CGFloat = 16
    static let sectionSpacingPad: CGFloat = 22

    static let cardCornerRadius: CGFloat = 22
    static let smallCardCornerRadius: CGFloat = 18

    static let cardInnerPadding: CGFloat = 16
    static let compactCardInnerPadding: CGFloat = 14

    static let sidebarWidthPhone: CGFloat = 86
    static let sidebarWidthCompact: CGFloat = 74
    static let sidebarWidthPad: CGFloat = 108

    static let contentMaxWidthPad: CGFloat = 760
}
