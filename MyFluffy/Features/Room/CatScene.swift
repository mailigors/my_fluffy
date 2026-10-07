import SpriteKit
import UIKit

enum PetSymbolImage {
    static func make(preferred: String, fallback: String, pointSize: CGFloat) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .regular)
        let name = UIImage(systemName: preferred) == nil ? fallback : preferred
        return UIImage(systemName: name, withConfiguration: config)?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
    }
}

enum CatOutfitRenderer {
    private static let fittedCache = NSCache<NSString, UIImage>()

    static func render(base: UIImage, shop: ShopState) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false
        return UIGraphicsImageRenderer(size: CGSize(width: 320, height: 320), format: format).image { _ in
            let sleeping = base === ArtImage.named("cat_plush_sleeping")
            let catFrame = CGRect(x: 35, y: 35, width: 250, height: 250)
            base.draw(in: catFrame)
            if !sleeping {
                for item in [shop.equippedNeck, shop.equippedHead, shop.equippedFace].compactMap({ $0 }) {
                    fittedOverlay(for: item)?.draw(in: catFrame)
                }
            }
            if let happy = ArtImage.named("cat_plush_happy"), base === happy,
               shop.equippedNeck != nil, let context = UIGraphicsGetCurrentContext() {
                // In this expression the paws lift in front of the chest wearables.
                context.saveGState()
                let pawRegions = [CGRect(x: 390, y: 670, width: 285, height: 285),
                                  CGRect(x: 685, y: 670, width: 285, height: 285)]
                for region in pawRegions {
                    let path = CGRect(x: catFrame.minX + region.minX / 1224 * catFrame.width,
                                      y: catFrame.minY + region.minY / 1285 * catFrame.height,
                                      width: region.width / 1224 * catFrame.width,
                                      height: region.height / 1285 * catFrame.height)
                    context.addEllipse(in: path)
                }
                context.clip()
                base.draw(in: catFrame)
                context.restoreGState()
            }
        }
    }

    private static func fittedOverlay(for item: ShopItem) -> UIImage? {
        let key = item.rawValue as NSString
        if let cached = fittedCache.object(forKey: key) { return cached }
        guard let reference = ArtImage.named("cat_plush_awake"),
              let fitted = ArtImage.uncached("cat_fitted_\(item.artName.dropFirst(5))"),
              let region = garmentRegion(for: item),
              let overlay = ArtworkDifferenceMask.extract(from: fitted, comparedWith: reference,
                                                          region: region, width: 612, height: 643) else { return nil }
        fittedCache.setObject(overlay, forKey: key)
        return overlay
    }

    // Coordinates use the 1224 × 1285 character art. Restricting each region keeps
    // small changes to the generated character's fur out of the wearable layer.
    private static func garmentRegion(for item: ShopItem) -> CGRect? {
        switch item {
        case .bow: return CGRect(x: 760, y: 65, width: 335, height: 320)
        case .partyHat: return CGRect(x: 510, y: 0, width: 465, height: 330)
        case .crown: return CGRect(x: 560, y: 15, width: 405, height: 275)
        case .beret: return CGRect(x: 280, y: 35, width: 885, height: 540)
        case .sunHat: return CGRect(x: 105, y: 55, width: 1100, height: 880)
        case .tiara: return CGRect(x: 355, y: 60, width: 670, height: 335)
        case .earmuffs: return CGRect(x: 140, y: 75, width: 1080, height: 640)
        case .visor: return CGRect(x: 285, y: 120, width: 800, height: 400)
        case .glasses, .starGlasses: return CGRect(x: 280, y: 310, width: 790, height: 325)
        case .collar, .bowTie: return CGRect(x: 440, y: 710, width: 420, height: 240)
        case .scarf: return CGRect(x: 400, y: 710, width: 510, height: 375)
        case .pendant: return CGRect(x: 445, y: 710, width: 405, height: 270)
        case .bandana: return CGRect(x: 445, y: 710, width: 590, height: 310)
        default: return nil
        }
    }

}

