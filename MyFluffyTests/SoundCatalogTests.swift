import XCTest
@testable import MyFluffy

final class SoundCatalogTests: XCTestCase {
    func testRoomSoundsAreInTheHostBundle() {
        for name in ["meow_01", "mrr_meow", "purr_loop", "snore_loop", "faucet_open", "water_loop", "cooking_sizzle", "music_day"] {
            XCTAssertNotNil(
                BundleFile.url(name: name, extension: "caf", subdirectory: "Resources/Audio"),
                name
            )
        }
    }

    func testRoomArtIsInTheHostBundle() {
        let names = [
            "cat_idle_01@3x",
            "cat_sleeping_01@3x",
            "room_day@3x",
            "room_night@3x",
            "sticker_heart@3x",
            "sticker_moon@3x"
        ]
        for name in names {
            XCTAssertNotNil(
                BundleFile.url(name: name, extension: "png", subdirectory: "Resources/Art"),
                name
            )
        }
    }

    func testPreparedDishIllustrationsAreBundled() {
        for name in ["kitchen_dish", "kitchen_dish_milkshake", "kitchen_dish_soup", "kitchen_dish_salad", "kitchen_dish_burger", "kitchen_dish_pie", "kitchen_dish_fish", "kitchen_dish_chicken", "kitchen_dish_dairy", "kitchen_dish_mixed"] {
            XCTAssertNotNil(BundleFile.url(name: name, extension: "png", subdirectory: "Resources/Art"), name)
        }
    }
}
