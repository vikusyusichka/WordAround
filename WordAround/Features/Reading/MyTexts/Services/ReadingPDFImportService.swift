import Foundation
import PDFKit

enum ReadingPDFImportError: LocalizedError {
    case unsupported
    case noTextFound
    case cancelled

    var errorDescription: String? {
        switch self {
        case .unsupported: return "This PDF could not be opened. Try another file."
        case .noTextFound: return "No readable text was found in this PDF."
        case .cancelled: return "Import cancelled."
        }
    }
}

struct ReadingPDFImportService: ReadingPDFImportServicing, Sendable {
    static let shared = ReadingPDFImportService()

    func extractText(from url: URL) throws -> String {
        guard url.startAccessingSecurityScopedResource() else {
            throw ReadingPDFImportError.unsupported
        }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let document = PDFDocument(url: url) else {
            throw ReadingPDFImportError.unsupported
        }

        var parts: [String] = []
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index),
                  let pageText = page.string?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !pageText.isEmpty else { continue }
            parts.append(pageText)
        }

        let combined = parts.joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !combined.isEmpty else { throw ReadingPDFImportError.noTextFound }
        return combined
    }
}
