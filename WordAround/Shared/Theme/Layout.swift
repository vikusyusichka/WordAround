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

// MARK: - Shared Create Set Layout

extension Layout {
    static var createSetSectionPadding: CGFloat { isPadLike ? 22 : 14 }
    static var createSetSectionCornerRadius: CGFloat { isPadLike ? 26 : 22 }
    static var createSetSectionLabelSize: CGFloat { isPadLike ? 16 : 13 }
    static var createSetOptionalTextSize: CGFloat { isPadLike ? 13 : 11 }
    static var createSetSmallVerticalSpacing: CGFloat { 8 }
}

// MARK: - Create Set Header

extension Layout {
    static var createSetHeaderSpacing: CGFloat { isPadLike ? 20 : 16 }
    static var createSetBackButtonSize: CGFloat { isPadLike ? 56 : 42 }
    static var createSetBackButtonIconSize: CGFloat { isPadLike ? 22 : 16 }
    static var createSetChooseIconTextSize: CGFloat { isPadLike ? 16 : 13 }
    static var createSetHeaderIconCircleSize: CGFloat { isPadLike ? 74 : 48 }
    static var createSetHeaderIconSize: CGFloat { isPadLike ? 30 : 21 }
    static var createSetHeaderContentSpacing: CGFloat { 10 }
    static var createSetHeaderTitleStackSpacing: CGFloat { isPadLike ? 8 : 4 }
    static var createSetHeaderTitleSize: CGFloat { isPadLike ? 38 : 26 }
    static var createSetHeaderSubtitleSize: CGFloat { isPadLike ? 20 : 13 }
    static var createSetPrivacySpacing: CGFloat { isPadLike ? 8 : 4 }
    static var createSetPrivacyInnerSpacing: CGFloat { isPadLike ? 7 : 4 }
    static var createSetPrivacyLabelSize: CGFloat { 15 }
    static var createSetPrivacyIconSize: CGFloat { isPadLike ? 14 : 10 }
    static var createSetPrivacyTextSize: CGFloat { isPadLike ? 14 : 10 }
    static var createSetPrivacyHorizontalPadding: CGFloat { isPadLike ? 14 : 7 }
    static var createSetPrivacyButtonHeight: CGFloat { isPadLike ? 42 : 30 }
    static var createSetPrivacyCornerRadius: CGFloat { isPadLike ? 13 : 10 }
}

// MARK: - Create Set Preview Card

extension Layout {
    static var createSetPreviewSectionSpacing: CGFloat { 10 }
    static var createSetPreviewCardSpacing: CGFloat { isPadLike ? 18 : 12 }
    static var createSetPreviewTitleStackSpacing: CGFloat { 6 }
    static var createSetPreviewTitleSize: CGFloat { isPadLike ? 24 : 18 }
    static var createSetPreviewSubtitleSize: CGFloat { isPadLike ? 17 : 14 }
    static var createSetPreviewPadding: CGFloat { isPadLike ? 16 : 12 }
    static var createSetPreviewCornerRadius: CGFloat { 24 }
    static var createSetPreviewIconCircleSize: CGFloat { isPadLike ? 76 : 52 }
    static var createSetPreviewIconSize: CGFloat { isPadLike ? 32 : 22 }
}

// MARK: - Create Set Cards Section

