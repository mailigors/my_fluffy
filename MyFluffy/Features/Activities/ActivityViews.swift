import Combine
import SwiftUI

struct ActivityScene<Content: View>: View {
    let art: String
    let title: String
    @ViewBuilder let content: Content
    @EnvironmentObject private var model: RoomViewModel

    init(art: String, title: String, @ViewBuilder content: () -> Content) {
        self.art = art
        self.title = title
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let picture = ArtImage.named(art) {
                    Image(uiImage: picture).resizable().scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                } else { AppColors.background }
                content
                VStack {
                    HStack {
                        FluffyIconButton(symbol: "house.fill", fallback: "house", label: "Домой") { model.closeActivity() }
                        Spacer()
                        Text(title).font(AppFonts.heading(25)).foregroundStyle(AppColors.ink)
                            .padding(.horizontal, 18).padding(.vertical, 10)
                            .background(.white.opacity(0.9), in: Capsule())
                        Spacer()
                        Color.clear.frame(width: 64, height: 64)
                    }
                    .padding(.horizontal, 15).padding(.top, 8)
                    Spacer()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

struct ActivityPrompt: View {
    let text: String
    var body: some View {
        Text(text).font(AppFonts.heading(23)).foregroundStyle(AppColors.ink)
            .multilineTextAlignment(.center).padding(.horizontal, 20).padding(.vertical, 13)
            .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 25))
            .overlay { RoundedRectangle(cornerRadius: 25).stroke(AppColors.ink, lineWidth: 2) }
            .padding(.horizontal, 20)
    }
}

struct ActivityResult: View {
    let title: String
    let detail: String
    let home: () -> Void
    var again: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 17) {
            Text("🌟").font(.system(size: 64))
            Text(title).font(AppFonts.heading(30))
            Text(detail).font(AppFonts.heading(21)).multilineTextAlignment(.center)
            if let again { Button("Ещё раз", action: again).buttonStyle(ActivityButtonStyle()) }
            Button("Домой", action: home).buttonStyle(ActivityButtonStyle())
        }
        .foregroundStyle(AppColors.ink).padding(27)
        .background(.white, in: RoundedRectangle(cornerRadius: 32))
        .overlay { RoundedRectangle(cornerRadius: 32).stroke(AppColors.ink, lineWidth: 3) }
        .padding(22)
    }
}

struct ActivityButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(AppFonts.heading(21)).foregroundStyle(AppColors.ink)
            .frame(minWidth: 170, minHeight: 64).padding(.horizontal, 12)
            .background(AppColors.yellow, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}

struct BathView: View {
    @EnvironmentObject private var model: RoomViewModel
    @State private var toolPoint = GamePoint(x: 0.18, y: 0.72)
    @State private var toolGrabbed = false
    @State private var previousDragPoint: GamePoint?
    private let bubbles: [GamePoint] = [
        .init(x: 0.18, y: 0.48), .init(x: 0.36, y: 0.44), .init(x: 0.56, y: 0.47),
        .init(x: 0.78, y: 0.45), .init(x: 0.25, y: 0.57), .init(x: 0.47, y: 0.56),
        .init(x: 0.7, y: 0.58), .init(x: 0.16, y: 0.68), .init(x: 0.48, y: 0.69),
        .init(x: 0.8, y: 0.68)
    ]

