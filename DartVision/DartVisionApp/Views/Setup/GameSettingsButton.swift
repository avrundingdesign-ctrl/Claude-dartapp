import SwiftUI

/// Button that opens game settings (mode, double out)
struct GameSettingsButton: View {
    @Binding var gameMode: GameMode
    @Binding var doubleOut: Bool
    @State private var showSheet = false

    var body: some View {
        Button {
            showSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .bold))
                Text(gameMode.rawValue)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.secondaryDark)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSheet) {
            settingsSheet
                .presentationDetents([.fraction(0.35)])
        }
    }

    private var settingsSheet: some View {
        VStack(spacing: 20) {
            Text("Spieleinstellungen")
                .font(.title3.bold())
                .padding(.top, 16)

            Picker("Modus", selection: $gameMode) {
                ForEach(GameMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)

            Toggle("Double Out", isOn: $doubleOut)
                .padding(.horizontal, 24)
                .toggleStyle(SwitchToggleStyle(tint: Theme.primary))

            Spacer()
        }
    }
}
