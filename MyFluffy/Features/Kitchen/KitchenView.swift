import SwiftUI

struct KitchenView: View {
    @EnvironmentObject private var model: RoomViewModel
    @State private var lastWashPoint: CGPoint?
    @State private var lastStirPoint: CGPoint?
    @State private var stirPoint: CGPoint?
    @State private var isCutting = false
    @State private var showSlices = false
    @State private var slicedFood = ""
    @State private var showsRestock = false
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)
    private let toppingColumns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    private let toppings = ["⭐️", "❤️", "🌈", "✨", "🌼", "☁️"]

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                FluffyIconButton(symbol: "arrow.left", fallback: "chevron.left", label: String(localized: "В комнату")) {
                    model.closeKitchen()
                }
                Spacer()
                Label("\(model.kitchen.coins)", systemImage: "circle.fill")
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.ink)
                    .frame(minWidth: 64)
                    .padding(8)
                    .background(AppColors.yellow)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)

            stepTitle
            ScrollView {
                Group {
                    switch model.kitchenSession.step {
                    case .choosing: choosing
                    case .washing: washing
                    case .chopping: chopping
                    case .frying: frying
                    case .decorating: decorating
                    case .serving: serving
                    case .burnt: burnt
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 22)
            }
        }
        .padding(.top, 8)
        .background(KitchenBackdrop())
        .sheet(isPresented: $showsRestock) { restockSheet }
    }

    private var stepTitle: some View {
        VStack(spacing: 8) {
            Text(model.kitchenSession.step.title)
                .font(AppFonts.heading(24))
                .foregroundStyle(AppColors.ink)
            HStack(spacing: 6) {
                ForEach(0..<5) { index in
                    Capsule()
                        .fill(index <= model.kitchenSession.step.progress ? AppColors.pink : AppColors.background)
                        .frame(height: 9)
                        .overlay { Capsule().stroke(AppColors.ink, lineWidth: 1.5) }
                }
            }
            .padding(.horizontal, 36)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(AppColors.background.opacity(0.95))
        .overlay(alignment: .bottom) { AppColors.ink.frame(height: 3) }
    }

    private var choosing: some View {
        VStack(spacing: 14) {
            VStack(spacing: 12) {
                Label(String(localized: "Нажми на 2–4 продукта"), systemImage: "hand.tap.fill")
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.ink)
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Ingredient.allCases, id: \.self) { ingredient in
                        ingredientButton(ingredient)
                    }
                }
            }
            .padding(12)
            .kitchenCard()
            .padding(.horizontal, 16)
            Button { showsRestock = true } label: {
                HStack(spacing: 10) {
                    Text("🎁").font(.system(size: 30))
                    Text(String(localized: "Пополнить продукты"))
                        .font(AppFonts.action)
                        .foregroundStyle(AppColors.ink)
                }
                .frame(maxWidth: .infinity, minHeight: 68)
                .kitchenCard(tint: AppColors.mint)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            bowl
            HStack(spacing: 20) {
                FluffyIconButton(symbol: "delete.left", fallback: "minus", label: String(localized: "Убрать последний продукт")) {
                    model.removeLastIngredient()
                }
                .disabled(model.kitchenSession.selected.isEmpty)
                actionButton(String(localized: "Готовить"), symbol: "arrow.right", enabled: model.kitchenSession.canStart) {
                    model.startCooking()
                }
            }
        }
    }

    private var restockSheet: some View {
        VStack(spacing: 16) {
            Text(String(localized: "Продукты для котёнка"))
                .font(AppFonts.heading(24))
                .foregroundStyle(AppColors.ink)
            Text(String(localized: "Пока бесплатно — без рекламы"))
                .font(AppFonts.body())
                .foregroundStyle(AppColors.ink)
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Ingredient.allCases, id: \.self) { ingredient in
                        Button {
                            model.restockIngredient(ingredient)
                        } label: {
                            VStack(spacing: 4) {
                                Text(ingredient.emoji).font(.system(size: 34))
                                Text("×\(model.kitchen.available(ingredient))")
                                    .font(AppFonts.body(15))
                                Text("+3").font(AppFonts.action)
                            }
                            .foregroundStyle(AppColors.ink)
                            .frame(maxWidth: .infinity, minHeight: 106)
                            .kitchenCard(tint: AppColors.yellow)
                        }
                        .buttonStyle(.plain)
                        .disabled(model.kitchen.available(ingredient) >= 99)
                        .accessibilityLabel(Text(String(localized: "Добавить три: \(ingredient.spokenName)")))
                    }
                }
                .padding(8)
            }
            Button { showsRestock = false } label: {
                Text(String(localized: "Готово"))
                    .font(AppFonts.action)
                    .foregroundStyle(AppColors.ink)
                    .frame(maxWidth: .infinity, minHeight: 68)
                    .kitchenCard(tint: AppColors.mint)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(AppColors.background.ignoresSafeArea())
    }

    private func ingredientButton(_ ingredient: Ingredient) -> some View {
        Button { model.addIngredient(ingredient) } label: {
            VStack(spacing: 2) {
                Text(ingredient.emoji).font(.system(size: 32))
                Text("×\(model.kitchen.available(ingredient))")
                    .font(AppFonts.body(15))
                    .foregroundStyle(AppColors.ink)
            }
            .frame(maxWidth: .infinity, minHeight: 74)
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay { RoundedRectangle(cornerRadius: 16).stroke(AppColors.ink, lineWidth: 2) }
        }
        .buttonStyle(.plain)
        .disabled(model.kitchen.available(ingredient) == 0)
        .accessibilityLabel(Text(ingredient.spokenName))
    }

    private var bowl: some View {
        VStack(spacing: 4) {
            KitchenBowlIllustration(food: model.kitchenSession.selected.map(\.emoji).joined(separator: " "))
                .frame(height: 100)
            Text(String(localized: "В миске: \(model.kitchenSession.selected.count)"))
                .font(AppFonts.body(15))
                .foregroundStyle(AppColors.ink)
        }
        .frame(maxWidth: .infinity, minHeight: 142)
        .kitchenCard(tint: AppColors.yellow)
        .padding(.horizontal, 16)
        .accessibilityLabel(Text(String(localized: "Миска для продуктов")))
    }

    private var washing: some View {
        VStack(spacing: 12) {
            activityHint(washingHint, symbol: model.kitchenSession.waterTemperature == .warm ? "hand.draw.fill" : "slider.vertical.3")
            HStack(spacing: 0) {
                WaterFlowSlider(value: model.kitchenSession.coldFlow, color: AppColors.sky, icon: "❄️", label: "Холодная вода") {
                    model.setColdFlow($0)
                }
                sinkScene
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if let lastWashPoint {
                                let movement = hypot(value.location.x - lastWashPoint.x, value.location.y - lastWashPoint.y)
                                model.washIngredients(distance: min(40, movement))
                            }
                            lastWashPoint = value.location
                        }
                        .onEnded { _ in lastWashPoint = nil })
                WaterFlowSlider(value: model.kitchenSession.hotFlow, color: .red, icon: "🔥", label: "Горячая вода") {
                    model.setHotFlow($0)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 265)
            .kitchenCard(tint: AppColors.sky)
            .padding(.horizontal, 12)
            temperatureMeter
            VStack(spacing: 8) {
                Text("\(min(model.kitchenSession.washedCount + 1, model.kitchenSession.selected.count)) / \(model.kitchenSession.selected.count)")
                    .font(AppFonts.heading())
                    .foregroundStyle(AppColors.ink)
                ProgressView(value: washProgress)
                    .tint(AppColors.mint)
            }
            .padding(16)
            .kitchenCard()
            .padding(.horizontal, 28)
        }
    }

    private var sinkScene: some View {
        ZStack {
            art("kitchen_sink", width: 220, height: 220)
            if model.kitchenSession.waterOn {
                Text("💧💧")
                    .font(.system(size: 29))
                    .offset(y: -18)
            }
            Text(model.kitchenSession.selected[model.kitchenSession.washedCount].emoji)
                .font(.system(size: 50))
                .offset(y: 53)
            if model.kitchenSession.waterTemperature == .warm {
                HStack(spacing: 4) {
                    ForEach(0..<max(0, 5 - Int(washProgress * 5)), id: \.self) { _ in
                        Text("🫧").font(.system(size: 19))
                    }
                }
                .offset(y: 99)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 250)
        .accessibilityLabel(Text(String(localized: "Потереть продукт в раковине")))
    }

    private var washingHint: String {
        switch model.kitchenSession.waterTemperature {
        case .off: return "Открой оба крана"
        case .warm: return "Потри продукт"
        case .cold, .hot: return "Сделай воду тёплой"
        }
    }

    private var temperatureMeter: some View {
        VStack(spacing: 6) {
            Text(temperatureText)
                .font(AppFonts.action)
                .foregroundStyle(AppColors.ink)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(colors: [AppColors.sky, AppColors.mint, .red], startPoint: .leading, endPoint: .trailing))
                        .frame(height: 22)
                        .overlay { Capsule().stroke(AppColors.ink, lineWidth: 2) }
                    if model.kitchenSession.waterOn {
                        Circle()
                            .fill(.white)
                            .frame(width: 31, height: 31)
                            .overlay { Circle().stroke(AppColors.ink, lineWidth: 3) }
                            .offset(x: max(0, min(geometry.size.width - 31, model.kitchenSession.hotShare * (geometry.size.width - 31))))
                    }
                }
                .frame(height: 31)
            }
            .frame(height: 31)
        }
        .padding(12)
        .kitchenCard(tint: model.kitchenSession.waterTemperature == .warm ? AppColors.mint : AppColors.yellow)
        .padding(.horizontal, 28)
        .accessibilityLabel(Text(String(localized: "Температура воды: \(temperatureText)")))
    }

    private var temperatureText: String {
        switch model.kitchenSession.waterTemperature {
        case .off: return "Температура воды"
        case .cold: return "🔵 Холодная"
        case .warm: return "🟢 Тёплая"
        case .hot: return "🔴 Горячая"
        }
    }

    private var chopping: some View {
        VStack(spacing: 24) {
            activityHint("Нажми на продукт", symbol: "hand.tap.fill")
            Button(action: cutNextIngredient) {
                VStack(spacing: 12) {
                    Text("🔪").font(.system(size: 56))
                    Text(model.kitchenSession.selected[min(model.kitchenSession.choppedCount, model.kitchenSession.selected.count - 1)].emoji)
                        .font(.system(size: 90))
                    if isCutting {
                        HStack(spacing: 10) {
                            ForEach(0..<3, id: \.self) { index in
                                Text(slicedFood)
                                    .font(.system(size: 28))
                                    .offset(x: showSlices ? CGFloat(index - 1) * 23 : 0, y: showSlices ? -18 : 20)
                                    .opacity(showSlices ? 1 : 0)
                            }
                        }
                        .frame(height: 35)
                    }
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(AppColors.ink)
                }
                .frame(maxWidth: .infinity, minHeight: 280)
                .kitchenCard(tint: AppColors.yellow)
            }
            .buttonStyle(.plain)
            .disabled(isCutting)
            .accessibilityLabel(Text(String(localized: "Порезать продукт")))
            .padding(.horizontal, 18)
            Text("\(model.kitchenSession.choppedCount) / \(model.kitchenSession.selected.count)")
                .font(AppFonts.heading())
        }
    }

    private func cutNextIngredient() {
        guard !isCutting else { return }
        slicedFood = model.kitchenSession.selected[model.kitchenSession.choppedCount].emoji
        isCutting = true
        showSlices = false
        withAnimation(AppMetrics.spring) { showSlices = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            model.chopIngredient()
            isCutting = false
            showSlices = false
        }
    }

    private var frying: some View {
        VStack(spacing: 14) {
            activityHint(cookingHint, symbol: model.kitchenSession.ingredientsInPan ? "hand.draw.fill" : "slider.horizontal.3")
            stoveScene
            heatMeter
            if model.kitchenSession.stoveOn && !model.kitchenSession.ingredientsInPan {
                Button { model.placeIngredientsInPan() } label: {
                    HStack(spacing: 10) {
                        Text(model.kitchenSession.selected.map(\.emoji).joined(separator: " "))
                            .font(.system(size: 30))
                        Text(String(localized: "В сковороду"))
                            .font(AppFonts.action)
                            .foregroundStyle(AppColors.ink)
                    }
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .kitchenCard(tint: AppColors.yellow)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 18)
            } else if model.kitchenSession.ingredientsInPan {
                VStack(spacing: 7) {
                    Text(String(localized: "Помешай лопаткой  \(model.kitchenSession.stirCount)/3"))
                        .font(AppFonts.action)
                        .foregroundStyle(AppColors.ink)
                    ProgressView(value: (Double(model.kitchenSession.stirCount) * 120 + model.kitchenSession.stirDistance) / 360)
                        .tint(AppColors.mint)
                }
                .padding(14)
                .kitchenCard(tint: AppColors.background)
                .padding(.horizontal, 24)
            }
        }
    }

    private var stoveScene: some View {
        ZStack {
            art("kitchen_stove", width: 290, height: 260)
            if model.kitchenSession.ingredientsInPan {
                Text(model.kitchenSession.selected.map(\.emoji).joined(separator: " "))
                    .font(.system(size: 36))
                    .lineLimit(1)
                    .offset(x: -20, y: -30)
            }
            if model.kitchenSession.stoveOn {
                Text(model.kitchenSession.heatZone == .yellow ? "🟡" : model.kitchenSession.heatZone == .green ? "🟢" : "🔴")
                    .font(.system(size: 26))
                    .offset(x: 0, y: 118)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .overlay {
            GeometryReader { geometry in
                ZStack {
                    if model.kitchenSession.ingredientsInPan {
                        art("kitchen_spatula", width: 96, height: 96)
                            .position(stirPoint ?? CGPoint(x: geometry.size.width * 0.72, y: 164))
                            .allowsHitTesting(false)
                    }
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard model.kitchenSession.ingredientsInPan else { return }
                                stirPoint = value.location
                                guard abs(value.location.x - geometry.size.width / 2) < 115,
                                      (35...180).contains(value.location.y) else {
                                    lastStirPoint = nil
                                    return
                                }
                                if let lastStirPoint {
                                    let movement = hypot(value.location.x - lastStirPoint.x, value.location.y - lastStirPoint.y)
                                    model.stirPan(distance: min(40, movement))
                                }
                                lastStirPoint = value.location
                            }
                            .onEnded { _ in
                                lastStirPoint = nil
                                stirPoint = nil
                            })
                }
            }
        }
        .kitchenCard(tint: AppColors.background)
        .padding(.horizontal, 18)
        .accessibilityAction(named: Text(String(localized: "Перемешать"))) {
            model.stirPan(distance: 120)
        }
    }

    private var heatMeter: some View {
        VStack(spacing: 5) {
            Text(heatLabel)
                .font(AppFonts.action)
                .foregroundStyle(AppColors.ink)
            StoveHeatSlider(value: model.kitchenSession.heatLevel) { model.setHeat($0) }
            HStack {
                Text(String(localized: "Выкл"))
                Spacer()
                Text("🟡")
                Spacer()
                Text("🟢")
                Spacer()
                Text("🔴")
            }
            .font(AppFonts.body(15))
            .foregroundStyle(AppColors.ink)
        }
        .padding(14)
        .kitchenCard(tint: AppColors.background)
        .padding(.horizontal, 18)
    }

    private var heatLabel: String {
        if !model.kitchenSession.stoveOn { return String(localized: "Плита выключена") }
        switch model.kitchenSession.heatZone {
        case .yellow: return String(localized: "🟡 Не готовится")
        case .green: return String(localized: "🟢 Готовится")
        case .red: return String(localized: "🔴 Слишком горячо")
        }
    }

    private var cookingHint: String {
        if !model.kitchenSession.stoveOn { return String(localized: "Сдвинь ползунок плиты") }
        if !model.kitchenSession.ingredientsInPan { return String(localized: "Положи продукты") }
        if model.kitchenSession.heatZone == .yellow { return String(localized: "Жёлтый — не жарит") }
        return String(localized: "Води лопаткой по сковороде")
    }

    private var decorating: some View {
        VStack(spacing: 20) {
            activityHint("Выбери украшение", symbol: "hand.tap.fill")
            KitchenMealIllustration(ingredients: model.kitchenSession.selected)
                .frame(maxWidth: .infinity, minHeight: 180)
                .kitchenCard(tint: AppColors.mint)
                .padding(.horizontal, 18)
            LazyVGrid(columns: toppingColumns, spacing: 12) {
                ForEach(toppings.indices, id: \.self) { index in
                    Button {
                        model.chooseDecoration(index)
                        model.decorateDish()
                    } label: {
                        Text(toppings[index])
                            .font(.system(size: 52))
                            .frame(maxWidth: .infinity, minHeight: 88)
                            .kitchenCard(tint: AppColors.yellow)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(String(localized: "Посыпка \(index + 1)")))
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var serving: some View {
        VStack(spacing: 26) {
            activityHint("Нажми на миску", symbol: "hand.tap.fill")
            Button { model.serveDish() } label: {
                KitchenMealIllustration(ingredients: model.kitchenSession.selected,
                                        topping: model.kitchenSession.decoration.map { toppings[$0] })
                    .frame(maxWidth: .infinity, minHeight: 220)
                    .kitchenCard(tint: AppColors.yellow)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(String(localized: "Дать блюдо котёнку")))
            .padding(.horizontal, 18)
            Text(String(localized: "\(model.petName) ждёт угощение!"))
                .font(AppFonts.heading())
        }
    }

    private var burnt: some View {
        VStack(spacing: 26) {
            art("kitchen_coals", width: 260, height: 220)
                .frame(maxWidth: .infinity, minHeight: 220)
                .kitchenCard(tint: AppColors.pink)
                .padding(.horizontal, 18)
            Text(String(localized: "Блюдо подгорело"))
                .font(AppFonts.heading())
                .foregroundStyle(AppColors.ink)
            actionButton(String(localized: "Начать заново"), symbol: "arrow.clockwise", enabled: true) {
                model.discardDish()
            }
        }
    }

    private func activityHint(_ title: String, symbol: String) -> some View {
        Label(String(localized: String.LocalizationValue(title)), systemImage: symbol)
            .font(AppFonts.body())
            .foregroundStyle(AppColors.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(AppColors.background.opacity(0.95))
            .clipShape(Capsule())
    }

    private var washProgress: Double {
        min(1, model.kitchenSession.washDistance / 120)
    }

    @ViewBuilder
    private func art(_ name: String, width: CGFloat, height: CGFloat) -> some View {
        if let image = ArtImage.named(name) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: width, height: height)
        } else {
            Image(systemName: "circle.fill")
                .frame(width: width, height: height)
        }
    }

    private func actionButton(_ title: String, symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(AppFonts.action)
                .foregroundStyle(AppColors.ink)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 22)
                .frame(minWidth: 160, minHeight: 70)
                .background(AppColors.yellow)
                .clipShape(Capsule())
                .overlay { Capsule().stroke(AppColors.ink, lineWidth: 3) }
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.5)
    }
}

