import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var trending: [Media] = []
    @Published var seasonal: [Media] = []
    @Published var lastSeason: [Media] = []
    @Published var popular: [Media] = []
    @Published var topRated: [Media] = []
    @Published var isLoading = false
    @Published var error: String?
    /// Whose rows these are — the provider that was first when they were asked for. A change is
    /// Home switching providers, which it animates.
    @Published private(set) var feedProvider: ProviderType?

    private var loaded = false
    private var loadedSourceID: String?
    private var generation = UUID()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Cold start: show the last-saved feed for whichever provider is primary right now,
        // before any network request — the same cache-then-refresh shape `LibraryViewModel`
        // already uses. The view's `.task` calls `load()` immediately after and refreshes it.
        seedFromCache()

        ProviderManager.shared.$orderedProviders
            .map { $0.first?.providerType }
            .removeDuplicates { $0 == $1 }
            .dropFirst() // skip initial value — load() is called by the view's .task
            .sink { [weak self] _ in
                guard let self else { return }
                Task { await self.reload() }
            }
            .store(in: &cancellables)
    }

    func load() async {
        let sourceID = DiscoverySource.shared.sourceID
        guard !loaded || loadedSourceID != sourceID else { return }
        let requestID = UUID()
        generation = requestID
        isLoading = true
        error = nil
        if let loadedSourceID, loadedSourceID != sourceID {
            apply(HomeFeed(trending: [], seasonal: [], lastSeason: [], popular: [], topRated: []), from: nil)
        }

        do {
            if let module = DiscoverySource.shared.metadataModule, DiscoverySource.shared.usesMetadata {
                let service = ModuleMetadataService(module: module)
                let ranked = try await service.browse(.topRated)
                let newest = try await service.browse(.newest)
                guard generation == requestID, DiscoverySource.shared.sourceID == sourceID else { return }
                apply(HomeFeed(trending: ranked, seasonal: newest, lastSeason: [], popular: [], topRated: ranked), from: nil)
                loaded = true
                loadedSourceID = sourceID
                isLoading = false
                return
            }
            // One call, not five. Each provider decides how few requests that actually takes
            // (AniList: a single aliased GraphQL query; MAL: five, paced). Going through
            // `call` once also means the whole screen comes from one provider — five separate
            // calls could each fall back independently and leave Home showing a mix.
            let feed = try await ProviderManager.shared.call { try await $0.homeFeed() }
            guard generation == requestID, DiscoverySource.shared.sourceID == sourceID else { return }
            let type = ProviderManager.shared.primary?.providerType
            apply(feed, from: type)
            if let type {
                HomeCacheStore.shared.save(feed: feed, provider: type)
            }
            loaded = true
            loadedSourceID = sourceID
        } catch {
            guard generation == requestID, DiscoverySource.shared.sourceID == sourceID else { return }
            self.error = error.localizedDescription
            // A reload that fails (e.g. right after switching providers) leaves whatever is on
            // screen untouched — nothing above clears it on failure, by design, so a background
            // refresh doesn't flash the screen empty. But with `trending` non-empty, HomeView's
            // own error view never shows either (it only appears when `trending.isEmpty`), so
            // the failure was completely silent: switching to a provider that's down looked
            // exactly like the switch did nothing at all.
            #if !os(tvOS)
            if !trending.isEmpty {
                let name = ProviderManager.shared.primary?.providerType.displayName ?? "provider"
                ToastManager.shared.show(message: String(localized: "home.couldnt_load_showing_previous_results \(name)"),
                                          type: .error, duration: 4)
            }
            #endif
        }

        isLoading = false
    }

    func reload() async {
        loaded = false
        // Switching providers swaps to that provider's last-known feed straight away, rather
        // than leaving the old provider's rows up while the new request is in flight — which
        // read as the switch having done nothing.
        seedFromCache()
        await load()
    }

    // MARK: - Private

    private func seedFromCache() {
        if DiscoverySource.shared.usesMetadata {
            apply(HomeFeed(trending: [], seasonal: [], lastSeason: [], popular: [], topRated: []), from: nil)
            return
        }
        guard let type = ProviderManager.shared.primary?.providerType,
              let cached = HomeCacheStore.shared.snapshot(provider: type) else { return }
        apply(cached.feed, from: type)
    }

    private func apply(_ feed: HomeFeed, from provider: ProviderType?) {
        feedProvider = provider
        trending = feed.trending
        seasonal = feed.seasonal
        lastSeason = feed.lastSeason
        popular = feed.popular
        topRated = feed.topRated
    }
}
