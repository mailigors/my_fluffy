import SwiftUI

struct WardrobeView: View {
    @EnvironmentObject private var model: RoomViewModel

    private var outfits: [ShopItem] {
        ShopItem.allCases.filter { $0.category == .outfits && model.shop.owned.contains($0) }
    }

    var body: some View {
        ActivityScene(art: "wardrobe_scene", title: "Гардероб") {
            GeometryReader { area in
                let catSize = max(170, min(280, area.size.height * 0.34))
                VStack(spacing: 12) {
                    Text("Наряди котёнка")
                        .font(AppFonts.heading(24))
                        .foregroundStyle(AppColors.ink)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(.white.opacity(0.94), in: Capsule())
                    Spacer(minLength: 0)
                    ZStack {
                        if let cat = ArtImage.named("cat_plush_awake") {
                            Image(uiImage: CatOutfitRenderer.render(base: cat, shop: model.shop))
                                .resizable().scaledToFit()
                                .frame(width: 280, height: 280)
                        }
                    }
                    .frame(width: 280, height: 280)
                    .scaleEffect(catSize / 280)
                    .frame(width: catSize, height: catSize)
                    .accessibilityLabel("Котёнок в выбранном наряде")
                    Spacer(minLength: 0)
                    if outfits.isEmpty {
                        Text("В магазине ждут наряды!")
                            .font(AppFonts.heading(22))
                            .foregroundStyle(AppColors.ink)
                            .padding(18)
                            .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 22))
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(outfits, id: \.self) { item in
                                    Button { model.toggleOutfit(item) } label: {
                                        VStack(spacing: 5) {
                                            ShopProductImage(artName: item.artName, size: 82)
                                            Text(item.title)
                                                .font(AppFonts.heading(16))
                                                .foregroundStyle(AppColors.ink)
                                            if model.shop.isEquipped(item) {
                                                Text("✓ Надето")
                                                    .font(AppFonts.body(14))
                                                    .foregroundStyle(AppColors.ink)
                                            }
                                        }
                                        .frame(width: 108, height: 142)
                                        .background(model.shop.isEquipped(item) ? AppColors.yellow : .white,
                                                    in: RoundedRectangle(cornerRadius: 22))
                                        .overlay { RoundedRectangle(cornerRadius: 22).stroke(AppColors.ink, lineWidth: 2) }
                                    }
                                    .accessibilityLabel("\(item.title), \(model.shop.isEquipped(item) ? "надето" : "надеть")")
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .frame(height: 152)
                    }
                    Button { model.returnToShop() } label: {
                        Label("В магазин", systemImage: "bag.fill")
                            .font(AppFonts.heading(20))
                            .foregroundStyle(AppColors.ink)
                            .frame(minWidth: 190, minHeight: 64)
                            .background(AppColors.mint, in: Capsule())
                    }
                    .padding(.bottom, 15)
                }
                .padding(.top, 95)
                .frame(width: area.size.width, height: area.size.height, alignment: .top)
            }
        }
    }
}

struct RoomSceneLayout {
    let viewSize: CGSize
    private let artSize = CGSize(width: 941, height: 1672)

    private var scale: CGFloat {
        max(viewSize.width / artSize.width, viewSize.height / artSize.height)
    }

    func point(x: CGFloat, y: CGFloat) -> CGPoint {
        CGPoint(x: (viewSize.width - artSize.width * scale) / 2 + x * scale,
                y: (viewSize.height - artSize.height * scale) / 2 + y * scale)
    }

    func size(_ sourceSize: CGFloat, maximum: CGFloat) -> CGFloat {
        min(maximum, max(36, sourceSize * scale))
    }

    func length(_ sourceSize: CGFloat) -> CGFloat { sourceSize * scale }
}

private struct RoomFittedDecorSpec {
    let crop: CGRect
    let center: CGPoint
    let scale: CGFloat

    static func forItem(_ item: ShopItem) -> Self? {
        func make(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat,
                  centerX: CGFloat, centerY: CGFloat, scale: CGFloat) -> Self {
            Self(crop: CGRect(x: x, y: y, width: width, height: height),
                 center: CGPoint(x: centerX, y: centerY), scale: scale)
        }
        switch item {
        case .picture: return make(650, 545, 280, 265, centerX: 735, centerY: 695, scale: 0.62)
        case .mirror: return make(30, 525, 300, 295, centerX: 200, centerY: 690, scale: 0.58)
        case .clock: return make(20, 470, 315, 325, centerX: 200, centerY: 655, scale: 0.52)
        case .shelf: return make(20, 585, 350, 190, centerX: 210, centerY: 730, scale: 0.60)
        case .banner: return make(170, 540, 650, 285, centerX: 470, centerY: 710, scale: 0.75)
        case .mobile: return make(745, 85, 190, 330, centerX: 760, centerY: 280, scale: 0.72)
        case .flower: return make(0, 745, 230, 305, centerX: 165, centerY: 905, scale: 0.60)
        case .plant: return make(0, 750, 265, 310, centerX: 165, centerY: 905, scale: 0.53)
        case .lamp: return make(650, 800, 200, 270, centerX: 755, centerY: 915, scale: 0.60)
        case .nightlight: return make(720, 800, 210, 235, centerX: 765, centerY: 905, scale: 0.62)
        case .cushion: return make(25, 1150, 400, 305, centerX: 190, centerY: 1300, scale: 0.52)
        case .rug: return make(100, 1140, 750, 390, centerX: 470, centerY: 1320, scale: 0.70)
        case .stool: return make(45, 1110, 320, 335, centerX: 195, centerY: 1260, scale: 0.62)
        case .basket: return make(515, 1110, 410, 380, centerX: 750, centerY: 1280, scale: 0.48)
        default: return nil
        }
    }
}