private extension KitchenStep {
    var progress: Int {
        switch self {
        case .choosing: return 0
        case .washing: return 1
        case .chopping: return 2
        case .frying: return 3
        case .decorating: return 4
        case .serving, .burnt: return 4
        }
    }

    var title: String {
        switch self {
        case .choosing: return String(localized: "Продукты")
        case .washing: return String(localized: "Помой")
        case .chopping: return String(localized: "Порежь")
        case .frying: return String(localized: "Пожарь")
        case .decorating: return String(localized: "Укрась")
        case .serving: return String(localized: "Угощение")
        case .burnt: return String(localized: "Ой!")
        }
    }
}

private struct KitchenBackdrop: View {
    var body: some View {
        ZStack {
            AppColors.background
            if let image = ArtImage.named("kitchen_day") {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
        }
        .ignoresSafeArea()
    }
}

private struct WaterFlowSlider: View {
    let value: Double
    let color: Color
    let icon: String
    let label: String
    let onChange: (Double) -> Void

    var body: some View {
        VStack(spacing: 5) {
            Text(icon).font(.system(size: 27))
            ZStack {
                Capsule()
                    .fill(AppColors.background)
                    .frame(width: 22, height: 130)
                    .overlay { Capsule().stroke(AppColors.ink, lineWidth: 2) }
                    .position(x: 32, y: 80)
                Capsule()
                    .fill(color)
                    .frame(width: 18, height: max(2, 126 * value))
                    .position(x: 32, y: 143 - 63 * value)
                Circle()
                    .fill(.white)
                    .frame(width: 42, height: 42)
                    .overlay { Circle().stroke(AppColors.ink, lineWidth: 3) }
                    .position(x: 32, y: 145 - 130 * value)
            }
            .frame(width: 64, height: 160)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { gesture in
                onChange(min(1, max(0, (145 - gesture.location.y) / 130)))
            })
            Image(systemName: "arrow.up")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppColors.ink)
        }
        .frame(width: 64)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label))
        .accessibilityValue(Text("\(Int(value * 100))%"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: onChange(min(1, value + 0.1))
            case .decrement: onChange(max(0, value - 0.1))
            @unknown default: break
            }
        }
    }
}

