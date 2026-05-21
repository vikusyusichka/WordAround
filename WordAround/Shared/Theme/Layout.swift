import SwiftUI

enum Layout {
    // MARK: - Cached device checks (computed once, not on every body call)
    private static let _screenWidth = UIScreen.main.bounds.width
    private static let _isPad = UIDevice.current.userInterfaceIdiom == .pad

    static let isPadLike: Bool = _isPad || _screenWidth >= 700
    static let isCompactPhone: Bool = !isPadLike && _screenWidth < 390

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
    static let createSetSectionPadding: CGFloat = isPadLike ? 22 : 14
    static let createSetSectionCornerRadius: CGFloat = isPadLike ? 26 : 22
    static let createSetSectionLabelSize: CGFloat = isPadLike ? 16 : 13
    static let createSetOptionalTextSize: CGFloat = isPadLike ? 13 : 11
    static let createSetSmallVerticalSpacing: CGFloat = 8
}

// MARK: - Create Set Header

extension Layout {
    static let createSetHeaderSpacing: CGFloat = isPadLike ? 20 : 16
    static let createSetBackButtonSize: CGFloat = isPadLike ? 56 : 42
    static let createSetBackButtonIconSize: CGFloat = isPadLike ? 22 : 16
    static let createSetChooseIconTextSize: CGFloat = isPadLike ? 16 : 13
    static let createSetHeaderIconCircleSize: CGFloat = isPadLike ? 74 : 48
    static let createSetHeaderIconSize: CGFloat = isPadLike ? 30 : 21
    static let createSetHeaderContentSpacing: CGFloat = 10
    static let createSetHeaderTitleStackSpacing: CGFloat = isPadLike ? 8 : 4
    static let createSetHeaderTitleSize: CGFloat = isPadLike ? 38 : 26
    static let createSetHeaderSubtitleSize: CGFloat = isPadLike ? 20 : 13
    static let createSetPrivacySpacing: CGFloat = isPadLike ? 8 : 4
    static let createSetPrivacyInnerSpacing: CGFloat = isPadLike ? 7 : 4
    static let createSetPrivacyLabelSize: CGFloat = 15
    static let createSetPrivacyIconSize: CGFloat = isPadLike ? 14 : 10
    static let createSetPrivacyTextSize: CGFloat = isPadLike ? 14 : 10
    static let createSetPrivacyHorizontalPadding: CGFloat = isPadLike ? 14 : 7
    static let createSetPrivacyButtonHeight: CGFloat = isPadLike ? 42 : 30
    static let createSetPrivacyCornerRadius: CGFloat = isPadLike ? 13 : 10
}

// MARK: - Create Set Preview Card

extension Layout {
    static let createSetPreviewSectionSpacing: CGFloat = 10
    static let createSetPreviewCardSpacing: CGFloat = isPadLike ? 18 : 12
    static let createSetPreviewTitleStackSpacing: CGFloat = 6
    static let createSetPreviewTitleSize: CGFloat = isPadLike ? 24 : 18
    static let createSetPreviewSubtitleSize: CGFloat = isPadLike ? 17 : 14
    static let createSetPreviewPadding: CGFloat = isPadLike ? 16 : 12
    static let createSetPreviewCornerRadius: CGFloat = 24
    static let createSetPreviewIconCircleSize: CGFloat = isPadLike ? 76 : 52
    static let createSetPreviewIconSize: CGFloat = isPadLike ? 32 : 22
}

// MARK: - Create Set Cards Section

extension Layout {
    static let createSetCardsSectionSpacing: CGFloat = isPadLike ? 18 : 14
    static let createSetCardsSectionPadding: CGFloat = isPadLike ? 22 : 14
    static let createSetCardsTitleSize: CGFloat = isPadLike ? 16 : 14
    static let createSetCardsEditorPadSpacing: CGFloat = 24
    static let createSetCardsEditorPhoneSpacing: CGFloat = 14
    static let createSetCardsInputStackSpacing: CGFloat = isPadLike ? 16 : 12
    static let createSetCardsPhoneInputImageSpacing: CGFloat = 10
    static let createSetCardsImagePhoneWidth: CGFloat = 116
    static let createSetCardsFieldSpacing: CGFloat = 8
    static let createSetCardsMicIconSize: CGFloat = isPadLike ? 18 : 15
    static let createSetCardsFieldFontSize: CGFloat = isPadLike ? 16 : 14
    static let createSetCardsFieldHorizontalPadding: CGFloat = isPadLike ? 18 : 14
    static let createSetCardsFieldHeight: CGFloat = isPadLike ? 54 : 48
    static let createSetCardsFieldCornerRadius: CGFloat = isPadLike ? 18 : 16
    static let createSetCardsExampleMinHeight: CGFloat = isPadLike ? 84 : 76
    static let createSetCardsCounterSize: CGFloat = isPadLike ? 14 : 12
    static let createSetCardsImageContentSpacing: CGFloat = isPadLike ? 12 : 6
    static let createSetCardsImageMaxWidth: CGFloat = isPadLike ? 220 : .infinity
    static let createSetCardsImageMinHeight: CGFloat = isPadLike ? 220 : 126
    static let createSetCardsImageIconSize: CGFloat = isPadLike ? 42 : 24
    static let createSetCardsImageTitleSize: CGFloat = isPadLike ? 17 : 12
    static let createSetCardsImageSubtitleSize: CGFloat = isPadLike ? 14 : 10
    static let createSetCardsImageLineLimit: Int = isPadLike ? 2 : 1
    static let createSetCardsImageCornerRadius: CGFloat = isPadLike ? 20 : 16
    static let createSetAddCardIconSize: CGFloat = isPadLike ? 22 : 18
    static let createSetAddCardIconFrame: CGFloat = isPadLike ? 48 : 38
    static let createSetAddCardTextSize: CGFloat = isPadLike ? 17 : 15
    static let createSetCardsSectionCornerRadius: CGFloat = isPadLike ? 26 : 22
    static let createSetCardsOptionalTextSize: CGFloat = isPadLike ? 13 : 11
}

// MARK: - Create Set Info Section

extension Layout {
    static let createSetInfoSectionSpacing: CGFloat = isPadLike ? 20 : 14
    static let createSetTitleFieldHeight: CGFloat = isPadLike ? 56 : 48
    static let createSetTitleFieldFontSize: CGFloat = isPadLike ? 16 : 14
    static let createSetDescriptionPlaceholderFontSize: CGFloat = isPadLike ? 16 : 14
    static let createSetDescriptionMinHeight: CGFloat = isPadLike ? 118 : 96
    static let createSetDescriptionCounterSize: CGFloat = isPadLike ? 14 : 12
}

// MARK: - Create Set Customization Section

extension Layout {
    static let createSetCustomizationSectionSpacing: CGFloat = isPadLike ? 22 : 16
    static let createSetFolderTextSize: CGFloat = isPadLike ? 16 : 14
    static let createSetFolderHeight: CGFloat = isPadLike ? 50 : 46
    static let createSetFolderCornerRadius: CGFloat = 16
    static let createSetColorPickerSpacing: CGFloat = 12
    static let createSetColorCircleSize: CGFloat = isPadLike ? 36 : 28
    static let createSetSelectedColorStrokeWidth: CGFloat = isPadLike ? 4 : 3
    static let createSetSelectedColorOuterCircleSize: CGFloat = isPadLike ? 44 : 34
    static let createSetColorPickerHorizontalPadding: CGFloat = isPadLike ? 20 : 8
}

// MARK: - Home Shared

extension Layout {
    static let homeSidebarWidth: CGFloat = isPadLike ? sidebarWidthPad : (isCompactPhone ? sidebarWidthCompact : sidebarWidthPhone)
    static let homeHorizontalPadding: CGFloat = isPadLike ? screenHorizontalPaddingPad : screenHorizontalPaddingPhone
    static let homeTopSpacing: CGFloat = isPadLike ? topPaddingPad : topPaddingPhone
    static let homeContentSpacing: CGFloat = isPadLike ? 16 : 12
    static let homeHeaderSidebarSpacing: CGFloat = isPadLike ? 14 : 8
    static let homeBottomBarHorizontalPadding: CGFloat = isPadLike ? 28 : 14
    static let homeBottomBarBottomPadding: CGFloat = isPadLike ? 20 : 10
    static let homeBottomSafeSpacing: CGFloat = isPadLike ? 132 : 118
    static let homeScrollBottomPadding: CGFloat = isPadLike ? 18 : 8
    static let homeStatCardSpacing: CGFloat = isPadLike ? 14 : 8
    static let homeSetsListSpacing: CGFloat = isPadLike ? 14 : 10
    static let homeSectionTitleSize: CGFloat = isPadLike ? 34 : 22
    static let homeSectionTitleTopPadding: CGFloat = isPadLike ? 20 : 13
    static let homeSectionActionSize: CGFloat = isPadLike ? 18 : 14
    static let homeErrorTextSize: CGFloat = isPadLike ? 15 : 13
    static let homePlaceholderTitleSize: CGFloat = isPadLike ? 34 : 24
    static let homePlaceholderSubtitleSize: CGFloat = isPadLike ? 18 : 15
    static let homePlaceholderPadding: CGFloat = isPadLike ? 24 : 18
    static let homePlaceholderHeight: CGFloat = isPadLike ? 220 : 160
    static let homeEmptySetTitleSize: CGFloat = isPadLike ? 30 : 22
    static let homeEmptySetHeight: CGFloat = isPadLike ? 180 : 140
}

