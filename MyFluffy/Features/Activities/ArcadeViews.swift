import Combine
import SwiftUI

struct AirHockeyView: View {
    @EnvironmentObject private var model: RoomViewModel
    private let ticker = Timer.publish(every: 0.025, on: .main, in: .common).autoconnect()

    var body: some View {
        ActivityScene(art: "room_day", title: "Аэрохоккей") {
            if let round = model.hockeyRound {
                GeometryReader { area in
                    let width = min(area.size.width - 26, 420)
                    let height = min(area.size.height - 300, 540)
                    ZStack {
                        VStack(spacing: 14) {
                            ActivityPrompt(text: "Води ракеткой пальцем · Первый до 3 голов")
                            Text("Ты \(round.childScore) : \(round.catScore) Котёнок  ·  ⏱ \(round.secondsRemaining)")
                                .font(AppFonts.heading(21)).foregroundStyle(AppColors.ink)
                                .padding(10).background(.white.opacity(0.94), in: Capsule())
                            rink(round, width: width, height: height)
                            Spacer(minLength: 0)
                        }
                        .padding(.top, 100)
                        if let outcome = round.outcome {
                            ActivityResult(title: outcome == .child ? "Ты победил!" : (outcome == .cat ? "Котёнок победил!" : "Ничья!"),
                                           detail: outcome == .child ? "+5 монеток" : "Сыграем ещё?",
                                           home: model.closeActivity,
                                           again: model.startAirHockey)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .onReceive(ticker) { _ in model.tickAirHockey() }
            }
        }
    }

    private func rink(_ round: AirHockeyRound, width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 32)
                .fill(LinearGradient(colors: [AppColors.sky.opacity(0.9), .white, AppColors.sky.opacity(0.9)],
                                     startPoint: .top, endPoint: .bottom))
                .overlay { RoundedRectangle(cornerRadius: 32).stroke(AppColors.ink, lineWidth: 5) }
            Rectangle().fill(AppColors.ink.opacity(0.2)).frame(height: 3)
            Circle().stroke(AppColors.ink.opacity(0.2), lineWidth: 3).frame(width: 90, height: 90)
            Capsule().fill(AppColors.pink).frame(width: width * 0.44, height: 12)
                .position(x: width * 0.5, y: 5)
            Capsule().fill(AppColors.mint).frame(width: width * 0.44, height: 12)
                .position(x: width * 0.5, y: height - 5)
            Circle().fill(AppColors.pink).frame(width: 68, height: 68)
                .overlay { Text("🐱").font(.system(size: 39)) }
                .position(x: width * round.catX, y: height * 0.18)
            Circle().fill(AppColors.yellow).frame(width: 36, height: 36)
                .overlay { Circle().stroke(AppColors.ink, lineWidth: 3) }
                .position(x: width * round.puck.x, y: height * round.puck.y)
            Circle().fill(AppColors.mint).frame(width: 74, height: 74)
                .overlay { Circle().stroke(AppColors.ink, lineWidth: 4) }
                .overlay { Text("🐾").font(.system(size: 42)) }
                .position(x: width * round.childX, y: height * 0.82)
        }
        .frame(width: width, height: height)
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0).onChanged { value in
            model.moveHockeyPaddle(to: Double(value.location.x / width))
        })
        .accessibilityLabel("Поле аэрохоккея. Води ракеткой пальцем")
    }
}

struct ToyTargetsView: View {
    @EnvironmentObject private var model: RoomViewModel
    @State private var now = Date()
    @State private var shotPoint: GamePoint?
    @State private var shotProgress: CGFloat = 0
    @State private var lastHit = false
    private let ticker = Timer.publish(every: 0.04, on: .main, in: .common).autoconnect()
    private let targets = ["🎈", "🫧", "⭐️"]

    var body: some View {
        ActivityScene(art: "cloud_scene", title: "Игрушечный тир") {
            if let round = model.toyTargetRound {
                GeometryReader { area in
                    ZStack {
                        VStack {
                            ActivityPrompt(text: "Попади мягким шариком в движущиеся мишени!")
                            Text("Попадания \(round.hits)/\(round.targetHits)  ·  Шарики \(round.maxShots - round.shots)  ·  ⏱ \(round.secondsRemaining(at: now))")
                                .font(AppFonts.heading(18)).foregroundStyle(AppColors.ink)
                                .padding(10).background(.white.opacity(0.95), in: Capsule())
                            Spacer()
                        }
                        .padding(.top, 102)
                        ForEach(0..<3, id: \.self) { index in
                            if round.isVisible(index, at: now) {
                                let position = round.position(index, at: now)
                                Text(targets[index]).font(.system(size: model.ageMode == .toddler ? 80 : 65))
                                    .frame(width: 96, height: 96)
                                    .position(x: area.size.width * position.x, y: area.size.height * position.y)
                                    .allowsHitTesting(false)
                            }
                        }
                        if let shotPoint {
                            Circle().fill(lastHit ? AppColors.yellow : .white)
                                .frame(width: 25, height: 25)
                                .overlay { Circle().stroke(AppColors.ink, lineWidth: 2) }
                                .position(x: area.size.width * (0.5 + (shotPoint.x - 0.5) * shotProgress),
                                          y: area.size.height * (0.88 + (shotPoint.y - 0.88) * shotProgress))
                                .allowsHitTesting(false)
                        }
                        if let outcome = round.outcome {
                            ActivityResult(title: outcome == .win ? "Все мишени!" : "Попробуем ещё!",
                                           detail: outcome == .win ? "+5 монеток" : "Попаданий: \(round.hits)",
                                           home: model.closeActivity,
                                           again: model.startToyTargets)
                        } else {
                            Color.clear.contentShape(Rectangle())
                                .gesture(DragGesture(minimumDistance: 0).onEnded { value in
                                    let point = GamePoint(x: Double(value.location.x / area.size.width),
                                                          y: Double(value.location.y / area.size.height))
                                    lastHit = model.shootToyTarget(at: point)
                                    shotPoint = point
                                    shotProgress = 0
                                    withAnimation(.easeOut(duration: 0.22)) { shotProgress = 1 }
                                })
                                .accessibilityLabel("Коснись мишени, чтобы запустить мягкий шарик")
                        }
                    }
                }
                .onReceive(ticker) { now = $0; model.tickToyTargets() }
            }
        }
    }
}
