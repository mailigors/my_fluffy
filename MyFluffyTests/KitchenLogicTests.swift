import XCTest
@testable import MyFluffy

final class KitchenLogicTests: XCTestCase {
    private func prepared(_ ingredients: [Ingredient]) -> KitchenSession {
        var session = KitchenSession()
        for ingredient in ingredients { session.add(ingredient, from: .newcomer) }
        session.start()
        session.setColdFlow(0.6)
        session.setHotFlow(0.6)
        for _ in ingredients { session.wash(distance: 120) }
        for _ in ingredients { session.chop() }
        session.setHeat(0.55)
        session.placeIngredientsInPan()
        for _ in 0..<3 { session.stir(distance: 120) }
        session.chooseDecoration(0)
        session.decorate()
        return session
    }

    func testExactRecipeUsesBonusAndAwardsCoinsOnlyWhenHungry() throws {
        let session = prepared([.fish, .rice])
        var needs = PetNeeds.newcomer(at: Date(timeIntervalSince1970: 0))
        needs.satiety = 59
        let hungry = try XCTUnwrap(KitchenEconomy.serve(session, needs: needs, kitchen: .newcomer))
        XCTAssertEqual(hungry.recipe, .plov)
        XCTAssertEqual(hungry.needs.satiety, 92.6, accuracy: 0.001)
        XCTAssertEqual(hungry.coinsEarned, 6)
        XCTAssertEqual(hungry.kitchen.available(.fish), 1)
        XCTAssertTrue(hungry.kitchen.discoveredRecipes.contains(.plov))

        needs.satiety = 60
        let full = KitchenEconomy.serve(session, needs: needs, kitchen: .newcomer)
        XCTAssertEqual(full?.coinsEarned, 0)
        XCTAssertEqual(full?.kitchen.coins, 0)
    }

    func testExtraIngredientAndDuplicateDoNotMatchRecipe() {
        XCTAssertNil(RecipeID.matching([.fish, .rice, .milk]))
        XCTAssertNil(RecipeID.matching([.fish, .fish, .rice]))
        XCTAssertEqual(RecipeID.matching([.rice, .fish]), .plov)
    }

    func testDishVisualFollowsChosenIngredients() {
        XCTAssertEqual(KitchenDishVisual.artName(for: [.fish, .rice]), "kitchen_dish")
        XCTAssertEqual(KitchenDishVisual.artName(for: [.milk, .berry]), "kitchen_dish_milkshake")
        XCTAssertEqual(KitchenDishVisual.artName(for: [.chicken, .carrot, .rice]), "kitchen_dish_soup")
        XCTAssertEqual(KitchenDishVisual.artName(for: [.carrot, .herb, .cheese]), "kitchen_dish_salad")
        XCTAssertEqual(KitchenDishVisual.artName(for: [.chicken, .cheese, .rice]), "kitchen_dish_burger")
        XCTAssertEqual(KitchenDishVisual.artName(for: [.berry, .milk, .rice]), "kitchen_dish_pie")
        XCTAssertEqual(KitchenDishVisual.artName(for: [.milk, .cheese]), "kitchen_dish_dairy")
        XCTAssertEqual(KitchenDishVisual.artName(for: [.fish, .cheese]), "kitchen_dish_fish")
        XCTAssertEqual(KitchenDishVisual.artName(for: [.chicken, .herb]), "kitchen_dish_chicken")
        XCTAssertEqual(KitchenDishVisual.artName(for: [.rice, .rice]), "kitchen_dish_mixed")
    }

