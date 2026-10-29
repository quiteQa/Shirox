import Foundation

struct ModuleMetadataIdentity: Codable, Equatable, Hashable, Sendable {
    let moduleID: String
    let source: String
    let subjectID: Int
}

/// The v1 metadata contract. Optional fields remain unknown rather than inferred.
struct ModuleMetadata: Codable, Sendable {
    struct Titles: Codable, Sendable {
        let chinese: String?
        let original: String?
    }

    struct Rating: Codable, Sendable {
        let score: Double?
        let scale: Int
        let rank: Int?
        let votes: Int?

        var scoreOutOf100: Int? {
            guard scale == 10, let score, score.isFinite, score > 0, score <= 10 else { return nil }
            return Int((score * 10).rounded())
        }
    }

    let schemaVersion: Int
    let source: String
    let id: Int
    let url: String
    let title: String
    let titles: Titles
    let aliases: [String]
    let description: String
    let poster: String?
    let format: String?
    let releaseDate: String?
    let year: Int?
    let episodeCount: Int?
    let totalEpisodes: Int?
    let tags: [String]
    let studios: [String]
    let directors: [String]
    let rating: Rating

    var isValid: Bool {
        schemaVersion == 1 && id > 0 && !source.isEmpty && !title.isEmpty && rating.scale == 10
    }

    func media(moduleID: String) -> Media {
        let key = "metadata|\(moduleID)|\(source)|\(id)"
        var result = Media(
            id: Media.localId(forKey: key), idMal: nil, provider: .local,
            title: MediaTitle(romaji: nil, english: title, native: titles.original),
            coverImage: MediaCoverImage(large: poster, extraLarge: poster), bannerImage: nil,
            description: description, episodes: episodeCount, status: nil,
            averageScore: rating.scoreOutOf100, genres: nil, season: nil, seasonYear: year,
            nextAiringEpisode: nil, relations: nil, type: "ANIME", format: format)
        result.moduleMetadata = ModuleMetadataIdentity(moduleID: moduleID, source: source, subjectID: id)
        return result
    }
}

struct ModuleEpisodeMetadata: Decodable, Identifiable, Sendable {
    let id: Int
    let subjectId: Int
    let number: Double
    let episodeNumber: Double?
    let title: String
    let originalTitle: String?
    let description: String
    let airdate: String?
    let duration: String?
    let durationSeconds: Int?
    let url: String
}

enum ModuleMetadataCatalog: String, CaseIterable, Identifiable {
    case topRated, newest
    var id: String { rawValue }
    var title: String {
        switch self {
        case .topRated: return String(localized: "shared.top_rated")
        case .newest: return String(localized: "modules.metadata_newest")
        }
    }
}
