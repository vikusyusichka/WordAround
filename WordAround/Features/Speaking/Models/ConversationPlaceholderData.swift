import SwiftUI

struct ConversationMetric: Identifiable {
    let id = UUID()
    let title: String
    let rating: String
    let icon: String
    let accentColor: Color
    let blobColor: Color
}

extension ConversationMetric {
    static let placeholderMetrics: [ConversationMetric] = [
        ConversationMetric(
            title: "Grammar",
            rating: "Good",
            icon: "checkmark.circle.fill",
            accentColor: AppColors.primaryBlue,
            blobColor: AppColors.blobBlue
        ),
        ConversationMetric(
            title: "Pronunciation",
            rating: "Good",
            icon: "mic.fill",
            accentColor: AppColors.greenAccent,
            blobColor: AppColors.blobGreen
        ),
        ConversationMetric(
            title: "Vocabulary",
            rating: "Great",
            icon: "text.book.closed.fill",
            accentColor: AppColors.orangeAccent,
            blobColor: AppColors.blobYellow
        ),
        ConversationMetric(
            title: "Fluency",
            rating: "Good",
            icon: "waveform",
            accentColor: Color(red: 0.54, green: 0.36, blue: 0.88),
            blobColor: Color(red: 0.90, green: 0.84, blue: 0.98)
        ),
    ]
}

struct ConversationCorrection: Identifiable {
    let id = UUID()
    let youSaid: String
    let better: String
    let explanation: String
}

extension ConversationCorrection {
    static let placeholderCorrections: [ConversationCorrection] = [
        ConversationCorrection(
            youSaid: "I very like coffee.",
            better: "I really like coffee.",
            explanation: "Use \"really\" before \"like\" to sound more natural."
        ),
        ConversationCorrection(
            youSaid: "Could I have a chocolate cake?",
            better: "Could I have a slice of chocolate cake?",
            explanation: "Use \"a slice of\" when ordering part of a whole cake."
        ),
    ]
}
