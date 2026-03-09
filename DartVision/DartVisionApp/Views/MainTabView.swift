import SwiftUI

/// Root navigation — switches between Vision (camera) and Analog mode
struct MainTabView: View {
    @StateObject private var gameVM = GameViewModel()
    @State private var selectedTab: Tab = .vision

    enum Tab: String, CaseIterable {
        case vision = "Vision"
        case analog = "Analog"

        var icon: String {
            switch self {
            case .vision: return "camera.viewfinder"
            case .analog: return "hand.tap"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Content
            Group {
                switch selectedTab {
                case .vision:
                    VisionGameView(viewModel: gameVM)
                case .analog:
                    AnalogGameView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Only show tab bar when not in active game
            if gameVM.phase != .playing && gameVM.phase != .paused {
                tabBar
            }
        }
        .background(Theme.background)
        .ignoresSafeArea(edges: .bottom)
    }

    private var tabBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.2)
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: .semibold))
                            Text(tab.rawValue)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(selectedTab == tab ? Theme.primary : Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .background(Theme.surface)
        }
    }
}
