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

    func testBackgroundMusicActuallyStarts() {
        let sound = BundleSoundPlayer()
        sound.prepareSession()
        sound.startMusic()
        XCTAssertTrue(sound.isMusicPlaying)
        sound.stopMusic()
    }

    func testEveryGameCueIsBundled() {
        for cue in GameCue.allCases {
            XCTAssertNotNil(BundleFile.url(name: cue.rawValue, extension: "caf", subdirectory: "Resources/Audio"), cue.rawValue)
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

    func testPuzzlePicturesAreBundled() {
        for name in ["puzzle_playroom", "puzzle_picnic", "puzzle_space", "puzzle_dinosaurs"] {
            XCTAssertNotNil(BundleFile.url(name: name, extension: "png", subdirectory: "Resources/Art"), name)
        }
    }

    func testShopIllustrationsAreBundled() {
        let names = ShopItem.allCases.map(\.artName)
            + Ingredient.allCases.map(\.shopArtName)
            + ["shop_scene", "wardrobe_scene", "parent_scene", "reward_gift", "no_ads_badge"]
        for name in names {
            XCTAssertNotNil(BundleFile.url(name: name, extension: "png", subdirectory: "Resources/Art"), name)
        }
    }

    func testFittedRoomAndOutfitArtIsBundled() {
        let outfitNames = ShopItem.allCases.filter { $0.category == .outfits }
            .map { "cat_fitted_\($0.artName.dropFirst(5))" }
        let roomNames = ShopItem.allCases.filter { $0.category == .room }
            .map { "room_fitted_\($0.artName.dropFirst(5))" }
        let toyNames = ShopItem.allCases.filter { $0.category == .toys }
            .map { "room_toy_\($0.artName.dropFirst(5))" }
        let extra = ["room_day_clean", "room_night_clean", "room_cutout_flower", "room_cutout_plant",
                     "room_cutout_lamp", "room_cutout_nightlight"]
        for name in outfitNames + roomNames + toyNames + extra {
            XCTAssertNotNil(BundleFile.url(name: name, extension: "png", subdirectory: "Resources/Art"), name)
        }
    }
}