enum ArtworkDifferenceMask {
    static func extract(from fitted: UIImage, comparedWith reference: UIImage, region: CGRect,
                        width: Int, height: Int) -> UIImage? {
        guard let fittedPixels = pixels(of: fitted, width: width, height: height),
              let referencePixels = pixels(of: reference, width: width, height: height),
              let source = reference.cgImage else { return nil }
        var output = [UInt8](repeating: 0, count: width * height * 4)
        var opacity = [UInt8](repeating: 0, count: width * height)
        let scaleX = CGFloat(width) / CGFloat(source.width)
        let scaleY = CGFloat(height) / CGFloat(source.height)
        let left = max(0, Int(region.minX * scaleX))
        let top = max(0, Int(region.minY * scaleY))
        let right = min(width, Int(region.maxX * scaleX))
        let bottom = min(height, Int(region.maxY * scaleY))
        for y in top..<bottom {
            for x in left..<right {
                let index = (y * width + x) * 4
                let delta = (0..<3).map { abs(Int(fittedPixels[index + $0]) - Int(referencePixels[index + $0])) }.max() ?? 0
                let strength = max(0, min(255, (delta - 35) * 7))
                opacity[y * width + x] = UInt8(strength)
            }
        }
        // Discard isolated changes introduced while generating the scene art.
        var visited = [Bool](repeating: false, count: width * height)
        for y in top..<bottom {
            for x in left..<right {
                let start = y * width + x
                guard opacity[start] > 0, !visited[start] else { continue }
                var group = [start]
                visited[start] = true
                var cursor = 0
                while cursor < group.count {
                    let current = group[cursor]
                    cursor += 1
                    let column = current % width
                    let neighbors = [current - width, current + width,
                                     column > left ? current - 1 : current,
                                     column + 1 < right ? current + 1 : current]
                    for neighbor in neighbors where neighbor >= 0 && neighbor < opacity.count {
                        if opacity[neighbor] > 0 && !visited[neighbor] {
                            visited[neighbor] = true
                            group.append(neighbor)
                        }
                    }
                }
                if group.count < 24 {
                    for pixel in group { opacity[pixel] = 0 }
                }
            }
        }
        for y in top..<bottom {
            for x in left..<right {
                let pixel = y * width + x
                let strength = Int(opacity[pixel])
                guard strength > 0 else { continue }
                let index = pixel * 4
                for channel in 0..<4 {
                    output[index + channel] = UInt8(Int(fittedPixels[index + channel]) * strength / 255)
                }
            }
        }
        let data = Data(output) as CFData
        guard let provider = CGDataProvider(data: data),
              let image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                                  bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue),
                                  provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) else { return nil }
        return UIImage(cgImage: image)
    }

    private static func pixels(of image: UIImage, width: Int, height: Int) -> [UInt8]? {
        guard let cgImage = image.cgImage else { return nil }
        var output = [UInt8](repeating: 0, count: width * height * 4)
        let ok = output.withUnsafeMutableBytes { bytes -> Bool in
            guard let context = CGContext(data: bytes.baseAddress, width: width, height: height,
                                          bitsPerComponent: 8, bytesPerRow: width * 4,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue) else { return false }
            context.interpolationQuality = .high
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return ok ? output : nil
    }
}

final class CatScene: SKScene {
    private let cat = SKSpriteNode()
    private let badge = SKSpriteNode()
    private var outfit = ShopState()
    private var currentBaseImage: UIImage?
    private var shownPrefix: String?
    private var shownArtName: String?
    private var outgoingCat: SKSpriteNode?
    private var reduceMotion = false

