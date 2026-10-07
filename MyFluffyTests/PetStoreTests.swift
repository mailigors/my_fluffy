import XCTest
@testable import MyFluffy

final class PetStoreTests: XCTestCase {
    func testMissingPetLoadsAsNil() async throws {
        let store = PetStore(inMemory: true)
        try await store.loadStores()
        let loaded = try store.load()
        XCTAssertNil(loaded)
    }

    func testSaveAndLoadRoundTrip() async throws {
        let store = PetStore(inMemory: true)
        try await store.loadStores()
        let origin = Date(timeIntervalSince1970: 1_700_000_000)
        var needs = PetNeeds.newcomer(at: origin)
        needs.mood = 44
        let pet = StoredPet(needs: needs, isSleeping: true)
        try store.save(pet)
        let loaded = try store.load()
        XCTAssertEqual(loaded, pet)
    }

    func testShopOwnershipAndFoodPersist() async throws {
        let store = PetStore(inMemory: true)
        try await store.loadStores()
        var kitchen = KitchenState.newcomer
        kitchen.coins = 100
        var shop = ShopState()
        XCTAssertTrue(shop.buy(.bow, kitchen: &kitchen))
        XCTAssertTrue(ShopState.buyFood(.fish, kitchen: &kitchen))
        let pet = StoredPet(needs: .newcomer(at: Date(timeIntervalSince1970: 1_700_000_000)),
                            isSleeping: false, kitchen: kitchen, shop: shop)
        try store.save(pet)
        XCTAssertEqual(try store.load()?.shop, shop)
        XCTAssertEqual(try store.load()?.kitchen, kitchen)
    }
}