    var body: some View {
        ActivityScene(art: "bathroom_scene", title: "Купание") {
            GeometryReader { area in
                ZStack {
                    VStack { ActivityPrompt(text: prompt); Spacer() }
                        .padding(.top, 100)
                    kitten(in: area.size)
                    foam(in: area.size)
                    if model.bathSession.step == .bubbles { bubbleButtons(in: area.size) }
                    if model.bathSession.step == .soap || model.bathSession.step == .towel || model.bathSession.step == .comb {
                        if model.bathSession.heldTool == nil { toolShelf }
                    }
                    if model.bathSession.step == .shower && !model.bathSession.showerTaken {
                        Button { model.pickUpBathShower() } label: {
                            Text("🚿").font(.system(size: 58))
                                .frame(width: 84, height: 84)
                                .background(.white.opacity(0.95), in: Circle())
                                .overlay { Circle().stroke(AppColors.yellow, lineWidth: 5) }
                        }
                            .position(x: area.size.width * 0.5, y: area.size.height * 0.27)
                            .accessibilityLabel("Взять душ")
                    }
                    if model.bathSession.heldTool != nil {
                        tool(in: area.size)
                        dragSurface(in: area.size)
                    }
                    if model.bathSession.step == .towel {
                        VStack {
                            Spacer()
                            ProgressView(value: model.bathSession.towelProgress)
                                .tint(AppColors.mint).padding(.horizontal, 55).padding(.bottom, 85)
                        }
                        .allowsHitTesting(false)
                    }
                    if model.bathSession.step == .finished {
                        VStack {
                            Spacer()
                            ActivityResult(title: "Чистенький!", detail: "+6 монеток", home: model.closeActivity)
                                .padding(.bottom, 22)
                        }
                    }
                }
            }
        }
        .onChange(of: model.bathSession.step) { step in
            toolPoint = step == .shower ? GamePoint(x: 0.5, y: 0.27) : GamePoint(x: 0.5, y: 0.8)
            toolGrabbed = false
            previousDragPoint = nil
        }
    }

