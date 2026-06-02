import Foundation

protocol ListeningTranscriptionServicing {
    func transcribeVideo(
        fileURL: URL,
        language: GrammarLanguage,
        level: EssayDifficulty
    ) async throws -> ListeningTranscriptionResponse
}

struct CloudflareListeningTranscriptionService: ListeningTranscriptionServicing {
    static let defaultBaseURL = "https://wordaround-gemini-proxy.vikusyusichka-ai.workers.dev"

    private let endpoint: URL
    private let session: URLSession

    init(baseURL: String = CloudflareListeningTranscriptionService.defaultBaseURL,
         session: URLSession? = nil) {
        self.endpoint = URL(string: baseURL.appending("/api/listening/transcribe"))!
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 300
            config.timeoutIntervalForResource = 600
            self.session = URLSession(configuration: config)
        }
    }

    func transcribeVideo(
        fileURL: URL,
        language: GrammarLanguage,
        level: EssayDifficulty
    ) async throws -> ListeningTranscriptionResponse {
        let boundary = "WAUpload-\(UUID().uuidString)"
        let bodyURL: URL
        do {
            bodyURL = try ListeningMultipartBuilder.makeBody(
                boundary: boundary,
                fileURL: fileURL,
                fields: [
                    "language": language.shortTitle.lowercased(),
                    "level": level.rawValue,
                    "mode": "importVideo",
                ]
            )
        } catch {
            throw ListeningTranscriptionError.failed("Could not prepare the upload.")
        }
        defer { try? FileManager.default.removeItem(at: bodyURL) }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.upload(for: request, fromFile: bodyURL)
        } catch {
            throw ListeningTranscriptionError.failed("Upload failed. Check your connection and try again.")
        }

        guard let http = response as? HTTPURLResponse else {
            throw ListeningTranscriptionError.failed("No response from the transcription service.")
        }
        guard (200..<300).contains(http.statusCode) else {
            let message = (try? JSONDecoder().decode(WorkerError.self, from: data))?.error
            if http.statusCode == 413 {
                throw ListeningTranscriptionError.failed(message ?? "That file is too large to transcribe.")
            }
            throw ListeningTranscriptionError.failed(message ?? "Transcription failed (\(http.statusCode)).")
        }

        let decoded: ListeningTranscriptionResponse
        do {
            decoded = try JSONDecoder().decode(ListeningTranscriptionResponse.self, from: data)
        } catch {
            throw ListeningTranscriptionError.failed("Transcription returned an unexpected response.")
        }
        guard decoded.hasUsableTranscript else {
            throw ListeningTranscriptionError.emptyTranscript
        }
        return decoded
    }

    private struct WorkerError: Decodable { let error: String }
}

struct MockListeningTranscriptionService: ListeningTranscriptionServicing {
    var transcript: String = ListeningPlaceholderData.sampleText
    var delayNanoseconds: UInt64 = 800_000_000

    func transcribeVideo(
        fileURL: URL,
        language: GrammarLanguage,
        level: EssayDifficulty
    ) async throws -> ListeningTranscriptionResponse {
        try? await Task.sleep(nanoseconds: delayNanoseconds)
        let cues = ListeningSubtitleBuilder.estimatedCues(transcript: transcript, totalDuration: 60)
        return ListeningTranscriptionResponse(
            transcriptText: transcript,
            subtitles: cues,
            vttText: nil,
            detectedLanguage: language.shortTitle.lowercased(),
            durationSeconds: 60
        )
    }
}

enum ListeningMultipartBuilder {
    static func makeBody(boundary: String, fileURL: URL, fields: [String: String]) throws -> URL {
        let fm = FileManager.default
        let bodyURL = fm.temporaryDirectory.appendingPathComponent("wa-upload-\(UUID().uuidString).bin")
        fm.createFile(atPath: bodyURL.path, contents: nil)

        let handle = try FileHandle(forWritingTo: bodyURL)
        defer { try? handle.close() }

        func write(_ string: String) throws {
            if let data = string.data(using: .utf8) { try handle.write(contentsOf: data) }
        }

        for (key, value) in fields {
            try write("--\(boundary)\r\n")
            try write("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            try write("\(value)\r\n")
        }

        let fileName = fileURL.lastPathComponent
        let mime = mimeType(for: fileURL.pathExtension.lowercased())
        try write("--\(boundary)\r\n")
        try write("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
        try write("Content-Type: \(mime)\r\n\r\n")

        let source = try FileHandle(forReadingFrom: fileURL)
        defer { try? source.close() }
        let chunkSize = 1024 * 1024
        while true {
            let chunk = try source.read(upToCount: chunkSize) ?? Data()
            if chunk.isEmpty { break }
            try handle.write(contentsOf: chunk)
        }

        try write("\r\n--\(boundary)--\r\n")
        return bodyURL
    }

    static func mimeType(for ext: String) -> String {
        switch ext {
        case "mp4":  return "video/mp4"
        case "m4v":  return "video/x-m4v"
        case "mov":  return "video/quicktime"
        case "m4a":  return "audio/mp4"
        case "wav":  return "audio/wav"
        case "mp3":  return "audio/mpeg"
        case "aac":  return "audio/aac"
        default:     return "application/octet-stream"
        }
    }
}
