import Foundation

enum ReadingTextImportSource: String, CaseIterable, Identifiable, Codable, Equatable {
    case pasteText
    case photo
    case pdf

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pasteText: return "Paste Text"
        case .photo: return "Photo"
        case .pdf: return "PDF"
        }
    }

    static var segmentTitles: [String] { allCases.map(\.title) }

    static func from(title: String) -> ReadingTextImportSource {
        allCases.first { $0.title == title } ?? .pasteText
    }
}
