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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.top = (try? container.decode([CGFloat].self, forKey: .top)) ?? []
        self.right = (try? container.decode([CGFloat].self, forKey: .right)) ?? []
        self.bottom = (try? container.decode([CGFloat].self, forKey: .bottom)) ?? []
        self.left = (try? container.decode([CGFloat].self, forKey: .left)) ?? []
    }

    /// All four keypoints have exactly 2 values (x, y)
    var isValid: Bool {
        [top, right, bottom, left].allSatisfy { $0.count == 2 }
    }

    func toBoardKeypoints() -> BoardKeypoints {
        guard isValid else {
            return BoardKeypoints(top: .zero, right: .zero, bottom: .zero, left: .zero)
        }
        return BoardKeypoints(
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
    let confidence: Double
    private enum CodingKeys: String, CodingKey {
        case x, y, score, field_type, confidence
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // x/y might come as Int or Double from Python
        if let xDouble = try? container.decode(Double.self, forKey: .x) {
            self.x = CGFloat(xDouble)
        } else if let xInt = try? container.decode(Int.self, forKey: .x) {
            self.x = CGFloat(xInt)
        } else {
            self.x = 0
        }
        if let yDouble = try? container.decode(Double.self, forKey: .y) {
            self.y = CGFloat(yDouble)
        } else if let yInt = try? container.decode(Int.self, forKey: .y) {
            self.y = CGFloat(yInt)
        } else {
            self.y = 0
        }
        self.score = (try? container.decode(Int.self, forKey: .score)) ?? 0
        self.field_type = (try? container.decode(String.self, forKey: .field_type)) ?? "miss"
        self.confidence = (try? container.decode(Double.self, forKey: .confidence)) ?? 0.0
    }
}
