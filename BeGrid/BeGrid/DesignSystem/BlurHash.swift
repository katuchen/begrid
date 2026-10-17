import UIKit

nonisolated enum BlurHash {
    static let defaultSize = 32

    private static let alphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz#$%*+,-.:;=?@[]^_{|}~")
    private static let digits = Dictionary(uniqueKeysWithValues: alphabet.enumerated().map { ($0.element, $0.offset) })

    @concurrent static func decodedImage(from hash: String, size: Int = defaultSize) async -> UIImage? {
        image(from: hash, size: size)
    }

    static func image(from hash: String, size: Int = defaultSize, punch: Double = 1) -> UIImage? {
        guard size > 0, let components = Components(hash: hash, punch: punch) else { return nil }
        return image(rgbx: components.pixels(width: size, height: size), width: size, height: size)
    }

    private static func decode83(_ characters: some Sequence<Character>) -> Int? {
        var value = 0
        for character in characters {
            guard let digit = digits[character] else { return nil }
            value = value * 83 + digit
        }
        return value
    }

    private struct Components {
        let countX: Int
        let countY: Int
        let colors: [SIMD3<Double>]

        init?(hash: String, punch: Double) {
            let characters = Array(hash)
            guard characters.count >= 6,
                  let sizeFlag = BlurHash.decode83(characters[0..<1]),
                  let quantisedMax = BlurHash.decode83(characters[1..<2]),
                  let average = BlurHash.decode83(characters[2..<6])
            else { return nil }

            countX = sizeFlag % 9 + 1
            countY = sizeFlag / 9 + 1
            guard characters.count == 4 + 2 * countX * countY else { return nil }

            let maxValue = Double(quantisedMax + 1) / 166 * punch
            var colors = [SIMD3(Self.linear(average >> 16), Self.linear((average >> 8) & 255), Self.linear(average & 255))]
            for index in 1..<(countX * countY) {
                let start = 4 + index * 2
                guard let value = BlurHash.decode83(characters[start..<(start + 2)]) else { return nil }
                colors.append(SIMD3(Self.ac(value / 361), Self.ac(value / 19 % 19), Self.ac(value % 19)) * maxValue)
            }
            self.colors = colors
        }

        func pixels(width: Int, height: Int) -> [UInt8] {
            let cosinesX = Self.cosines(count: countX, length: width)
            let cosinesY = Self.cosines(count: countY, length: height)
            var bytes = [UInt8]()
            bytes.reserveCapacity(width * height * 4)

            for y in 0..<height {
                for x in 0..<width {
                    var color = SIMD3<Double>()
                    for row in 0..<countY {
                        let cosineY = cosinesY[y * countY + row]
                        for column in 0..<countX {
                            color += colors[column + row * countX] * (cosinesX[x * countX + column] * cosineY)
                        }
                    }
                    bytes.append(Self.sRGB(color.x))
                    bytes.append(Self.sRGB(color.y))
                    bytes.append(Self.sRGB(color.z))
                    bytes.append(255)
                }
            }
            return bytes
        }

        private static func cosines(count: Int, length: Int) -> [Double] {
            (0..<length).flatMap { position in
                (0..<count).map { cos(Double.pi * Double(position * $0) / Double(length)) }
            }
        }

        private static func ac(_ quantised: Int) -> Double {
            let value = Double(quantised - 9) / 9
            return value * abs(value)
        }

        private static func linear(_ channel: Int) -> Double {
            let value = Double(channel) / 255
            return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }

        private static func sRGB(_ linear: Double) -> UInt8 {
            let value = min(max(linear, 0), 1)
            let encoded = value <= 0.0031308 ? value * 12.92 : 1.055 * pow(value, 1 / 2.4) - 0.055
            return UInt8((encoded * 255).rounded())
        }
    }

    private static func image(rgbx bytes: [UInt8], width: Int, height: Int) -> UIImage? {
        guard let provider = CGDataProvider(data: Data(bytes) as CFData),
              let space = CGColorSpace(name: CGColorSpace.sRGB),
              let cgImage = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: width * 4,
                space: space,
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
              )
        else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
