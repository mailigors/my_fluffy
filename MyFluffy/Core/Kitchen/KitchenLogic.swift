import Foundation

enum Ingredient: String, Codable, CaseIterable, Hashable, Sendable {
    case fish = "ing_fish"
    case chicken = "ing_chick"
    case milk = "ing_milk"
    case rice = "ing_rice"
    case carrot = "ing_carrot"
    case cheese = "ing_cheese"
    case berry = "ing_berry"
    case herb = "ing_herb"

    var satiety: Double {
        switch self {
        case .fish: return 18
        case .chicken: return 14
        case .milk, .carrot: return 8
        case .rice: return 10
        case .cheese: return 12
        case .berry, .herb: return 6
        }
    }
}

enum RecipeID: String, Codable, CaseIterable, Hashable, Sendable {
    case plov = "rec_plov"
    case milkshake = "rec_milkshake"
    case soup = "rec_soup"
    case salad = "rec_salad"
    case burger = "rec_burger"
    case pie = "rec_pie"

    var ingredients: Set<Ingredient> {
        switch self {
        case .plov: return [.fish, .rice]
        case .milkshake: return [.milk, .berry]
        case .soup: return [.chicken, .carrot, .rice]
        case .salad: return [.carrot, .herb, .cheese]
        case .burger: return [.chicken, .cheese, .rice]
        case .pie: return [.berry, .milk, .rice]
        }
    }

    static func matching(_ selected: [Ingredient]) -> RecipeID? {
        let unique = Set(selected)
        guard unique.count == selected.count else { return nil }
        return allCases.first { $0.ingredients == unique }
    }
}

enum KitchenDishVisual {
    static func artName(for ingredients: [Ingredient]) -> String {
        if let recipe = RecipeID.matching(ingredients) {
            switch recipe {
            case .plov: return "kitchen_dish"
            case .milkshake: return "kitchen_dish_milkshake"
            case .soup: return "kitchen_dish_soup"
            case .salad: return "kitchen_dish_salad"
            case .burger: return "kitchen_dish_burger"
            case .pie: return "kitchen_dish_pie"
            }
        }
        let picked = Set(ingredients)
        if picked.contains(.fish) { return "kitchen_dish_fish" }
        if picked.contains(.chicken) { return "kitchen_dish_chicken" }
        if picked.contains(.berry) { return picked.contains(.rice) ? "kitchen_dish_pie" : "kitchen_dish_milkshake" }
        if picked.contains(.milk) || picked.contains(.cheese) { return "kitchen_dish_dairy" }
        if picked.contains(.carrot) || picked.contains(.herb) { return "kitchen_dish_salad" }
        return "kitchen_dish_mixed"
    }
}

struct KitchenState: Codable, Equatable, Sendable {
    var inventory: [Ingredient: Int]
    var readyMeals: Int
    var coins: Int
    var discoveredRecipes: Set<RecipeID>

    static var newcomer: KitchenState {
        KitchenState(
            inventory: Dictionary(uniqueKeysWithValues: Ingredient.allCases.map { ($0, 2) }),
            readyMeals: 0,
            coins: 0,
            discoveredRecipes: []
        )
    }

    func available(_ ingredient: Ingredient) -> Int {
        inventory[ingredient, default: 0]
    }

    mutating func restock(_ ingredient: Ingredient, amount: Int = 3) {
        guard amount > 0 else { return }
        inventory[ingredient] = min(99, available(ingredient) + amount)
    }
}

enum KitchenStep: Equatable, Sendable {
    case choosing, washing, chopping, frying, decorating, serving, burnt
}

enum WaterTemperature: Equatable, Sendable {
    case off, cold, warm, hot
}

struct KitchenSession: Equatable, Sendable {
    private(set) var selected: [Ingredient] = []
    private(set) var step: KitchenStep = .choosing
    private(set) var coldFlow = 0.0
    private(set) var hotFlow = 0.0
    private(set) var washedCount = 0
    private(set) var washDistance = 0.0
    private(set) var choppedCount = 0
    private(set) var stoveOn = false
    private(set) var ingredientsInPan = false
    private(set) var stirCount = 0
    private(set) var stirDistance = 0.0
    private(set) var decoration: Int?
    private(set) var heatLevel = 0.0

    var canStart: Bool { selected.count >= 2 && selected.count <= 4 }
    var waterOn: Bool { coldFlow > 0.05 || hotFlow > 0.05 }
    var hotShare: Double {
        let total = coldFlow + hotFlow
        return total > 0 ? hotFlow / total : 0.5
    }
    var waterTemperature: WaterTemperature {
        guard waterOn else { return .off }
        if coldFlow > 0.15, hotFlow > 0.15, (0.4...0.6).contains(hotShare) { return .warm }
        return hotShare < 0.5 ? .cold : .hot
    }
    var heatZone: HeatZone {
        if heatLevel < 0.35 { return .yellow }
        if heatLevel < 0.75 { return .green }
        return .red
    }

