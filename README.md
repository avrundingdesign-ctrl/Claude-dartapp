# DartVision 🎯

Eine iOS-App zur automatischen Dart-Erkennung mit Kamera und Server-basierter Bildverarbeitung.

## Architektur

```
DartVisionApp/
├── DartVisionApp.swift              # App Entry Point
├── Info.plist                       # App permissions (Camera, Photos, HTTP)
│
├── Models/
│   ├── GameModels.swift             # Player, GamePhase, GameMode, BoardKeypoints
│   └── ServerModels.swift           # ServerResponse, DartData, ServerKeypoints
│
├── Services/
│   ├── CameraService.swift          # Kamera-Capture (async/await)
│   ├── MotionService.swift          # Bewegungserkennung (CoreMotion)
│   ├── NetworkService.swift         # Server-Kommunikation (Upload + Decode)
│   ├── SpeechService.swift          # Text-to-Speech (deutsch)
│   ├── PhotoLibraryService.swift    # Fotos in Album speichern
│   └── DartTracker.swift            # Dart-Deduplizierung & Runden-Tracking
│
├── ViewModels/
│   ├── GameViewModel.swift          # Haupt-Spiellogik (Vision-Modus)
│   └── AnalogGameViewModel.swift    # Analog-Modus Spiellogik
│
├── Views/
│   ├── MainTabView.swift            # Tab-Navigation (Vision / Analog)
│   ├── Setup/
│   │   ├── PlayerSetupButton.swift  # Spieler hinzufügen/entfernen
│   │   └── GameSettingsButton.swift # 301/501, Double Out
│   ├── Game/
│   │   ├── VisionGameView.swift     # Hauptansicht Vision-Modus
│   │   ├── PlayerScoreList.swift    # Spieler-Scores
│   │   ├── CurrentThrowView.swift   # 3 Dart-Slots
│   │   ├── CameraPreviewView.swift  # Kamera-Vorschau
│   │   ├── CalibrationOverlay.swift # Kalibrierungs-Status
│   │   ├── GameControlsView.swift   # Stop, Pause, Korrektur
│   │   ├── ScoreCorrectionView.swift # Manuelle Score-Korrektur
│   │   └── WinOverlayView.swift     # Sieges-Overlay
│   └── Analog/
│       └── AnalogGameView.swift     # Analog-Scoring (ohne Kamera)
│
├── Theme/
│   └── Theme.swift                  # Farben, Design-Tokens
│
└── Assets.xcassets/                 # App-Icons, Farben
```

## Features

- 📸 **Automatische Kamera-Aufnahme** — Fotos nur bei Gerätestillstand
- 📱 **Bewegungserkennung** — CoreMotion-basierte Stillstandserkennung
- 🎯 **Board-Kalibrierung** — Keypoints vom Server werden gespeichert
- 📤 **Server-Upload** — Bild + Keypoints per multipart/form-data
- 🏹 **Dart-Tracking** — Deduplizierung über Position, Rundenmanagement
- 🎮 **Spielmodi** — 301 / 501 mit optionalem Double Out
- 🔧 **Score-Korrektur** — Manuelle Korrektur des letzten Wurfs
- 🏆 **Sieg-Erkennung** — Overlay mit Animation
- 🗣️ **Sprachausgabe** — Scores auf Deutsch
- 🎲 **Analog-Modus** — Manuelles Scoring ohne Kamera
- 👥 **2-Spieler-Modus** — Spielerwechsel automatisch
- 📷 **Foto-Speicherung** — Album "DartImages"

## Server-API

Die App kommuniziert mit einem Python-Server:

**Endpoint:** `POST http://192.168.178.106:5000/upload`

**Request:** multipart/form-data
- `file`: JPEG-Bild
- `keypoints`: JSON-String mit Board-Keypoints

**Response:**
```json
{
  "keypoints": {
    "top": [x, y],
    "right": [x, y],
    "bottom": [x, y],
    "left": [x, y]
  },
  "darts": [
    {
      "x": 123.4,
      "y": 567.8,
      "score": 20,
      "field_type": "triple"
    }
  ]
}
```

## Setup

1. Öffne `DartVision/DartVision.xcodeproj` in Xcode
2. Wähle dein Development Team unter Signing & Capabilities
3. Passe die Server-URL in `NetworkService.swift` an
4. Build & Run auf einem echten iOS-Gerät (Kamera erforderlich)

## Voraussetzungen

- iOS 17.0+
- Xcode 15+
- Python-Server muss im gleichen Netzwerk laufen