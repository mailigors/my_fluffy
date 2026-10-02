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