    override init() {
        super.init(size: CGSize(width: 320, height: 320))
        scaleMode = .resizeFill
        backgroundColor = .clear
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        cat.size = CGSize(width: 320, height: 320)
        badge.position = CGPoint(x: 78, y: 78)
        badge.size = CGSize(width: 56, height: 56)
        addChild(cat)
        addChild(badge)
    }

    required init?(coder decoder: NSCoder) {
        return nil
    }

    func setOutfit(_ shop: ShopState) {
        guard outfit != shop else { return }
        outfit = shop
        guard let currentBaseImage else { return }
        cat.texture = SKTexture(image: CatOutfitRenderer.render(base: currentBaseImage, shop: outfit))
        cat.removeAction(forKey: "blinking")
        startBlinkAnimation()
    }

    func setReduceMotion(_ enabled: Bool) {
        guard reduceMotion != enabled else { return }
        reduceMotion = enabled
        guard let shownPrefix else { return }
        cat.removeAllActions()
        cat.setScale(1)
        if shownArtName == "cat_plush_awake", let image = ArtImage.named("cat_plush_awake") {
            currentBaseImage = image
            cat.texture = SKTexture(image: CatOutfitRenderer.render(base: image, shop: outfit))
        }
        startIdleAnimation(sleeping: shownPrefix == "cat_sleeping")
    }

    func setLook(_ look: PetLook) {
        let prefix = look.artPrefix
        if prefix == shownPrefix {
            return
        }
        shownPrefix = prefix
        cat.removeAllActions()
        cat.setScale(1)
        let artName = look.plushArtName
        if let image = ArtImage.named(artName) {
            let previous = shownArtName == artName ? nil : cat.texture
            shownArtName = artName
            currentBaseImage = image
            cat.texture = SKTexture(image: CatOutfitRenderer.render(base: image, shop: outfit))
            cat.colorBlendFactor = 0
            badge.isHidden = true
            crossfade(from: previous)
            if look == .happy && !reduceMotion {
                let bounce = SKAction.sequence([
                    .scale(to: 1.035, duration: 0.22),
                    .scale(to: 1, duration: 0.34),
                    .run { [weak self] in self?.startIdleAnimation(sleeping: false) }
                ])
                bounce.timingMode = .easeInEaseOut
                cat.run(bounce)
            } else {
                startIdleAnimation(sleeping: look == .sleeping)
            }
            return
        }
        shownArtName = nil
        let frames = ArtImage.frames(prefix: prefix)
        if frames.isEmpty {
            outgoingCat?.removeFromParent()
            outgoingCat = nil
            showSymbol(for: look)
            startIdleAnimation(sleeping: look == .sleeping)
            return
        }
        guard let image = look == .happy ? frames.last : frames.first else { return }
        let previous = cat.texture
        currentBaseImage = image
        cat.texture = SKTexture(image: CatOutfitRenderer.render(base: image, shop: outfit))
        cat.colorBlendFactor = 0
        badge.isHidden = true
        crossfade(from: previous)
        if look == .happy {
            let bounce = SKAction.sequence([
                .scale(to: 1.03, duration: 0.25),
                .scale(to: 1, duration: 0.35)
            ])
            bounce.timingMode = .easeInEaseOut
            cat.run(.sequence([bounce, .run { [weak self] in self?.startIdleAnimation(sleeping: false) }]))
            return
        }
        startIdleAnimation(sleeping: look == .sleeping)
    }

    private func crossfade(from previous: SKTexture?) {
        outgoingCat?.removeFromParent()
        outgoingCat = nil
        guard let previous else { return }
        let outgoing = SKSpriteNode(texture: previous, size: cat.size)
        outgoing.zPosition = cat.zPosition + 1
        outgoing.xScale = cat.xScale
        outgoing.yScale = cat.yScale
        addChild(outgoing)
        outgoingCat = outgoing
        let fade = SKAction.fadeOut(withDuration: 0.25)
        fade.timingMode = .easeInEaseOut
        outgoing.run(.sequence([fade, .removeFromParent()]))
    }

