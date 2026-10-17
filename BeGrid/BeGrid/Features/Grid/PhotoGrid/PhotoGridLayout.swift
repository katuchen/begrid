import SwiftUI

enum PhotoGridLayout {
    static let spacing: CGFloat = 2
    static let columns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: 2)
}