extension Layout {
    static var createSetCardsSectionSpacing: CGFloat { isPadLike ? 18 : 14 }
    static var createSetCardsSectionPadding: CGFloat { isPadLike ? 22 : 14 }
    static var createSetCardsTitleSize: CGFloat { isPadLike ? 16 : 14 }
    static var createSetCardsEditorPadSpacing: CGFloat { 24 }
    static var createSetCardsEditorPhoneSpacing: CGFloat { 14 }
    static var createSetCardsInputStackSpacing: CGFloat { isPadLike ? 16 : 12 }
    static var createSetCardsPhoneInputImageSpacing: CGFloat { 10 }
    static var createSetCardsImagePhoneWidth: CGFloat { 116 }
    static var createSetCardsFieldSpacing: CGFloat { 8 }
    static var createSetCardsMicIconSize: CGFloat { isPadLike ? 18 : 15 }
    static var createSetCardsFieldFontSize: CGFloat { isPadLike ? 16 : 14 }
    static var createSetCardsFieldHorizontalPadding: CGFloat { isPadLike ? 18 : 14 }
    static var createSetCardsFieldHeight: CGFloat { isPadLike ? 54 : 48 }
    static var createSetCardsFieldCornerRadius: CGFloat { isPadLike ? 18 : 16 }
    static var createSetCardsExampleMinHeight: CGFloat { isPadLike ? 84 : 76 }
    static var createSetCardsCounterSize: CGFloat { isPadLike ? 14 : 12 }
    static var createSetCardsImageContentSpacing: CGFloat { isPadLike ? 12 : 6 }
    static var createSetCardsImageMaxWidth: CGFloat { isPadLike ? 220 : .infinity }
    static var createSetCardsImageMinHeight: CGFloat { isPadLike ? 220 : 126 }
    static var createSetCardsImageIconSize: CGFloat { isPadLike ? 42 : 24 }
    static var createSetCardsImageTitleSize: CGFloat { isPadLike ? 17 : 12 }
    static var createSetCardsImageSubtitleSize: CGFloat { isPadLike ? 14 : 10 }
    static var createSetCardsImageLineLimit: Int { isPadLike ? 2 : 1 }
    static var createSetCardsImageCornerRadius: CGFloat { isPadLike ? 20 : 16 }
    static var createSetAddCardIconSize: CGFloat { isPadLike ? 22 : 18 }
    static var createSetAddCardIconFrame: CGFloat { isPadLike ? 48 : 38 }
    static var createSetAddCardTextSize: CGFloat { isPadLike ? 17 : 15 }
    static var createSetCardsSectionCornerRadius: CGFloat { isPadLike ? 26 : 22 }
    static var createSetCardsOptionalTextSize: CGFloat { isPadLike ? 13 : 11 }
}

// MARK: - Create Set Info Section

extension Layout {
    static var createSetInfoSectionSpacing: CGFloat { isPadLike ? 20 : 14 }
    static var createSetTitleFieldHeight: CGFloat { isPadLike ? 56 : 48 }
    static var createSetTitleFieldFontSize: CGFloat { isPadLike ? 16 : 14 }
    static var createSetDescriptionPlaceholderFontSize: CGFloat { isPadLike ? 16 : 14 }
    static var createSetDescriptionMinHeight: CGFloat { isPadLike ? 118 : 96 }
    static var createSetDescriptionCounterSize: CGFloat { isPadLike ? 14 : 12 }
}

// MARK: - Create Set Customization Section

extension Layout {
    static var createSetCustomizationSectionSpacing: CGFloat { isPadLike ? 22 : 16 }
    static var createSetFolderTextSize: CGFloat { isPadLike ? 16 : 14 }
    static var createSetFolderHeight: CGFloat { isPadLike ? 50 : 46 }
    static var createSetFolderCornerRadius: CGFloat { 16 }
    static var createSetColorPickerSpacing: CGFloat { 12 }
    static var createSetColorCircleSize: CGFloat { isPadLike ? 36 : 28 }
    static var createSetSelectedColorStrokeWidth: CGFloat { isPadLike ? 4 : 3 }
    static var createSetSelectedColorOuterCircleSize: CGFloat { isPadLike ? 44 : 34 }
    static var createSetColorPickerHorizontalPadding: CGFloat { isPadLike ? 20 : 8 }
}

// MARK: - Home Shared

