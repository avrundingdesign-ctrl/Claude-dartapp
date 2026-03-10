import Foundation
import CoreGraphics

/// Result of merging new darts from the server with existing tracking history
enum DartMergeResult {
    /// No changes detected — same darts as before
    case unchanged
    /// New darts were added in this round.
    /// `allDarts` = complete history, `newIndices` = indices of newly added darts
    case newDarts(allDarts: [DartData], newIndices: [Int])
}

/// Tracks darts across frames, deduplicates by position, manages rounds of 3 darts
final class DartTracker: ObservableObject {
    private var history: [DartData] = []
    private let tolerance: CGFloat = 20.0
    private var maxDarts = 3
    
    
    @Published var currentRoundScores: [Int] = []

    var historyCount: Int { history.count }

    /// Merges server-detected darts with local tracking.
    /// Returns new darts or signals an unchanged round.
    func merge(with newDarts: [DartData], isBusted: Bool) -> DartMergeResult {
        // If board is empty after a full round, reset
        if newDarts.isEmpty && history.count == maxDarts {
            reset()
        }

        // If current round is full or busted, check if it's the same round
        if history.count == maxDarts || isBusted {
            if isBusted{
                maxDarts = history.count
            }
            let sameRound = newDarts.contains { newDart in
                history.contains { old in
                    hypot(old.x - newDart.x, old.y - newDart.y) < tolerance
                }
            }
            if sameRound {
                return .unchanged
            }
            // New round detected
            print("♻️ Neue Runde erkannt.")
            history.removeAll()
            currentRoundScores = []
        }

        // Capture start index AFTER any potential reset
        let startIndex = history.count
        let sortedNewDarts = newDarts.sorted { $0.confidence > $1.confidence }
        // Add new unique darts
        for newDart in sortedNewDarts {
            guard history.count < maxDarts else { break }

            let isDuplicate = history.contains { old in
                hypot(old.x - newDart.x, old.y - newDart.y) < tolerance
            }

            if isDuplicate {
                continue
            }

            history.append(newDart)
        }

        currentRoundScores = history.map(\.score)

        // Build indices of newly added darts
        let newIndices = Array(startIndex..<history.count)

        if newIndices.isEmpty {
            return .unchanged
        }

        return .newDarts(allDarts: history, newIndices: newIndices)
    }

    func reset() {
        print("🗑️ DartTracker reset.")
        history.removeAll()
        currentRoundScores = []
        maxDarts = 3
    }
}
