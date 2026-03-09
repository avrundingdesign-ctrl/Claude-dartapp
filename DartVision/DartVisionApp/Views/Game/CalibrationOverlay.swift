import SwiftUI

/// Calibration status overlay shown during active game
struct CalibrationOverlay: View {
    let isCalibrated: Bool
    let showPopup: Bool
    let isActive: Bool

    var body: some View {
        if isActive {
            VStack {
                Spacer().frame(height: 60)

                if !isCalibrated {
                    statusBadge(
                        icon: nil,
                        text: "Warten auf Kalibrierung...",
                        color: .yellow,
                        textColor: .black,
                        showSpinner: true
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                } else if showPopup {
                    statusBadge(
                        icon: "checkmark.circle.fill",
                        text: "Kalibriert",
                        color: .green,
                        textColor: .white,
                        showSpinner: false
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()
            }
            .animation(.easeInOut, value: isCalibrated)
            .animation(.easeInOut, value: showPopup)
        }
    }

    private func statusBadge(icon: String?, text: String, color: Color,
                              textColor: Color, showSpinner: Bool) -> some View {
        HStack(spacing: 12) {
            if showSpinner {
                ProgressView()
                    .tint(textColor)
            }
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 22))
            }
            Text(text)
                .font(.system(size: 16, weight: .bold))
        }
        .foregroundColor(textColor)
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color)
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        )
    }
}
