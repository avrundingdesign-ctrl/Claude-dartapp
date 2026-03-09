import SwiftUI

/// Displays the list of players with their scores during an active game
struct PlayerScoreList: View {
    let players: [Player]
    let currentIndex: Int

    var body: some View {
        VStack(spacing: 10) {
            ForEach(players.indices, id: \.self) { i in
                let player = players[i]
                let isActive = i == currentIndex

                HStack {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(isActive ? Theme.primary : Theme.disabled)
                            .frame(width: 10, height: 10)

                        Text(player.name)
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(isActive ? Theme.primary : Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Text("\(player.remaining)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(isActive ? Theme.primary : Theme.textSecondary)
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Theme.surface)
                        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isActive ? Theme.primary.opacity(0.5) : Color.clear, lineWidth: 2)
                        )
                )
            }
        }
    }
}
