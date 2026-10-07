import XCTest
@testable import MyFluffy

final class ShopLogicTests: XCTestCase {
    func testExpandedCatalogHasExpectedCategoriesAndPrices() {
        XCTAssertEqual(ShopItem.allCases.count, 42)
        XCTAssertEqual(Ingredient.allCases.count, 18)
        XCTAssertEqual(ShopItem.allCases.filter { $0.category == .outfits }.count, 15)
        XCTAssertEqual(ShopItem.allCases.filter { $0.category == .toys }.count, 13)
        XCTAssertEqual(ShopItem.allCases.filter { $0.category == .room }.count, 14)
        XCTAssertEqual(ShopItem.crown.price, 90)
        XCTAssertEqual(Ingredient.fish.shopPrice, 12)
    }

    func testBuyingItemCostsCoinsOnce() {
        var kitchen = KitchenState.newcomer
        kitchen.coins = 40
        var shop = ShopState()
        XCTAssertTrue(shop.buy(.bow, kitchen: &kitchen))
        XCTAssertEqual(kitchen.coins, 0)
        XCTAssertTrue(shop.owned.contains(.bow))
        XCTAssertFalse(shop.buy(.bow, kitchen: &kitchen))
        XCTAssertFalse(shop.buy(.crown, kitchen: &kitchen))
        XCTAssertEqual(kitchen.coins, 0)
    }

    func testFoodAddsThreeAndRespectsBalanceAndCapacity() {
        var kitchen = KitchenState.newcomer
        kitchen.coins = 12
        XCTAssertTrue(ShopState.buyFood(.fish, kitchen: &kitchen))
        XCTAssertEqual(kitchen.available(.fish), 5)
        XCTAssertEqual(kitchen.coins, 0)
        XCTAssertFalse(ShopState.buyFood(.fish, kitchen: &kitchen))
        kitchen.coins = 100
        kitchen.inventory[.fish] = 97
        XCTAssertFalse(ShopState.buyFood(.fish, kitchen: &kitchen))
        XCTAssertEqual(kitchen.coins, 100)
    }

    func testOutfitsUseSlotsAndGlassesReplaceCrown() {
        var kitchen = KitchenState.newcomer
        kitchen.coins = 300
        var shop = ShopState()
        for item in [ShopItem.crown, .glasses, .collar, .bow] {
            XCTAssertTrue(shop.buy(item, kitchen: &kitchen))
        }
        shop.toggleOutfit(.crown)
        shop.toggleOutfit(.collar)
        XCTAssertTrue(shop.isEquipped(.crown))
        XCTAssertTrue(shop.isEquipped(.collar))
        shop.toggleOutfit(.glasses)
        XCTAssertNil(shop.equippedHead)
        XCTAssertTrue(shop.isEquipped(.glasses))
        XCTAssertTrue(shop.isEquipped(.collar))
        shop.toggleOutfit(.bow)
        XCTAssertTrue(shop.isEquipped(.bow))
        XCTAssertTrue(shop.isEquipped(.glasses))
    }

    func testSelectedDecorIsSavedWithShop() throws {
        var kitchen = KitchenState.newcomer
        kitchen.coins = 100
        var shop = ShopState()
        XCTAssertTrue(shop.buy(.flower, kitchen: &kitchen))
        XCTAssertTrue(shop.buy(.lamp, kitchen: &kitchen))
        XCTAssertEqual(shop.displayedDecor, .lamp)
        shop.selectDecor(.flower)
        XCTAssertEqual(shop.displayedDecor, .flower)
        XCTAssertEqual(shop.displayed(in: .surface), .flower)
        let restored = try JSONDecoder().decode(ShopState.self, from: JSONEncoder().encode(shop))
        XCTAssertEqual(restored.displayedDecor, .flower)
        XCTAssertEqual(restored.displayed(in: .surface), .flower)
    }

    func testRoomItemsUseSeparatePlaces() {
        var kitchen = KitchenState.newcomer
        kitchen.coins = 200
        var shop = ShopState()
        for item in [ShopItem.picture, .flower, .rug, .clock] {
            XCTAssertTrue(shop.buy(item, kitchen: &kitchen))
        }
        XCTAssertEqual(shop.displayed(in: .wall), .clock)
        XCTAssertEqual(shop.displayed(in: .surface), .flower)
        XCTAssertEqual(shop.displayed(in: .floor), .rug)
        shop.selectDecor(.picture)
        XCTAssertEqual(shop.displayed(in: .wall), .picture)
        XCTAssertEqual(shop.displayed(in: .floor), .rug)
    }

    func testPreviouslySavedPurchasesRemainVisibleAfterSchemaChange() throws {
        let oldSave = Data(#"{"owned":["w_beret","r_lamp","t_yarn"],"equippedHead":"w_beret","equippedFace":null,"equippedNeck":null}"#.utf8)
        let shop = try JSONDecoder().decode(ShopState.self, from: oldSave)
        XCTAssertTrue(shop.isEquipped(.beret))
        XCTAssertEqual(shop.displayed(in: .surface), .lamp)
        XCTAssertTrue(shop.owned.contains(.yarn))
        XCTAssertEqual(shop.ownedToysInDisplayOrder, [.yarn])
    }

    func testBandanaUsesNeckSlotAndToysKeepPurchaseOrder() throws {
        var kitchen = KitchenState.newcomer
        kitchen.coins = 500
        var shop = ShopState()
        for item in [ShopItem.bandana, .bow, .rocket, .ball, .teddy] {
            XCTAssertTrue(shop.buy(item, kitchen: &kitchen))
        }
        shop.toggleOutfit(.bow)
        shop.toggleOutfit(.bandana)
        XCTAssertEqual(shop.equippedHead, .bow)
        XCTAssertEqual(shop.equippedNeck, .bandana)
        XCTAssertEqual(shop.ownedToysInDisplayOrder, [.rocket, .ball, .teddy])
        let restored = try JSONDecoder().decode(ShopState.self, from: JSONEncoder().encode(shop))
        XCTAssertEqual(restored.ownedToysInDisplayOrder, [.rocket, .ball, .teddy])
    }

    func testFittedScarfRendersOnCurrentCatExpression() {
        guard let cat = ArtImage.named("cat_plush_dirty") else {
            return XCTFail("Missing cat art")
        }
        var kitchen = KitchenState.newcomer
        kitchen.coins = 100
        var shop = ShopState()
        XCTAssertTrue(shop.buy(.scarf, kitchen: &kitchen))
        shop.toggleOutfit(.scarf)
        let withoutScarf = CatOutfitRenderer.render(base: cat, shop: ShopState())
        let withScarf = CatOutfitRenderer.render(base: cat, shop: shop)
        XCTAssertEqual(withScarf.size, CGSize(width: 320, height: 320))
        XCTAssertNotEqual(withoutScarf.pngData(), withScarf.pngData())
    }

    func testSleepingCatTemporarilyRemovesOutfit() {
        guard let cat = ArtImage.named("cat_plush_sleeping") else { return XCTFail("Missing sleeping cat") }
        var kitchen = KitchenState.newcomer
        kitchen.coins = 100
        var shop = ShopState()
        XCTAssertTrue(shop.buy(.scarf, kitchen: &kitchen))
        shop.toggleOutfit(.scarf)
        XCTAssertEqual(CatOutfitRenderer.render(base: cat, shop: shop).pngData(),
                       CatOutfitRenderer.render(base: cat, shop: ShopState()).pngData())
    }
}
