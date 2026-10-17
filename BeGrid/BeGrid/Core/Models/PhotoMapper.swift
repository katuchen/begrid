import Foundation

nonisolated enum PhotoMapper {
    static func photos(from dtos: [PhotoDTO]) -> [Photo] {
        dtos.map(photo(from:))
    }

    static func photo(from dto: PhotoDTO) -> Photo {
        Photo(
            id: dto.id,
            summary: summary(altDescription: dto.altDescription, description: dto.description),
            size: size(width: dto.width, height: dto.height),
            blurHash: nonBlank(dto.blurHash),
            averageColor: nonBlank(dto.color),
            urls: PhotoURLs(raw: dto.urls.raw, full: dto.urls.full, regular: dto.urls.regular, small: dto.urls.small),
            photographer: Photographer(
                name: nonBlank(dto.user.name) ?? dto.user.username,
                username: dto.user.username,
                profileURL: dto.user.links?.html
            )
        )
    }

    static func summary(altDescription: String?, description: String?) -> String? {
        nonBlank(altDescription) ?? nonBlank(description)
    }

    private static func size(width: Int?, height: Int?) -> PixelSize? {
        guard let width, let height, width > 0, height > 0 else { return nil }
        return PixelSize(width: width, height: height)
    }

    private static func nonBlank(_ text: String?) -> String? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
        return trimmed
    }
}