extension Layout {
    static var homeSidebarWidth: CGFloat { isPadLike ? sidebarWidthPad : (isCompactPhone ? sidebarWidthCompact : sidebarWidthPhone) }
    static var homeHorizontalPadding: CGFloat { isPadLike ? screenHorizontalPaddingPad : screenHorizontalPaddingPhone }
    static var homeTopSpacing: CGFloat { isPadLike ? topPaddingPad : topPaddingPhone }
    static var homeContentSpacing: CGFloat { isPadLike ? 16 : 12 }
    static var homeHeaderSidebarSpacing: CGFloat { isPadLike ? 14 : 8 }
    static var homeBottomBarHorizontalPadding: CGFloat { isPadLike ? 28 : 14 }
    static var homeBottomBarBottomPadding: CGFloat { isPadLike ? 20 : 10 }
    static var homeBottomSafeSpacing: CGFloat { isPadLike ? 132 : 118 }
    static var homeScrollBottomPadding: CGFloat { isPadLike ? 18 : 8 }
    static var homeStatCardSpacing: CGFloat { isPadLike ? 14 : 8 }
    static var homeSetsListSpacing: CGFloat { isPadLike ? 14 : 10 }
    static var homeSectionTitleSize: CGFloat { isPadLike ? 34 : 22 }
    static var homeSectionTitleTopPadding: CGFloat { isPadLike ? 20 : 13 }
    static var homeSectionActionSize: CGFloat { isPadLike ? 18 : 14 }
    static var homeErrorTextSize: CGFloat { isPadLike ? 15 : 13 }
    static var homePlaceholderTitleSize: CGFloat { isPadLike ? 34 : 24 }
    static var homePlaceholderSubtitleSize: CGFloat { isPadLike ? 18 : 15 }
    static var homePlaceholderPadding: CGFloat { isPadLike ? 24 : 18 }
    static var homePlaceholderHeight: CGFloat { isPadLike ? 220 : 160 }
    static var homeEmptySetTitleSize: CGFloat { isPadLike ? 30 : 22 }
    static var homeEmptySetHeight: CGFloat { isPadLike ? 180 : 140 }
}

// MARK: - Home Create Menu

extension Layout {
    static var homeCreateMenuFrameHeight: CGFloat { isPadLike ? 300 : 235 }
    static var homeCreateMenuBottomPadding: CGFloat { isPadLike ? 58 : 48 }
    static var homeCreateMenuItemSpacing: CGFloat { isPadLike ? 10 : 7 }
    static var homeCreateMenuCircleSize: CGFloat { isPadLike ? 78 : 58 }
    static var homeCreateMenuShadowRadius: CGFloat { isPadLike ? 16 : 12 }
    static var homeCreateMenuShadowY: CGFloat { isPadLike ? 9 : 7 }
    static var homeCreateMenuIconSize: CGFloat { isPadLike ? 30 : 22 }
    static var homeCreateMenuTitleSize: CGFloat { isPadLike ? 16 : 13 }
    static var homeCreateMenuItemWidth: CGFloat { isPadLike ? 100 : 78 }
    static var homeCreateMenuItemHeight: CGFloat { isPadLike ? 112 : 86 }

    static var homeCreateFolderOffset: CGSize { CGSize(width: isPadLike ? -210 : -150, height: isPadLike ? -92 : -74) }
    static var homeCreateSetOffset: CGSize { CGSize(width: isPadLike ? -120 : -86, height: isPadLike ? -182 : -144) }
    static var homeCreateTextOffset: CGSize { CGSize(width: 0, height: isPadLike ? -220 : -174) }
    static var homeCreateAudioOffset: CGSize { CGSize(width: isPadLike ? 120 : 86, height: isPadLike ? -182 : -144) }
    static var homeCreateEssayOffset: CGSize { CGSize(width: isPadLike ? 210 : 150, height: isPadLike ? -92 : -74) }
}

// MARK: - Home Background

extension Layout {
    static var homeBackgroundBlobSize: CGSize { CGSize(width: isPadLike ? 180 : 120, height: isPadLike ? 240 : 160) }
    static var homeBackgroundBlobX: CGFloat { isPadLike ? 90 : 28 }
    static var homeBackgroundBlobBottomOffset: CGFloat { isPadLike ? 130 : 110 }
    static var homeBackgroundGreenDotSize: CGFloat { isPadLike ? 16 : 12 }
    static var homeBackgroundGreenDotX: CGFloat { isPadLike ? 142 : 78 }
    static var homeBackgroundGreenDotBottomOffset: CGFloat { isPadLike ? 98 : 76 }
    static var homeBackgroundBlueDotSize: CGFloat { isPadLike ? 14 : 10 }
    static var homeBackgroundBlueDotX: CGFloat { isPadLike ? 210 : 128 }
    static var homeBackgroundBlueDotBottomOffset: CGFloat { isPadLike ? 148 : 142 }
}

// MARK: - Home Header

