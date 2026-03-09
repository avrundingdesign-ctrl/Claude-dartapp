import SwiftUI
import Combine

/// Central ViewModel orchestrating all game logic, camera, and server communication
@MainActor
final class GameViewModel: ObservableObject {

    // MARK: - Services
    let cameraService = CameraService()
    let motionService = MotionService()
    let speechService = SpeechService()
    let dartTracker = DartTracker()
    private let networkService = NetworkService()

    // MARK: - Game State
    @Published var phase: GamePhase = .setup
    @Published var gameMode: GameMode = .threeOhOne
    @Published var doubleOut = false
    @Published var players: [Player] = []
    @Published var currentPlayerIndex = 0
    @Published var showWinOverlay = false
    @Published var winnerName: String?
    @Published var showCorrection = false
    @Published var currentRoundScores: [Int] = []

    // MARK: - Calibration
    @Published var boardKeypoints: BoardKeypoints?
    @Published var showCalibratedPopup = false

    // MARK: - Internal
    private var captureTask: Task<Void, Never>?
    private var isBusted = false
    private var currentTurnScore = 0
    private var turnStartScore = 0
    private var lastTurn: TurnSnapshot?
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Observe dart tracker scores
        dartTracker.$currentRoundScores
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentRoundScores)
    }

    // MARK: - Setup

    func addPlayer(name: String) {
        guard players.count < 2, !name.isEmpty else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !players.contains(where: { $0.name == trimmed }) else { return }
        players.append(Player(name: trimmed, startScore: gameMode.startScore))
    }

    func removePlayer(at index: Int) {
        guard players.indices.contains(index) else { return }
        players.remove(at: index)
    }

    // MARK: - Game Controls

    func startGame() {
        guard !players.isEmpty else { return }

        // Reset all state
        currentTurnScore = 0
        isBusted = false
        currentPlayerIndex = 0
        boardKeypoints = nil
        showWinOverlay = false
        winnerName = nil
        lastTurn = nil
        dartTracker.reset()

        // Initialize player scores
        for i in players.indices {
            players[i].remaining = gameMode.startScore
            players[i].isActive = (i == 0)
        }
        turnStartScore = gameMode.startScore

        phase = .playing
        cameraService.configure()
        startCaptureLoop()

        speechService.speak("Spiel gestartet. \(gameMode.startScore) Punkte.")
        print("🎯 Spiel gestartet: \(players.count) Spieler, \(gameMode.rawValue)")
    }

    func stopGame() {
        phase = .setup
        stopCaptureLoop()
        boardKeypoints = nil
        dartTracker.reset()
        currentTurnScore = 0
    }

    func togglePause() {
        if phase == .paused {
            phase = .playing
            startCaptureLoop()
        } else if phase == .playing {
            phase = .paused
            stopCaptureLoop()
        }
    }

    func finishGame() {
        showWinOverlay = false
        winnerName = nil
        stopCaptureLoop()
        boardKeypoints = nil
        dartTracker.reset()
        currentTurnScore = 0
        phase = .setup
    }

    // MARK: - Score Correction

    func correctLastTurn(newTotal: Int) {
        guard let last = lastTurn else { return }
        print("🔧 Korrektur: \(players[last.playerIndex].name) — Alt \(last.scoreThrown) → Neu \(newTotal)")

        let oldRest = last.previousRemaining
        let correctedRest = oldRest - newTotal

        if correctedRest < 0 {
            players[last.playerIndex].remaining = oldRest
        } else if correctedRest == 0 {
            players[last.playerIndex].remaining = 0
            winnerName = players[last.playerIndex].name
            showWinOverlay = true
            stopCaptureLoop()
        } else {
            players[last.playerIndex].remaining = correctedRest
        }

        lastTurn = TurnSnapshot(playerIndex: last.playerIndex, scoreThrown: newTotal, previousRemaining: oldRest)
        showCorrection = false
        if phase == .paused { togglePause() }
    }

    func openCorrection() {
        showCorrection = true
        if phase == .playing { togglePause() }
    }

    func cancelCorrection() {
        showCorrection = false
        if phase == .paused { togglePause() }
    }

    // MARK: - Capture Loop

    private func startCaptureLoop() {
        motionService.startMonitoring()
        cameraService.ensureRunning()

        captureTask?.cancel()
        captureTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 4_000_000_000) // 4 seconds
                guard !Task.isCancelled else { break }
                await self?.tryCaptureAndUpload()
            }
        }
        print("▶️ Capture-Loop gestartet.")
    }

    private func stopCaptureLoop() {
        captureTask?.cancel()
        captureTask = nil
        motionService.stopMonitoring()
        print("🛑 Capture-Loop gestoppt.")
    }

    private func tryCaptureAndUpload() async {
        guard phase == .playing else { return }
        guard motionService.hasBeenStillLongEnough else {
            print("⏸️ Gerät nicht still genug.")
            return
        }
        guard !speechService.isSpeaking else { return }

        print("📸 Foto wird aufgenommen...")
        guard let image = await cameraService.capturePhoto() else { return }

        // Save to Photos album
        PhotoLibraryService.save(image) { result in
            switch result {
            case .success: print("✅ Foto gespeichert.")
            case .failure(let err): print("❌ Speichern fehlgeschlagen: \(err.localizedDescription)")
            }
        }

        // Upload to server
        do {
            let response = try await networkService.uploadImage(image, keypoints: boardKeypoints)
            processServerResponse(response)
        } catch {
            print("❌ Upload-Fehler: \(error.localizedDescription)")
        }
    }

    // MARK: - Server Response Processing

    private func processServerResponse(_ response: ServerResponse) {
        // Validate keypoints
        guard response.keypoints.isValid else {
            print("⚠️ Ungültige Keypoints → Reset.")
            boardKeypoints = nil
            scheduleRestart(after: 3.0)
            return
        }

        // Store keypoints (only once per calibration)
        if boardKeypoints == nil {
            print("💾 Initiale Keypoints gespeichert.")
            boardKeypoints = response.keypoints.toBoardKeypoints()
            withAnimation {
                showCalibratedPopup = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                withAnimation {
                    self?.showCalibratedPopup = false
                }
            }
        }

        // Process darts
        let countBefore = dartTracker.historyCount
        let result = dartTracker.merge(with: response.darts, isBusted: isBusted)

        switch result {
        case .unchanged:
            print("📊 Keine neuen Darts erkannt.")

        case .newDarts(let allDarts):
            for i in countBefore..<allDarts.count {
                let dart = allDarts[i]
                let dartNumber = i + 1

                if dartNumber < 3 {
                    // Dart 1 or 2: process intermediate throw
                    handleIntermediateThrow(dart)
                } else {
                    // Dart 3: finish the turn
                    let totalScore = allDarts.reduce(0) { $0 + $1.score }
                    speechService.speak("\(totalScore)")
                    handleTurnFinished(dart)
                }
            }
        }

        scheduleRestart(after: 1.0)
    }

    // MARK: - Throw Handling

    private func handleIntermediateThrow(_ dart: DartData) {
        guard !players.isEmpty else { return }

        let idx = currentPlayerIndex
        let currentRest = players[idx].remaining
        currentTurnScore += dart.score
        let newRest = currentRest - currentTurnScore

        if newRest < 0 {
            // Bust
            print("❌ Überworfen!")
            isBusted = true
            speechService.speak("Überworfen")
            players[currentPlayerIndex].remaining = turnStartScore
            advanceToNextPlayer()
            isBusted = false
        } else if newRest == 0 {
            handlePotentialWin(dart: dart, playerIndex: idx)
        }
    }

    private func handleTurnFinished(_ dart: DartData) {
        guard !players.isEmpty else { return }

        let idx = currentPlayerIndex
        let currentRest = players[idx].remaining
        currentTurnScore += dart.score

        lastTurn = TurnSnapshot(playerIndex: idx, scoreThrown: currentTurnScore,
                                previousRemaining: currentRest)

        let newRest = currentRest - currentTurnScore
        speechService.stop()

        if newRest < 0 {
            // Bust
            print("❌ Überworfen!")
            isBusted = true
            speechService.speak("Überworfen")
            players[currentPlayerIndex].remaining = turnStartScore
            advanceToNextPlayer()
            isBusted = false
        } else if newRest == 0 {
            handlePotentialWin(dart: dart, playerIndex: idx)
        } else {
            // Valid throw, update score
            print("✅ Gültiger Wurf. Rest: \(newRest)")
            isBusted = false
            players[idx].remaining = newRest
            speechService.speak("Rest \(newRest)")
            advanceToNextPlayer()
        }
    }

    private func handlePotentialWin(dart: DartData, playerIndex: Int) {
        let playerName = players[playerIndex].name

        if doubleOut && dart.field_type != "double" {
            // Must finish on double
            speechService.speak("Kein Double Out! Überworfen.")
            isBusted = true
            players[currentPlayerIndex].remaining = turnStartScore
            advanceToNextPlayer()
            isBusted = false
        } else {
            // Win!
            players[playerIndex].remaining = 0
            isBusted = false
            winnerName = playerName
            withAnimation(.spring()) {
                showWinOverlay = true
            }
        }
    }

    private func advanceToNextPlayer() {
        currentPlayerIndex = (currentPlayerIndex + 1) % players.count
        currentTurnScore = 0
        turnStartScore = players[currentPlayerIndex].remaining

        // Update active flags
        for i in players.indices {
            players[i].isActive = (i == currentPlayerIndex)
        }
    }

    private func scheduleRestart(after seconds: TimeInterval) {
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard let self, self.phase == .playing else { return }

            // Wait if speech is still active
            if self.speechService.isSpeaking {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
            }

            guard self.phase == .playing, !self.speechService.isSpeaking else { return }
            // The capture loop handles restarts automatically
        }
    }

    // MARK: - Keypoints Reset (for recalibration)

    func resetCalibration() {
        boardKeypoints = nil
        print("📍 Kalibrierung zurückgesetzt.")
    }
}