    func testWaterMustBeWarmAndEveryIngredientWashed() {
        var session = KitchenSession()
        session.add(.fish, from: .newcomer)
        session.add(.rice, from: .newcomer)
        session.start()
        session.wash(distance: 240)
        XCTAssertEqual(session.washedCount, 0)
        session.setColdFlow(0.8)
        XCTAssertEqual(session.waterTemperature, .cold)
        session.wash(distance: 120)
        XCTAssertEqual(session.washedCount, 0)
        session.setHotFlow(0.2)
        XCTAssertEqual(session.waterTemperature, .cold)
        session.wash(distance: 120)
        XCTAssertEqual(session.washedCount, 0)
        session.setHotFlow(0.8)
        XCTAssertEqual(session.waterTemperature, .warm)
        session.wash(distance: 60)
        XCTAssertEqual(session.washedCount, 0)
        XCTAssertEqual(session.washDistance, 60)
        session.wash(distance: 60)
        XCTAssertEqual(session.washedCount, 1)
        XCTAssertEqual(session.step, .washing)
        session.setColdFlow(0.2)
        XCTAssertEqual(session.waterTemperature, .hot)
        session.wash(distance: 120)
        XCTAssertEqual(session.washedCount, 1)
        session.setColdFlow(0.8)
        session.wash(distance: 120)
        XCTAssertEqual(session.step, .chopping)
    }

    func testYellowDoesNotCookGreenStirringFinishesDish() {
        var session = KitchenSession()
        session.add(.fish, from: .newcomer)
        session.add(.rice, from: .newcomer)
        session.start()
        session.setColdFlow(0.6)
        session.setHotFlow(0.6)
        session.wash(distance: 120)
        session.wash(distance: 120)
        session.chop()
        session.chop()
        session.setHeat(0.15)
        session.placeIngredientsInPan()
        session.stir(distance: 120)
        XCTAssertEqual(session.stirCount, 0)
        XCTAssertEqual(session.step, .frying)
        session.setHeat(0.55)
        session.stir(distance: 60)
        XCTAssertEqual(session.stirCount, 0)
        session.stir(distance: 60)
        session.stir(distance: 120)
        XCTAssertEqual(session.step, .frying)
        session.stir(distance: 120)
        XCTAssertEqual(session.step, .decorating)
    }

    func testRedBurnsAndConsumesIngredients() {
        var session = KitchenSession()
        session.add(.fish, from: .newcomer)
        session.add(.rice, from: .newcomer)
        session.start()
        session.setColdFlow(0.6)
        session.setHotFlow(0.6)
        session.wash(distance: 120)
        session.wash(distance: 120)
        session.chop()
        session.chop()
        session.setHeat(0.55)
        session.placeIngredientsInPan()
        session.setHeat(0.9)
        XCTAssertEqual(session.step, .burnt)
        XCTAssertNil(KitchenEconomy.serve(session, needs: .newcomer(at: Date()), kitchen: .newcomer))
        let remaining = KitchenEconomy.consumeBurnt(session, kitchen: .newcomer)
        XCTAssertEqual(remaining?.available(.fish), 1)
        XCTAssertEqual(remaining?.available(.rice), 1)
        XCTAssertEqual(remaining?.coins, 0)
    }

    func testOffSliderCannotCookOrAcceptIngredients() {
        var session = KitchenSession()
        session.add(.fish, from: .newcomer)
        session.add(.rice, from: .newcomer)
        session.start()
        session.setColdFlow(0.6)
        session.setHotFlow(0.6)
        session.wash(distance: 120)
        session.wash(distance: 120)
        session.chop()
        session.chop()
        session.placeIngredientsInPan()
        XCTAssertFalse(session.ingredientsInPan)
        session.setHeat(0.55)
        XCTAssertTrue(session.stoveOn)
        session.placeIngredientsInPan()
        session.setHeat(0)
        XCTAssertFalse(session.stoveOn)
        session.stir(distance: 120)
        XCTAssertEqual(session.stirCount, 0)
    }

    func testLegacyKitchenStateStillDecodes() throws {
        var original = KitchenState.newcomer
        original.readyMeals = 1
        let data = try JSONEncoder().encode(original)
        XCTAssertEqual(try JSONDecoder().decode(KitchenState.self, from: data), original)
    }

    func testRestockHasBoundedInventory() {
        var kitchen = KitchenState.newcomer
        kitchen.restock(.fish)
        XCTAssertEqual(kitchen.available(.fish), 5)
        kitchen.restock(.fish, amount: 200)
        XCTAssertEqual(kitchen.available(.fish), 99)
        kitchen.restock(.fish, amount: -1)
        XCTAssertEqual(kitchen.available(.fish), 99)
    }
}
