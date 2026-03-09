import SwiftUI

/// Shows 3 dart slots for the current throw
struct CurrentThrowView: View {
    let scores: [Int]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { index in
                let hasScore = index < scores.count
                let scoreText = hasScore ? "\(scores[index])" : "–"

                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(hasScore ? Theme.primary.opacity(0.12) : Theme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(hasScore ? Theme.primary.opacity(0.4) : Theme.border, lineWidth: 2)
                        )

                    VStack(spacing: 2) {
                        Text("Dart \(index + 1)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                        Text(scoreText)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(hasScore ? Theme.textPrimary : Theme.disabled)
                    }
                }
                .frame(height: 64)
                .frame(maxWidth: .infinity)
            }
        }
    }
}
