import SwiftUI

/// Button that opens a sheet for adding/removing players
struct PlayerSetupButton: View {
    @Binding var players: [Player]
    @State private var showSheet = false
    @State private var newName = ""

    var body: some View {
        Button {
            showSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 16))
                Text(players.isEmpty ? "Spieler" : "\(players.count) Spieler")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.secondary)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSheet) {
            playerSheet
                .presentationDetents([.fraction(0.55)])
        }
    }

    private var playerSheet: some View {
        VStack(spacing: 16) {
            Text("Spieler hinzufügen")
                .font(.title3.bold())
                .padding(.top, 16)

            // Player list
            List {
                Section {
                    ForEach(players) { player in
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(Theme.primary)
                            Text(player.name)
                                .font(.system(size: 17))
                            Spacer()
                            Button {
                                players.removeAll { $0.id == player.id }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(Theme.danger)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section {
                    HStack {
                        TextField("Name eingeben", text: $newName)
                            .textFieldStyle(.roundedBorder)
                            .disableAutocorrection(true)
                            .autocapitalization(.words)

                        Button("Hinzufügen") {
                            let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmed.isEmpty && players.count < 2 {
                                players.append(Player(name: trimmed, startScore: 301))
                                newName = ""
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.primary)
                        .disabled(players.count >= 2 || newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .listStyle(.insetGrouped)

            Text("Maximal 2 Spieler.")
                .font(.footnote)
                .foregroundColor(Theme.textSecondary)

            Button("Fertig") {
                showSheet = false
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.primary)
            .padding(.bottom, 12)
        }
    }
}
