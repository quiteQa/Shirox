import SwiftUI

@MainActor
struct MetadataCatalogView: View {
    let catalog: ModuleMetadataCatalog
    @ObservedObject private var discovery = DiscoverySource.shared
    @State private var items: [Media] = []
    @State private var page = 1
    @State private var loading = false
    @State private var reachedEnd = false
    @State private var error: String?
    @State private var generation = UUID()

    private var columns: [GridItem] {
        #if os(macOS)
        PosterGrid.columns
        #else
        [GridItem(.adaptive(minimum: 140, maximum: 220), spacing: 12)]
        #endif
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                if let error { Text(error).foregroundStyle(.red).padding() }
                if !loading && items.isEmpty && error == nil { Text("modules.metadata_empty").padding() }
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(items) { media in
                        NavigationLink { MediaDestination(media: media) } label: { AniListCardView(media: media) }
                            .buttonStyle(CardPressStyle())
                            .onAppear {
                                if media.id == items.last?.id && !reachedEnd && !loading {
                                    Task { await load(generation: generation) }
                                }
                            }
                    }
                }
                if loading { ProgressView().padding() }
            }
            .padding(16)
        }
        .navigationTitle(catalog.title)
        .task(id: discovery.sourceID) {
            let request = UUID()
            generation = request
            items = []
            page = 1
            reachedEnd = false
            loading = false
            await load(generation: request)
        }
    }

    private func load(generation request: UUID) async {
        guard !loading, !reachedEnd, let module = discovery.metadataModule else { return }
        loading = true
        error = nil
        defer { if generation == request { loading = false } }
        do {
            let result = try await ModuleMetadataService(module: module).browse(catalog, page: page)
            guard !Task.isCancelled, generation == request else { return }
            let known = Set(items.map(\.uniqueId))
            let fresh = result.filter { !known.contains($0.uniqueId) }
            reachedEnd = result.isEmpty || fresh.isEmpty
            items.append(contentsOf: fresh)
            page += 1
        } catch {
            if !Task.isCancelled && generation == request { self.error = error.localizedDescription }
        }
    }
}