// MARK: - Home Create Menu

extension Layout {
    static let homeCreateMenuFrameHeight: CGFloat = isPadLike ? 300 : 235
    static let homeCreateMenuBottomPadding: CGFloat = isPadLike ? 58 : 48
    static let homeCreateMenuItemSpacing: CGFloat = isPadLike ? 10 : 7
    static let homeCreateMenuCircleSize: CGFloat = isPadLike ? 78 : 58
    static let homeCreateMenuShadowRadius: CGFloat = isPadLike ? 16 : 12
    static let homeCreateMenuShadowY: CGFloat = isPadLike ? 9 : 7
    static let homeCreateMenuIconSize: CGFloat = isPadLike ? 30 : 22
    static let homeCreateMenuTitleSize: CGFloat = isPadLike ? 16 : 13
    static let homeCreateMenuItemWidth: CGFloat = isPadLike ? 100 : 78
    static let homeCreateMenuItemHeight: CGFloat = isPadLike ? 112 : 86

    static let homeCreateFolderOffset: CGSize = CGSize(width: isPadLike ? -210 : -150, height: isPadLike ? -92 : -74)
    static let homeCreateSetOffset: CGSize = CGSize(width: isPadLike ? -120 : -86, height: isPadLike ? -182 : -144)
    static let homeCreateTextOffset: CGSize = CGSize(width: 0, height: isPadLike ? -220 : -174)
    static let homeCreateAudioOffset: CGSize = CGSize(width: isPadLike ? 120 : 86, height: isPadLike ? -182 : -144)
    static let homeCreateEssayOffset: CGSize = CGSize(width: isPadLike ? 210 : 150, height: isPadLike ? -92 : -74)
}

// MARK: - Home Background

extension Layout {
    static let homeBackgroundBlobSize: CGSize = CGSize(width: isPadLike ? 180 : 120, height: isPadLike ? 240 : 160)
    static let homeBackgroundBlobX: CGFloat = isPadLike ? 90 : 28
    static let homeBackgroundBlobBottomOffset: CGFloat = isPadLike ? 130 : 110
    static let homeBackgroundGreenDotSize: CGFloat = isPadLike ? 16 : 12
    static let homeBackgroundGreenDotX: CGFloat = isPadLike ? 142 : 78
    static let homeBackgroundGreenDotBottomOffset: CGFloat = isPadLike ? 98 : 76
    static let homeBackgroundBlueDotSize: CGFloat = isPadLike ? 14 : 10
    static let homeBackgroundBlueDotX: CGFloat = isPadLike ? 210 : 128
    static let homeBackgroundBlueDotBottomOffset: CGFloat = isPadLike ? 148 : 142
}

// MARK: - Home Header

extension Layout {
    static let homeHeaderTitleSize: CGFloat = isPadLike ? 34 : 29
    static let homeHeaderSubtitleSize: CGFloat = isPadLike ? 18 : 15
    static let homeHeaderAvatarCircleSize: CGFloat = isPadLike ? 62 : 54
    static let homeHeaderAvatarIconSize: CGFloat = isPadLike ? 48 : 42
    static let homeHeaderNotificationDotSize: CGFloat = isPadLike ? 14 : 12
}

// MARK: - Bottom Navigation Bar

extension Layout {
    static let bottomNavHorizontalPadding: CGFloat = isPadLike ? 16 : (isCompactPhone ? 8 : 10)
    static let bottomNavHeight: CGFloat = isPadLike ? 110 : (isCompactPhone ? 76 : 84)
    static let bottomNavCornerRadius: CGFloat = isPadLike ? 34 : 26
    static let bottomNavShadowRadius: CGFloat = isPadLike ? 18 : 12
    static let bottomNavShadowY: CGFloat = isPadLike ? 8 : 5
    static let bottomNavRegularStackSpacing: CGFloat = isPadLike ? 8 : 5
    static let bottomNavSelectedCircleSize: CGFloat = isPadLike ? 50 : (isCompactPhone ? 36 : 40)
    static let bottomNavIconSize: CGFloat = isPadLike ? 26 : (isCompactPhone ? 18 : 20)
    static let bottomNavIconFrameHeight: CGFloat = isPadLike ? 52 : (isCompactPhone ? 36 : 40)
    static let bottomNavIndicatorSize: CGFloat = isPadLike ? 8 : 6
    static let bottomNavButtonHeight: CGFloat = isPadLike ? 82 : (isCompactPhone ? 56 : 60)
    static let bottomNavCreateCircleSize: CGFloat = isPadLike ? 72 : (isCompactPhone ? 54 : 60)
    static let bottomNavCreateShadowRadius: CGFloat = isPadLike ? 14 : 10
    static let bottomNavCreateShadowY: CGFloat = isPadLike ? 8 : 6
    static let bottomNavCreateIconSize: CGFloat = isPadLike ? 36 : (isCompactPhone ? 26 : 30)
}

// MARK: - Category Sidebar

extension Layout {
    static let categorySidebarVerticalPadding: CGFloat = isPadLike ? 6 : 2
    static let categorySidebarSpacing: CGFloat = isPadLike ? 16 : 12
    static let categorySidebarItemSpacing: CGFloat = isPadLike ? 8 : 6
    static let categorySidebarHorizontalPadding: CGFloat = isPadLike ? 6 : 4
    static let categorySidebarIndicatorWidth: CGFloat = isPadLike ? 4 : 3
    static let categorySidebarSelectedIndicatorHeight: CGFloat = isPadLike ? 96 : 80
    static let categorySidebarUnselectedIndicatorHeight: CGFloat = isPadLike ? 82 : 68
    static let categorySidebarIndicatorShadowRadius: CGFloat = isPadLike ? 8 : 6
    static let categorySidebarHighlightWidth: CGFloat = isPadLike ? 1.8 : 1.4
    static let categorySidebarHighlightHeight: CGFloat = isPadLike ? 22 : 18
    static let categorySidebarHighlightOffsetY: CGFloat = isPadLike ? -18 : -16
    static let categorySidebarCircleSize: CGFloat = isPadLike ? 58 : 50
    static let categorySidebarUnselectedCircleSize: CGFloat = isPadLike ? 54 : 46
    static let categorySidebarCircleShadowRadius: CGFloat = isPadLike ? 9 : 6
    static let categorySidebarCircleShadowY: CGFloat = isPadLike ? 4 : 3
    static let categorySidebarIconSize: CGFloat = isPadLike ? 21 : 18
    static let categorySidebarTextSize: CGFloat = isPadLike ? 10.5 : 9
    static let categorySidebarContentWidth: CGFloat = isPadLike ? 78 : 60
    static let categorySidebarContentHeight: CGFloat = isPadLike ? 98 : 78
    static let categorySidebarLabelSpacing: CGFloat = isPadLike ? 10 : 8
}

// MARK: - Set Item

extension Layout {
    static let setItemCornerRadius: CGFloat = isPadLike ? 30 : 22
    static let setItemHeight: CGFloat = isPadLike ? 104 : (isCompactPhone ? 78 : 86)
    static let setItemBlobSize: CGSize = CGSize(width: isPadLike ? 130 : 92, height: isPadLike ? 86 : 62)
    static let setItemBlobOffset: CGSize = CGSize(width: isPadLike ? 28 : 22, height: isPadLike ? 18 : 14)
    static let setItemContentSpacing: CGFloat = isPadLike ? 16 : 12
    static let setItemIconCircleSize: CGFloat = isPadLike ? 62 : 46
    static let setItemIconSize: CGFloat = isPadLike ? 24 : 18
    static let setItemTextStackSpacing: CGFloat = isPadLike ? 7 : 5
    static let setItemTitleSize: CGFloat = isPadLike ? 24 : 18
    static let setItemSubtitleSize: CGFloat = isPadLike ? 16 : 13
    static let setItemTrailingTextSize: CGFloat = isPadLike ? 16 : 12
    static let setItemArrowSize: CGFloat = isPadLike ? 15 : 11
    static let setItemHorizontalPadding: CGFloat = isPadLike ? 18 : 14
    static let setItemVerticalPadding: CGFloat = isPadLike ? 18 : 14
}

