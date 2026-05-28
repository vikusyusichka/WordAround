import Foundation

final class CloudflareSpeakingTopicAIClient: SpeakingTopicAIClient {

    private let session: URLSession
    private let endpointURL: URL
    private let timeoutInterval: TimeInterval

    init(
        endpointURL: URL,
        session: URLSession = .shared,
        timeoutInterval: TimeInterval = 25
    ) {
        self.endpointURL = endpointURL
        self.session = session
        self.timeoutInterval = timeoutInterval
    }

    private struct WorkerRequest: Encodable {
        let language: String
        let level: String
        let lengthMinutes: Int
        let avoidTitles: [String]
    }

    private struct WorkerResponse: Decodable {
        let title: String?
        let description: String?
        let prompt: String?
        let openingQuestion: String?
        let firstAIMessage: String?
        let promptContext: String?
        let context: String?
        let category: String?
        let level: String?
        let difficulty: String?
        let estimatedMinutes: Int?
        let error: String?

        var resolvedDescription: String? { description ?? prompt }
        var resolvedOpeningQuestion: String? { openingQuestion ?? firstAIMessage }
        var resolvedPromptContext: String? { promptContext ?? context }
        var resolvedLevel: String? { level ?? difficulty }
    }

    func generateTopic(
        language: GrammarLanguage,
        level: EssayDifficulty,
        length: ConversationLength,
        avoidTitles: [String]
    ) async throws -> GeneratedConversationTopic {
        let endpointPath = endpointURL.path

        let trimmedAvoid = Array(avoidTitles.suffix(12))
        #if DEBUG
        print("[TopicAI] → POST \(endpointPath) language=\(language.title) level=\(level.rawValue) length=\(length.minutes)min avoidCount=\(trimmedAvoid.count)")
        #endif

        var request = URLRequest(url: endpointURL, timeoutInterval: timeoutInterval)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let body = WorkerRequest(
            language: language.title,
            level: level.rawValue,
            lengthMinutes: length.minutes,
            avoidTitles: trimmedAvoid
        )

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            #if DEBUG
            print("[TopicAI] failed to encode request body: \(error)")
            #endif
            throw SpeakingTopicAIClientError.invalidResponse
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            #if DEBUG
            print("[TopicAI] network error: \(error.localizedDescription)")
            #endif
            throw SpeakingTopicAIClientError.network(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw SpeakingTopicAIClientError.invalidResponse
        }

        #if DEBUG
        print("[TopicAI] ← HTTP \(http.statusCode) for \(endpointPath)")
        if let bodyString = String(data: data, encoding: .utf8) {
            print("[TopicAI] raw response: \(bodyString.prefix(400))")
        }
        #endif

        let envelope: WorkerResponse
        do {
            envelope = try JSONDecoder().decode(WorkerResponse.self, from: data)
        } catch {
            #if DEBUG
            print("[TopicAI] envelope decode failed: \(error)")
            #endif
            throw SpeakingTopicAIClientError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let message = envelope.error?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            throw SpeakingTopicAIClientError.serverError(http.statusCode, message)
        }

        guard
            let title = envelope.title?.trimmingCharacters(in: .whitespacesAndNewlines),
            let description = envelope.resolvedDescription?.trimmingCharacters(in: .whitespacesAndNewlines),
            let promptContext = envelope.resolvedPromptContext?.trimmingCharacters(in: .whitespacesAndNewlines),
            let openingQuestion = envelope.resolvedOpeningQuestion?.trimmingCharacters(in: .whitespacesAndNewlines),
            !title.isEmpty,
            !description.isEmpty,
            !promptContext.isEmpty,
            !openingQuestion.isEmpty
        else {
            #if DEBUG
            print("[TopicAI] validation failed — missing one of {title, description, promptContext, openingQuestion}")
            #endif
            throw SpeakingTopicAIClientError.validationFailed("missing required fields")
        }

        let category = envelope.category?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedCategory = (category?.isEmpty == false) ? category! : "Conversation"

        #if DEBUG
        print("[TopicAI] decoded topic title='\(title)' category='\(resolvedCategory)'")
        #endif

        return GeneratedConversationTopic(
            title: title,
            description: description,
            firstAIMessage: openingQuestion,
            promptContext: promptContext,
            category: resolvedCategory
        )
    }
}
