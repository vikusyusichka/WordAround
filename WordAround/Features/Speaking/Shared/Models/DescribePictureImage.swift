import Foundation

struct DescribePictureImage: Codable, Identifiable, Equatable {
    let id: String
    let imageURL: String
    let authorName: String
    let authorURL: String

    var url: URL? { URL(string: imageURL) }
    var attribution: String { "Photo by \(authorName)" }
}
