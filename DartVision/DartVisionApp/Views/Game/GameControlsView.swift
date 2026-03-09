import SwiftUI

/// Controls shown during an active game: stop, pause, correction
struct GameControlsView: View {
    let isPaused: Bool
    let onStop: () -> Void
    let onPause: () -> Void
    let onCorrection: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            // Stop & Pause
            HStack(spacing: 12) {
                controlButton(
                    icon: "stop.fill",
                    color: Theme.danger
                ) {
                    onStop()
                }

                controlButton(
                    icon: isPaused ? "play.fill" : "pause.fill",
                    color: Theme.primary
                ) {
                    onPause()
                }
            }

            // Correction
            Button {
                onCorrection()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.rays")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Korrektur")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Theme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.textPrimary.opacity(0.08))
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func controlButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(color)
                )
        }
        .buttonStyle(.plain)
    }
}
