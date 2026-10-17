import Foundation
import Testing
@testable import BeGrid

struct PhotoDecodingTests {
    @Test func decodesFeedPage() throws {
        let dtos = try Fixture.decode([PhotoDTO].self, named: "photos")
        let photos = PhotoMapper.photos(from: dtos)

        #expect(photos.map(\.id) == ["feed-1", "feed-2"])

        let first = try #require(photos.first)
        #expect(first.summary == "a lake surrounded by mountains")
        #expect(first.size == PixelSize(width: 4000, height: 6000))
        #expect(first.aspectRatio == 4000.0 / 6000.0)
        #expect(first.blurHash == "LKO2?U%2Tw=w]~RBVZRi};RPxuwH")
        #expect(first.averageColor == "#26400c")
        #expect(first.urls.small.absoluteString.hasPrefix("https://images.unsplash.com/photo-feed-1?"))
        #expect(first.photographer == Photographer(
            name: "Jane Doe",
            username: "jane_doe",
            profileURL: URL(string: "https://unsplash.com/@jane_doe")
        ))
    }

    @Test func decodesSearchPage() throws {
        let response = try Fixture.decode(SearchResponseDTO.self, named: "search")
        #expect(response.totalPages == 5)

        let photos = PhotoMapper.photos(from: response.results)
        #expect(photos.map(\.id) == ["search-1", "search-2"])
        #expect(photos[0].summary == "a cat sleeping on a sofa")
    }

    @Test func toleratesFieldsMissingFromSearchResults() throws {
        let response = try Fixture.decode(SearchResponseDTO.self, named: "search")
        let sparse = PhotoMapper.photo(from: try #require(response.results.last))

        #expect(sparse.size == nil)
        #expect(sparse.aspectRatio == Photo.defaultAspectRatio)
        #expect(sparse.blurHash == nil)
        #expect(sparse.photographer.name == "anonymous_lens")
        #expect(sparse.photographer.profileURL == nil)
    }
}
