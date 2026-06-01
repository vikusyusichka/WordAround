import Foundation

enum SpeedReadingGenerationError: LocalizedError {
    case notConfigured
    case network(String)
    case serverError(Int, String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Speed Reading generation isn't available right now."
        case .network:
            return "Couldn't reach the server. Check your connection and try again."
        case .serverError:
            return "The server couldn't create the reading. Please try again."
        case .emptyResponse:
            return "The reading came back empty. Please try again."
        }
    }
}

// MARK: - AI client

protocol SpeedReadingAIClienting: Sendable {
    func complete(prompt: String, task: String, maxTokens: Int) async throws -> String
}

struct CloudflareSpeedReadingAIClient: SpeedReadingAIClienting {
    private let session: URLSession
    private let endpointURL: URL?
    private let timeoutInterval: TimeInterval

    init(
        session: URLSession = .shared,
        endpointURL: URL? = GrammarQuizAIConfiguration.endpointURL,
        timeoutInterval: TimeInterval = 45
    ) {
        self.session = session
        self.endpointURL = endpointURL
        self.timeoutInterval = timeoutInterval
    }

    private struct WorkerRequest: Encodable {
        let prompt: String
        let task: String
    }

    private struct WorkerResponse: Decodable {
        let text: String?
        let error: String?
    }

    func complete(prompt: String, task: String, maxTokens: Int) async throws -> String {
        guard let endpointURL else { throw SpeedReadingGenerationError.notConfigured }

        var request = URLRequest(url: endpointURL, timeoutInterval: timeoutInterval)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(WorkerRequest(prompt: prompt, task: task))

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw SpeedReadingGenerationError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw SpeedReadingGenerationError.serverError(-1, "")
        }

        let envelope = try? JSONDecoder().decode(WorkerResponse.self, from: data)

        guard (200...299).contains(http.statusCode) else {
            throw SpeedReadingGenerationError.serverError(http.statusCode, envelope?.error ?? "")
        }

        let text = envelope?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !text.isEmpty else { throw SpeedReadingGenerationError.emptyResponse }
        return text
    }
}

// MARK: - Service

struct SpeedReadingGenerated: Equatable {
    let text: String
    let chunks: [String]
}

protocol SpeedReadingGenerating: Sendable {
    func generateReading(for configuration: SpeedReadingConfiguration) async throws -> SpeedReadingGenerated
}

struct SpeedReadingGenerationService: SpeedReadingGenerating {
    private let client: SpeedReadingAIClienting
    private let analyzer: ReadingTextAnalyzing

    init(
        client: SpeedReadingAIClienting = CloudflareSpeedReadingAIClient(),
        analyzer: ReadingTextAnalyzing = ReadingTextAnalyzerService.shared
    ) {
        self.client = client
        self.analyzer = analyzer
    }

    func generateReading(for configuration: SpeedReadingConfiguration) async throws -> SpeedReadingGenerated {
        let prompt = SpeedReadingPromptBuilder.prompt(for: configuration)
        let maxTokens = max(700, configuration.targetWordCount * 3)
        let raw = try await client.complete(prompt: prompt, task: "speed_reading", maxTokens: maxTokens)
        let cleaned = ReadingTextNormalizationService.normalize(raw)
        guard !cleaned.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SpeedReadingGenerationError.emptyResponse
        }
        let chunks = Self.makeChunks(from: cleaned, configuration: configuration, analyzer: analyzer)
        return SpeedReadingGenerated(text: cleaned, chunks: chunks)
    }

    // MARK: - Chunking

    static func makeChunks(
        from text: String,
        configuration: SpeedReadingConfiguration,
        analyzer: ReadingTextAnalyzing = ReadingTextAnalyzerService.shared
    ) -> [String] {
        let paragraphs = ReadingTextNormalizationService.paragraphs(from: text)
        guard !paragraphs.isEmpty else { return [text] }

        let target = max(20, configuration.wordsPerChunk)
        var chunks: [String] = []
        var current = ""
        var currentWords = 0

        func flush() {
            let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { chunks.append(trimmed) }
            current = ""
            currentWords = 0
        }

        for paragraph in paragraphs {
            let words = analyzer.wordCount(for: paragraph)
            if words >= Int(Double(target) * 1.6) {
                flush()
                let sentences = analyzer.sentences(from: paragraph)
                for sentence in sentences {
                    let sentenceWords = analyzer.wordCount(for: sentence)
                    if currentWords + sentenceWords > target && !current.isEmpty {
                        flush()
                    }
                    current += (current.isEmpty ? "" : " ") + sentence
                    currentWords += sentenceWords
                }
                flush()
                continue
            }

            if currentWords + words > Int(Double(target) * 1.4) && !current.isEmpty {
                flush()
            }
            current += (current.isEmpty ? "" : "\n\n") + paragraph
            currentWords += words
        }
        flush()

        return chunks.isEmpty ? [text] : chunks
    }
}

// MARK: - Prompt builder

enum SpeedReadingPromptBuilder {
    static func prompt(for configuration: SpeedReadingConfiguration) -> String {
        let language = configuration.language.title
        let band = configuration.length.wordCountRange
        var lines: [String] = []
        lines.append("Write a self-contained non-fiction reading passage in \(language) for a speed-reading practice session.")
        lines.append("Target length: about \(configuration.targetWordCount) words (between \(band.lowerBound) and \(band.upperBound)).")
        lines.append("Pick an engaging everyday topic — science, culture, history, technology, nature, or daily life.")
        lines.append("Use clear paragraphs separated by a blank line. Avoid lists, headings, dialogue, and quoted speech.")
        lines.append("Aim for clean, even sentence rhythm so the reader can sustain pace.")
        lines.append("Use vocabulary appropriate for an upper-intermediate learner of \(language).")
        lines.append("")
        lines.append("Formatting rules — follow exactly:")
        lines.append("- Return only the passage.")
        lines.append("- No markdown, no bold, no italics, no headings, no bullet points.")
        lines.append("- Do not write a title.")
        lines.append("- Do not include intros, outros, or notes to the reader.")
        return lines.joined(separator: "\n")
    }
}

// MARK: - Mock (previews / tests)

struct MockSpeedReadingGenerationService: SpeedReadingGenerating {
    var simulatedDelayNanos: UInt64 = 0
    var error: Error? = nil

    func generateReading(for configuration: SpeedReadingConfiguration) async throws -> SpeedReadingGenerated {
        if simulatedDelayNanos > 0 { try? await Task.sleep(nanoseconds: simulatedDelayNanos) }
        if let error { throw error }

        let unit = "Reading at speed trains the eyes to scan ahead while the mind processes meaning. The key is to keep the gaze moving and to trust the brain to assemble the sense of the sentence as a whole. With practice, the reader stops sounding out each word and starts grasping ideas instead. "
        let target = configuration.targetWordCount
        var assembled = ""
        var words = 0
        while words < target {
            assembled += unit
            words += unit.split(whereSeparator: { $0.isWhitespace }).count
            if assembled.count > 80 { assembled += "\n\n" }
        }
        let chunks = SpeedReadingGenerationService.makeChunks(from: assembled, configuration: configuration)
        return SpeedReadingGenerated(text: assembled, chunks: chunks)
    }
}