// MARK: - Progress Card

extension Layout {
    static let progressCardCornerRadius: CGFloat = isPadLike ? 30 : 22
    static let progressGoalCardHeight: CGFloat = isPadLike ? 230 : (isCompactPhone ? 154 : 170)
    static let progressActionCardHeight: CGFloat = isPadLike ? 190 : 130
    static let progressGoalBlobSize: CGSize = CGSize(width: isPadLike ? 250 : 170, height: isPadLike ? 280 : 170)
    static let progressActionBlobSize: CGSize = CGSize(width: isPadLike ? 270 : 180, height: isPadLike ? 70 : 56)
    static let progressLayoutSpacing: CGFloat = isPadLike ? 12 : 8
    static let progressGoalTitleSize: CGFloat = isPadLike ? 21 : 15
    static let progressGoalSparkleSize: CGFloat = isPadLike ? 12 : 9
    static let progressGoalProgressWidth: CGFloat = isPadLike ? 190 : 116
    static let progressGoalLeadingPadding: CGFloat = isPadLike ? 28 : 18
    static let progressGoalTrailingPadding: CGFloat = isPadLike ? 180 : 112
    static let progressGoalVerticalPadding: CGFloat = isPadLike ? 24 : 16
    static let progressGoalIconCircleSize: CGFloat = isPadLike ? 98 : 78
    static let progressGoalIconSize: CGFloat = isPadLike ? 34 : 29
    static let progressGoalIconContainerSize: CGSize = CGSize(width: isPadLike ? 180 : 136, height: isPadLike ? 180 : 136)
    static let progressGoalIconTrailingPadding: CGFloat = isPadLike ? 18 : 8
    static let progressActionSpacing: CGFloat = isPadLike ? 20 : 12
    static let progressActionIconCircleSize: CGFloat = isPadLike ? 74 : 52
    static let progressActionIconSize: CGFloat = isPadLike ? 28 : 20
    static let progressActionTitleStackSpacing: CGFloat = isPadLike ? 10 : 6
    static let progressActionTitleSize: CGFloat = isPadLike ? 34 : 25
    static let progressActionSubtitleSize: CGFloat = isPadLike ? 20 : 17
    static let progressActionValueSize: CGFloat = isPadLike ? 18 : 15
    static let progressActionButtonCornerRadius: CGFloat = isPadLike ? 18 : 14
    static let progressActionButtonSize: CGFloat = isPadLike ? 62 : 46
    static let progressActionButtonIconSize: CGFloat = isPadLike ? 24 : 18
    static let progressActionHorizontalPadding: CGFloat = isPadLike ? 24 : 16
    static let progressActionVerticalPadding: CGFloat = isPadLike ? 24 : 18
    static let progressValueCurrentSize: CGFloat = isPadLike ? 56 : 38
    static let progressValueTotalSize: CGFloat = isPadLike ? 25 : 15
    static let progressSectionSpacing: CGFloat = isPadLike ? 10 : 6
    static let progressSectionSubtitleSize: CGFloat = isPadLike ? 18 : 15
    static let progressBarHeight: CGFloat = isPadLike ? 10 : 7
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
    static let flashcardDetailContentMaxWidth: CGFloat = isPadLike ? 760 : .infinity
    static let flashcardDetailMainSpacing: CGFloat = isPadLike ? 14 : 4
    static let flashcardDetailHorizontalPadding: CGFloat = isPadLike ? 34 : 20

    static let flashcardDetailTopBarPaddingTop: CGFloat = isPadLike ? 12 : 0
    static let flashcardDetailTopButtonSize: CGFloat = isPadLike ? 58 : 42
    static let flashcardDetailTopButtonIconSize: CGFloat = isPadLike ? 22 : 16

    static let flashcardDetailHeaderTopPadding: CGFloat = 0
    static let flashcardDetailHeaderSpacing: CGFloat = isPadLike ? 12 : 6
    static let flashcardDetailHeaderCollapsedBottomPadding: CGFloat = isPadLike ? 6 : 0
    static let flashcardDetailHeaderExpandedBottomPadding: CGFloat = isPadLike ? 16 : 12

    static let flashcardDetailHeaderTitleSize: CGFloat = isPadLike ? 52 : (isCompactPhone ? 27 : 30)
    static let flashcardDetailHeaderDescriptionSize: CGFloat = isPadLike ? 20 : (isCompactPhone ? 13 : 14)
    static let flashcardDetailHeaderDescriptionLineSpacing: CGFloat = isPadLike ? 6 : 4
    static let flashcardDetailHeaderDescriptionTrailingPadding: CGFloat = isPadLike ? 170 : 0
    static let flashcardDetailDescriptionButtonSize: CGFloat = isPadLike ? 15 : 11

    static let flashcardDetailAvatarSize: CGFloat = isPadLike ? 58 : 44
    static let flashcardDetailAvatarTextSize: CGFloat = isPadLike ? 20 : 15
    static let flashcardDetailHeaderBlobSize: CGSize = CGSize(width: isPadLike ? 220 : 150, height: isPadLike ? 230 : 164)
    static let flashcardDetailHeaderBlobOffset: CGSize = CGSize(width: isPadLike ? 100 : 72, height: isPadLike ? 72 : 52)
    static let flashcardDetailSparkleLargeSize: CGFloat = isPadLike ? 25 : 18
    static let flashcardDetailSparkleSmallSize: CGFloat = isPadLike ? 22 : 16
    static let flashcardDetailSparkleOneOffset: CGSize = CGSize(width: isPadLike ? -215 : -112, height: isPadLike ? 2 : -6)
    static let flashcardDetailSparkleTwoOffset: CGSize = CGSize(width: isPadLike ? -118 : -38, height: isPadLike ? 48 : 34)

    static let flashcardDetailCardHeight: CGFloat = isPadLike ? 360 : 220
    static let flashcardDetailCardCornerRadius: CGFloat = isPadLike ? 36 : 28
    static let flashcardDetailCardStrokeWidth: CGFloat = isPadLike ? 5 : 4
    static let flashcardDetailWordSize: CGFloat = isPadLike ? 68 : (isCompactPhone ? 38 : 42)
    static let flashcardDetailSpeakerSize: CGFloat = isPadLike ? 26 : 19
    static let flashcardDetailTranslationSize: CGFloat = isPadLike ? 30 : 21
    static let flashcardDetailCardContentSpacing: CGFloat = isPadLike ? 14 : 9
    static let flashcardDetailCounterTextSize: CGFloat = isPadLike ? 16 : 13
    static let flashcardDetailCounterHorizontalPadding: CGFloat = isPadLike ? 16 : 13
    static let flashcardDetailCounterVerticalPadding: CGFloat = isPadLike ? 7 : 5
    static let flashcardDetailCardOverlayPadding: CGFloat = isPadLike ? 22 : 16
    static let flashcardDetailExpandIconSize: CGFloat = isPadLike ? 20 : 16
    static let flashcardDetailTopBlobSize: CGSize = CGSize(width: isPadLike ? 230 : 158, height: isPadLike ? 170 : 118)
    static let flashcardDetailTopBlobOffset: CGSize = CGSize(width: isPadLike ? 304 : 154, height: isPadLike ? -136 : -88)
    static let flashcardDetailBottomBlobSize: CGSize = CGSize(width: isPadLike ? 240 : 170, height: isPadLike ? 150 : 105)
    static let flashcardDetailBottomBlobOffset: CGSize = CGSize(width: isPadLike ? -294 : -154, height: isPadLike ? 124 : 82)
    static let flashcardDetailCardSparkleSize: CGFloat = isPadLike ? 24 : 17
    static let flashcardDetailCardSparkleOffset: CGSize = CGSize(width: isPadLike ? 250 : 126, height: isPadLike ? 100 : 66)

    static let flashcardDetailControlsTopPadding: CGFloat = isPadLike ? 12 : 6
    static let flashcardDetailControlsTextSize: CGFloat = isPadLike ? 18 : 13
    static let flashcardDetailControlsMainIconSize: CGFloat = isPadLike ? 22 : 18
    static let flashcardDetailControlsToggleScale: CGFloat = isPadLike ? 0.78 : 0.62
    static let flashcardDetailControlsToggleWidth: CGFloat = isPadLike ? 50 : 36
    static let flashcardDetailControlsInnerSpacing: CGFloat = isPadLike ? 10 : 6
    static let flashcardDetailControlsDividerPadding: CGFloat = isPadLike ? 22 : 16
    static let flashcardDetailControlsDividerHeight: CGFloat = isPadLike ? 32 : 24

