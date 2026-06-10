import SwiftUI

struct SpeakingMode: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let accentColor: Color
    let blobColor: Color
}

extension SpeakingMode {
    static var allModes: [SpeakingMode] {
        [
        SpeakingMode(
            id: "ai-conversation",
            title: L10n.string("speakingModeAITitle"),
            subtitle: L10n.string("speakingModeAISubtitle"),
            systemImage: "bubble.left.and.bubble.right.fill",
            accentColor: AppColors.primaryBlue,
            blobColor: AppColors.blobBlue
        ),
        SpeakingMode(
            id: "free-speaking",
            title: L10n.string("speakingModeFreeTitle"),
            subtitle: L10n.string("speakingModeFreeSubtitle"),
            systemImage: "mic.fill",
            accentColor: AppColors.greenAccent,
            blobColor: AppColors.blobGreen
        ),
        SpeakingMode(
            id: "describe-picture",
            title: L10n.string("speakingModePictureTitle"),
            subtitle: L10n.string("speakingModePictureSubtitle"),
            systemImage: "photo.fill",
            accentColor: AppColors.orangeAccent,
            blobColor: AppColors.blobYellow
        ),
        SpeakingMode(
            id: "debate-mode",
            title: L10n.string("speakingModeDebateTitle"),
            subtitle: L10n.string("speakingModeDebateSubtitle"),
            systemImage: "person.2.fill",
            accentColor: Color(red: 0.93, green: 0.40, blue: 0.60),
            blobColor: AppColors.blobPink
        ),
        SpeakingMode(
            id: "shadowing",
            title: L10n.string("speakingModeShadowingTitle"),
            subtitle: L10n.string("speakingModeShadowingSubtitle"),
            systemImage: "headphones",
            accentColor: Color(red: 0.54, green: 0.36, blue: 0.88),
            blobColor: Color(red: 0.90, green: 0.84, blue: 0.98)
        ),
        SpeakingMode(
            id: "pronunciation",
            title: L10n.string("speakingModePronunciationTitle"),
            subtitle: L10n.string("speakingModePronunciationSubtitle"),
            systemImage: "waveform",
            accentColor: Color(red: 0.18, green: 0.72, blue: 0.80),
            blobColor: Color(red: 0.80, green: 0.94, blue: 0.96)
        )
        ]
    }
}
