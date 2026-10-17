import CoreGraphics
import Testing
import UIKit
@testable import BeGrid

struct BlurHashTests {
    private static let alphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~")

    private static func encode83(_ value: Int, length: Int) -> String {
        String((0..<length).reversed().map { alphabet[value / Int(pow(83, Double($0))) % 83] })
    }

    private static func solidHash(red: Int, green: Int, blue: Int) -> String {
        "00" + encode83(red << 16 | green << 8 | blue, length: 4)
    }

    private func rgba(of image: UIImage) throws -> [UInt8] {
        let cgImage = try #require(image.cgImage)
        let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        var bytes = [UInt8](repeating: 0, count: cgImage.width * cgImage.height * 4)
        let context = try #require(CGContext(
            data: &bytes,
            width: cgImage.width,
            height: cgImage.height,
            bitsPerComponent: 8,
            bytesPerRow: cgImage.width * 4,
            space: space,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ))
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height))
        return bytes
    }

    @Test func decodesToRequestedSize() throws {
        let image = try #require(BlurHash.image(from: "LEHV6nWB2yk8pyo0adR*.7kCMdnj"))

        #expect(image.cgImage?.width == BlurHash.defaultSize)
        #expect(image.cgImage?.height == BlurHash.defaultSize)
    }

    @Test(arguments: [(255, 0, 0), (12, 200, 99), (128, 128, 128)])
    func solidHashDecodesToItsColor(red: Int, green: Int, blue: Int) throws {
        let image = try #require(BlurHash.image(from: Self.solidHash(red: red, green: green, blue: blue), size: 4))
        let bytes = try rgba(of: image)

        for pixel in stride(from: 0, to: bytes.count, by: 4) {
            #expect(abs(Int(bytes[pixel]) - red) <= 1)
            #expect(abs(Int(bytes[pixel + 1]) - green) <= 1)
            #expect(abs(Int(bytes[pixel + 2]) - blue) <= 1)
        }
    }

    @Test(arguments: ["", "00", "LEHV6nWB2yk8pyo0adR*.7kCMdn", "LEHV6nWB2yk8pyo0adR*.7kCMdnjj", "00\"000"])
    func malformedHashIsRejected(hash: String) {
        #expect(BlurHash.image(from: hash) == nil)
    }
}
