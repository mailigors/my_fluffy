import SwiftUI

struct SleepPrompt: View {
    let onYes: () -> Void
    let onNo: () -> Void

    var body: some View {
        ZStack {
            AppColors.ink.opacity(0.25)
                .ignoresSafeArea()
            VStack(spacing: 24) {
                moon
                    .accessibilityLabel(Text(String(localized: "Уложить спать?")))
                HStack(spacing: 24) {
                    FluffyIconButton(
                        symbol: "checkmark",
                        fallback: "checkmark",
                        label: String(localized: "Да"),
                        action: onYes
                    )
                    FluffyIconButton(
                        symbol: "xmark",
                        fallback: "xmark",
                        label: String(localized: "Нет"),
                        action: onNo
                    )
                }
            }
            .padding(32)
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }

    @ViewBuilder
    private var moon: some View {
        if let image = ArtImage.named("sticker_moon") {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
        } else {
            Image(systemName: "moon.fill")
                .font(.system(size: 88))
                .foregroundStyle(AppColors.yellow)
        }
    }
}

struct NightCover: View {
    let visible: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            AppColors.night
                .opacity(visible ? 0.9 : 0)
            if visible {
                star
                    .position(x: 70, y: 90)
                star
                    .position(x: 280, y: 140)
                star
                    .position(x: 160, y: 50)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .animation(reduceMotion ? nil : .easeInOut(duration: AppMetrics.nightFade), value: visible)
    }

    private var star: some View {
        Image(systemName: "star.fill")
            .font(.system(size: 22))
            .foregroundStyle(AppColors.yellow)
            .accessibilityHidden(true)
    }
}
