import SwiftUI
import AVFoundation

/// ViewModel for the analog (manual) dart scoring mode
@MainActor
final class AnalogGameViewModel: ObservableObject {
    @Published var selectedMode: GameMode?
    @Published var player1Name = ""
    @Published var player2Name = ""
    @Published var doubleOut = false
    @Published var gameStarted = false
    @Published var players: [Player] = []
    @Published var currentPlayerIndex = 0
    @Published var multiplier = 1
    @Published var dartsThrown = 0
    @Published var showWinAlert = false
    @Published var winnerName = ""

    private let synthesizer = AVSpeechSynthesizer()

    var canStart: Bool {
        selectedMode != nil && !player1Name.isEmpty && !player2Name.isEmpty
    }

    func startGame() {
        guard let mode = selectedMode else { return }
        players = [
            Player(name: player1Name, startScore: mode.startScore),
            Player(name: player2Name, startScore: mode.startScore)
        ]
        currentPlayerIndex = 0
        multiplier = 1
        dartsThrown = 0
        gameStarted = true
        speak("Spiel gestartet mit \(mode.startScore) Punkten.")
    }

    func resetGame() {
        gameStarted = false
        players.removeAll()
        selectedMode = nil
        player1Name = ""
        player2Name = ""
        multiplier = 1
        dartsThrown = 0
        speak("Spiel gestoppt.")
    }

    func addScore(_ base: Int) {
        guard gameStarted, !players.isEmpty else { return }

        let score = base * multiplier
        let currentRest = players[currentPlayerIndex].remaining
        let newRest = currentRest - score

        if newRest < 0 {
            speak("Überworfen! Nächster Spieler.")
            nextPlayer()
            return
        }

        if newRest == 0 {
            if doubleOut {
                if multiplier == 2 {
                    winnerName = players[currentPlayerIndex].name
                    showWinAlert = true
                    speak("\(players[currentPlayerIndex].name) gewinnt mit Double Out!")
                } else {
                    speak("Kein Double Out! Überworfen.")
                    nextPlayer()
                }
            } else {
                winnerName = players[currentPlayerIndex].name
                showWinAlert = true
                speak("\(players[currentPlayerIndex].name) gewinnt!")
            }
            return
        }

        players[currentPlayerIndex].remaining = newRest
        speak("\(score) Punkte. Rest \(newRest)")

        dartsThrown += 1
        if dartsThrown == 3 {
            dartsThrown = 0
            nextPlayer()
        }

        multiplier = 1
    }

    private func nextPlayer() {
        dartsThrown = 0
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        speak("Nächster Spieler: \(players[currentPlayerIndex].name)")
    }

    private func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "de-DE")
        utterance.rate = 0.45
        synthesizer.speak(utterance)
    }
}