    static let flashcardDetailTabsHeight: CGFloat = isPadLike ? 74 : 58
    static let flashcardDetailTabsCornerRadius: CGFloat = isPadLike ? 24 : 18
    static let flashcardDetailTabTextSize: CGFloat = isPadLike ? 18 : (isCompactPhone ? 13 : 15)
    static let flashcardDetailTabBadgeTextSize: CGFloat = isPadLike ? 14 : 12
    static let flashcardDetailTabHorizontalPadding: CGFloat = isPadLike ? 16 : 8
    static let flashcardDetailTabBadgeSpacing: CGFloat = isPadLike ? 7 : 5
    static let flashcardDetailTabBadgeHorizontalPadding: CGFloat = isPadLike ? 9 : 7
    static let flashcardDetailTabBadgeVerticalPadding: CGFloat = isPadLike ? 3 : 2
    static let flashcardDetailTabUnderlineHeight: CGFloat = 3
    static let flashcardDetailTabUnderlineSpacing: CGFloat = isPadLike ? 8 : 6
    static let flashcardDetailTabUnderlineHorizontalPadding: CGFloat = isPadLike ? 12 : 8
    static let flashcardDetailTabDividerHeight: CGFloat = isPadLike ? 26 : 22

    static let flashcardDetailListCornerRadius: CGFloat = isPadLike ? 26 : 22
    static let flashcardDetailRowHorizontalPadding: CGFloat = isPadLike ? 26 : 6
    static let flashcardDetailRowVerticalPadding: CGFloat = isPadLike ? 20 : 14
    static let flashcardDetailRowSpacing: CGFloat = isPadLike ? 18 : 12
    static let flashcardDetailRowIndexSize: CGFloat = isPadLike ? 18 : 15
    static let flashcardDetailRowIndexWidth: CGFloat = isPadLike ? 26 : 20
    static let flashcardDetailRowImageSize: CGFloat = isPadLike ? 92 : 64
    static let flashcardDetailRowImageCornerRadius: CGFloat = isPadLike ? 18 : 14
    static let flashcardDetailRowTextSpacing: CGFloat = isPadLike ? 7 : 5
    static let flashcardDetailRowWordSize: CGFloat = isPadLike ? 23 : 17
    static let flashcardDetailRowSpeakerSize: CGFloat = isPadLike ? 18 : 14
    static let flashcardDetailRowTranslationSize: CGFloat = isPadLike ? 18 : 15
    static let flashcardDetailRowExampleSize: CGFloat = isPadLike ? 16 : 13
    static let flashcardDetailRowIconSize: CGFloat = isPadLike ? 24 : 19
    static let flashcardDetailRowIconSpacing: CGFloat = isPadLike ? 24 : 18
    static let flashcardDetailRowPlaceholderIconSize: CGFloat = isPadLike ? 34 : 26
    static let flashcardDetailRowRightDividerLeadingPadding: CGFloat = isPadLike ? 8 : 2

    static let flashcardDetailAddButtonHeight: CGFloat = isPadLike ? 68 : 56
    static let flashcardDetailAddButtonCornerRadius: CGFloat = isPadLike ? 24 : 18
    static let flashcardDetailAddButtonTextSize: CGFloat = isPadLike ? 20 : 16
    static let flashcardDetailAddButtonIconSize: CGFloat = isPadLike ? 22 : 18
    static let flashcardDetailBottomCoverHeight: CGFloat = isPadLike ? 170 : 138
    static let flashcardDetailBottomPadding: CGFloat = isPadLike ? 180 : 152
    static let homeBottomBarHeight: CGFloat = isPadLike ? 110 : 90
}

// MARK: - SF Symbol Picker

extension Layout {
    static let symbolPickerHorizontalPadding: CGFloat = isPadLike ? 54 : (isCompactPhone ? 18 : 22)
    static let symbolPickerTopPadding: CGFloat = isPadLike ? 18 : 14
    static let symbolPickerBottomPadding: CGFloat = isPadLike ? 42 : 34
    static let symbolPickerContentSpacing: CGFloat = isPadLike ? 22 : 18

    static let symbolPickerTopBarHeight: CGFloat = isPadLike ? 48 : 44
    static let symbolPickerTopBarSpacing: CGFloat = isPadLike ? 26 : 14
    static let symbolPickerTitleSize: CGFloat = isPadLike ? 18 : 16

    static let symbolPickerCloseButtonSize: CGFloat = isPadLike ? 42 : 36
    static let symbolPickerCloseIconSize: CGFloat = isPadLike ? 15 : 14

    static let symbolPickerSearchWidth: CGFloat = isPadLike ? 260 : (isCompactPhone ? 150 : 180)
    static let symbolPickerSearchHeight: CGFloat = isPadLike ? 36 : 34
    static let symbolPickerSearchHorizontalPadding: CGFloat = isPadLike ? 14 : 12
    static let symbolPickerSearchIconSize: CGFloat = isPadLike ? 14 : 13
    static let symbolPickerSearchTextSize: CGFloat = isPadLike ? 14 : 13
    static let symbolPickerSearchIconSpacing: CGFloat = isPadLike ? 9 : 8

    static let symbolPickerGridColumns: Int = isPadLike ? 5 : 4
    static let symbolPickerGridSpacing: CGFloat = isPadLike ? 18 : 17
    static let symbolPickerGridItemSpacing: CGFloat = isPadLike ? 26 : 16

    static let symbolPickerCircleSize: CGFloat = isPadLike ? 58 : 54
    static let symbolPickerIconSize: CGFloat = isPadLike ? 24 : 22
}

// MARK: - Adaptive Layout System

struct ScreenMetrics {
    let horizontalSizeClass: UserInterfaceSizeClass?
    let verticalSizeClass: UserInterfaceSizeClass?
    let containerWidth: CGFloat

    var isCompact: Bool {
        horizontalSizeClass == .compact || containerWidth < LayoutConstants.Breakpoints.regularMinWidth
    }

    var isRegular: Bool { !isCompact }
    var isLandscapeCompact: Bool { horizontalSizeClass == .compact && verticalSizeClass == .compact }

    static func current(
        horizontal: UserInterfaceSizeClass?,
        vertical: UserInterfaceSizeClass?,
        containerWidth: CGFloat = UIScreen.main.bounds.width
    ) -> ScreenMetrics {
        ScreenMetrics(
            horizontalSizeClass: horizontal,
            verticalSizeClass: vertical,
            containerWidth: containerWidth
        )
    }
}

// MARK: - Centralized Layout Constants

enum LayoutConstants {
    enum Breakpoints {
        static let regularMinWidth: CGFloat = 700
    }

    enum Common {
        static func screenHorizontalPadding(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 34 : 22 }
        static func screenTopPadding(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 24 : 16 }
        static func screenBottomPadding(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 40 : 28 }
        static func contentMaxWidth(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 620 : .infinity }
        static func narrowContentMaxWidth(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 520 : .infinity }
        static func sectionSpacing(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 24 : 18 }
        static func itemSpacing(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 16 : 12 }
        static func smallSpacing(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 10 : 8 }
        static let hairline: CGFloat = 1
    }

    enum Typography {
        static func writingTitle(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 42 : 34 }
        static func screenTitle(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 40 : 32 }
        static func largeTitle(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 34 : 28 }
        static func title(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 22 : 18 }
        static func cardTitle(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 19 : 16 }
        static func body(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 16 : 14 }
        static func bodySmall(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 15 : 13 }
        static func caption(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 14 : 12 }
        static func captionSmall(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 13 : 11 }
    }

    enum Writing {
        static func topPadding(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 6 : 0 }
        static func headerSpacing(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 10 : 8 }

        static func contentMaxWidth(_ metrics: ScreenMetrics) -> CGFloat { .infinity }

        static func goalHeight(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 144 : 118 }
        static func goalCornerRadius(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 26 : 24 }
        static func goalHorizontalPadding(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 28 : 20 }
        static func goalVerticalPadding(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 24 : 20 }
        static func goalBlobSize(_ metrics: ScreenMetrics) -> CGSize { CGSize(width: metrics.isRegular ? 160 : 132, height: metrics.isRegular ? 135 : 112) }
        static func goalBlobOffset(_ metrics: ScreenMetrics) -> CGSize { CGSize(width: 30, height: 2) }
        static func goalContentSpacing(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 18 : 18 }
        static func goalTextSpacing(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 10 : 10 }
        static func goalProgressWidth(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 190 : 152 }
        static func goalProgressHeight(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 6 : 5 }
        static func goalIconCircleSize(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 58 : 48 }
        static func goalIconSize(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 22 : 19 }
        static func goalNumberSize(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 32 : 27 }

        static func menuIconBoxSize(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 62 : 50 }
        static func menuIconCornerRadius(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 18 : 16 }
        static func menuIconSize(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 25 : 21 }
        static func menuHeight(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 94 : 80 }
        static func menuCornerRadius(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 24 : 22 }
        static func menuHorizontalPadding(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 22 : 18 }
        static func menuSpacing(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 18 : 14 }
        static func menuChevronSize(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 16 : 14 }
    }

