import Foundation

enum ShopCategory: String, CaseIterable, Sendable {
    case food, outfits, toys, room

    var title: String {
        switch self {
        case .food: "Еда"
        case .outfits: "Наряды"
        case .toys: "Игрушки"
        case .room: "Комната"
        }
    }
}

enum RoomDecorSlot: Equatable, Sendable {
    case wall, surface, floor
}

enum ShopItem: String, Codable, CaseIterable, Hashable, Sendable {
    case bow = "w_bow", glasses = "w_glasses", collar = "w_collar"
    case partyHat = "w_partyhat", crown = "w_crown"
    case ball = "t_ball", teddy = "t_teddy", butterfly = "t_butterfly"
    case cushion = "r_cushion", flower = "r_flower", lamp = "r_lamp", picture = "r_picture"
    case beret = "w_beret", scarf = "w_scarf", bowTie = "w_bowtie", sunHat = "w_sunhat"
    case tiara = "w_tiara", earmuffs = "w_earmuffs", bandana = "w_bandana"
    case visor = "w_visor", pendant = "w_pendant", starGlasses = "w_starglasses"
    case yarn = "t_yarn", kite = "t_kite", drum = "t_drum", duck = "t_duck"
    case train = "t_train", blocks = "t_blocks", rocket = "t_rocket"
    case mouse = "t_mouse", rattle = "t_rattle", pinwheel = "t_pinwheel"
    case rug = "r_rug", clock = "r_clock", shelf = "r_shelf", plant = "r_plant"
    case banner = "r_banner", stool = "r_stool", nightlight = "r_nightlight"
    case basket = "r_basket", mobile = "r_mobile", mirror = "r_mirror"

    var category: ShopCategory {
        switch self {
        case .bow, .glasses, .collar, .partyHat, .crown, .beret, .scarf, .bowTie,
             .sunHat, .tiara, .earmuffs, .bandana, .visor, .pendant, .starGlasses: .outfits
        case .ball, .teddy, .butterfly, .yarn, .kite, .drum, .duck, .train,
             .blocks, .rocket, .mouse, .rattle, .pinwheel: .toys
        case .cushion, .flower, .lamp, .picture, .rug, .clock, .shelf, .plant,
             .banner, .stool, .nightlight, .basket, .mobile, .mirror: .room
        }
    }

    var price: Int {
        switch self {
        case .bow: 40
        case .glasses: 50
        case .collar: 60
        case .partyHat: 45
        case .crown: 90
        case .ball: 25
        case .teddy, .flower: 35
        case .butterfly, .lamp: 40
        case .cushion, .picture: 30
        case .beret, .scarf, .bowTie, .sunHat, .tiara, .earmuffs, .bandana,
             .visor, .pendant, .starGlasses: 45
        case .yarn, .kite, .drum, .duck, .train, .blocks, .rocket, .mouse,
             .rattle, .pinwheel: 30
        case .rug, .clock, .shelf, .plant, .banner, .stool, .nightlight,
             .basket, .mobile, .mirror: 35
        }
    }

    var title: String {
        switch self {
        case .bow: "Бантик"
        case .glasses: "Очки"
        case .collar: "Ошейник"
        case .partyHat: "Колпак"
        case .crown: "Корона"
        case .ball: "Мячик"
        case .teddy: "Мишка"
        case .butterfly: "Бабочка"
        case .cushion: "Подушка"
        case .flower: "Цветок"
        case .lamp: "Лампа"
        case .picture: "Картина"
        case .beret: "Берет"
        case .scarf: "Шарфик"
        case .bowTie: "Бабочка"
        case .sunHat: "Панамка"
        case .tiara: "Диадема"
        case .earmuffs: "Наушники"
        case .bandana: "Бандана"
        case .visor: "Козырёк"
        case .pendant: "Кулон"
        case .starGlasses: "Звёздные очки"
        case .yarn: "Клубок"
        case .kite: "Змей"
        case .drum: "Барабан"
        case .duck: "Уточка"
        case .train: "Паровозик"
        case .blocks: "Кубики"
        case .rocket: "Ракета"
        case .mouse: "Мышка"
        case .rattle: "Погремушка"
        case .pinwheel: "Вертушка"
        case .rug: "Коврик"
        case .clock: "Часы"
        case .shelf: "Полочка"
        case .plant: "Растение"
        case .banner: "Гирлянда"
        case .stool: "Табурет"
        case .nightlight: "Ночник"
        case .basket: "Корзинка"
        case .mobile: "Мобиль"
        case .mirror: "Зеркало"
        }
    }