extension Layout {
    static var homeHeaderTitleSize: CGFloat { isPadLike ? 34 : 29 }
    static var homeHeaderSubtitleSize: CGFloat { isPadLike ? 18 : 15 }
    static var homeHeaderAvatarCircleSize: CGFloat { isPadLike ? 62 : 54 }
    static var homeHeaderAvatarIconSize: CGFloat { isPadLike ? 48 : 42 }
    static var homeHeaderNotificationDotSize: CGFloat { isPadLike ? 14 : 12 }
}

// MARK: - Bottom Navigation Bar

extension Layout {
    static var bottomNavHorizontalPadding: CGFloat { isPadLike ? 16 : (isCompactPhone ? 8 : 10) }
    static var bottomNavHeight: CGFloat { isPadLike ? 110 : (isCompactPhone ? 76 : 84) }
    static var bottomNavCornerRadius: CGFloat { isPadLike ? 34 : 26 }
    static var bottomNavShadowRadius: CGFloat { isPadLike ? 18 : 12 }
    static var bottomNavShadowY: CGFloat { isPadLike ? 8 : 5 }
    static var bottomNavRegularStackSpacing: CGFloat { isPadLike ? 8 : 5 }
    static var bottomNavSelectedCircleSize: CGFloat { isPadLike ? 50 : (isCompactPhone ? 36 : 40) }
    static var bottomNavIconSize: CGFloat { isPadLike ? 26 : (isCompactPhone ? 18 : 20) }
    static var bottomNavIconFrameHeight: CGFloat { isPadLike ? 52 : (isCompactPhone ? 36 : 40) }
    static var bottomNavIndicatorSize: CGFloat { isPadLike ? 8 : 6 }
    static var bottomNavButtonHeight: CGFloat { isPadLike ? 82 : (isCompactPhone ? 56 : 60) }
    static var bottomNavCreateCircleSize: CGFloat { isPadLike ? 72 : (isCompactPhone ? 54 : 60) }
    static var bottomNavCreateShadowRadius: CGFloat { isPadLike ? 14 : 10 }
    static var bottomNavCreateShadowY: CGFloat { isPadLike ? 8 : 6 }
    static var bottomNavCreateIconSize: CGFloat { isPadLike ? 36 : (isCompactPhone ? 26 : 30) }
}

// MARK: - Category Sidebar

extension Layout {
    static var categorySidebarVerticalPadding: CGFloat { isPadLike ? 6 : 2 }
    static var categorySidebarSpacing: CGFloat { isPadLike ? 16 : 12 }
    static var categorySidebarItemSpacing: CGFloat { isPadLike ? 8 : 6 }
    static var categorySidebarHorizontalPadding: CGFloat { isPadLike ? 6 : 4 }
    static var categorySidebarIndicatorWidth: CGFloat { isPadLike ? 4 : 3 }
    static var categorySidebarSelectedIndicatorHeight: CGFloat { isPadLike ? 96 : 80 }
    static var categorySidebarUnselectedIndicatorHeight: CGFloat { isPadLike ? 82 : 68 }
    static var categorySidebarIndicatorShadowRadius: CGFloat { isPadLike ? 8 : 6 }
    static var categorySidebarHighlightWidth: CGFloat { isPadLike ? 1.8 : 1.4 }
    static var categorySidebarHighlightHeight: CGFloat { isPadLike ? 22 : 18 }
    static var categorySidebarHighlightOffsetY: CGFloat { isPadLike ? -18 : -16 }
    static var categorySidebarCircleSize: CGFloat { isPadLike ? 58 : 50 }
    static var categorySidebarUnselectedCircleSize: CGFloat { isPadLike ? 54 : 46 }
    static var categorySidebarCircleShadowRadius: CGFloat { isPadLike ? 9 : 6 }
    static var categorySidebarCircleShadowY: CGFloat { isPadLike ? 4 : 3 }
    static var categorySidebarIconSize: CGFloat { isPadLike ? 21 : 18 }
    static var categorySidebarTextSize: CGFloat { isPadLike ? 10.5 : 9 }
    static var categorySidebarContentWidth: CGFloat { isPadLike ? 78 : 60 }
    static var categorySidebarContentHeight: CGFloat { isPadLike ? 98 : 78 }
    static var categorySidebarLabelSpacing: CGFloat { isPadLike ? 10 : 8 }
}