    enum WriteWords {
        static func topBarTopPadding(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 22 : 12 }
        static func progressTopPadding(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 22 : 14 }
        static func cardTopSpacer(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 24 : 10 }
        static func afterCardSpacer(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 22 : 10 }
        static func bottomPadding(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 24 : 10 }
        static func topBarTitleSize(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 18 : 16 }
        static func topBarIconSize(_ metrics: ScreenMetrics) -> CGFloat { 18 }
        static func topBarButtonSize(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 40 : 38 }

        static func exerciseHeight(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 500 : 390 }
        static func exerciseHeight(_ metrics: ScreenMetrics, availableHeight: CGFloat) -> CGFloat {
            let usedHeight = topBarTopPadding(metrics)
            + topBarButtonSize(metrics)
            + progressTopPadding(metrics)
            + progressHeight(metrics)
            + cardTopSpacer(metrics)
            + afterCardSpacer(metrics)
            + modeBarHeight(metrics)
            + bottomPadding(metrics)
            + Common.smallSpacing(metrics)

            let availableCardHeight = availableHeight - usedHeight
            let minimumHeight: CGFloat = metrics.isRegular ? 430 : 340
            let maximumHeight: CGFloat = metrics.isRegular ? 500 : 390
            return min(max(availableCardHeight, minimumHeight), maximumHeight)
        }
        static func exerciseHorizontalPadding(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 26 : 16 }
        static func exerciseSpacing(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 22 : 16 }
        static func exerciseTopPadding(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 32 : 20 }
        static func exerciseHeaderSpacing(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 10 : 9 }
        static func exerciseTitleSize(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 34 : 28 }
        static func exerciseHintSize(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 17 : 15 }
        static func exerciseCornerRadius(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 28 : 24 }
        static func primaryButtonHeight(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 54 : 48 }
        static func primaryButtonCornerRadius(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 20 : 18 }
        static func secondaryButtonHeight(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 50 : 44 }
        static func secondaryButtonCornerRadius(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 18 : 17 }
        static func secondaryButtonSpacing(_ metrics: ScreenMetrics) -> CGFloat { 14 }
        static func cardBottomPadding(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 24 : 18 }
        static func successHorizontalPadding(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 24 : 22 }
        static func successVerticalPadding(_ metrics: ScreenMetrics) -> CGFloat { 12 }

        static func answerCellSpacing(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 10 : 7 }
        static func answerCellSize(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 42 : 34 }
        static func answerCellCornerRadius(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 9 : 8 }
        static func answerCellFontSize(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 18 : 15 }

        static func answerInputHeight(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 58 : 54 }
        static func answerInputMaxWidth(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 420 : .infinity }
        static func answerInputHorizontalPadding(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 24 : 18 }
        static func answerInputCornerRadius(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 18 : 17 }
        static func answerInputFontSize(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 22 : 19 }

        static func progressSegmentCount(_ metrics: ScreenMetrics) -> Int { metrics.isRegular ? 10 : 9 }
        static func progressSegmentSpacing(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 8 : 7 }
        static func progressHeight(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 6 : 5 }
        static func progressTextWidth(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 52 : 44 }
        static func progressSpacing(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 16 : 14 }

        static func modeBarHeight(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 54 : 48 }
        static func modeBarHorizontalPadding(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 20 : 18 }
        static func modeBarCornerRadius(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 18 : 17 }
        static func modeIconSize(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 18 : 17 }
        static func modeChevronSize(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 10 : 9 }
        static func modeGapWidth(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 24 : 22 }
        static func modeInlineSpacing(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 6 : 5 }
    }

    enum WritingSetSelection {
        static func listMaxWidth(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 620 : .infinity }
        static func cardSpacing(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 16 : 12 }
        static func topBarButtonSize(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 42 : 40 }
        static func topBarIconSize(_ metrics: ScreenMetrics) -> CGFloat { 18 }
        static func emptyPadding(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 24 : 18 }
        static func emptyCornerRadius(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 26 : 24 }

        static func setCardSpacing(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 18 : 14 }
        static func setCardPadding(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 18 : 14 }
        static func setCardCornerRadius(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 26 : 22 }
        static func setIconSize(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 62 : 54 }
        static func setIconCornerRadius(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 20 : 17 }
        static func setIconSymbolSize(_ metrics: ScreenMetrics) -> CGFloat { metrics.isRegular ? 24 : 21 }
        static func badgeHorizontalPadding(_ metrics: ScreenMetrics) -> CGFloat { 10 }
        static func badgeVerticalPadding(_ metrics: ScreenMetrics) -> CGFloat { 5 }
    }
}

// MARK: - Reusable Adaptive Container

struct AdaptiveContentContainer<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let maxWidth: (ScreenMetrics) -> CGFloat
    let alignment: Alignment
    let content: (ScreenMetrics) -> Content

    init(
        maxWidth: @escaping (ScreenMetrics) -> CGFloat = LayoutConstants.Common.contentMaxWidth,
        alignment: Alignment = .topLeading,
        @ViewBuilder content: @escaping (ScreenMetrics) -> Content
    ) {
        self.maxWidth = maxWidth
        self.alignment = alignment
        self.content = content
    }

    var body: some View {
        GeometryReader { proxy in
            let metrics = ScreenMetrics.current(
                horizontal: horizontalSizeClass,
                vertical: verticalSizeClass,
                containerWidth: proxy.size.width
            )

            content(metrics)
                .frame(maxWidth: maxWidth(metrics), alignment: alignment)
                .frame(maxWidth: .infinity, alignment: alignment)
        }
    }
}

// MARK: - Write Words Lose Screen

extension Layout {
    static let writeWordsLoseHorizontalPadding: CGFloat = isPadLike ? screenHorizontalPaddingPad : screenHorizontalPaddingPhone
    static let writeWordsLoseSectionSpacing: CGFloat = isPadLike ? sectionSpacingPad : sectionSpacingPhone
    static let writeWordsLoseLargeSpacing: CGFloat = isPadLike ? 40 : 32

    static let writeWordsLoseCardHorizontalPadding: CGFloat = isPadLike ? 24 : 18
    static let writeWordsLoseCardVerticalPadding: CGFloat = isPadLike ? sectionSpacingPad : sectionSpacingPhone
    static let writeWordsLoseCardMaxWidth: CGFloat = isPadLike ? contentMaxWidthPad : .infinity
    static let writeWordsLoseCardCornerRadius: CGFloat = cardCornerRadius
    static let writeWordsLoseCardShadowRadius: CGFloat = cardCornerRadius + 2
    static let writeWordsLoseCardShadowY: CGFloat = topPaddingPhone + 2

    static let writeWordsLoseIconSize: CGFloat = isPadLike ? 82 : 68
    static let writeWordsLoseIconSymbolSize: CGFloat = isPadLike ? 34 : 28

    static let writeWordsLoseTitleSize: CGFloat = isPadLike ? 34 : 28
    static let writeWordsLoseSubtitleSize: CGFloat = isPadLike ? 16 : 14
    static let writeWordsLoseBodyTextSize: CGFloat = isPadLike ? 16 : 14
    static let writeWordsLoseCaptionSize: CGFloat = isPadLike ? 15 : 13

    static let writeWordsLoseStatsPadding: CGFloat = isPadLike ? sectionSpacingPad : sectionSpacingPhone
    static let writeWordsLoseStatsSpacing: CGFloat = 8
    static let writeWordsLoseStatsCornerRadius: CGFloat = isPadLike ? 20 : 18

    static let writeWordsLoseActionsSpacing: CGFloat = 10
    static let writeWordsLosePrimaryButtonHeight: CGFloat = isPadLike ? 54 : 50
    static let writeWordsLoseSecondaryButtonHeight: CGFloat = isPadLike ? 52 : 48
    static let writeWordsLoseButtonCornerRadius: CGFloat = isPadLike ? 18 : 16

    static let writeWordsLoseHeaderSpacing: CGFloat = 8
    static let writeWordsLoseDividerHeight: CGFloat = 1

    static let writeWordsLoseBlobSize: CGFloat = isPadLike ? 360 : 260
}

// MARK: - Essay Practice Layout

extension Layout {
    static let essayContentMaxWidth: CGFloat = isPadLike ? 720 : .infinity
    static let essayScreenHorizontalPadding: CGFloat = isPadLike ? 28 : 20
    static let essayScreenVerticalPadding: CGFloat = isPadLike ? 28 : 20
    static let essayMainSpacing: CGFloat = isPadLike ? 22 : 16