    mutating func add(_ ingredient: Ingredient, from kitchen: KitchenState) {
        guard step == .choosing, selected.count < 4 else { return }
        let picked = selected.filter { $0 == ingredient }.count
        guard picked < kitchen.available(ingredient) else { return }
        selected.append(ingredient)
    }

    mutating func removeLast() {
        guard step == .choosing, selected.isEmpty == false else { return }
        selected.removeLast()
    }

    mutating func start() {
        guard step == .choosing, canStart else { return }
        step = .washing
    }

    mutating func setColdFlow(_ value: Double) {
        guard step == .washing else { return }
        coldFlow = min(1, max(0, value))
    }

    mutating func setHotFlow(_ value: Double) {
        guard step == .washing else { return }
        hotFlow = min(1, max(0, value))
    }

    mutating func wash(distance: Double) {
        guard step == .washing, waterTemperature == .warm else { return }
        washDistance += max(0, distance)
        if washDistance >= 120 {
            washedCount += 1
            washDistance = 0
            if washedCount >= selected.count { step = .chopping }
        }
    }

    mutating func chop() {
        guard step == .chopping else { return }
        choppedCount += 1
        if choppedCount >= selected.count {
            step = .frying
        }
    }

    mutating func setHeat(_ value: Double) {
        guard step == .frying else { return }
        heatLevel = min(1, max(0, value))
        stoveOn = heatLevel > 0.05
        if ingredientsInPan && heatZone == .red { step = .burnt }
    }

    mutating func placeIngredientsInPan() {
        guard step == .frying, stoveOn, !ingredientsInPan else { return }
        ingredientsInPan = true
        if heatZone == .red { step = .burnt }
    }

    mutating func stir(distance: Double) {
        guard step == .frying, stoveOn, ingredientsInPan, heatZone == .green else { return }
        stirDistance += max(0, distance)
        if stirDistance >= 120 {
            stirCount += 1
            stirDistance -= 120
            if stirCount >= 3 { step = .decorating }
        }
    }

    mutating func chooseDecoration(_ index: Int) {
        guard step == .decorating, (0..<6).contains(index) else { return }
        decoration = index
    }

    mutating func decorate() {
        guard step == .decorating, decoration != nil else { return }
        step = .serving
    }
}

enum HeatZone: Equatable, Sendable {
    case yellow, green, red
}

struct FeedingResult: Equatable, Sendable {
    var needs: PetNeeds
    var kitchen: KitchenState
    var recipe: RecipeID?
    var coinsEarned: Int
}

enum KitchenEconomy {
    static func consumeBurnt(_ session: KitchenSession, kitchen: KitchenState) -> KitchenState? {
        guard session.step == .burnt else { return nil }
        return consuming(session.selected, from: kitchen)
    }

    static func serve(_ session: KitchenSession, needs: PetNeeds, kitchen: KitchenState) -> FeedingResult? {
        guard session.step == .serving, (2...4).contains(session.selected.count) else { return nil }
        guard var updatedKitchen = consuming(session.selected, from: kitchen) else { return nil }

        let recipe = RecipeID.matching(session.selected)
        let baseSatiety = session.selected.reduce(0) { $0 + $1.satiety }
        var gain = baseSatiety
        if recipe == .plov { gain *= 1.2 }
        if recipe == .burger { gain *= 1.3 }
        var updated = needs
        updated.satiety = clamp(needs.satiety + gain)
        updated.mood = clamp(needs.mood + Double(session.selected.filter { $0 == .berry }.count * 4))
        updated.energy = clamp(needs.energy + Double(session.selected.filter { $0 == .herb }.count * 4))
        switch recipe {
        case .milkshake: updated.mood = clamp(updated.mood + 10)
        case .soup: updated.energy = clamp(updated.energy + 10)
        case .salad: updated.cleanliness = clamp(updated.cleanliness + 6)
        case .pie:
            updated.satiety = clamp(updated.satiety + 6)
            updated.cleanliness = clamp(updated.cleanliness + 6)
            updated.mood = clamp(updated.mood + 6)
            updated.energy = clamp(updated.energy + 6)
            updated.toilet = clamp(updated.toilet + 6)
        case .plov, .burger, .none: break
        }
        let earned = needs.satiety < 60 ? 6 : 0
        updatedKitchen.coins += earned
        if let recipe { updatedKitchen.discoveredRecipes.insert(recipe) }
        return FeedingResult(needs: updated, kitchen: updatedKitchen, recipe: recipe, coinsEarned: earned)
    }

    private static func clamp(_ value: Double) -> Double {
        min(100, max(0, value))
    }

    private static func consuming(_ ingredients: [Ingredient], from kitchen: KitchenState) -> KitchenState? {
        var updated = kitchen
        for ingredient in ingredients {
            guard updated.inventory[ingredient, default: 0] > 0 else { return nil }
            updated.inventory[ingredient, default: 0] -= 1
        }
        return updated
    }
}
