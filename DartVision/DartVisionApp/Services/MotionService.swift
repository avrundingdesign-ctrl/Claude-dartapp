import Foundation
import CoreMotion

/// Monitors device motion to detect stillness
final class MotionService: ObservableObject {
    private let motionManager = CMMotionManager()
    private var stillnessStart: Date?

    @Published var isStill = false
    @Published var hasBeenStillLongEnough = false

    private let motionThreshold: Double = 0.08
    private let requiredStillness: TimeInterval = 1.0

    func startMonitoring() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 0.15

        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }

            let rotation = motion.rotationRate
            let accel = motion.userAcceleration
            let total = abs(rotation.x) + abs(rotation.y) + abs(rotation.z)
                      + abs(accel.x) + abs(accel.y) + abs(accel.z)

            if total < self.motionThreshold {
                if self.stillnessStart == nil {
                    self.stillnessStart = Date()
                } else if Date().timeIntervalSince(self.stillnessStart!) > self.requiredStillness {
                    if !self.hasBeenStillLongEnough {
                        self.hasBeenStillLongEnough = true
                        print("📱 Gerät ruhig genug für Foto.")
                    }
                }
                self.isStill = true
            } else {
                self.isStill = false
                self.hasBeenStillLongEnough = false
                self.stillnessStart = nil
            }
        }
    }

    func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
        isStill = false
        hasBeenStillLongEnough = false
        stillnessStart = nil
    }

    /// Resets the "still long enough" flag, requiring a new stillness period
    func resetStillness() {
        hasBeenStillLongEnough = false
        stillnessStart = nil
    }
}
