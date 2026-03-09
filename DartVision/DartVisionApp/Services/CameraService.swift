import AVFoundation
import UIKit
import Combine

/// Manages the camera session and photo capture
@MainActor
final class CameraService: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var photoContinuation: CheckedContinuation<UIImage?, Never>?

    @Published private(set) var isConfigured = false

    func configure() {
        guard !isConfigured else { return }
        session.beginConfiguration()

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device)
        else {
            print("❌ Kamera konnte nicht initialisiert werden.")
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(photoOutput) { session.addOutput(photoOutput) }

        session.commitConfiguration()
        session.startRunning()
        isConfigured = true
        print("📸 Kamera konfiguriert.")
    }

    func capturePhoto() async -> UIImage? {
        guard isConfigured else { return nil }
        return await withCheckedContinuation { continuation in
            self.photoContinuation = continuation
            let settings = AVCapturePhotoSettings()
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    func ensureRunning() {
        if !session.isRunning {
            session.startRunning()
        }
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            print("❌ Fotoverarbeitung fehlgeschlagen: \(error.localizedDescription)")
            Task { @MainActor in photoContinuation?.resume(returning: nil); photoContinuation = nil }
            return
        }
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            print("⚠️ Konnte Bilddaten nicht lesen.")
            Task { @MainActor in photoContinuation?.resume(returning: nil); photoContinuation = nil }
            return
        }
        Task { @MainActor in
            photoContinuation?.resume(returning: image)
            photoContinuation = nil
        }
    }
}
