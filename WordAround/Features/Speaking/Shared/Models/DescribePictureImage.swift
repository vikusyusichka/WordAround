import Foundation

/// A single picture for the Describe Picture speaking mode.
/// Mirrors the simplified JSON returned by the Worker's
/// `/api/describe-picture/random-image` endpoint.
struct DescribePictureImage: Codable, Identifiable, Equatable {
    let id: String
    let imageURL: String
    let authorName: String
    let authorURL: String

    var url: URL? { URL(string: imageURL) }
    var attribution: String { "Photo by \(authorName)" }
}