    static let essayCardSpacing: CGFloat = isPadLike ? 18 : 14
    static let essayCardPadding: CGFloat = isPadLike ? 22 : 18
    static let essayCardCornerRadius: CGFloat = 24
    static let essayCardShadowRadius: CGFloat = 18
    static let essayCardShadowYOffset: CGFloat = 10

    static let essayTopicTitleSize: CGFloat = isPadLike ? 22 : 19
    static let essayTopicMetaSize: CGFloat = isPadLike ? 13 : 12
    static let essayTopicBodySize: CGFloat = isPadLike ? 16 : 14
    static let essayTopicSectionLabelSize: CGFloat = isPadLike ? 14 : 12
    static let essayTopicLevelBadgeSize: CGFloat = isPadLike ? 13 : 11
    static let essayTopicRefreshButtonSize: CGFloat = isPadLike ? 38 : 34
    static let essayTopicRefreshIconSize: CGFloat = isPadLike ? 16 : 14
    static let essayTipChipMinWidth: CGFloat = isPadLike ? 140 : 110
    static let essayTipChipTextSize: CGFloat = isPadLike ? 13 : 11

    static let essayWritingCardSpacing: CGFloat = isPadLike ? 14 : 12
    static let essayWritingTitleSize: CGFloat = isPadLike ? 20 : 17
    static let essayWordCountSize: CGFloat = isPadLike ? 13 : 12
    static let essayEditorPlaceholderSize: CGFloat = isPadLike ? 16 : 15
    static let essayEditorTextSize: CGFloat = isPadLike ? 17 : 15
    static let essayEditorMinHeight: CGFloat = isPadLike ? 260 : 220
    static let essayEditorCornerRadius: CGFloat = 20
    static let essayEditorScaleFocused: CGFloat = 1.01
    static let essayValidationTextSize: CGFloat = isPadLike ? 13 : 12
    static let essayButtonTextSize: CGFloat = isPadLike ? 15 : 14
    static let essayButtonVerticalPadding: CGFloat = isPadLike ? 14 : 13
    static let essayButtonCornerRadius: CGFloat = 16

    // MARK: - Essay Setup Section

    static let essaySetupSpacing: CGFloat = isPadLike ? 12 : 10
    static let essaySetupHeaderSpacing: CGFloat = 8
    static let essaySetupIconSize: CGFloat = isPadLike ? 15 : 13
    static let essaySetupTitleSize: CGFloat = isPadLike ? 16 : 15
    static let essayHintsBadgeTextSize: CGFloat = isPadLike ? 12 : 11
    static let essayHintsBadgeHorizontalPadding: CGFloat = 10
    static let essayHintsBadgeVerticalPadding: CGFloat = 6
    static let essaySetupSelectorColumnsSpacing: CGFloat = 12
    static let essaySetupSelectorStackSpacing: CGFloat = 10
    static let essayPrivacyNoticeTextSize: CGFloat = isPadLike ? 12 : 11
    static let essayPrivacyNoticeLineSpacing: CGFloat = 3
    static let essayPrivacyNoticeTopPadding: CGFloat = 2
    static let essaySetupCardOpacity: CGFloat = 0.58
    static let essaySetupShadowOpacity: CGFloat = 0.035
    static let essaySetupShadowRadius: CGFloat = 14
    static let essaySetupShadowYOffset: CGFloat = 8

    // MARK: - Essay Selectors

    static let essaySelectorOuterSpacing: CGFloat = 8
    static let essaySelectorButtonContentSpacing: CGFloat = 9
    static let essaySelectorIconSize: CGFloat = isPadLike ? 15 : 13
    static let essaySelectorLabelSpacing: CGFloat = 2
    static let essaySelectorLabelSize: CGFloat = isPadLike ? 11 : 10
    static let essaySelectorTitleSize: CGFloat = isPadLike ? 14 : 13
    static let essaySelectorBadgeTextSize: CGFloat = isPadLike ? 12 : 11
    static let essaySelectorBadgeHorizontalPadding: CGFloat = 8
    static let essaySelectorBadgeVerticalPadding: CGFloat = 5
    static let essaySelectorChevronSize: CGFloat = 11
    static let essaySelectorHorizontalPadding: CGFloat = isPadLike ? 16 : 14
    static let essaySelectorVerticalPadding: CGFloat = isPadLike ? 13 : 12
    static let essaySelectorCornerRadius: CGFloat = 18
    static let essaySelectorBorderWidth: CGFloat = 1
    static let essaySelectorShadowOpacity: CGFloat = 0.035
    static let essaySelectorShadowRadius: CGFloat = 12
    static let essaySelectorShadowYOffset: CGFloat = 7
    static let essaySelectorAnimationDuration: Double = 0.22

    static let essaySelectorOptionsSpacing: CGFloat = 6
    static let essaySelectorOptionsPadding: CGFloat = 8
    static let essaySelectorOptionContentSpacing: CGFloat = 10
    static let essaySelectorOptionHorizontalPadding: CGFloat = 12
    static let essaySelectorOptionVerticalPadding: CGFloat = 10
    static let essaySelectorOptionCornerRadius: CGFloat = 14
    static let essaySelectorOptionCodeWidth: CGFloat = 34
    static let essaySelectorOptionLevelWidth: CGFloat = 46
    static let essaySelectorOptionBadgeHeight: CGFloat = 26
    static let essaySelectorOptionBadgeTextSize: CGFloat = 11
    static let essaySelectorOptionTitleSize: CGFloat = isPadLike ? 14 : 13
    static let essaySelectorOptionSubtitleSize: CGFloat = isPadLike ? 12 : 11
    static let essaySelectorCheckmarkSize: CGFloat = 15
    static let essaySelectorOptionsShadowOpacity: CGFloat = 0.05
    static let essaySelectorOptionsShadowRadius: CGFloat = 14
    static let essaySelectorOptionsShadowYOffset: CGFloat = 8


    // MARK: - Essay Topic Mode

    static let essayTopicModeSpacing: CGFloat = isPadLike ? 14 : 10
    static let essayTopicModeButtonSpacing: CGFloat = 8
    static let essayTopicModeTextSize: CGFloat = isPadLike ? 14 : 13
    static let essayTopicModeButtonVerticalPadding: CGFloat = isPadLike ? 12 : 10
    static let essayTopicModeButtonCornerRadius: CGFloat = 16
    static let essayTopicModePickerPadding: CGFloat = 6
    static let essayTopicModePickerCornerRadius: CGFloat = 20

    // MARK: - Essay Helper Toolbar

    static let essayHelperToolbarSpacing: CGFloat = isPadLike ? 10 : 8
    static let essayHelperToolbarButtonSpacing: CGFloat = isPadLike ? 10 : 7
    static let essayHelperButtonInnerSpacing: CGFloat = isPadLike ? 6 : 4
    static let essayHelperButtonIconSize: CGFloat = isPadLike ? 18 : 15
    static let essayHelperButtonTitleSize: CGFloat = isPadLike ? 13 : 11
    static let essayHelperButtonSubtitleSize: CGFloat = isPadLike ? 11 : 9
    static let essayHelperButtonVerticalPadding: CGFloat = isPadLike ? 13 : 10
    static let essayHelperButtonCornerRadius: CGFloat = isPadLike ? 18 : 15
    static let essayHelperUsageTextSize: CGFloat = isPadLike ? 12 : 11

    // MARK: - Essay Hints

    static let essayHintListSpacing: CGFloat = isPadLike ? 10 : 8
    static let essayHintWordSize: CGFloat = isPadLike ? 15 : 14
    static let essayHintTranslationSize: CGFloat = isPadLike ? 12 : 11
    static let essayHintExampleSize: CGFloat = isPadLike ? 13 : 12
    static let essayHintItemPadding: CGFloat = isPadLike ? 14 : 12
    static let essayHintItemCornerRadius: CGFloat = 16

    // MARK: - Essay Custom Topic

    static let essayCustomTopicSpacing: CGFloat = isPadLike ? 12 : 10
    static let essayCustomTopicIconSize: CGFloat = isPadLike ? 16 : 14
    static let essayCustomTopicTitleSize: CGFloat = isPadLike ? 18 : 16
    static let essayCustomTopicTextSize: CGFloat = isPadLike ? 16 : 14
    static let essayCustomTopicMinHeight: CGFloat = isPadLike ? 92 : 76
    static let essayCustomTopicInnerPadding: CGFloat = isPadLike ? 16 : 14
    static let essayCustomTopicCornerRadius: CGFloat = 18

    // MARK: - Essay Assistance Modal