private enum RoomFittedDecorArt {
    static let cache = NSCache<NSString, UIImage>()

    static func image(for item: ShopItem, spec: RoomFittedDecorSpec) -> UIImage? {
        let key = item.rawValue as NSString
        if let cached = cache.object(forKey: key) { return cached }
        if let cutout = ArtImage.uncached("room_cutout_\(item.artName.dropFirst(5))"),
           let trimmed = trimmedCutout(cutout) {
            cache.setObject(trimmed, forKey: key)
            return trimmed
        }
        guard let reference = ArtImage.named("room_day_clean"),
              let fitted = ArtImage.uncached("room_fitted_\(item.artName.dropFirst(5))"),
              let fullImage = ArtworkDifferenceMask.extract(from: fitted, comparedWith: reference,
                                                            region: spec.crop, width: 471, height: 836),
              let fullCG = fullImage.cgImage else { return nil }
        let crop = CGRect(x: spec.crop.minX * 0.5, y: spec.crop.minY * 0.5,
                          width: spec.crop.width * 0.5, height: spec.crop.height * 0.5).integral
        guard let cropped = fullCG.cropping(to: crop) else { return nil }
        let image = UIImage(cgImage: cropped)
        cache.setObject(image, forKey: key)
        return image
    }

    private static func trimmedCutout(_ image: UIImage) -> UIImage? {
        guard let source = image.cgImage else { return nil }
        let width = source.width, height = source.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = pixels.withUnsafeMutableBytes { bytes -> Bool in
            guard let context = CGContext(data: bytes.baseAddress, width: width, height: height,
                                          bitsPerComponent: 8, bytesPerRow: width * 4,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue) else { return false }
            context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return nil }
        var minX = width, minY = height, maxX = 0, maxY = 0
        for y in 0..<height {
            for x in 0..<width where pixels[(y * width + x) * 4 + 3] > 12 {
                minX = min(minX, x); minY = min(minY, y)
                maxX = max(maxX, x); maxY = max(maxY, y)
            }
        }
        guard minX <= maxX, minY <= maxY else { return nil }
        let margin = 8
        let crop = CGRect(x: max(0, minX - margin), y: max(0, minY - margin),
                          width: min(width - max(0, minX - margin), maxX - minX + 1 + margin * 2),
                          height: min(height - max(0, minY - margin), maxY - minY + 1 + margin * 2))
        guard let clipped = source.cropping(to: crop) else { return nil }
        return UIImage(cgImage: clipped)
    }
}

struct RoomOwnedDecor: View {
    let shop: ShopState
    let night: Bool

