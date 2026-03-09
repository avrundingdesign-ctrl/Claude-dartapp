import Foundation
import CoreGraphics

// MARK: - Server Response

struct ServerResponse: Codable {
    let keypoints: ServerKeypoints
    let darts: [DartData]
}

struct ServerKeypoints: Codable {
    let top: [CGFloat]
    let right: [CGFloat]
    let bottom: [CGFloat]
    let left: [CGFloat]

    /// All four keypoints have exactly 2 values (x, y)
    var isValid: Bool {
        [top, right, bottom, left].allSatisfy { $0.count == 2 }
    }

    func toBoardKeypoints() -> BoardKeypoints {
        BoardKeypoints(
            top: CGPoint(x: top[0], y: top[1]),
            right: CGPoint(x: right[0], y: right[1]),
            bottom: CGPoint(x: bottom[0], y: bottom[1]),
            left: CGPoint(x: left[0], y: left[1])
        )
    }
}

struct DartData: Codable, Identifiable {
    var id = UUID()
    let x: CGFloat
    let y: CGFloat
    let score: Int
    let field_type: String

    private enum CodingKeys: String, CodingKey {
        case x, y, score, field_type
    }
}
