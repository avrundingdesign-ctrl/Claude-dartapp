import SwiftUI

/// Victory overlay shown when a player wins
struct WinOverlayView: View {
    let winnerName: String
    let resetAction: () -> Void

    @State private var trophyScale: CGFloat = 0.5
    @State private var trophyRotation: Double = -10

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Trophy
                Image(systemName: "trophy.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(Color(hex: "#FFD700"))
                    .shadow(color: .yellow.opacity(0.6), radius: 12)
                    .scaleEffect(trophyScale)
                    .rotationEffect(.degrees(trophyRotation))
                    .onAppear {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                            trophyScale = 1.0
                            trophyRotation = 0
                        }
                    }

                Text("SIEG!")
                    .font(.custom("Italiana-Regular", size: 48))
                    .foregroundColor(Theme.textPrimary)

                Text("\(winnerName) hat gewonnen!")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center)

                Button {
                    resetAction()
                } label: {
                    Text("Neues Spiel")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Theme.primary)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(36)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Theme.background)
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            )
        }
    }
}
