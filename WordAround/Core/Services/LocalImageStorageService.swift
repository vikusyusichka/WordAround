import Foundation
import UIKit

final class LocalImageStorageService {
    func saveImage(_ image: UIImage, fileName: String) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.75) else {
            throw NSError(
                domain: "ImageCompression",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Could not convert image to JPEG."]
            )
        }

        let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        try data.write(to: fileURL)

        return fileName
    }

    func loadImage(fileName: String) -> UIImage? {
        let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        return UIImage(contentsOfFile: fileURL.path)
    }

    func deleteImage(fileName: String) {
        let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]

        let fileURL = documentsDirectory.appendingPathComponent(fileName)

        try? FileManager.default.removeItem(at: fileURL)
    }
}
