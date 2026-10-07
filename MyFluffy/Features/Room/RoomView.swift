import SpriteKit
import SwiftUI
import UIKit

struct RoomView: View {
    @EnvironmentObject private var model: RoomViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var stage = CatStageHolder()

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            RoomBackdrop(night: model.nightVisible)
                .ignoresSafeArea()
            if ArtImage.named("room_night_clean") == nil {
                NightCover(visible: model.nightVisible)
            }
            RoomOwnedDecor(shop: model.shop, night: model.nightVisible)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                HStack {
                    if !model.isSleeping && !model.isFeeding {
                        FluffyIconButton(
                            symbol: "bag.fill",
                            fallback: "bag",
                            label: "Магазин",
                            action: { model.openShop() }
                        )
                    } else {
                        Color.clear.frame(width: AppMetrics.childButton, height: AppMetrics.childButton)
                    }
                    Spacer(minLength: 0)
                    Text(model.petName)
                        .font(AppFonts.heading())
                        .foregroundStyle(nameColor)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    FluffyIconButton(
                        symbol: "house.fill",
                        fallback: "house",
                        label: String(localized: "На стартовый экран"),
                        action: { model.leaveGame() }
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                NeedScales(needs: model.needs)
                Spacer(minLength: 0)
            }
            VStack {
                HStack(spacing: 12) {
                    ForEach(CareAccess.blinkingNeeds(for: model.needs), id: \.self) { need in
                        if need == .toilet {
                            Button { model.openToilet() } label: { BlinkingNeedIcon(need: need).frame(width: 64, height: 64) }
                                .accessibilityLabel(Text("Убрать лоток"))
                        } else {
                            BlinkingNeedIcon(need: need)
                        }
                    }
                }
                .padding(.bottom, 220)
            }
            VStack {
                Spacer(minLength: 0)
                cat
                Color.clear.frame(height: 108)
            }
            RoomToyField(shop: model.shop, night: model.nightVisible, play: model.playWithToy)
                .ignoresSafeArea()
            if model.isSleeping == false && model.isFeeding == false && model.showsSleepPrompt == false {
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        roomAction("fork.knife", label: String(localized: "Кухня")) { model.openKitchen() }
                        roomAction("drop.fill", label: "Купание") { model.openBath() }
                        roomAction("gamecontroller.fill", label: "Игры") { model.openPlayMenu() }
                        if model.canSleep { sleepButton }
                    }
                        .padding(.bottom, 28)
                }
            }
            if model.isFeeding {
                VStack {
                    Spacer()
                    Text(String(localized: "Вкусно!"))
                        .font(AppFonts.heading(26))
                        .foregroundStyle(AppColors.ink)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 8)
                        .background(AppColors.yellow)
                        .clipShape(Capsule())
                        .overlay { Capsule().stroke(AppColors.ink, lineWidth: 3) }
                    KitchenMealIllustration(ingredients: model.kitchenSession.selected)
                        .frame(width: 190, height: 110)
                        .accessibilityLabel(Text(String(localized: "Котёнок кушает")))
                    Spacer().frame(height: 150)
                }
                .allowsHitTesting(false)
            }
            if model.showsSleepPrompt {
                SleepPrompt(
                    onYes: { model.beginSleep() },
                    onNo: { model.cancelSleepPrompt() }
                )
            }
        }
        .onAppear {
            stage.scene.setReduceMotion(reduceMotion)
            stage.scene.setLook(model.look)
            stage.scene.setOutfit(model.shop)
        }
        .onChange(of: model.look) { look in
            stage.scene.setLook(look)
        }
        .onChange(of: reduceMotion) { enabled in
            stage.scene.setReduceMotion(enabled)
        }
        .onChange(of: model.shop) { shop in
            stage.scene.setOutfit(shop)
        }
    }

    private var nameColor: Color {
        if model.nightVisible, ArtImage.named("room_night_clean") == nil {
            return AppColors.yellow
        }
        return AppColors.ink
    }

    private var cat: some View {
        ZStack {
            SpriteView(scene: stage.scene, options: [.allowsTransparency])
                .allowsHitTesting(false)
            if model.isSleeping {
                Image(systemName: UIImage(systemName: "zzz") == nil ? "moon.fill" : "zzz")
                    .font(AppFonts.heading(40))
                    .foregroundStyle(AppColors.yellow)
                    .offset(y: -120)
                    .accessibilityLabel(Text(String(localized: "Спит")))
            }
            hearts
        }
        .frame(width: 280, height: 280)
        .offset(y: model.isSleeping ? -35 : 0)
        .contentShape(Rectangle())
        .gesture(petGesture)
        .accessibilityLabel(Text(String(localized: "Котёнок")))
        .accessibilityAddTraits(.isButton)
    }

    private var sleepButton: some View {
        Button(action: { model.requestSleep() }) {
            if let image = ArtImage.named("sticker_moon") {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 88, height: 88)
            } else {
                Image(systemName: UIImage(systemName: "moon.fill") == nil ? "moon" : "moon.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(AppColors.ink)
                    .frame(width: AppMetrics.childButton, height: AppMetrics.childButton)
                    .background(AppColors.yellow)
                    .clipShape(Circle())
            }
        }
        .buttonStyle(FluffyPressStyle(reduceMotion: reduceMotion))
        .accessibilityLabel(Text(String(localized: "Сон")))
    }

    private func roomAction(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        FluffyIconButton(symbol: symbol, fallback: "circle.fill", label: label, action: action)
    }

    private var petGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard model.isSleeping == false else { return }
                model.beginStroke()
                model.pet(at: value.location)
            }
            .onEnded { value in
                if model.isSleeping {
                    model.wake()
                } else {
                    model.pet(at: value.location)
                    model.endStroke()
                }
            }
    }

    @ViewBuilder
    private var hearts: some View {
        if reduceMotion == false {
            ForEach(model.hearts) { heart in
                heartSticker
                    .position(heart.point)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }

    @ViewBuilder
    private var heartSticker: some View {
        if let image = ArtImage.named("sticker_heart") {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
        } else {
            Image(systemName: "heart.fill")
                .font(.system(size: 28))
                .foregroundStyle(AppColors.pink)
        }
    }
}

struct RoomBackdrop: View {
    let night: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            picture("room_day_clean")
            picture("room_night_clean")
                .opacity(night ? 1 : 0)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: AppMetrics.nightFade), value: night)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func picture(_ name: String) -> some View {
        if let image = ArtImage.named(name) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
    }
}

final class CatStageHolder: ObservableObject {
    let scene = CatScene()
}
