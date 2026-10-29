import SwiftUI

/// Metadata stays on its own page. Playback is a separate, user-confirmed source match.
@MainActor
struct MetadataDetailView: View {
    let identity: ModuleMetadataIdentity
    let seed: Media
    @State private var record: ModuleMetadata?
    @State private var episodes: [ModuleEpisodeMetadata] = []
    @State private var error: String?
    @State private var episodeError: String?
    @State private var showPlayback = false
    @State private var loading = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                CachedAsyncImage(urlString: record?.poster ?? seed.coverImage.large ?? "")
                    .frame(height: 280)
                    .frame(maxWidth: .infinity)
                    .clipped()
                Text(record?.title ?? seed.title.displayTitle).font(.title.bold())
                if loading { ProgressView() }
                if let error { Text(error).foregroundStyle(.red) }
                if let record {
                    metadata(record)
                    Button { showPlayback = true } label: {
                        Label("modules.metadata_find_playback", icon: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    Text("common.episodes").font(.headline)
                    if let episodeError { Text(episodeError).foregroundStyle(.secondary) }
                    ForEach(episodes) { episode in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(episode.title).font(.subheadline.weight(.semibold))
                            if let airdate = episode.airdate { Text(airdate).font(.caption).foregroundStyle(.secondary) }
                            if !episode.description.isEmpty { Text(episode.description).font(.caption) }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle(seed.title.displayTitle)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                BookmarkButton(media: record?.media(moduleID: identity.moduleID) ?? seed, style: .toolbar)
            }
        }
        .task(id: identity) { await load() }
        .sheet(isPresented: $showPlayback) {
            if let record { MetadataPlaybackPicker(metadata: record) }
        }
    }

    @ViewBuilder
    private func metadata(_ record: ModuleMetadata) -> some View {
        if let original = record.titles.original, original != record.title {
            Text(original).foregroundStyle(.secondary)
        }
        HStack {
            if let score = record.rating.score {
                Text(String(format: "%.1f / 10", score)).font(.headline)
            }
            if let date = record.releaseDate { Text(date).foregroundStyle(.secondary) }
            if let format = record.format { Text(format).foregroundStyle(.secondary) }
        }
        if let count = record.episodeCount { Text("modules.metadata_episode_count \(count)") }
        if !record.studios.isEmpty {
            Text("modules.metadata_studios").font(.headline)
            Text(record.studios.joined(separator: ", "))
        }
        if !record.directors.isEmpty {
            Text("modules.metadata_directors").font(.headline)
            Text(record.directors.joined(separator: ", "))
        }
        Text(record.description)
        if !record.tags.isEmpty { Text(record.tags.joined(separator: " · ")).font(.caption).foregroundStyle(.secondary) }
    }

    private func load() async {
        loading = true
        error = nil
        episodeError = nil
        defer { loading = false }
        guard let module = ModuleManager.shared.metadataModules.first(where: { $0.id == identity.moduleID }) else {
            error = String(localized: "modules.metadata_unavailable")
            return
        }
        let service = ModuleMetadataService(module: module)
        do {
            let fetched = try await service.detail(id: identity.subjectID)
            guard !Task.isCancelled else { return }
            guard fetched.source == identity.source else { throw ProviderError.notFound }
            record = fetched
        } catch {
            if !Task.isCancelled { self.error = error.localizedDescription }
            return
        }
        do {
            let fetched = try await service.episodes(id: identity.subjectID)
            guard !Task.isCancelled else { return }
            episodes = fetched
        } catch {
            if !Task.isCancelled { episodeError = error.localizedDescription }
        }
    }
}

@MainActor
private struct MetadataPlaybackPicker: View {
    let metadata: ModuleMetadata
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var manager = ModuleManager.shared
    @State private var moduleID = ""
    @State private var results: [SearchItem] = []
    @State private var error: String?
    @State private var loading = false

    private var sources: [ModuleDefinition] {
        manager.modules.filter { $0.isAnimePlayback && !$0.isLocalPlayback && !$0.isJellyfin }
    }

    var body: some View {
        NavigationStack {
            List {
                if sources.isEmpty {
                    Text("modules.metadata_install_playback")
                } else {
                    Picker("modules.sources", selection: $moduleID) {
                        ForEach(sources) { module in Text(module.sourceName).tag(module.id) }
                    }
                    if loading { ProgressView() }
                    if let error { Text(error).foregroundStyle(.red) }
                    if !loading && error == nil && results.isEmpty { Text("modules.metadata_empty") }
                    ForEach(results) { item in
                        NavigationLink {
                            DetailView(item: item, moduleId: moduleID)
                        } label: {
                            Text(item.title)
                        }
                    }
                }
            }
            .navigationTitle("modules.metadata_find_playback")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("common.done") { dismiss() } }
            }
            .onAppear {
                moduleID = sources.first(where: { $0.id == manager.activeModule?.id })?.id ?? sources.first?.id ?? ""
            }
            .task(id: moduleID) { await search() }
        }
    }

    private func search() async {
        let requested = moduleID
        guard let module = sources.first(where: { $0.id == requested }) else { return }
        loading = true
        results = []
        error = nil
        defer { if moduleID == requested { loading = false } }
        do {
            let runner = ModuleJSRunner()
            try await runner.load(module: module)
            var seen = Set<String>()
            let queries = ([metadata.title] + metadata.aliases).filter { seen.insert($0).inserted }
            for query in queries.prefix(4) {
                try Task.checkCancellation()
                let found = try await runner.search(keyword: query)
                guard !Task.isCancelled, moduleID == requested else { return }
                if !found.isEmpty { results = found; return }
            }
        } catch {
            if !Task.isCancelled && moduleID == requested { self.error = error.localizedDescription }
        }
    }
}