// MARK: - Set Item

extension Layout {
    static var setItemCornerRadius: CGFloat { isPadLike ? 30 : 22 }
    static var setItemHeight: CGFloat { isPadLike ? 104 : (isCompactPhone ? 78 : 86) }
    static var setItemBlobSize: CGSize { CGSize(width: isPadLike ? 130 : 92, height: isPadLike ? 86 : 62) }
    static var setItemBlobOffset: CGSize { CGSize(width: isPadLike ? 28 : 22, height: isPadLike ? 18 : 14) }
    static var setItemContentSpacing: CGFloat { isPadLike ? 16 : 12 }
    static var setItemIconCircleSize: CGFloat { isPadLike ? 62 : 46 }
    static var setItemIconSize: CGFloat { isPadLike ? 24 : 18 }
    static var setItemTextStackSpacing: CGFloat { isPadLike ? 7 : 5 }
    static var setItemTitleSize: CGFloat { isPadLike ? 24 : 18 }
    static var setItemSubtitleSize: CGFloat { isPadLike ? 16 : 13 }
    static var setItemTrailingTextSize: CGFloat { isPadLike ? 16 : 12 }
    static var setItemArrowSize: CGFloat { isPadLike ? 15 : 11 }
    static var setItemHorizontalPadding: CGFloat { isPadLike ? 18 : 14 }
    static var setItemVerticalPadding: CGFloat { isPadLike ? 18 : 14 }
}

// MARK: - Progress Card

extension Layout {
    static var progressCardCornerRadius: CGFloat { isPadLike ? 30 : 22 }
    static var progressGoalCardHeight: CGFloat { isPadLike ? 230 : (isCompactPhone ? 154 : 170) }
    static var progressActionCardHeight: CGFloat { isPadLike ? 190 : 130 }
    static var progressGoalBlobSize: CGSize { CGSize(width: isPadLike ? 250 : 170, height: isPadLike ? 280 : 170) }
    static var progressActionBlobSize: CGSize { CGSize(width: isPadLike ? 270 : 180, height: isPadLike ? 70 : 56) }
    static var progressLayoutSpacing: CGFloat { isPadLike ? 12 : 8 }
    static var progressGoalTitleSize: CGFloat { isPadLike ? 21 : 15 }
    static var progressGoalSparkleSize: CGFloat { isPadLike ? 12 : 9 }
    static var progressGoalProgressWidth: CGFloat { isPadLike ? 190 : 116 }
    static var progressGoalLeadingPadding: CGFloat { isPadLike ? 28 : 18 }
    static var progressGoalTrailingPadding: CGFloat { isPadLike ? 180 : 112 }
    static var progressGoalVerticalPadding: CGFloat { isPadLike ? 24 : 16 }
    static var progressGoalIconCircleSize: CGFloat { isPadLike ? 98 : 78 }
    static var progressGoalIconSize: CGFloat { isPadLike ? 34 : 29 }
    static var progressGoalIconContainerSize: CGSize { CGSize(width: isPadLike ? 180 : 136, height: isPadLike ? 180 : 136) }
    static var progressGoalIconTrailingPadding: CGFloat { isPadLike ? 18 : 8 }
    static var progressActionSpacing: CGFloat { isPadLike ? 20 : 12 }
    static var progressActionIconCircleSize: CGFloat { isPadLike ? 74 : 52 }
    static var progressActionIconSize: CGFloat { isPadLike ? 28 : 20 }
    static var progressActionTitleStackSpacing: CGFloat { isPadLike ? 10 : 6 }
    static var progressActionTitleSize: CGFloat { isPadLike ? 34 : 25 }
    static var progressActionSubtitleSize: CGFloat { isPadLike ? 20 : 17 }
    static var progressActionValueSize: CGFloat { isPadLike ? 18 : 15 }
    static var progressActionButtonCornerRadius: CGFloat { isPadLike ? 18 : 14 }
    static var progressActionButtonSize: CGFloat { isPadLike ? 62 : 46 }
    static var progressActionButtonIconSize: CGFloat { isPadLike ? 24 : 18 }
    static var progressActionHorizontalPadding: CGFloat { isPadLike ? 24 : 16 }
    static var progressActionVerticalPadding: CGFloat { isPadLike ? 24 : 18 }
    static var progressValueCurrentSize: CGFloat { isPadLike ? 56 : 38 }
    static var progressValueTotalSize: CGFloat { isPadLike ? 25 : 15 }
    static var progressSectionSpacing: CGFloat { isPadLike ? 10 : 6 }
    static var progressSectionSubtitleSize: CGFloat { isPadLike ? 18 : 15 }
    static var progressBarHeight: CGFloat { isPadLike ? 10 : 7 }
}

