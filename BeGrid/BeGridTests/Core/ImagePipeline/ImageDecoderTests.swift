import Testing
@testable import BeGrid

struct ImageDecoderTests {
    @Test(arguments: [
        (PixelSize(width: 400, height: 300), PixelSize(width: 200, height: 150), 200),
        (PixelSize(width: 400, height: 300), PixelSize(width: 60, height: 200), 267),
        (PixelSize(width: 300, height: 400), PixelSize(width: 150, height: 100), 200),
        (PixelSize(width: 400, height: 300), PixelSize(width: 1000, height: 1000), 400)
    ])
    func maxPixelSizeCoversTargetWithoutUpscaling(source: PixelSize, target: PixelSize, expected: Int) {
        #expect(ImageDecoder.maxPixelSize(of: source, covering: target) == expected)
    }
}
