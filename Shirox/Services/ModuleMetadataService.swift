import Foundation

/// A separate runner prevents reading metadata from replacing the playback module's JS.
@MainActor
final class ModuleMetadataService {
    private let module: ModuleDefinition
    private let runner = ModuleJSRunner()
    private var loaded = false

    init(module: ModuleDefinition) { self.module = module }

    private func prepare() async throws {
        guard module.isMetadata else { throw ProviderError.unsupported }
        if !loaded {
            try await runner.load(module: module)
            loaded = true
        }
    }

    func search(_ keyword: String) async throws -> [ModuleMetadata] {
        try await prepare()
        let result: [ModuleMetadata] = try await runner.readMetadata("searchMetadata", args: [keyword])
        return try validated(result)
    }

    func detail(id: Int) async throws -> ModuleMetadata {
        try await prepare()
        let result: ModuleMetadata = try await runner.readMetadata("extractMetadata", args: [id])
        guard result.isValid, result.id == id else { throw ProviderError.notFound }
        return result
    }

    func episodes(id: Int) async throws -> [ModuleEpisodeMetadata] {
        try await prepare()
        let result: [ModuleEpisodeMetadata] = try await runner.readMetadata("extractEpisodeMetadata", args: [id])
        guard result.allSatisfy({ $0.id > 0 && $0.subjectId == id && $0.number.isFinite && $0.number > 0 }) else {
            throw ProviderError.notFound
        }
        return result.sorted { $0.number < $1.number }
    }

    func browse(_ catalog: ModuleMetadataCatalog, page: Int = 1) async throws -> [Media] {
        try await prepare()
        let result: [ModuleMetadata] = try await runner.readMetadata("browseMetadata", args: [catalog.rawValue, page])
        return try validated(result).map { $0.media(moduleID: module.id) }
    }

    private func validated(_ records: [ModuleMetadata]) throws -> [ModuleMetadata] {
        guard records.allSatisfy(\.isValid) else { throw ProviderError.unsupported }
        var seen = Set<String>()
        return records.filter { seen.insert("\($0.source):\($0.id)").inserted }
    }
}