    var artName: String {
        switch self {
        case .bow: "shop_bow"
        case .glasses: "shop_glasses"
        case .collar: "shop_collar"
        case .partyHat: "shop_partyhat"
        case .crown: "shop_crown"
        case .ball: "shop_ball"
        case .teddy: "shop_teddy"
        case .butterfly: "shop_butterfly"
        case .cushion: "shop_cushion"
        case .flower: "shop_flower"
        case .lamp: "shop_lamp"
        case .picture: "shop_picture"
        case .beret: "shop_beret"
        case .scarf: "shop_scarf"
        case .bowTie: "shop_bowtie"
        case .sunHat: "shop_sunhat"
        case .tiara: "shop_tiara"
        case .earmuffs: "shop_earmuffs"
        case .bandana: "shop_bandana"
        case .visor: "shop_visor"
        case .pendant: "shop_pendant"
        case .starGlasses: "shop_starglasses"
        case .yarn: "shop_yarn"
        case .kite: "shop_kite"
        case .drum: "shop_drum"
        case .duck: "shop_duck"
        case .train: "shop_train"
        case .blocks: "shop_blocks"
        case .rocket: "shop_rocket"
        case .mouse: "shop_mouse"
        case .rattle: "shop_rattle"
        case .pinwheel: "shop_pinwheel"
        case .rug: "shop_rug"
        case .clock: "shop_clock"
        case .shelf: "shop_shelf"
        case .plant: "shop_plant"
        case .banner: "shop_banner"
        case .stool: "shop_stool"
        case .nightlight: "shop_nightlight"
        case .basket: "shop_basket"
        case .mobile: "shop_mobile"
        case .mirror: "shop_mirror"
        }
    }

    var roomSlot: RoomDecorSlot? {
        switch self {
        case .picture, .clock, .shelf, .banner, .mobile, .mirror: .wall
        case .flower, .lamp, .plant, .nightlight: .surface
        case .cushion, .rug, .stool, .basket: .floor
        default: nil
        }
    }
}

extension Ingredient {
    var shopPrice: Int {
        switch self {
        case .fish: 12
        case .chicken, .cheese: 10
        case .milk, .berry: 8
        case .rice, .carrot, .herb: 6
        case .apple, .pumpkin, .banana, .pear, .broccoli, .egg,
             .yogurt, .oats, .peas, .potato: 8
        }
    }

    var shopTitle: String {
        switch self {
        case .fish: "Рыбка"
        case .chicken: "Курочка"
        case .milk: "Молочко"
        case .rice: "Рисик"
        case .carrot: "Морковка"
        case .cheese: "Сырик"
        case .berry: "Ягодки"
        case .herb: "Травка"
        case .apple: "Яблоко"
        case .pumpkin: "Тыква"
        case .banana: "Банан"
        case .pear: "Груша"
        case .broccoli: "Брокколи"
        case .egg: "Яйцо"
        case .yogurt: "Йогурт"
        case .oats: "Овсянка"
        case .peas: "Горошек"
        case .potato: "Картошка"
        }
    }

    var shopArtName: String {
        switch self {
        case .fish: "food_fish"
        case .chicken: "food_chicken"
        case .milk: "food_milk"
        case .rice: "food_rice"
        case .carrot: "food_carrot"
        case .cheese: "food_cheese"
        case .berry: "food_berry"
        case .herb: "food_herb"
        case .apple: "food_apple"
        case .pumpkin: "food_pumpkin"
        case .banana: "food_banana"
        case .pear: "food_pear"
        case .broccoli: "food_broccoli"
        case .egg: "food_egg"
        case .yogurt: "food_yogurt"
        case .oats: "food_oats"
        case .peas: "food_peas"
        case .potato: "food_potato"
        }
    }
}