    var body: some View {
        GeometryReader { area in
            let layout = RoomSceneLayout(viewSize: area.size)
            ZStack {
                decor(in: .wall, layout: layout)
                decor(in: .surface, layout: layout)
                decor(in: .floor, layout: layout)
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder private func decor(in slot: RoomDecorSlot, layout: RoomSceneLayout) -> some View {
        if let item = shop.displayed(in: slot),
           let spec = RoomFittedDecorSpec.forItem(item),
           let image = RoomFittedDecorArt.image(for: item, spec: spec) {
            Image(uiImage: image).resizable().scaledToFit()
                .frame(width: layout.length(spec.crop.width * spec.scale),
                       height: layout.length(spec.crop.height * spec.scale))
                .colorMultiply(night ? Color(red: 0.76, green: 0.77, blue: 0.91) : .white)
                .shadow(color: night && (item == .lamp || item == .nightlight) ? AppColors.yellow : .clear, radius: 14)
                .position(layout.point(x: spec.center.x, y: spec.center.y))
        }
    }
}

private enum RoomFittedToyArt {
    static let cache = NSCache<NSString, UIImage>()

    static func image(for item: ShopItem) -> UIImage? {
        let key = item.rawValue as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let region = crop(for: item),
              let reference = ArtImage.named("room_day_clean"),
              let fitted = ArtImage.uncached("room_toy_\(item.artName.dropFirst(5))"),
              let fullImage = ArtworkDifferenceMask.extract(from: fitted, comparedWith: reference,
                                                            region: region, width: 471, height: 836),
              let fullCG = fullImage.cgImage else { return nil }
        let bounds = CGRect(x: region.minX * 0.5, y: region.minY * 0.5,
                            width: region.width * 0.5, height: region.height * 0.5).integral
        guard let cropped = fullCG.cropping(to: bounds) else { return nil }
        let image = UIImage(cgImage: cropped)
        cache.setObject(image, forKey: key)
        return image
    }

    private static func crop(for item: ShopItem) -> CGRect? {
        switch item {
        case .ball: return CGRect(x: 85, y: 1200, width: 195, height: 205)
        case .teddy: return CGRect(x: 65, y: 1090, width: 270, height: 310)
        case .butterfly: return CGRect(x: 65, y: 1180, width: 310, height: 270)
        case .yarn: return CGRect(x: 95, y: 1220, width: 215, height: 220)
        case .kite: return CGRect(x: 65, y: 1200, width: 300, height: 235)
        case .drum: return CGRect(x: 70, y: 1140, width: 265, height: 265)
        case .duck: return CGRect(x: 90, y: 1130, width: 265, height: 270)
        case .train: return CGRect(x: 30, y: 1160, width: 310, height: 275)
        case .blocks: return CGRect(x: 40, y: 1170, width: 315, height: 265)
        case .rocket: return CGRect(x: 40, y: 1150, width: 270, height: 260)
        case .mouse: return CGRect(x: 50, y: 1160, width: 295, height: 275)
        case .rattle: return CGRect(x: 50, y: 1210, width: 265, height: 245)
        case .pinwheel: return CGRect(x: 70, y: 1240, width: 255, height: 250)
        default: return nil
        }
    }
}

struct RoomToyField: View {
    let shop: ShopState
    let night: Bool
    let play: (ShopItem) -> Void
    @State private var showsAllToys = false

    private var toys: [ShopItem] { shop.ownedToysInDisplayOrder }
    private var placedToys: [ShopItem] { Array(toys.suffix(4)) }
    private let places = [CGPoint(x: 205, y: 1280), CGPoint(x: 740, y: 1290),
                          CGPoint(x: 215, y: 1430), CGPoint(x: 730, y: 1430)]

    var body: some View {
        if !toys.isEmpty {
            GeometryReader { area in
                let layout = RoomSceneLayout(viewSize: area.size)
                ZStack {
                    ForEach(placedToys.indices, id: \.self) { index in
                        let item = placedToys[index]
                        let point = layout.point(x: places[index].x, y: places[index].y)
                        Button { play(item) } label: {
                            if let art = RoomFittedToyArt.image(for: item) {
                                Image(uiImage: art).resizable().scaledToFit()
                                    .frame(width: layout.size(145, maximum: 78),
                                           height: layout.size(145, maximum: 78))
                                    .colorMultiply(night ? Color(red: 0.76, green: 0.77, blue: 0.91) : .white)
                                    .frame(minWidth: 64, minHeight: 64)
                            }
                        }
                        .buttonStyle(.plain)
                        .position(x: point.x, y: min(point.y, area.size.height - 145))
                        .accessibilityLabel("Играть: \(item.title)")
                    }
                    if toys.count > placedToys.count {
                        Button { showsAllToys = true } label: {
                            Label("+\(toys.count - placedToys.count)", systemImage: "shippingbox.fill")
                                .font(AppFonts.body(16))
                                .foregroundStyle(AppColors.ink)
                                .padding(10)
                                .background(AppColors.yellow, in: Capsule())
                        }
                        .position(layout.point(x: 735, y: 735))
                        .accessibilityLabel("Остальные игрушки")
                    }
                }
            }
            .sheet(isPresented: $showsAllToys) {
                VStack(spacing: 16) {
                    Text("Мои игрушки").font(AppFonts.heading(25)).foregroundStyle(AppColors.ink)
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                            ForEach(toys, id: \.self) { item in
                                Button { play(item); showsAllToys = false } label: {
                                    VStack(spacing: 5) {
                                        ShopProductImage(artName: item.artName, size: 72)
                                        Text(item.title).font(AppFonts.body(14))
                                    }
                                    .foregroundStyle(AppColors.ink)
                                    .frame(maxWidth: .infinity, minHeight: 108)
                                    .background(.white, in: RoundedRectangle(cornerRadius: 17))
                                }
                            }
                        }
                    }
                    Button("Готово") { showsAllToys = false }
                        .font(AppFonts.heading(20))
                        .foregroundStyle(AppColors.ink)
                        .frame(minWidth: 150, minHeight: 60)
                        .background(AppColors.mint, in: Capsule())
                }
                .padding(20)
                .background(AppColors.background.ignoresSafeArea())
            }
        }
    }
}
