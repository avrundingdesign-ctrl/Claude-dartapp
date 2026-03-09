import SwiftUI

/// Overlay for correcting the last turn's scores
struct ScoreCorrectionView: View {
    @State private var selectedDart: Int? = nil
    @State private var dartValues: [Int] = [0, 0, 0]
    @State private var dartMultipliers: [Int] = [1, 1, 1]

    let onConfirm: (Int) -> Void
    let onCancel: () -> Void

    private var totalScore: Int {
        zip(dartValues, dartMultipliers).map(*).reduce(0, +)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }

            VStack(spacing: 16) {
                Text("Wurf korrigieren")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Theme.textPrimary)
                    .padding(.top, 8)

                // Dart slots
                HStack(spacing: 14) {
                    ForEach(0..<3, id: \.self) { i in
                        dartSlot(index: i)
                    }
                }

                // Number pad for selected dart
                if let active = selectedDart {
                    numberPad(for: active)
                        .transition(.opacity)
                }

                // Total
                HStack {
                    Text("Gesamt:")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    Text("\(totalScore)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primary)
                }
                .padding(.horizontal, 4)

                // Buttons
                HStack(spacing: 14) {
                    Button { onCancel() } label: {
                        Text("Abbrechen")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.surface))
                            .foregroundColor(Theme.textPrimary)
                    }
                    .buttonStyle(.plain)

                    Button { onConfirm(totalScore) } label: {
                        Text("Übernehmen")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.primary))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .disabled(dartValues.allSatisfy { $0 == 0 })
                }
            }
            .padding(20)
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Theme.background)
                    .shadow(color: .black.opacity(0.2), radius: 16, y: 6)
            )
            .padding(24)
        }
    }

    // MARK: - Dart Slot

    private func dartSlot(index: Int) -> some View {
        VStack(spacing: 4) {
            Text("Dart \(index + 1)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Theme.textSecondary)

            Button { selectedDart = index } label: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedDart == index ? Theme.primary.opacity(0.12) : Theme.surface)
                    .frame(height: 56)
                    .overlay(
                        Text(displayValue(for: index))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedDart == index ? Theme.primary : Theme.border, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func displayValue(for i: Int) -> String {
        let v = dartValues[i]
        let m = dartMultipliers[i]
        guard v > 0 else { return "–" }
        if v == 50 { return "Bull" }
        switch m {
        case 2: return "D\(v)"
        case 3: return "T\(v)"
        default: return "\(v)"
        }
    }

    // MARK: - Number Pad

    @ViewBuilder
    private func numberPad(for index: Int) -> some View {
        VStack(spacing: 6) {
            // Numbers 1-20
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 5), spacing: 5) {
                ForEach(1...20, id: \.self) { n in
                    Button {
                        dartValues[index] = n
                        dartMultipliers[index] = 1
                    } label: {
                        Text("\(n)")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity, minHeight: 34)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(dartValues[index] == n ? Theme.primary.opacity(0.15) : Theme.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(dartValues[index] == n ? Theme.primary : Color.clear, lineWidth: 1.5)
                            )
                    }
                    .foregroundColor(Theme.textPrimary)
                    .buttonStyle(.plain)
                }
            }

            // Bulls
            HStack(spacing: 8) {
                specialButton("25", isSelected: dartValues[index] == 25) {
                    dartValues[index] = 25
                    dartMultipliers[index] = 1
                }
                specialButton("Bull", isSelected: dartValues[index] == 50) {
                    dartValues[index] = 50
                    dartMultipliers[index] = 1
                }
            }

            // Multipliers
            HStack(spacing: 12) {
                multiplierButton("D", active: dartMultipliers[index] == 2) {
                    guard dartValues[index] <= 20, dartValues[index] > 0 else { return }
                    dartMultipliers[index] = dartMultipliers[index] == 2 ? 1 : 2
                }
                multiplierButton("T", active: dartMultipliers[index] == 3) {
                    guard dartValues[index] <= 20, dartValues[index] > 0 else { return }
                    dartMultipliers[index] = dartMultipliers[index] == 3 ? 1 : 3
                }
            }
            .padding(.top, 4)
        }
    }

    private func specialButton(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15, weight: .bold))
                .frame(maxWidth: .infinity, minHeight: 34)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Theme.primary.opacity(0.2) : Theme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Theme.primary : Color.clear, lineWidth: 1.5)
                )
                .foregroundColor(Theme.textPrimary)
        }
        .buttonStyle(.plain)
    }

    private func multiplierButton(_ label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15, weight: .bold))
                .padding(.horizontal, 22)
                .padding(.vertical, 8)
                .background(
                    Capsule().fill(active ? Theme.primary.opacity(0.15) : Theme.surface)
                )
                .overlay(
                    Capsule().stroke(active ? Theme.primary : Color.clear, lineWidth: 1.5)
                )
                .foregroundColor(Theme.textPrimary)
        }
        .buttonStyle(.plain)
    }
}
