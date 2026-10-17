import Foundation
import SwiftUI
import Testing
@testable import BeGrid

@MainActor
struct PhotoCellModelTests {
    @Test func modelsOfTheSamePhotoAreEqual() {
        let photo = Photo.stub(id: "a", blurHash: "LEHV6nWB2yk8pyo0adR*.7kCMdnj", averageColor: "#a0b0c0")

        #expect(PhotoCellModel(photo: photo) == PhotoCellModel(photo: photo))
        #expect(PhotoCellModel(photo: photo) != PhotoCellModel(photo: .stub(id: "b")))
    }

    @Test(arguments: [
        ("#A0B0C0", Color(red: 160 / 255, green: 176 / 255, blue: 192 / 255)),
        ("0a0b0c", Color(red: 10 / 255, green: 11 / 255, blue: 12 / 255))
    ])
    func hexColorIsParsed(hex: String, expected: Color) {
        #expect(Color(hex: hex) == expected)
    }

    @Test(arguments: ["", "#12345", "#1234567", "#12345G", "+12345"])
    func malformedHexIsRejected(hex: String) {
        #expect(Color(hex: hex) == nil)
    }

    @Test func missingColorFallsBackToPlaceholder() {
        #expect(PhotoCellModel(photo: .stub(id: "a", averageColor: "nope")).color == .photoPlaceholder)
    }

    @Test(arguments: [
        (PixelSize(width: 3, height: 2), 750),
        (PixelSize(width: 2, height: 3), 400),
        (PixelSize(width: 4, height: 5), 400)
    ])
    func downloadWidthCoversTheCell(photoSize: PixelSize, expectedWidth: Int) throws {
        let model = PhotoCellModel(photo: .stub(id: "a", size: photoSize))
        let url = model.imageURL(covering: PixelSize(width: 400, height: 500))
        let items = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)

        #expect(items.first { $0.name == "w" }?.value == String(expectedWidth))
    }
}
