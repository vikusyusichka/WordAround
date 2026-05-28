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
    static let allModes: [SpeakingMode] = [
        SpeakingMode(
            id: "ai-conversation",
            title: "AI Conversation",
            subtitle: "Talk with an AI tutor in real-time.",
            systemImage: "bubble.left.and.bubble.right.fill",
            accentColor: AppColors.primaryBlue,
            blobColor: AppColors.blobBlue
        ),
        SpeakingMode(
            id: "free-speaking",
            title: "Free Speaking",
            subtitle: "Speak on generated topics and get feedback.",
            systemImage: "mic.fill",
            accentColor: AppColors.greenAccent,
            blobColor: AppColors.blobGreen
        ),
        SpeakingMode(
            id: "describe-picture",
            title: "Describe Picture",
            subtitle: "Describe images and learn useful vocabulary.",
            systemImage: "photo.fill",
            accentColor: AppColors.orangeAccent,
            blobColor: AppColors.blobYellow
        ),
        SpeakingMode(
            id: "debate-mode",
            title: "Debate Mode",
            subtitle: "Discuss topics and build your arguments.",
            systemImage: "person.2.fill",
            accentColor: Color(red: 0.93, green: 0.40, blue: 0.60),
            blobColor: AppColors.blobPink
        ),
        SpeakingMode(
            id: "shadowing",
            title: "Shadowing",
            subtitle: "Repeat phrases and improve pronunciation.",
            systemImage: "headphones",
            accentColor: Color(red: 0.54, green: 0.36, blue: 0.88),
            blobColor: Color(red: 0.90, green: 0.84, blue: 0.98)
        ),
        SpeakingMode(
            id: "pronunciation",
            title: "Pronunciation Trainer",
            subtitle: "Focus on difficult sounds and words.",
            systemImage: "waveform",
            accentColor: Color(red: 0.18, green: 0.72, blue: 0.80),
            blobColor: Color(red: 0.80, green: 0.94, blue: 0.96)
        )
    ]
}
