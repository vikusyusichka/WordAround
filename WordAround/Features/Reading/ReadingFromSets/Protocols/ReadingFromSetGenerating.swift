import Foundation

protocol ReadingFromSetGenerating: Sendable {
    func generateReading(from request: ReadingFromSetGenerationRequest) async throws -> ReadingGeneratedReadingText
}