// MARK: - Stat Card

extension Layout {
    static let statCardHeight: CGFloat = 122
    static let statCardCornerRadius: CGFloat = 20
    static let statCardSmallWidthThreshold: CGFloat = 120
}

// MARK: - Stat Card Sizes

extension Layout {
    static func statBlobSize(isSmall: Bool) -> CGSize {
        CGSize(width: isSmall ? 64 : 78, height: isSmall ? 54 : 66)
    }

    static func statBlobOffset(isSmall: Bool) -> CGSize {
        CGSize(width: isSmall ? 20 : 24, height: isSmall ? 13 : 16)
    }

    static func statSparkleSize(index: Int, isSmall: Bool) -> CGFloat {
        switch index {
        case 1: return isSmall ? 8 : 10
        case 2: return isSmall ? 6 : 8
        default: return isSmall ? 5 : 7
        }
    }

    static func statSparkleOffset(index: Int, isSmall: Bool) -> CGSize {
        switch index {
        case 1: return CGSize(width: isSmall ? -20 : -26, height: isSmall ? -80 : -86)
        case 2: return CGSize(width: isSmall ? -42 : -48, height: isSmall ? -48 : -54)
        default: return CGSize(width: isSmall ? -8 : -12, height: isSmall ? -36 : -40)
        }
    }

    static func statIconCircleSize(isSmall: Bool) -> CGFloat { isSmall ? 34 : 40 }
    static func statIconSize(isSmall: Bool) -> CGFloat { isSmall ? 14 : 16 }
    static func statTextStackSpacing(isSmall: Bool) -> CGFloat { isSmall ? 5 : 7 }
    static func statTitleSize(isSmall: Bool) -> CGFloat { isSmall ? 10 : 12 }
    static func statValueSize(isSmall: Bool) -> CGFloat { isSmall ? 22 : 26 }
    static func statSubtitleSize(isSmall: Bool) -> CGFloat { isSmall ? 10 : 11 }
    static func statTopPadding(isSmall: Bool) -> CGFloat { isSmall ? 10 : 12 }
    static func statLeadingPadding(isSmall: Bool) -> CGFloat { isSmall ? 11 : 14 }
    static func statBottomPadding(isSmall: Bool) -> CGFloat { isSmall ? 12 : 14 }
}

// MARK: - Flashcard Set Detail

extension Layout {
    static var flashcardDetailContentMaxWidth: CGFloat { isPadLike ? 760 : .infinity }
    static var flashcardDetailMainSpacing: CGFloat { isPadLike ? 14 : 4 }
    static var flashcardDetailHorizontalPadding: CGFloat { isPadLike ? 34 : 20 }

    static var flashcardDetailTopBarPaddingTop: CGFloat { isPadLike ? 12 : 0 }
    static var flashcardDetailTopButtonSize: CGFloat { isPadLike ? 58 : 42 }
    static var flashcardDetailTopButtonIconSize: CGFloat { isPadLike ? 22 : 16 }

    static var flashcardDetailHeaderTopPadding: CGFloat { 0 }
    static var flashcardDetailHeaderSpacing: CGFloat { isPadLike ? 12 : 6 }
    static var flashcardDetailHeaderCollapsedBottomPadding: CGFloat { isPadLike ? 6 : 0 }
    static var flashcardDetailHeaderExpandedBottomPadding: CGFloat { isPadLike ? 16 : 12 }

