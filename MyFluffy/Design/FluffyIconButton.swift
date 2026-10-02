import SwiftUI
import UIKit

struct FluffyIconButton: View {
    let symbol: String
    let fallback: String
    let label: String
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            Image(systemName: resolvedSymbol)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(AppColors.ink)
                .frame(minWidth: AppMetrics.childButton, minHeight: AppMetrics.childButton)
                .background(AppColors.yellow)
                .clipShape(Circle())
        }
        .buttonStyle(FluffyPressStyle(reduceMotion: reduceMotion))
        .accessibilityLabel(Text(label))
    }

    private var resolvedSymbol: String {
        UIImage(systemName: symbol) == nil ? fallback : symbol
    }
}

struct FluffyPressStyle: ButtonStyle {
    var reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && reduceMotion == false ? 0.95 : 1)
            .animation(reduceMotion ? nil : AppMetrics.spring, value: configuration.isPressed)
    }
}