private struct StoveHeatSlider: View {
    let value: Double
    let onChange: (Double) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(LinearGradient(stops: [
                        .init(color: .gray, location: 0),
                        .init(color: AppColors.yellow, location: 0.16),
                        .init(color: AppColors.mint, location: 0.55),
                        .init(color: .red, location: 1)
                    ], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 28)
                    .overlay { Capsule().stroke(AppColors.ink, lineWidth: 2) }
                    .position(x: geometry.size.width / 2, y: 33)
                Circle()
                    .fill(.white)
                    .frame(width: 48, height: 48)
                    .overlay { Circle().stroke(AppColors.ink, lineWidth: 4) }
                    .position(x: 24 + value * max(0, geometry.size.width - 48), y: 33)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { gesture in
                let width = max(1, geometry.size.width - 48)
                onChange(min(1, max(0, (gesture.location.x - 24) / width)))
            })
        }
        .frame(height: 66)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(String(localized: "Нагрев плиты")))
        .accessibilityValue(Text("\(Int(value * 100))%"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: onChange(min(1, value + 0.1))
            case .decrement: onChange(max(0, value - 0.1))
            @unknown default: break
            }
        }
    }
}

struct KitchenBowlIllustration: View {
    let food: String

    var body: some View {
        ZStack {
            if let image = ArtImage.named("kitchen_bowl") {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Text("🥣").font(.system(size: 100))
            }
            Text(food)
                .font(.system(size: 27))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .offset(y: -8)
        }
        .frame(maxWidth: 280)
        .accessibilityLabel(Text(String(localized: "Миска с едой")))
    }
}

