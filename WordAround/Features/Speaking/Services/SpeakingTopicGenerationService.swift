import Foundation

final class SpeakingTopicGenerationService {

    private let primaryClient: SpeakingTopicAIClient
    private let fallbackClient: SpeakingTopicAIClient
    private let cacheStore = TopicCacheStore()

    init(
        primaryClient: SpeakingTopicAIClient = SpeakingTopicAIConfiguration.makeClient(),
        fallbackClient: SpeakingTopicAIClient = LocalFallbackSpeakingTopicAIClient()
    ) {
        self.primaryClient = primaryClient
        self.fallbackClient = fallbackClient
    }

    func topic(
        for language: GrammarLanguage,
        level: EssayDifficulty,
        length: ConversationLength,
        avoidTitles: [String] = [],
        forceRefresh: Bool = false
    ) async -> (topic: GeneratedConversationTopic, usedFallback: Bool) {
        let key = GeneratedConversationTopicCacheKey(language: language, level: level, length: length)

        #if DEBUG
        print("[TopicAI] request lang=\(language.title) level=\(level.rawValue) length=\(length.minutes)min forceRefresh=\(forceRefresh) avoid=\(avoidTitles)")
        #endif

        if !forceRefresh, let cached = await cacheStore.value(for: key) {

            if !avoidTitles.contains(cached.title) {
                #if DEBUG
                print("[TopicAI] cache hit: '\(cached.title)'")
                #endif
                return (cached, false)
            }
            #if DEBUG
            print("[TopicAI] cache hit dropped — title is in avoidTitles")
            #endif
        }

        do {
            #if DEBUG
            print("[TopicAI] remote attempt 1")
            #endif
            let topic = try await primaryClient.generateTopic(language: language, level: level, length: length, avoidTitles: avoidTitles)

            if avoidTitles.contains(topic.title) {
                #if DEBUG
                print("[TopicAI] remote returned avoided title '\(topic.title)' — retrying once")
                #endif
                do {
                    let retried = try await primaryClient.generateTopic(language: language, level: level, length: length, avoidTitles: avoidTitles)
                    await storeRemote(retried, for: key)
                    return (retried, false)
                } catch {
                    #if DEBUG
                    print("[TopicAI] anti-repeat retry failed: \(error.localizedDescription) — keeping first result")
                    #endif
                }
            }
            await storeRemote(topic, for: key)
            return (topic, false)
        } catch {
            #if DEBUG
            print("[TopicAI] remote attempt 1 failed: \(error.localizedDescription)")
            #endif
        }

        do {
            #if DEBUG
            print("[TopicAI] remote attempt 2")
            #endif
            let topic = try await primaryClient.generateTopic(language: language, level: level, length: length, avoidTitles: avoidTitles)
            await storeRemote(topic, for: key)
            return (topic, false)
        } catch {
            #if DEBUG
            print("[TopicAI] remote attempt 2 failed: \(error.localizedDescription) — falling back to local")
            #endif
        }

        let fallback = LocalFallbackSpeakingTopicAIClient.pickTopic(
            language: language,
            level: level,
            avoidTitles: avoidTitles
        )
        #if DEBUG
        print("[TopicAI] using LOCAL fallback: '\(fallback.title)' (NOT cached)")
        #endif
        return (fallback, true)
    }

    func clearCache() async {
        await cacheStore.removeAll()
    }

    private func storeRemote(_ topic: GeneratedConversationTopic, for key: GeneratedConversationTopicCacheKey) async {
        await cacheStore.store(topic, for: key)
    }
}

private actor TopicCacheStore {
    private var cache: [GeneratedConversationTopicCacheKey: GeneratedConversationTopic] = [:]

    func value(for key: GeneratedConversationTopicCacheKey) -> GeneratedConversationTopic? {
        cache[key]
    }

    func store(_ topic: GeneratedConversationTopic, for key: GeneratedConversationTopicCacheKey) {
        cache[key] = topic
    }

    func removeAll() {
        cache.removeAll()
    }
}