    static var flashcardDetailHeaderTitleSize: CGFloat { isPadLike ? 52 : (isCompactPhone ? 27 : 30) }
    static var flashcardDetailHeaderDescriptionSize: CGFloat { isPadLike ? 20 : (isCompactPhone ? 13 : 14) }
    static var flashcardDetailHeaderDescriptionLineSpacing: CGFloat { isPadLike ? 6 : 4 }
    static var flashcardDetailHeaderDescriptionTrailingPadding: CGFloat { isPadLike ? 170 : 0 }
    static var flashcardDetailDescriptionButtonSize: CGFloat { isPadLike ? 15 : 11 }

    static var flashcardDetailAvatarSize: CGFloat { isPadLike ? 58 : 44 }
    static var flashcardDetailAvatarTextSize: CGFloat { isPadLike ? 20 : 15 }
    static var flashcardDetailHeaderBlobSize: CGSize { CGSize(width: isPadLike ? 220 : 150, height: isPadLike ? 230 : 164) }
    static var flashcardDetailHeaderBlobOffset: CGSize { CGSize(width: isPadLike ? 100 : 72, height: isPadLike ? 72 : 52) }
    static var flashcardDetailSparkleLargeSize: CGFloat { isPadLike ? 25 : 18 }
    static var flashcardDetailSparkleSmallSize: CGFloat { isPadLike ? 22 : 16 }
    static var flashcardDetailSparkleOneOffset: CGSize { CGSize(width: isPadLike ? -215 : -112, height: isPadLike ? 2 : -6) }
    static var flashcardDetailSparkleTwoOffset: CGSize { CGSize(width: isPadLike ? -118 : -38, height: isPadLike ? 48 : 34) }

    static var flashcardDetailCardHeight: CGFloat { isPadLike ? 360 : 220 }
    static var flashcardDetailCardCornerRadius: CGFloat { isPadLike ? 36 : 28 }
    static var flashcardDetailCardStrokeWidth: CGFloat { isPadLike ? 5 : 4 }
    static var flashcardDetailWordSize: CGFloat { isPadLike ? 68 : (isCompactPhone ? 38 : 42) }
    static var flashcardDetailSpeakerSize: CGFloat { isPadLike ? 26 : 19 }
    static var flashcardDetailTranslationSize: CGFloat { isPadLike ? 30 : 21 }
    static var flashcardDetailCardContentSpacing: CGFloat { isPadLike ? 14 : 9 }
    static var flashcardDetailCounterTextSize: CGFloat { isPadLike ? 16 : 13 }
    static var flashcardDetailCounterHorizontalPadding: CGFloat { isPadLike ? 16 : 13 }
    static var flashcardDetailCounterVerticalPadding: CGFloat { isPadLike ? 7 : 5 }
    static var flashcardDetailCardOverlayPadding: CGFloat { isPadLike ? 22 : 16 }
    static var flashcardDetailExpandIconSize: CGFloat { isPadLike ? 20 : 16 }
    static var flashcardDetailTopBlobSize: CGSize { CGSize(width: isPadLike ? 230 : 158, height: isPadLike ? 170 : 118) }
    static var flashcardDetailTopBlobOffset: CGSize { CGSize(width: isPadLike ? 304 : 154, height: isPadLike ? -136 : -88) }
    static var flashcardDetailBottomBlobSize: CGSize { CGSize(width: isPadLike ? 240 : 170, height: isPadLike ? 150 : 105) }
    static var flashcardDetailBottomBlobOffset: CGSize { CGSize(width: isPadLike ? -294 : -154, height: isPadLike ? 124 : 82) }
    static var flashcardDetailCardSparkleSize: CGFloat { isPadLike ? 24 : 17 }
    static var flashcardDetailCardSparkleOffset: CGSize { CGSize(width: isPadLike ? 250 : 126, height: isPadLike ? 100 : 66) }

    static var flashcardDetailControlsTopPadding: CGFloat { isPadLike ? 12 : 6 }
    static var flashcardDetailControlsTextSize: CGFloat { isPadLike ? 18 : 13 }
    static var flashcardDetailControlsMainIconSize: CGFloat { isPadLike ? 22 : 18 }
    static var flashcardDetailControlsToggleScale: CGFloat { isPadLike ? 0.78 : 0.62 }
    static var flashcardDetailControlsToggleWidth: CGFloat { isPadLike ? 50 : 36 }
    static var flashcardDetailControlsInnerSpacing: CGFloat { isPadLike ? 10 : 6 }
    static var flashcardDetailControlsDividerPadding: CGFloat { isPadLike ? 22 : 16 }
    static var flashcardDetailControlsDividerHeight: CGFloat { isPadLike ? 32 : 24 }