    static let essayModalDimOpacity: CGFloat = 0.22
    static let essayModalSpacing: CGFloat = isPadLike ? 18 : 14
    static let essayModalPadding: CGFloat = isPadLike ? 24 : 18
    static let essayModalMaxWidth: CGFloat = isPadLike ? 520 : .infinity
    static let essayModalCornerRadius: CGFloat = isPadLike ? 28 : 24
    static let essayModalIconBoxSize: CGFloat = isPadLike ? 48 : 42
    static let essayModalIconCornerRadius: CGFloat = 15
    static let essayModalIconSize: CGFloat = isPadLike ? 20 : 17
    static let essayModalTitleSize: CGFloat = isPadLike ? 22 : 19
    static let essayModalSubtitleSize: CGFloat = isPadLike ? 12 : 11
    static let essayModalCloseButtonSize: CGFloat = isPadLike ? 36 : 32
    static let essayModalCloseIconSize: CGFloat = isPadLike ? 13 : 11
    static let essayModalInputTextSize: CGFloat = isPadLike ? 16 : 14
    static let essayModalInputHorizontalPadding: CGFloat = isPadLike ? 16 : 14
    static let essayModalInputVerticalPadding: CGFloat = isPadLike ? 14 : 12
    static let essayModalInputCornerRadius: CGFloat = 17
    static let essayModalMessageTextSize: CGFloat = isPadLike ? 14 : 13
    static let essayModalResultPadding: CGFloat = isPadLike ? 14 : 12
    static let essayModalResultSpacing: CGFloat = 8
    static let essayModalResultCornerRadius: CGFloat = 16
    static let essayModalResultTitleSize: CGFloat = isPadLike ? 16 : 14
    static let essayModalResultDetailSize: CGFloat = isPadLike ? 13 : 12
    static let essayModalDefaultMaxWidthPhone: CGFloat = 420
    static let essayModalDefaultMaxWidthPad: CGFloat = 560
    static let essayModalSynonymMaxWidthPhone: CGFloat = 430
    static let essayModalSynonymMaxWidthPad: CGFloat = 640

    static let essayModalHeaderSpacing: CGFloat = 12
    static let essayModalTitleSpacing: CGFloat = 3
    static let essayModalUsageTextLineLimit: Int = 2
    static let essayModalUsageTextScale: CGFloat = 0.8

    static let essayModalInputBorderWidth: CGFloat = 1
    static let essayModalInputMinHeight: CGFloat = 58
    static let essayModalInputMinLines: Int = 1
    static let essayModalInputMaxLines: Int = 3

    static let essayModalResultAnimationDuration: Double = 0.16
    static let essayModalResultListVerticalPadding: CGFloat = 1
    static let essayModalResultRowSpacing: CGFloat = 4
    static let essayModalResultTitleLineLimit: Int = 2
    static let essayModalResultTitleScale: CGFloat = 0.85
    static let essayModalResultDetailLineSpacing: CGFloat = 3

    static let essayModalLoadingSpacing: CGFloat = 12
    static let essayModalLoadingCircleTrimStart: CGFloat = 0.14
    static let essayModalLoadingCircleTrimEnd: CGFloat = 0.86
    static let essayModalLoadingCircleLineWidth: CGFloat = 3
    static let essayModalLoadingCircleSize: CGFloat = 22
    static let essayModalLoadingCircleDuration: Double = 0.72

    static let essayModalActionsSpacing: CGFloat = 10
    static let essayModalLanguagePickerSpacing: CGFloat = 10
    static let essayModalLanguageArrowWidth: CGFloat = 18
    static let essayModalLanguageArrowSize: CGFloat = 13

    static let essayModalLanguagePillSpacing: CGFloat = 6
    static let essayModalLanguagePillTextSpacing: CGFloat = 2
    static let essayModalLanguagePillSpacerMinLength: CGFloat = 2
    static let essayModalLanguagePillTitleSize: CGFloat = 10
    static let essayModalLanguagePillTextSize: CGFloat = 13
    static let essayModalLanguagePillCodeSize: CGFloat = 12
    static let essayModalLanguagePillChevronSize: CGFloat = 11
    static let essayModalLanguagePillHorizontalPadding: CGFloat = 12
    static let essayModalLanguagePillVerticalPadding: CGFloat = 10
    static let essayModalLanguagePillMinHeight: CGFloat = 76
    static let essayModalLanguagePillCornerRadius: CGFloat = 18
    static let essayModalLanguagePillCodeHorizontalPadding: CGFloat = 8
    static let essayModalLanguagePillCodeVerticalPadding: CGFloat = 6
    static let essayModalLanguageTextScale: CGFloat = 0.62

    static let essayModalTranslateResultsMaxHeight: CGFloat = 120
    static let essayModalHintResultsMaxHeight: CGFloat = 160
    static let essayModalSynonymResultsMaxHeightPhone: CGFloat = 110
    static let essayModalSynonymResultsMaxHeightPad: CGFloat = 280

    // MARK: - Essay Feedback / Score

    static let essayFeedbackSectionSpacing: CGFloat = isPadLike ? 14 : 12
    static let essayFeedbackTitleSize: CGFloat = isPadLike ? 20 : 17
    static let essayFeedbackCardSpacing: CGFloat = isPadLike ? 12 : 10
    static let essayFeedbackCardPadding: CGFloat = isPadLike ? 18 : 16
    static let essayFeedbackCardCornerRadius: CGFloat = 20
    static let essayFeedbackIconBoxSize: CGFloat = isPadLike ? 42 : 38
    static let essayFeedbackIconSize: CGFloat = isPadLike ? 18 : 16
    static let essayFeedbackEmptyTitleSize: CGFloat = isPadLike ? 16 : 15
    static let essayFeedbackBodySize: CGFloat = isPadLike ? 14 : 13
    static let essayFeedbackScoreMiniValueSize: CGFloat = isPadLike ? 18 : 16
    static let essayFeedbackScoreMiniLabelSize: CGFloat = isPadLike ? 11 : 10

    static let essayScoreCardSpacing: CGFloat = isPadLike ? 16 : 13
    static let essayScoreCardPadding: CGFloat = isPadLike ? 20 : 16
    static let essayScoreCardCornerRadius: CGFloat = 22
    static let essayScoreHeaderSpacing: CGFloat = 12
    static let essayScoreTitleSize: CGFloat = isPadLike ? 18 : 16
    static let essayScoreQualitySize: CGFloat = isPadLike ? 14 : 12
    static let essayScoreValueSize: CGFloat = isPadLike ? 36 : 30
    static let essayScoreLevelSize: CGFloat = isPadLike ? 13 : 11
    static let essayScoreBreakdownSpacing: CGFloat = isPadLike ? 11 : 9
    static let essayScoreRowTitleSize: CGFloat = isPadLike ? 13 : 12
    static let essayScoreRowValueSize: CGFloat = isPadLike ? 13 : 12
    static let essayScoreProgressHeight: CGFloat = isPadLike ? 8 : 6
    static let essayScoreStatMinWidth: CGFloat = isPadLike ? 116 : 92
    static let essayScoreStatValueSize: CGFloat = isPadLike ? 16 : 14
    static let essayScoreStatTitleSize: CGFloat = isPadLike ? 11 : 10
    static let essayScoreStatVerticalPadding: CGFloat = isPadLike ? 10 : 8
    static let essayScoreStatCornerRadius: CGFloat = 14

}


// MARK: - Generic pad/phone picker

extension Layout {
    /// Returns `pad` when on iPad/wide screen, `phone` otherwise.
    /// Replaces the old DeviceLayout.value(pad:phone:) helper.
    @inlinable
    static func value<T>(pad: T, phone: T) -> T {
        isPadLike ? pad : phone
    }
}

// MARK: - Grammar Note Editor

extension Layout {
    static let grammarNoteHorizontalPadding: CGFloat      = isPadLike ? 28 : 20
    static let grammarNoteTopPadding: CGFloat              = isPadLike ? 20 : 14
    static let grammarNoteBlockSpacing: CGFloat            = isPadLike ? 16 : 13
    static let grammarNoteBlockPadding: CGFloat            = isPadLike ? 16 : 14
    static let grammarNoteBlockCornerRadius: CGFloat       = isPadLike ? 24 : 21

    static let grammarNoteHeadingSize: CGFloat             = isPadLike ? 26 : 22
    static let grammarNoteSubheadingSize: CGFloat          = isPadLike ? 20 : 18

    static let grammarNoteCardCornerRadius: CGFloat        = isPadLike ? 25 : 22
    static let grammarNoteCardHorizontalPadding: CGFloat   = isPadLike ? 18 : 15
    static let grammarNoteCardVerticalPadding: CGFloat     = isPadLike ? 17 : 15
    static let grammarNoteCardIconSize: CGFloat            = isPadLike ? 52 : 46
    static let grammarNoteCardIconImageSize: CGFloat       = isPadLike ? 21 : 18
    static let grammarNoteCardTitleSize: CGFloat           = isPadLike ? 17 : 15
    static let grammarNoteCardPreviewSize: CGFloat         = isPadLike ? 14 : 12
    static let grammarNoteCardChevronSize: CGFloat         = isPadLike ? 15 : 13