struct KitchenMealIllustration: View {
    let ingredients: [Ingredient]
    var topping: String? = nil

    var body: some View {
        ZStack {
            if let image = ArtImage.named(KitchenDishVisual.artName(for: ingredients)) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
            if let topping {
                Text(topping)
                    .font(.system(size: 35))
                    .offset(y: -45)
            }
        }
        .frame(maxWidth: 280, maxHeight: 220)
        .accessibilityLabel(Text(String(localized: "Готовое блюдо")))
    }
}

private struct KitchenCard: ViewModifier {
    var tint: Color

    func body(content: Content) -> some View {
        content
            .background(tint.opacity(0.94))
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .overlay { RoundedRectangle(cornerRadius: 28).stroke(AppColors.ink, lineWidth: 4) }
            .shadow(color: AppColors.ink.opacity(0.16), radius: 0, x: 0, y: 5)
    }
}

private extension View {
    func kitchenCard(tint: Color = AppColors.background) -> some View {
        modifier(KitchenCard(tint: tint))
    }
}

private extension Ingredient {
    var emoji: String {
        switch self {
        case .fish: return "🐟"
        case .chicken: return "🍗"
        case .milk: return "🥛"
        case .rice: return "🍚"
        case .carrot: return "🥕"
        case .cheese: return "🧀"
        case .berry: return "🫐"
        case .herb: return "🌿"
        }
    }

    var spokenName: String {
        switch self {
        case .fish: return String(localized: "Рыбка")
        case .chicken: return String(localized: "Курочка")
        case .milk: return String(localized: "Молочко")
        case .rice: return String(localized: "Рис")
        case .carrot: return String(localized: "Морковка")
        case .cheese: return String(localized: "Сыр")
        case .berry: return String(localized: "Ягодки")
        case .herb: return String(localized: "Травка")
        }
    }
}