    @ViewBuilder private func kitten(in size: CGSize) -> some View {
        let art: String = switch model.bathSession.step {
        case .towel: "cat_plush_wet"
        case .comb: "cat_plush_shaggy"
        case .finished: "cat_plush_happy"
        default: "cat_plush_awake"
        }
        if let image = ArtImage.named(art) {
            Image(uiImage: image).resizable().scaledToFit()
                .frame(width: min(size.width * 0.66, 260), height: min(size.height * 0.43, 300))
                .position(x: size.width * 0.5,
                          y: size.height * (model.bathSession.step == .finished ? 0.32 : 0.55))
                .accessibilityLabel("Котёнок")
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder private func foam(in size: CGSize) -> some View {
        let session = model.bathSession
        if session.step == .soap || session.step == .shower {
            ForEach(BathSession.foamPositions.indices, id: \.self) { index in
                if index < session.soapStrokes && !session.rinsed.contains(index) {
                    Text("🫧").font(.system(size: 43))
                        .position(x: BathSession.foamPositions[index].x * size.width,
                                  y: BathSession.foamPositions[index].y * size.height)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private func bubbleButtons(in size: CGSize) -> some View {
        ForEach(bubbles.indices, id: \.self) { index in
            if !model.bathSession.popped.contains(index) {
                Button { model.popBathBubble(index) } label: {
                    Text("🫧").font(.system(size: 44)).frame(width: 68, height: 68)
                }
                .position(x: bubbles[index].x * size.width, y: bubbles[index].y * size.height)
                .accessibilityLabel("Лопнуть пузырь \(index + 1)")
            }
        }
    }

    @ViewBuilder private func tool(in size: CGSize) -> some View {
        let location = CGPoint(x: toolPoint.x * size.width, y: toolPoint.y * size.height)
        switch model.bathSession.step {
        case .soap:
            Text("🧼").font(.system(size: 64)).position(location).allowsHitTesting(false)
        case .shower:
            Text("🚿").font(.system(size: 65)).position(location).allowsHitTesting(false)
        case .towel:
            bathItem("bath_towel").position(location).shadow(radius: 4).allowsHitTesting(false)
        case .comb:
            bathItem("bath_comb").position(location).shadow(radius: 4).allowsHitTesting(false)
        default: EmptyView()
        }
    }

    private func bathItem(_ name: String) -> some View {
        Group {
            if let image = ArtImage.named(name) {
                Image(uiImage: image).resizable().scaledToFit()
            }
        }
        .frame(width: 84, height: 84)
    }

    private var toolShelf: some View {
        VStack {
            Spacer()
            Button { model.pickUpBathTool() } label: {
                Group {
                    if model.bathSession.step == .soap {
                        Text("🧼").font(.system(size: 63)).frame(width: 84, height: 84)
                    } else {
                        bathItem(model.bathSession.step == .towel ? "bath_towel" : "bath_comb")
                    }
                }
                    .frame(width: 104, height: 104)
                    .background(.white.opacity(0.97), in: Circle())
                    .overlay { Circle().stroke(AppColors.ink, lineWidth: 3) }
            }
            .buttonStyle(FluffyPressStyle(reduceMotion: false))
            .accessibilityLabel(model.bathSession.step == .soap ? "Взять мыло" :
                                (model.bathSession.step == .towel ? "Взять полотенце" : "Взять расчёску"))
            .padding(.bottom, 90)
        }
    }

    private func dragSurface(in size: CGSize) -> some View {
        Color.clear.contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !toolGrabbed {
                        toolGrabbed = true
                    }
                    let point = normalized(value.location, in: size)
                    toolPoint = point
                    switch model.bathSession.step {
                    case .shower: model.moveBathShower(to: point)
                    case .towel:
                        if let previousDragPoint { model.rubBathTowel(from: previousDragPoint, to: point) }
                    default: break
                    }
                    previousDragPoint = point
                }
                .onEnded { value in
                    guard toolGrabbed else { return }
                    let start = normalized(value.startLocation, in: size)
                    let end = normalized(value.location, in: size)
                    switch model.bathSession.step {
                    case .soap: model.soapBath(from: start, to: end)
                    case .towel:
                        if let previousDragPoint { model.rubBathTowel(from: previousDragPoint, to: end) }
                    case .comb: model.combBath(from: start, to: end)
                    default: break
                    }
                    toolGrabbed = false
                    previousDragPoint = nil
                })
            .accessibilityLabel("Проведи предметом по котёнку")
    }

    private func normalized(_ point: CGPoint, in size: CGSize) -> GamePoint {
        GamePoint(x: Double(point.x / size.width), y: Double(point.y / size.height))
    }

    private var prompt: String {
        switch model.bathSession.step {
        case .bubbles: "Лопни все пузырьки: \(model.bathSession.popped.count)/10"
        case .soap: model.bathSession.heldTool == nil ? "Возьми мыло" : "Намыль котёнка: \(model.bathSession.soapStrokes)/5"
        case .shower: model.bathSession.showerTaken ? "Смой всю пену: осталось \(model.bathSession.foamRemaining)" : "Возьми душ со стены"
        case .towel: model.bathSession.heldTool == nil ? "Выбери полотенце" : "Проводи пальцем по котёнку"
        case .comb: model.bathSession.heldTool == nil ? "Выбери расчёску" : "Причеши пальцем сверху вниз: \(model.bathSession.combStrokes)/5"
        case .finished: ""
        }
    }
}

struct ToiletView: View {
    @EnvironmentObject private var model: RoomViewModel
    @State private var toolPoint = GamePoint(x: 0.5, y: 0.85)

    private var prompt: String {
        switch model.toiletSession.step {
        case .paper: "Собери комочки туалетной бумагой"
        case .wipe: "Протри следы губкой"
        case .flush: "Спусти воду"
        case .finished: ""
        }
    }

    var body: some View {
        ActivityScene(art: "toilet_scene", title: "Лоток") {
            GeometryReader { area in
                ZStack {
                    VStack {
                        ActivityPrompt(text: prompt)
                        Spacer()
                    }
                        .padding(.top, 100)
                    if model.toiletSession.step != .finished {
                        ActivityCat(size: 125)
                            .position(x: area.size.width * 0.5, y: area.size.height * 0.43)
                            .allowsHitTesting(false)
                    }
                    if model.toiletSession.step == .paper {
                        ForEach(ToiletSession.clumpPositions.indices, id: \.self) { index in
                            if !model.toiletSession.collected.contains(index) {
                                Text("🟤").font(.system(size: 42))
                                    .position(x: ToiletSession.clumpPositions[index].x * area.size.width,
                                              y: ToiletSession.clumpPositions[index].y * area.size.height)
                            }
                        }
                    } else if model.toiletSession.step == .wipe {
                        ForEach(ToiletSession.pawPositions.indices, id: \.self) { index in
                            if !model.toiletSession.wiped.contains(index) {
                                Text("🐾").font(.system(size: 42))
                                    .position(x: ToiletSession.pawPositions[index].x * area.size.width,
                                              y: ToiletSession.pawPositions[index].y * area.size.height)
                            }
                        }
                    }
                    if model.toiletSession.step == .paper || model.toiletSession.step == .wipe {
                        Text(model.toiletSession.step == .paper ? "🧻" : "🧽").font(.system(size: 65))
                            .position(x: toolPoint.x * area.size.width, y: toolPoint.y * area.size.height)
                            .allowsHitTesting(false)
                        Color.clear.contentShape(Rectangle()).gesture(
                            DragGesture(minimumDistance: 0).onChanged { value in
                                let point = GamePoint(x: max(0, min(1, value.location.x / area.size.width)),
                                                      y: max(0, min(1, value.location.y / area.size.height)))
                                toolPoint = point
                                if model.toiletSession.step == .paper { model.movePaper(to: point) }
                                else { model.moveSponge(to: point) }
                            }
                        )
                    } else if model.toiletSession.step == .flush {
                        Button { model.flushToilet() } label: {
                            Text("🚽").font(.system(size: 92))
                                .frame(width: 150, height: 150)
                                .background(.white.opacity(0.95), in: Circle())
                                .overlay { Circle().stroke(AppColors.sky, lineWidth: 5) }
                        }
                        .position(x: area.size.width * 0.5, y: area.size.height * 0.70)
                        .accessibilityLabel("Спустить воду")
                    } else {
                        ActivityResult(title: "Готово!", detail: "+6 монеток", home: model.closeActivity)
                    }
                }
            }
        }
    }
}

struct PlayMenuView: View {
    @EnvironmentObject private var model: RoomViewModel

    var body: some View {
        ActivityScene(art: "cloud_scene", title: "Игры") {
            ScrollView {
                VStack(spacing: 14) {
                    gameCard("🐠", "Поймай рыбок", action: model.startFishRound)
                    gameCard("☁️", "Прыгни по облакам", action: model.startCloudRound)
                    gameCard("🧩", "Пазлы", action: model.openPuzzleMenu)
                    gameCard("🃏", "Мемори", action: model.startMemoryRound)
                    gameCard("⭕️", "Крестики-нолики", action: model.startTicTacToeRound)
                    gameCard("🦫", "Бобёр", action: model.startBeaverRound)
                    gameCard("🏒", "Аэрохоккей", action: model.startAirHockey)
                    gameCard("🎈", "Игрушечный тир", action: model.startToyTargets)
                }
                .padding(.top, 105).padding(.bottom, 30)
            }
        }
    }

    private func gameCard(_ icon: String, _ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 20) { Text(icon).font(.system(size: 55)); Text(title).font(AppFonts.heading(23)) }
                .foregroundStyle(AppColors.ink).frame(maxWidth: .infinity, minHeight: 90)
                .background(.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 28))
                .overlay { RoundedRectangle(cornerRadius: 28).stroke(AppColors.ink, lineWidth: 3) }
        }.padding(.horizontal, 25)
    }
}

struct FishGameView: View {
    @EnvironmentObject private var model: RoomViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var now = Date()
    private let ticker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        ActivityScene(art: "aquarium_scene", title: "Рыбки") {
            GeometryReader { area in
                ZStack {
                    VStack {
                        if let round = model.fishRound, !round.finished {
                            ActivityPrompt(text: "Задание \(round.level): \(questText(round))\n\(round.caughtCount)/\(round.targetCount)  ·  ⏱ \(round.secondsRemaining(at: now))")
                        }
                        Spacer()
                    }.padding(.top, 105)
                    fishContent(in: area.size)
                }
            }
            .onReceive(ticker) { now = $0; model.tickFishRound() }
        }
    }

