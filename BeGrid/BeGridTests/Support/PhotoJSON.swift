import Foundation

enum PhotoJSON {
    static func photos(count: Int) -> Data {
        Data("[\(photoObjects(count: count))]".utf8)
    }

    static func search(totalPages: Int, count: Int) -> Data {
        Data(#"{"total_pages": \#(totalPages), "results": [\#(photoObjects(count: count))]}"#.utf8)
    }

    private static func photoObjects(count: Int) -> String {
        (0..<count).map(photoObject(index:)).joined(separator: ",")
    }

    private static func photoObject(index: Int) -> String {
        let url = "https://images.unsplash.com/photo-\(index)"
        return #"""
        {"id": "photo-\#(index)", "urls": {"raw": "\#(url)", "full": "\#(url)", "regular": "\#(url)", "small": "\#(url)"},
         "user": {"username": "user-\#(index)"}}
        """#
    }
}