    static var flashcardDetailTabsHeight: CGFloat { isPadLike ? 74 : 58 }
    static var flashcardDetailTabsCornerRadius: CGFloat { isPadLike ? 24 : 18 }
    static var flashcardDetailTabTextSize: CGFloat { isPadLike ? 18 : (isCompactPhone ? 13 : 15) }
    static var flashcardDetailTabBadgeTextSize: CGFloat { isPadLike ? 14 : 12 }
    static var flashcardDetailTabHorizontalPadding: CGFloat { isPadLike ? 16 : 8 }
    static var flashcardDetailTabBadgeSpacing: CGFloat { isPadLike ? 7 : 5 }
    static var flashcardDetailTabBadgeHorizontalPadding: CGFloat { isPadLike ? 9 : 7 }
    static var flashcardDetailTabBadgeVerticalPadding: CGFloat { isPadLike ? 3 : 2 }
    static var flashcardDetailTabUnderlineHeight: CGFloat { 3 }
    static var flashcardDetailTabUnderlineSpacing: CGFloat { isPadLike ? 8 : 6 }
    static var flashcardDetailTabUnderlineHorizontalPadding: CGFloat { isPadLike ? 12 : 8 }
    static var flashcardDetailTabDividerHeight: CGFloat { isPadLike ? 26 : 22 }

    static var flashcardDetailListCornerRadius: CGFloat { isPadLike ? 26 : 22 }
    static var flashcardDetailRowHorizontalPadding: CGFloat { isPadLike ? 26 : 6 }
    static var flashcardDetailRowVerticalPadding: CGFloat { isPadLike ? 20 : 14 }
    static var flashcardDetailRowSpacing: CGFloat { isPadLike ? 18 : 12 }
    static var flashcardDetailRowIndexSize: CGFloat { isPadLike ? 18 : 15 }
    static var flashcardDetailRowIndexWidth: CGFloat { isPadLike ? 26 : 20 }
    static var flashcardDetailRowImageSize: CGFloat { isPadLike ? 92 : 64 }
    static var flashcardDetailRowImageCornerRadius: CGFloat { isPadLike ? 18 : 14 }
    static var flashcardDetailRowTextSpacing: CGFloat { isPadLike ? 7 : 5 }
    static var flashcardDetailRowWordSize: CGFloat { isPadLike ? 23 : 17 }
    static var flashcardDetailRowSpeakerSize: CGFloat { isPadLike ? 18 : 14 }
    static var flashcardDetailRowTranslationSize: CGFloat { isPadLike ? 18 : 15 }
    static var flashcardDetailRowExampleSize: CGFloat { isPadLike ? 16 : 13 }
    static var flashcardDetailRowIconSize: CGFloat { isPadLike ? 24 : 19 }
    static var flashcardDetailRowIconSpacing: CGFloat { isPadLike ? 24 : 18 }
    static var flashcardDetailRowPlaceholderIconSize: CGFloat { isPadLike ? 34 : 26 }
    static var flashcardDetailRowRightDividerLeadingPadding: CGFloat { isPadLike ? 8 : 2 }

    static var flashcardDetailAddButtonHeight: CGFloat { isPadLike ? 68 : 56 }
    static var flashcardDetailAddButtonCornerRadius: CGFloat { isPadLike ? 24 : 18 }
    static var flashcardDetailAddButtonTextSize: CGFloat { isPadLike ? 20 : 16 }
    static var flashcardDetailAddButtonIconSize: CGFloat { isPadLike ? 22 : 18 }
    static var flashcardDetailBottomCoverHeight: CGFloat { isPadLike ? 170 : 138 }
    static var flashcardDetailBottomPadding: CGFloat { isPadLike ? 180 : 152 }
    static var homeBottomBarHeight: CGFloat { isPadLike ? 110 : 90 }
}
