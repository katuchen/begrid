import Foundation

struct PhotoDetailRoute: Identifiable {
    let photos: [Photo]
    let selectedID: Photo.ID
    let previewPixelSize: PixelSize

    var id: Photo.ID {
        selectedID
    }
}
