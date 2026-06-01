import Combine
import Foundation

@MainActor
final class VideoListeningResultsViewModel: ObservableObject {

    enum State: Equatable {
        case loading
        case loaded([ListeningVideoItem])
        case empty
        case error(String)
    }

    let setup: ListeningVideoSetup

    @Published private(set) var state: State = .loading
    @Published var searchQuery: String = ""
    @Published var selectedVideo: ListeningVideoItem?
    @Published var showSession = false

    private let service: ListeningVideoSearching
    private let fallback: ListeningVideoSearching
    private var allLoaded: [ListeningVideoItem] = []
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(
        setup: ListeningVideoSetup,
        service: ListeningVideoSearching? = nil,
        fallback: ListeningVideoSearching? = nil
    ) {
        self.setup = setup
        self.service = service ?? Self.defaultService()
        self.fallback = fallback ?? MockListeningVideoSearchService()

        // Debounce search query changes: 450 ms delay before firing a new search.
        $searchQuery
            .debounce(for: .milliseconds(450), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.handleQueryChange(query)
            }
            .store(in: &cancellables)
    }

    nonisolated static func defaultService() -> ListeningVideoSearching {
        if let key = Bundle.main.object(forInfoDictionaryKey: "YouTubeAPIKey") as? String, !key.isEmpty {
            return YouTubeListeningVideoSearchService(apiKey: key)
        }
        return MockListeningVideoSearchService()
    }

    var videos: [ListeningVideoItem] {
        if case .loaded(let items) = state { return items }
        return []
    }

    // MARK: - Load (initial, on appear)

    func load() {
        guard case .loading = state, allLoaded.isEmpty else { return }
        fetchVideos(topic: nil)
    }

    // MARK: - Retry

    func retrySearch() {
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        fetchVideos(topic: q.isEmpty ? nil : q)
    }

    // MARK: - Query change

    private func handleQueryChange(_ raw: String) {
        let query = raw.trimmingCharacters(in: .whitespacesAndNewlines)

        // If we already have a full result set, filter client-side (fast, no network).
        if !allLoaded.isEmpty {
            applyClientFilter(query: query)
            return
        }

        // No results loaded yet — trigger a new search.
        fetchVideos(topic: query.isEmpty ? nil : query)
    }

    /// Filter the already-loaded list without a network call.
    private func applyClientFilter(query: String) {
        if query.isEmpty {
            state = allLoaded.isEmpty ? .empty : .loaded(allLoaded)
            return
        }
        let q = query.lowercased()
        let filtered = allLoaded.filter {
            $0.title.lowercased().contains(q) || $0.channel.lowercased().contains(q)
        }
        state = filtered.isEmpty ? .empty : .loaded(filtered)
    }

    // MARK: - Network search

    private func fetchVideos(topic: String?) {
        searchTask?.cancel()
        state = .loading

        searchTask = Task {
            do {
                let items = try await service.search(
                    language: setup.language,
                    level: setup.level,
                    topic: topic ?? defaultTopic,
                    length: setup.length
                )
                guard !Task.isCancelled else { return }
                allLoaded = items
                applyClientFilter(query: searchQuery.trimmingCharacters(in: .whitespacesAndNewlines))
            } catch ListeningVideoSearchError.noResults {
                guard !Task.isCancelled else { return }
                state = .empty
            } catch {
                guard !Task.isCancelled else { return }
                await loadFallback(topic: topic, originalError: error)
            }
        }
    }

    private func loadFallback(topic: String?, originalError: Error) async {
        do {
            let items = try await fallback.search(
                language: setup.language,
                level: setup.level,
                topic: topic ?? defaultTopic,
                length: setup.length
            )
            allLoaded = items
            applyClientFilter(query: searchQuery.trimmingCharacters(in: .whitespacesAndNewlines))
        } catch {
            let message = (originalError as? LocalizedError)?.errorDescription ?? originalError.localizedDescription
            state = .error(message)
        }
    }

    /// Default search topic when user hasn't typed anything.
    private var defaultTopic: String {
        switch setup.level {
        case .a1, .a2: return "simple conversation"
        case .b1, .b2: return "conversation"
        case .c1, .native: return "podcast"
        }
    }

    // MARK: - Selection

    func selectVideo(_ video: ListeningVideoItem) {
        selectedVideo = video
        showSession = true
    }
}