    @ViewBuilder private func fishContent(in size: CGSize) -> some View {
        if let round = model.fishRound {
            if round.finished {
                ActivityResult(title: round.won ? "Задание выполнено!" : "Время вышло!",
                               detail: round.won ? "Открыто новое задание · Монеток: \(round.coins)" : "Рыбок: \(round.caughtCount)/\(round.targetCount)",
                               home: { model.closeActivity() }, again: fishAgain)
            } else {
                ForEach(0..<7, id: \.self) { index in
                    if !round.caught.contains(index) { fishButton(index, round: round, in: size) }
                }
            }
        }
    }

    private var fishAgain: (() -> Void)? {
        { model.startFishRound() }
    }

    private func fishButton(_ index: Int, round: FishRound, in size: CGSize) -> some View {
        let toddler = model.ageMode == .toddler
        let position = round.position(index, at: reduceMotion ? round.startedAt : now)
        return Button { model.catchFish(index) } label: {
            Text(round.kind(index).emoji)
                .font(.system(size: toddler ? 72 : 52))
                .frame(width: toddler ? 90 : 68, height: 80)
                .background(index == 6 ? AppColors.yellow.opacity(0.45) : .clear, in: Circle())
        }
        .position(x: size.width * position.x, y: size.height * position.y)
        .accessibilityLabel(index == 6 ? "Золотая рыбка" : "\(round.kind(index).emoji) рыбка")
    }

