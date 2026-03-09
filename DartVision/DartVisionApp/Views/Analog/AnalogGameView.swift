import SwiftUI

/// Analog dart scoring mode — manual input without camera
struct AnalogGameView: View {
    @StateObject private var viewModel = AnalogGameViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !viewModel.gameStarted {
                    setupSection
                } else {
                    gameSection
                }
            }
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .alert("Spiel beendet", isPresented: $viewModel.showWinAlert) {
            Button("OK") { viewModel.resetGame() }
        } message: {
            Text("\(viewModel.winnerName) hat gewonnen!")
        }
    }

    // MARK: - Setup

    private var setupSection: some View {
        VStack(spacing: 20) {
            Text("Analog Modus")
                .font(.custom("Italiana-Regular", size: 40))
                .foregroundColor(Theme.textPrimary)
                .padding(.top, 40)

            // Mode selection
            HStack(spacing: 16) {
                modeButton("301", mode: .threeOhOne)
                modeButton("501", mode: .fiveOhOne)
            }
            .padding(.horizontal, 32)

            // Player names
            VStack(spacing: 14) {
                styledTextField("Spieler 1", text: $viewModel.player1Name)
                styledTextField("Spieler 2", text: $viewModel.player2Name)
            }
            .padding(.horizontal, 32)

            // Double Out
            Toggle(isOn: $viewModel.doubleOut) {
                Text("Double Out")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
            }
            .toggleStyle(SwitchToggleStyle(tint: Theme.primary))
            .padding(.horizontal, 32)

            // Start
            Button { viewModel.startGame() } label: {
                Text("Spiel starten")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(viewModel.canStart ? Theme.primary : Theme.disabled)
                    )
            }
            .disabled(!viewModel.canStart)
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Active Game

    private var gameSection: some View {
        VStack(spacing: 16) {
            // Current player
            Text("Am Zug: \(viewModel.players[viewModel.currentPlayerIndex].name)")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Theme.textPrimary)
                .padding(.top, 20)

            // Scores
            HStack(spacing: 16) {
                ForEach(viewModel.players.indices, id: \.self) { i in
                    VStack(spacing: 6) {
                        Text(viewModel.players[i].name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        Text("\(viewModel.players[i].remaining)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(i == viewModel.currentPlayerIndex ? Theme.primary : Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Multipliers
            HStack(spacing: 20) {
                multiplierButton("D", value: 2, color: Theme.danger)
                multiplierButton("T", value: 3, color: Theme.primary)
            }
            .padding(.top, 4)

            // Number grid 1-20
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                ForEach(1...20, id: \.self) { num in
                    Button { viewModel.addScore(num) } label: {
                        Text("\(num)")
                            .font(.system(size: 20, weight: .semibold))
                            .frame(width: 56, height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Theme.secondary)
                            )
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)

            // Bull buttons
            HStack(spacing: 24) {
                Button { viewModel.addScore(25) } label: {
                    Text("25")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 90, height: 52)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.secondary))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Button { viewModel.addScore(50) } label: {
                    Text("50")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(width: 90, height: 52)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.secondary))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }

            // Stop button
            Button { viewModel.resetGame() } label: {
                Text("Spiel beenden")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Theme.danger)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            .padding(.top, 10)
        }
    }

    // MARK: - Components

    private func modeButton(_ title: String, mode: GameMode) -> some View {
        Button {
            viewModel.selectedMode = mode
        } label: {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.selectedMode == mode ? Theme.secondaryDark : Theme.secondary)
                )
        }
        .buttonStyle(.plain)
    }

    private func multiplierButton(_ title: String, value: Int, color: Color) -> some View {
        Button {
            viewModel.multiplier = value
        } label: {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .frame(width: 72, height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.multiplier == value ? color : color.opacity(0.4))
                )
                .foregroundColor(.white)
        }
        .buttonStyle(.plain)
    }

    private func styledTextField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.surface)
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.primary.opacity(0.3), lineWidth: 1)
            )
            .font(.system(size: 17, weight: .medium))
            .foregroundColor(Theme.textPrimary)
            .autocapitalization(.words)
    }
}