struct ShopState: Codable, Equatable, Sendable {
    private(set) var owned: Set<ShopItem> = []
    private(set) var equippedHead: ShopItem?
    private(set) var equippedFace: ShopItem?
    private(set) var equippedNeck: ShopItem?
    private(set) var displayedDecor: ShopItem?
    private(set) var displayedWall: ShopItem?
    private(set) var displayedSurface: ShopItem?
    private(set) var displayedFloor: ShopItem?
    private(set) var toyOrder: [ShopItem]?

    func isEquipped(_ item: ShopItem) -> Bool {
        equippedHead == item || equippedFace == item || equippedNeck == item
    }

    mutating func toggleOutfit(_ item: ShopItem) {
        guard owned.contains(item), item.category == .outfits else { return }
        switch item {
        case .bow, .partyHat, .crown, .beret, .sunHat, .tiara,
             .earmuffs, .visor:
            equippedHead = equippedHead == item ? nil : item
            if item == .partyHat || item == .crown || item == .sunHat { equippedFace = nil }
        case .glasses, .starGlasses:
            equippedFace = equippedFace == item ? nil : item
            if equippedFace != nil && (equippedHead == .partyHat || equippedHead == .crown || equippedHead == .sunHat) {
                equippedHead = nil
            }
        case .collar, .scarf, .bowTie, .pendant, .bandana:
            if item == .bandana && equippedHead == .bandana { equippedHead = nil }
            equippedNeck = equippedNeck == item ? nil : item
        default: break
        }
    }

    mutating func selectDecor(_ item: ShopItem) {
        guard owned.contains(item), item.category == .room else { return }
        displayedDecor = item
        switch item.roomSlot {
        case .wall: displayedWall = item
        case .surface: displayedSurface = item
        case .floor: displayedFloor = item
        case nil: break
        }
    }

    func isDisplayed(_ item: ShopItem) -> Bool {
        guard let slot = item.roomSlot else { return false }
        switch slot {
        case .wall: return (displayedWall ?? (displayedDecor?.roomSlot == .wall ? displayedDecor : nil)) == item
        case .surface: return (displayedSurface ?? (displayedDecor?.roomSlot == .surface ? displayedDecor : nil)) == item
        case .floor: return (displayedFloor ?? (displayedDecor?.roomSlot == .floor ? displayedDecor : nil)) == item
        }
    }

    func displayed(in slot: RoomDecorSlot) -> ShopItem? {
        let item: ShopItem?
        switch slot {
        case .wall: item = displayedWall
        case .surface: item = displayedSurface
        case .floor: item = displayedFloor
        }
        if let item, owned.contains(item) { return item }
        if let displayedDecor, owned.contains(displayedDecor), displayedDecor.roomSlot == slot { return displayedDecor }
        return ShopItem.allCases.last { owned.contains($0) && $0.roomSlot == slot }
    }

    var ownedToysInDisplayOrder: [ShopItem] {
        let ownedToys = ShopItem.allCases.filter { $0.category == .toys && owned.contains($0) }
        guard let toyOrder else { return ownedToys }
        let saved = toyOrder.filter { owned.contains($0) && $0.category == .toys }
        return saved + ownedToys.filter { !saved.contains($0) }
    }

    mutating func buy(_ item: ShopItem, kitchen: inout KitchenState) -> Bool {
        guard !owned.contains(item), kitchen.coins >= item.price else { return false }
        kitchen.coins -= item.price
        owned.insert(item)
        if item.category == .room { selectDecor(item) }
        if item.category == .toys {
            var order = ownedToysInDisplayOrder.filter { $0 != item }
            order.append(item)
            toyOrder = order
        }
        return true
    }

    static func buyFood(_ ingredient: Ingredient, kitchen: inout KitchenState) -> Bool {
        guard kitchen.coins >= ingredient.shopPrice,
              kitchen.available(ingredient) <= 96 else { return false }
        kitchen.coins -= ingredient.shopPrice
        kitchen.restock(ingredient, amount: 3)
        return true
    }
}
