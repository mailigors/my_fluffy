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
}
