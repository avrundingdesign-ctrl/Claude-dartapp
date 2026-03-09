import SwiftUI

/// The main Vision mode view — handles setup and active game display
struct VisionGameView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                switch viewModel.phase {
                case .setup:
                    setupView
                case .playing, .paused:
                    activeGameView
                case .finished:
                    setupView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background)

            // Overlays
            if viewModel.showCorrection {
                ScoreCorrectionView(
                    onConfirm: { total in viewModel.correctLastTurn(newTotal: total) },
                    onCancel: { viewModel.cancelCorrection() }
                )
                .transition(.scale.combined(with: .opacity))
            }

            if viewModel.showWinOverlay, let winner = viewModel.winnerName {
                WinOverlayView(winnerName: winner) {
                    viewModel.finishGame()
                }
                .transition(.opacity)
            }

            CalibrationOverlay(
                isCalibrated: viewModel.boardKeypoints != nil,
                showPopup: viewModel.showCalibratedPopup,
                isActive: viewModel.phase == .playing || viewModel.phase == .paused
            )
        }
        .animation(.easeInOut, value: viewModel.showCorrection)
        .animation(.spring(), value: viewModel.showWinOverlay)
    }

    // MARK: - Setup View

    private var setupView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title
                Text("DartVision")
                    .font(.custom("Italiana-Regular", size: 58))
                    .foregroundColor(Theme.textPrimary)
                    .tracking(3)
                    .padding(.top, 50)

                // Setup buttons
                HStack(spacing: 14) {
                    PlayerSetupButton(players: $viewModel.players)
                    GameSettingsButton(
                        gameMode: $viewModel.gameMode,
                        doubleOut: $viewModel.doubleOut
                    )
                }
                .padding(.horizontal, 20)

                // Camera placeholder
                CameraPlaceholderView()
                    .frame(height: 200)
                    .padding(.horizontal, 20)

                // Start button
                Button {
                    viewModel.startGame()
                } label: {
                    Text("Spiel starten")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(viewModel.players.isEmpty ? Theme.disabled : Theme.primary)
                        )
                }
                .disabled(viewModel.players.isEmpty)
                .buttonStyle(.plain)
                .padding(.horizontal, 20)

                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Active Game View

    private var activeGameView: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 50)

            // Player scores
            PlayerScoreList(
                players: viewModel.players,
                currentIndex: viewModel.currentPlayerIndex
            )
            .padding(.horizontal, 16)

            // Current throw
            CurrentThrowView(scores: viewModel.currentRoundScores)
                .padding(.horizontal, 16)
                .padding(.top, 6)

            // Camera preview
            CameraPreviewView(session: viewModel.cameraService.session)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

            // Game controls
            GameControlsView(
                isPaused: viewModel.phase == .paused,
                onStop: {
                    viewModel.stopGame()
                    viewModel.resetCalibration()
                },
                onPause: { viewModel.togglePause() },
                onCorrection: { viewModel.openCorrection() }
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 20)

            Spacer(minLength: 10)
        }
    }
}
