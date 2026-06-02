import Foundation

struct PronunciationAttempt: Identifiable, Equatable {
    let id: UUID
    let itemId: UUID
    let targetText: String
    let recognizedText: String
    let assessment: PronunciationAssessmentResult
    let createdAt: Date

    init(
        id: UUID = UUID(),
        itemId: UUID,
        targetText: String,
        recognizedText: String,
        assessment: PronunciationAssessmentResult,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.itemId = itemId
        self.targetText = targetText
        self.recognizedText = recognizedText
        self.assessment = assessment
        self.createdAt = createdAt
    }

    var score: Int { Int(assessment.pronunciationScore.rounded()) }
}