    private func startIdleAnimation(sleeping: Bool) {
        guard !reduceMotion else { return }
        let duration = sleeping ? 1.8 : 1.4
        let inhale = SKAction.scaleY(to: 1.015, duration: duration)
        let exhale = SKAction.scaleY(to: 1, duration: duration)
        inhale.timingMode = .easeInEaseOut
        exhale.timingMode = .easeInEaseOut
        cat.run(.repeatForever(.sequence([inhale, exhale])), withKey: "breathing")
        startBlinkAnimation()
    }

    private func startBlinkAnimation() {
        guard !reduceMotion, shownArtName == "cat_plush_awake",
              let openImage = ArtImage.named("cat_plush_awake"),
              let closedImage = ArtImage.named("cat_plush_closed") else { return }
        let blink = SKAction.sequence([
            .wait(forDuration: 3.8, withRange: 2.0),
            .setTexture(SKTexture(image: CatOutfitRenderer.render(base: closedImage, shop: outfit))),
            .wait(forDuration: 0.13),
            .setTexture(SKTexture(image: CatOutfitRenderer.render(base: openImage, shop: outfit)))
        ])
        cat.run(.repeatForever(blink), withKey: "blinking")
    }

    private func showSymbol(for look: PetLook) {
        let symbol = look.catSymbol
        if let image = PetSymbolImage.make(preferred: symbol.preferred, fallback: symbol.fallback, pointSize: 180) {
            currentBaseImage = image
            cat.texture = SKTexture(image: CatOutfitRenderer.render(base: image, shop: outfit))
        }
        cat.color = look.tint
        cat.colorBlendFactor = 1
        if let badgeName = look.badgeName,
           let image = PetSymbolImage.make(preferred: badgeName, fallback: "circle.fill", pointSize: 44) {
            badge.texture = SKTexture(image: image)
            badge.color = AppUIColors.ink
            badge.colorBlendFactor = 1
            badge.isHidden = false
        } else {
            badge.isHidden = true
        }
    }

}

private extension PetLook {
    var plushArtName: String {
        switch self {
        case .idle: return "cat_plush_awake"
        case .happy: return "cat_plush_happy"
        case .hungry: return "cat_plush_hungry"
        case .dirty: return "cat_plush_dirty"
        case .bored: return "cat_plush_bored"
        case .sleepy: return "cat_plush_sleepy"
        case .needsToilet: return "cat_plush_toilet"
        case .sleeping: return "cat_plush_sleeping"
        }
    }

    var artPrefix: String {
        switch self {
        case .idle:
            return "cat_idle"
        case .happy:
            return "cat_happy"
        case .hungry:
            return "cat_hungry"
        case .dirty:
            return "cat_dirty"
        case .bored:
            return "cat_bored"
        case .sleepy:
            return "cat_sleepy"
        case .needsToilet:
            return "cat_toilet"
        case .sleeping:
            return "cat_sleeping"
        }
    }

    var catSymbol: (preferred: String, fallback: String) {
        switch self {
        case .sleeping:
            return ("moon.zzz.fill", "moon.fill")
        default:
            return ("cat.fill", "pawprint.fill")
        }
    }

    var badgeName: String? {
        switch self {
        case .hungry:
            return "fork.knife"
        case .dirty:
            return "drop.fill"
        case .bored:
            return "circle.fill"
        case .sleepy:
            return "bolt.fill"
        case .needsToilet:
            return "toilet"
        case .happy:
            return "heart.fill"
        case .idle, .sleeping:
            return nil
        }
    }

    var tint: UIColor {
        switch self {
        case .happy:
            return AppUIColors.pink
        case .hungry, .needsToilet:
            return AppUIColors.yellow
        case .dirty, .sleepy, .sleeping:
            return AppUIColors.sky
        case .idle, .bored:
            return AppUIColors.ink
        }
    }
}
