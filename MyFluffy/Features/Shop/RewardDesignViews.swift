import SwiftUI

struct RewardConfirmSheet: View {
    let accept: () -> Void
    let decline: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            ShopProductImage(artName: "reward_gift", size: 118)
            Text("Смотрим?")
                .font(AppFonts.heading(30))
                .foregroundStyle(AppColors.ink)
            HStack(spacing: 14) {
                Button("Нет", action: decline)
                    .background(AppColors.background, in: Capsule())
                Button("Да", action: accept)
                    .background(AppColors.yellow, in: Capsule())
            }
            .font(AppFonts.heading(22))
            .foregroundStyle(AppColors.ink)
            .buttonStyle(RewardChoiceStyle())
        }
        .padding(24)
        .background(.white, in: RoundedRectangle(cornerRadius: 32))
        .overlay { RoundedRectangle(cornerRadius: 32).stroke(AppColors.ink, lineWidth: 3) }
        .padding(24)
    }
}

private struct RewardChoiceStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, minHeight: 68)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct NoAdsPurchaseCard: View {
    let price: String
    let purchase: () -> Void
    let restore: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ShopProductImage(artName: "no_ads_badge", size: 100)
            Text("Без рекламы")
                .font(AppFonts.heading(26))
                .foregroundStyle(AppColors.ink)
            Button("Купить · \(price)", action: purchase)
                .font(AppFonts.heading(21))
                .foregroundStyle(AppColors.ink)
                .frame(maxWidth: .infinity, minHeight: 68)
                .background(AppColors.yellow, in: Capsule())
            Button("Восстановить покупку", action: restore)
                .font(AppFonts.body(17))
                .foregroundStyle(AppColors.ink)
                .frame(minHeight: 52)
        }
        .padding(18)
        .background(.white, in: RoundedRectangle(cornerRadius: 27))
        .overlay { RoundedRectangle(cornerRadius: 27).stroke(AppColors.ink, lineWidth: 2) }
    }
}
