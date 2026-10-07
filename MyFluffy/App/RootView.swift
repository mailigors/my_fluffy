import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: RoomViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch model.route {
            case .loading:
                LoadingView()
            case .start:
                StartView()
            case .onboarding:
                OnboardingView()
            case .room:
                RoomView()
            case .kitchen:
                KitchenView()
            case .bath:
                BathView()
            case .toilet:
                ToiletView()
            case .playMenu:
                PlayMenuView()
            case .fish:
                FishGameView()
            case .clouds:
                CloudGameView()
            case .puzzleMenu:
                PuzzleSelectionView()
            case .puzzle:
                PuzzleGameView()
            case .memory:
                MemoryGameView()
            case .ticTacToe:
                TicTacToeGameView()
            case .beaver:
                BeaverGameView()
            case .airHockey:
                AirHockeyView()
            case .toyTargets:
                ToyTargetsView()
            case .shop:
                ShopView()
            case .wardrobe:
                WardrobeView()
            case .parentGate:
                ParentGateView()
            case .parentSettings:
                ParentSettingsView()
            case .unavailable:
                retry
            }
        }
        .onChange(of: scenePhase) { phase in
            model.sceneChanged(to: phase)
        }
    }

    private var retry: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            FluffyIconButton(
                symbol: "arrow.clockwise",
                fallback: "arrow.clockwise",
                label: String(localized: "Ещё раз"),
                action: { model.retry() }
            )
        }
    }
}
