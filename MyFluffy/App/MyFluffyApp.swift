import SwiftUI

@main
struct MyFluffyApp: App {
    @StateObject private var model: RoomViewModel
    private let sound: BundleSoundPlayer

    init() {
        let sound = BundleSoundPlayer()
        self.sound = sound
        _model = StateObject(wrappedValue: RoomViewModel(sound: sound))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
        }
    }
}
