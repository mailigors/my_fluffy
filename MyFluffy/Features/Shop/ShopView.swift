import SwiftUI

struct ShopView: View {
    @EnvironmentObject private var model: RoomViewModel
    @State private var selected: ShopCategory = .food

    var body: some View {
        ActivityScene(art: "shop_scene", title: "Магазин") {
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    Text("🪙 \(model.kitchen.coins)")
                        .font(AppFonts.heading(27))
                        .foregroundStyle(AppColors.ink)
                        .padding(.horizontal, 18).padding(.vertical, 9)
                        .background(.white.opacity(0.95), in: Capsule())
                    Button { model.addTestCoins() } label: {
                        Text("Тест: +100")
                            .font(AppFonts.heading(19))
                            .foregroundStyle(AppColors.ink)
                            .frame(minHeight: 58)
                            .padding(.horizontal, 16)
                            .background(AppColors.mint, in: Capsule())
                    }
                    .disabled(model.kitchen.coins >= 9_999)
                    .accessibilityLabel("Добавить 100 тестовых монет")
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 9) {
                        ForEach(ShopCategory.allCases, id: \.self) { category in
                            Button { selected = category } label: {
                                Text(category.title)
                                    .font(AppFonts.heading(19))
                                    .foregroundStyle(AppColors.ink)
                                    .padding(.horizontal, 16)
                                    .frame(height: 62)
                                    .background(selected == category ? AppColors.yellow : .white, in: Capsule())
                                    .overlay { Capsule().stroke(AppColors.ink, lineWidth: 2) }
                            }
                            .accessibilityLabel(category.title)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if selected == .outfits {
                            Button { model.openWardrobe() } label: {
                                Label("Примерить наряды", systemImage: "hanger")
                                    .font(AppFonts.heading(21))
                                    .foregroundStyle(AppColors.ink)
                                    .frame(maxWidth: .infinity, minHeight: 68)
                                    .background(AppColors.mint, in: Capsule())
                            }
                        }
                        if selected == .food {
                            ForEach(Ingredient.allCases, id: \.self) { ingredient in
                                foodRow(ingredient)
                            }
                        } else {
                            ForEach(ShopItem.allCases.filter { $0.category == selected }, id: \.self) { item in
                                itemRow(item)
                            }
                        }
                    }
                    .padding(.horizontal, 16).padding(.bottom, 28)
                }
                Button { model.openParentGate() } label: {
                    Label("Для родителей", systemImage: "person.crop.circle.badge.checkmark")
                        .font(AppFonts.body(16))
                        .foregroundStyle(AppColors.ink)
                        .frame(minHeight: 50)
                }
            }
            .padding(.top, 92)
        }
    }

    private func foodRow(_ ingredient: Ingredient) -> some View {
        let stock = model.kitchen.available(ingredient)
        let detail: String
        if stock > 96 { detail = "Полка полна" }
        else if model.kitchen.coins < ingredient.shopPrice { detail = "Нужно ещё \(ingredient.shopPrice - model.kitchen.coins) монет" }
        else { detail = "В запасе: \(stock) · Набор ×3" }
        return productRow(artName: ingredient.shopArtName,
                   title: ingredient.shopTitle,
                   detail: detail,
                   price: ingredient.shopPrice,
                   bought: false,
                   canBuy: model.kitchen.coins >= ingredient.shopPrice && stock <= 96) {
            model.buyShopFood(ingredient)
        }
    }

    private func itemRow(_ item: ShopItem) -> some View {
        let bought = model.shop.owned.contains(item)
        let displayed = model.shop.isDisplayed(item)
        let equipped = model.shop.isEquipped(item)
        let detail = bought ? (displayed ? "Стоит в комнате" : equipped ? "На котёнке" : "Уже твой") :
            (model.kitchen.coins < item.price ? "Нужно ещё \(item.price - model.kitchen.coins) монет" : "")
        let ownedAction = bought && (item.category == .room || item.category == .outfits)
        let actionTitle: String? = ownedAction
            ? (item.category == .room ? (displayed ? "✓ Стоит" : "Поставить") : (equipped ? "✓ Надето" : "Надеть"))
            : nil
        return productRow(artName: item.artName,
                          title: item.title,
                          detail: detail,
                          price: item.price,
                          bought: bought,
                          canBuy: ownedAction ? !(item.category == .room ? displayed : equipped) : (!bought && model.kitchen.coins >= item.price),
                          buttonTitle: actionTitle) {
            if bought && item.category == .room {
                model.selectRoomDecor(item)
            } else if bought && item.category == .outfits {
                model.wearShopOutfit(item)
            } else {
                model.buyShopItem(item)
            }
        }
    }

    private func productRow(artName: String, title: String, detail: String, price: Int,
                            bought: Bool, canBuy: Bool, buttonTitle: String? = nil,
                            action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            ShopProductImage(artName: artName, size: 64)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(AppFonts.heading(20))
                if !detail.isEmpty { Text(detail).font(AppFonts.body(14)) }
            }
            .foregroundStyle(AppColors.ink)
            Spacer(minLength: 0)
            Button(action: action) {
                Text(buttonTitle ?? (bought ? "✓" : "🪙\(price)"))
                    .font(AppFonts.heading(buttonTitle == nil ? 19 : 15))
                    .foregroundStyle(AppColors.ink)
                    .frame(minWidth: 82, minHeight: 64)
                    .background(canBuy ? AppColors.yellow : AppColors.background, in: Capsule())
            }
            .disabled(!canBuy)
            .accessibilityLabel(buttonTitle.map { "\($0), \(title)" } ??
                                (bought ? "Куплено: \(title)" : "Купить \(title) за \(price) монет"))
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 24))
        .overlay { RoundedRectangle(cornerRadius: 24).stroke(AppColors.ink, lineWidth: 2) }
    }
}

struct ShopProductImage: View {
    let artName: String
    let size: CGFloat

    var body: some View {
        Group {
            if let image = ArtImage.named(artName) {
                Image(uiImage: image).resizable().scaledToFit()
            } else {
                Image(systemName: "shippingbox.fill")
                    .resizable().scaledToFit().padding(size * 0.22)
                    .foregroundStyle(AppColors.ink)
            }
        }
        .frame(width: size, height: size)
        .background(AppColors.background, in: RoundedRectangle(cornerRadius: size * 0.24))
        .overlay { RoundedRectangle(cornerRadius: size * 0.24).stroke(AppColors.ink, lineWidth: 2) }
    }
}