    static let grammarNoteCreateSpacing: CGFloat           = isPadLike ? 18 : 14
    static let grammarNoteCreatePadding: CGFloat           = isPadLike ? 28 : 20
    static let grammarNoteCreateTitleSize: CGFloat         = isPadLike ? 28 : 24
    static let grammarNoteCreateSubtitleSize: CGFloat      = isPadLike ? 15 : 13
    static let grammarNoteCreateFieldHeight: CGFloat       = isPadLike ? 58 : 52
    static let grammarNoteCreateFieldFontSize: CGFloat     = isPadLike ? 16 : 14
    static let grammarNoteCreatePreviewMinHeight: CGFloat  = isPadLike ? 112 : 96
    static let grammarNoteCreateTypeMinWidth: CGFloat      = isPadLike ? 150 : 126
    
    // MARK: - Grammar Notes FAB
    static let grammarNotesFABSize: CGFloat = isPadLike ? 70 : 58
    static let grammarNotesFABIconSize: CGFloat = isPadLike ? 30 : 25
    static let grammarNotesFABTrailingPadding: CGFloat = isPadLike ? 34 : 22
    static let grammarNotesFABBottomPadding: CGFloat = isPadLike ? 38 : 26
    static let grammarNotesFABDimOpacity: CGFloat = 0.10
    static let grammarNotesFABMenuSpacing: CGFloat = isPadLike ? 14 : 11
    static let grammarNotesFABMenuItemSpacing: CGFloat = isPadLike ? 10 : 8
    static let grammarNotesFABMenuPadding: CGFloat = isPadLike ? 13 : 11
    static let grammarNotesFABMenuWidth: CGFloat = isPadLike ? 250 : 218
    static let grammarNotesFABMenuCornerRadius: CGFloat = isPadLike ? 28 : 24
    static let grammarNotesFABMenuRowHeight: CGFloat = isPadLike ? 56 : 50
    static let grammarNotesFABMenuRowCornerRadius: CGFloat = isPadLike ? 20 : 17
    static let grammarNotesFABMenuIconBox: CGFloat = isPadLike ? 36 : 32
    static let grammarNotesFABMenuIconSize: CGFloat = isPadLike ? 15 : 13
    static let grammarNotesFABMenuTitleSize: CGFloat = isPadLike ? 15 : 13
    static let grammarNotesFABItemDelay: Double = 0.035
    static let grammarNotesFABSpring: Animation = .spring(response: 0.34, dampingFraction: 0.86)

    // MARK: - Quick Grammar Sheets
    static let grammarQuickSheetMaxWidth: CGFloat = isPadLike ? 620 : .infinity
    static let grammarQuickSheetPadding: CGFloat = isPadLike ? 24 : 18
    static let grammarQuickSheetSectionSpacing: CGFloat = isPadLike ? 15 : 12
    static let grammarQuickMiniSectionSpacing: CGFloat = isPadLike ? 12 : 10
    static let grammarQuickSheetAnimation: Animation = .easeInOut(duration: 0.22)
    static let grammarQuickNoteSheetHeight: CGFloat = isPadLike ? 720 : 660
    static let grammarQuickMistakeSheetHeight: CGFloat = isPadLike ? 780 : 720

    static let grammarQuickHeaderIconBox: CGFloat = isPadLike ? 52 : 46
    static let grammarQuickHeaderIconSize: CGFloat = isPadLike ? 21 : 18
    static let grammarQuickTitleSize: CGFloat = isPadLike ? 28 : 23
    static let grammarQuickSubtitleSize: CGFloat = isPadLike ? 14 : 12

    static let grammarQuickSectionCornerRadius: CGFloat = isPadLike ? 24 : 21
    static let grammarQuickSectionTitleSize: CGFloat = isPadLike ? 15 : 13
    static let grammarQuickHelperSize: CGFloat = isPadLike ? 12 : 11
    static let grammarQuickFieldCornerRadius: CGFloat = isPadLike ? 19 : 17
    static let grammarQuickTitleFieldHeight: CGFloat = isPadLike ? 56 : 50
    static let grammarQuickTitleFieldSize: CGFloat = isPadLike ? 18 : 16
    static let grammarQuickEditorTextSize: CGFloat = isPadLike ? 15 : 14
    static let grammarQuickNoteEditorMinHeight: CGFloat = isPadLike ? 128 : 112
    static let grammarQuickMistakeExplanationHeight: CGFloat = isPadLike ? 106 : 92
    static let grammarQuickTypeMinWidth: CGFloat = isPadLike ? 135 : 112
    static let grammarQuickActionHeight: CGFloat = isPadLike ? 54 : 50
    static let grammarQuickActionCornerRadius: CGFloat = isPadLike ? 19 : 17

    // MARK: - Grammar Empty States
    static let grammarEmptyStateSpacing: CGFloat = isPadLike ? 18 : 15
    static let grammarEmptyStatePadding: CGFloat = isPadLike ? 28 : 22
    static let grammarEmptyStateCornerRadius: CGFloat = isPadLike ? 30 : 26
    static let grammarEmptyStateOuterIconSize: CGFloat = isPadLike ? 116 : 96
    static let grammarEmptyStateInnerIconSize: CGFloat = isPadLike ? 82 : 70
    static let grammarEmptyStateIconSize: CGFloat = isPadLike ? 34 : 28
    static let grammarEmptyStateSparkleSize: CGFloat = isPadLike ? 18 : 15
    static let grammarEmptyStateTitleSize: CGFloat = isPadLike ? 27 : 22
    static let grammarEmptyStateMessageSize: CGFloat = isPadLike ? 15 : 13
    static let grammarEmptyStateTextMaxWidth: CGFloat = isPadLike ? 430 : 310
    static let grammarEmptyStateButtonTextSize: CGFloat = isPadLike ? 15 : 13
    static let grammarEmptyStateButtonHorizontalPadding: CGFloat = isPadLike ? 22 : 18
    static let grammarEmptyStateButtonHeight: CGFloat = isPadLike ? 52 : 47
    static let grammarEmptyStateButtonCornerRadius: CGFloat = isPadLike ? 18 : 16
    static let grammarEmptyStateBlobWidth: CGFloat = isPadLike ? 170 : 130
    static let grammarEmptyStateBlobHeight: CGFloat = isPadLike ? 135 : 102
    static let grammarEmptyStateBlobOffsetX: CGFloat = isPadLike ? 58 : 44
    static let grammarEmptyStateBlobOffsetY: CGFloat = isPadLike ? -42 : -34

    // MARK: - Grammar Settings
    static let grammarSettingsContentMaxWidth: CGFloat = isPadLike ? 690 : .infinity
    static let grammarSettingsHorizontalPadding: CGFloat = isPadLike ? 32 : 18
    static let grammarSettingsTopPadding: CGFloat = isPadLike ? 26 : 16
    static let grammarSettingsBottomPadding: CGFloat = isPadLike ? 42 : 30
    static let grammarSettingsSectionSpacing: CGFloat = isPadLike ? 18 : 14
    static let grammarSettingsBackButtonSize: CGFloat = isPadLike ? 48 : 42
    static let grammarSettingsBackIconSize: CGFloat = isPadLike ? 17 : 15
    static let grammarSettingsTitleSize: CGFloat = isPadLike ? 32 : 26
    static let grammarSettingsSubtitleSize: CGFloat = isPadLike ? 15 : 13

    static let grammarSettingsCardPadding: CGFloat = isPadLike ? 20 : 16
    static let grammarSettingsCardCornerRadius: CGFloat = isPadLike ? 28 : 24
    static let grammarSettingsCardInnerSpacing: CGFloat = isPadLike ? 15 : 12
    static let grammarSettingsSectionIconBox: CGFloat = isPadLike ? 46 : 40
    static let grammarSettingsSectionIconSize: CGFloat = isPadLike ? 18 : 16
    static let grammarSettingsSectionTitleSize: CGFloat = isPadLike ? 18 : 16
    static let grammarSettingsSectionSubtitleSize: CGFloat = isPadLike ? 13 : 12

    static let grammarSettingsRowPadding: CGFloat = isPadLike ? 14 : 12
    static let grammarSettingsRowCornerRadius: CGFloat = isPadLike ? 20 : 18
    static let grammarSettingsRowIconBox: CGFloat = isPadLike ? 38 : 34
    static let grammarSettingsRowTitleSize: CGFloat = isPadLike ? 15 : 13
    static let grammarSettingsRowSubtitleSize: CGFloat = isPadLike ? 12 : 11
    static let grammarSettingsTypeMinWidth: CGFloat = isPadLike ? 130 : 104
    static let grammarSettingsTypeButtonHeight: CGFloat = isPadLike ? 92 : 82
}



