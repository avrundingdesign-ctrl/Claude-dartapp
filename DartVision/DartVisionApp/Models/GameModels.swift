import Foundation
import CoreGraphics

// MARK: - Game State

enum GamePhase {
    case setup
    case playing
    case paused
    case finished
}

// MARK: - Game Mode

enum GameMode: String, CaseIterable, Identifiable {
    case threeOhOne = "301"
    case fiveOhOne = "501"

    var id: String { rawValue }
    var startScore: Int {
        switch self {
        case .threeOhOne: return 301
        case .fiveOhOne: return 501
        }
    }
}

// MARK: - Player

struct Player: Identifiable, Equatable {
    let id: UUID
    var name: String
    var remaining: Int
    var isActive: Bool

    init(name: String, startScore: Int) {
        self.id = UUID()
        self.name = name
        self.remaining = startScore
        self.isActive = false
    }
}

// MARK: - Turn Snapshot (for correction)

struct TurnSnapshot {
    let playerIndex: Int
    let scoreThrown: Int
    let previousRemaining: Int
}

// MARK: - Keypoints

struct BoardKeypoints: Equatable {
    var top: CGPoint
    var right: CGPoint
    var bottom: CGPoint
    var left: CGPoint

    func toDictionary() -> [String: [CGFloat]] {
        [
            "top": [top.x, top.y],
            "right": [right.x, right.y],
            "bottom": [bottom.x, bottom.y],
            "left": [left.x, left.y]
        ]
    }
}
