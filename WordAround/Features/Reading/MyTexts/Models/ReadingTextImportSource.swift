import Foundation

enum ReadingTextImportSource: String, CaseIterable, Identifiable, Codable, Equatable {
    case pasteText
    case photo
    case pdf
    case generate
    case explore

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pasteText: return "Paste"
        case .photo:     return "Photo"
        case .pdf:       return "PDF"
        case .generate:  return "Generate"
        case .explore:   return "Explore"
        }
    }

    var sectionTitle: String {
        switch self {
        case .pasteText: return "Paste Text"
        case .photo:     return "Photo OCR"
        case .pdf:       return "Import PDF"
        case .generate:  return "Generate Text"
        case .explore:   return "Explore Reading"
        }
    }

    var sectionSubtitle: String {
        switch self {
        case .pasteText: return "Paste a text you already have."
        case .photo:     return "Capture a page or photo and we'll extract the text."
        case .pdf:       return "Import a PDF file and we'll extract the text."
        case .generate:  return "Create a reading text from a topic."
        case .explore:   return "Find or fetch a text from a topic."
        }
    }

    static var segmentTitles: [String] { allCases.map(\.title) }

    static func from(title: String) -> ReadingTextImportSource {
        allCases.first { $0.title == title } ?? .pasteText
    }
}