    private func questText(_ round: FishRound) -> String {
        switch round.questRule {
        case .any: "Лови любых рыбок"
        case .avoidGold: "Лови всех, кроме золотой ✨🐠"
        case .only(let fish): "Лови только \(fish.emoji)"
        }
    }
}

struct CloudGameView: View {
    @EnvironmentObject private var model: RoomViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var now = Date()
    @State private var glimmer = false
    private let ticker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    private let spots: [GamePoint] = [
        .init(x: 0.18, y: 0.7), .init(x: 0.52, y: 0.6), .init(x: 0.82, y: 0.69),
        .init(x: 0.32, y: 0.43), .init(x: 0.7, y: 0.36)
    ]

    var body: some View {
        ActivityScene(art: "cloud_scene", title: "Облака") {
            GeometryReader { area in
                ZStack {
                    VStack { ActivityPrompt(text: "Лови сияющее облако! \(model.cloudRound?.jumps ?? 0)/8"); Spacer() }
                        .padding(.top, 105)
                    cloudContent(in: area.size)
                }
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.65).repeatForever(autoreverses: true)) { glimmer = true }
        }
        .onReceive(ticker) { now = $0; model.tickCloudRound() }
    }

    @ViewBuilder private func cloudContent(in size: CGSize) -> some View {
        if let round = model.cloudRound {
            if round.finished {
                ActivityResult(title: round.won ? "Звёздочка твоя!" : "Попробуем ещё!",
                               detail: "Прыжков: \(round.jumps) · Монеток: \(round.coins)",
                               home: { model.closeActivity() }, again: cloudAgain)
            } else {
                Text("⭐️").font(.system(size: 60)).position(x: size.width * 0.5, y: size.height * 0.23)
                ForEach(spots.indices, id: \.self) { index in
                    cloudButton(index, target: round.targetCloud, in: size)
                }
                ActivityCat(size: 74)
                    .position(x: spots[round.currentCloud].x * size.width,
                              y: spots[round.currentCloud].y * size.height - 64)
                    .allowsHitTesting(false)
                VStack {
                    Spacer()
                    Text("Промахи: \(round.misses)/3")
                        .font(AppFonts.heading(20)).padding(12).background(.white, in: Capsule())
                    ProgressView(value: max(0, round.targetUntil.timeIntervalSince(now)), total: model.ageMode == .toddler ? 2.5 : 1.7)
                        .tint(AppColors.yellow).padding(.horizontal, 50)
                }.padding(.bottom, 70)
            }
        }
    }

    private var cloudAgain: (() -> Void)? {
        { model.startCloudRound() }
    }

    private func cloudButton(_ index: Int, target: Int, in size: CGSize) -> some View {
        Button { model.tapCloud(index) } label: {
            Text(index == target ? "🌟☁️" : "☁️")
                .font(.system(size: 49)).frame(width: 100, height: 82)
                .scaleEffect(index == target && glimmer ? 1.12 : 1)
        }
        .position(x: spots[index].x * size.width, y: spots[index].y * size.height)
        .accessibilityLabel(index == target ? "Сияющее облако" : "Облако")
    }
}

private struct ActivityCat: View {
    let size: CGFloat
    var body: some View {
        Group {
            if let cat = ArtImage.named("cat_plush_awake") {
                Image(uiImage: cat).resizable().scaledToFit()
            } else { Text("🐱").font(.system(size: size * 0.8)) }
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Котёнок")
    }
}
