import XCTest
@testable import Shirox

@MainActor
final class MetadataModuleTests: XCTestCase {
    private var fixture: String {
        """
        {"schemaVersion":1,"source":"bangumi","id":400602,"url":"https://bgm.tv/subject/400602",
         "title":"Frieren","titles":{"chinese":"Frieren","original":"Sousou no Frieren"},
         "aliases":["Frieren"],"description":"Synopsis","poster":"https://example.com/cover.jpg",
         "format":"TV","releaseDate":"2023-09-29","year":2023,"episodeCount":28,"totalEpisodes":28,
         "tags":["Fantasy"],"studios":["MADHOUSE"],"directors":[],
         "rating":{"score":8.5,"scale":10,"rank":43,"votes":100}}
        """
    }

    private func module(type: String = "metadata") throws -> ModuleDefinition {
        try JSONDecoder().decode(ModuleDefinition.self, from: Data("""
        {"sourceName":"Metadata","version":"0.3.0","scriptUrl":"https://example.com/metadata.js","type":"\(type)"}
        """.utf8))
    }

    func testBangumiIsBundledAndAvailableWithoutInstalledModules() throws {
        let bundled = try BuiltInMetadataModules.loadBangumi(from: .main)
        XCTAssertEqual(bundled.id, BuiltInMetadataModules.bangumiID)
        XCTAssertEqual(bundled.sourceName, "Bangumi")
        XCTAssertTrue(bundled.isMetadata)
        XCTAssertFalse(bundled.isAnimePlayback)
        let script = try XCTUnwrap(bundled.scriptContent)
        XCTAssertTrue(script.contains("async function searchMetadata"))
        XCTAssertTrue(script.contains("async function extractMetadata"))
        XCTAssertTrue(script.contains("async function extractEpisodeMetadata"))
        XCTAssertTrue(script.contains("async function browseMetadata"))
        XCTAssertEqual(BuiltInMetadataModules.merging([]).map(\.id), [bundled.id])
    }

    func testLegacyBangumiUsesBundledMetadataAndDoesNotDuplicateItsSource() throws {
        let legacy = try JSONDecoder().decode(ModuleDefinition.self, from: Data("""
        {"sourceName":"Old Bangumi","version":"0.2.0","scriptUrl":"\(BuiltInMetadataModules.bangumiID)","type":"anime"}
        """.utf8))
        XCTAssertTrue(legacy.isMetadata)
        XCTAssertFalse(legacy.isAnimePlayback)
        let external = try module()
        let sources = BuiltInMetadataModules.merging([legacy, external])
        XCTAssertEqual(sources.map(\.id), [legacy.id, external.id])
        XCTAssertEqual(sources.first?.sourceName, "Bangumi")
        XCTAssertEqual(sources.first?.version, "0.3.0")
    }

    func testBuiltInChoiceSurvivesProfileReloadWithoutAUserInstalledModule() throws {
        let suite = "metadata-builtin-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let source = DiscoverySource(defaults: defaults, selectProvider: { _ in })
        source.chooseMetadataModule(try XCTUnwrap(BuiltInMetadataModules.bangumi))
        XCTAssertTrue(source.usesMetadata)
        XCTAssertEqual(source.metadataModule?.sourceName, "Bangumi")
        source.chooseProvider(.anilist)
        source.reloadForProfileSwitch()
        XCTAssertFalse(source.usesMetadata)
        defaults.set("metadata", forKey: DiscoverySource.choiceKey)
        source.reloadForProfileSwitch()
        XCTAssertTrue(source.usesMetadata)
        XCTAssertEqual(source.metadataModuleID, BuiltInMetadataModules.bangumiID)
    }

    func testMetadataIsNotAMangaOrPlaybackModule() throws {
        let metadata = try module()
        XCTAssertTrue(metadata.isMetadata)
        XCTAssertFalse(metadata.isManga)
        XCTAssertFalse(metadata.isAnimePlayback)
        let video = try module(type: "anime")
        XCTAssertEqual(AnimeModulePreference.pick(active: metadata, modules: [metadata, video]), video)
        XCTAssertNil(AnimeModulePreference.pick(active: metadata, modules: [metadata]))
    }

    func testMetadataIDsAreNamespacedAndScoresUseTheNativeScale() throws {
        let record = try JSONDecoder().decode(ModuleMetadata.self, from: Data(fixture.utf8))
        let media = record.media(moduleID: "first")
        XCTAssertEqual(media.averageScore, 85)
        XCTAssertEqual(media.provider, .local)
        XCTAssertNil(media.idMal)
        XCTAssertNil(media.title.romaji)
        XCTAssertEqual(media.title.native, record.titles.original)
        XCTAssertNil(media.genres, "community tags are not native genre names")
        XCTAssertFalse(media.usesTVDBArtwork)
        XCTAssertNotEqual(media.id, record.id, "Bangumi ids must not be used as AniList ids")
        XCTAssertNotEqual(media.uniqueId, record.media(moduleID: "second").uniqueId)
        let identity = ModuleMetadataIdentity(moduleID: "first", source: "bangumi", subjectID: 400602)
        XCTAssertEqual(media.moduleMetadata, identity)
        XCTAssertEqual(MediaDestination.target(for: media), .metadata(identity))
        XCTAssertEqual(try JSONDecoder().decode(Media.self, from: JSONEncoder().encode(media)).moduleMetadata, identity)
    }

    func testInvalidRatingScaleIsNotShownAsAValidNativeScore() throws {
        let json = fixture.replacingOccurrences(of: "\"scale\":10", with: "\"scale\":100")
        let record = try JSONDecoder().decode(ModuleMetadata.self, from: Data(json.utf8))
        XCTAssertFalse(record.isValid)
        XCTAssertNil(record.rating.scoreOutOf100)
    }

    func testMetadataCheckDoesNotCallTheStreamFunction() async throws {
        var definition = try module()
        let object = try JSONSerialization.jsonObject(with: Data(fixture.utf8))
        let json = String(decoding: try JSONSerialization.data(withJSONObject: object), as: UTF8.self)
        let quoted = String(decoding: try JSONSerialization.data(withJSONObject: json, options: .fragmentsAllowed), as: UTF8.self)
        definition.scriptContent = """
        async function searchMetadata(q) { return '[' + \(quoted) + ']' }
        async function extractMetadata(id) { return \(quoted) }
        async function extractStreamUrl() { throw new Error('metadata check tried playback') }
        """
        let result = await ModuleCheck.check(definition)
        XCTAssertEqual(result, .passed)
    }

    func testPlaybackRunnerRefusesMetadata() async throws {
        do {
            try await JSEngine.shared.loadModule(module())
            XCTFail("metadata must not replace the playback context")
        } catch {
            XCTAssertTrue(error is ProviderError)
        }
    }
}
