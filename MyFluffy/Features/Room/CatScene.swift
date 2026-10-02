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

final class CatScene: SKScene {
    private let cat = SKSpriteNode()
    private let badge = SKSpriteNode()
    private var shownPrefix: String?
    private var outgoingCat: SKSpriteNode?

    override init() {
        super.init(size: CGSize(width: 320, height: 320))
        scaleMode = .resizeFill
        backgroundColor = .clear
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        cat.size = CGSize(width: 260, height: 260)
        badge.position = CGPoint(x: 78, y: 78)
        badge.size = CGSize(width: 56, height: 56)
        addChild(cat)
        addChild(badge)
    }

    required init?(coder decoder: NSCoder) {
        return nil
    }

    func setLook(_ look: PetLook) {
        let prefix = look.artPrefix
        if prefix == shownPrefix {
            return
        }
        shownPrefix = prefix
        cat.removeAllActions()
        let frames = ArtImage.frames(prefix: prefix)
        if frames.isEmpty {
            outgoingCat?.removeFromParent()
            outgoingCat = nil
            showSymbol(for: look)
            startBreathing(for: look)
            return
        }
        guard let image = look == .happy ? frames.last : frames.first else { return }
        let previous = cat.texture
        cat.texture = SKTexture(image: image)
        cat.colorBlendFactor = 0
        badge.isHidden = true
        crossfade(from: previous)
        if look == .happy {
            let bounce = SKAction.sequence([
                .scale(to: 1.03, duration: 0.25),
                .scale(to: 1, duration: 0.35)
            ])
            bounce.timingMode = .easeInEaseOut
            cat.run(.sequence([bounce, .run { [weak self] in self?.startBreathing(for: look) }]))
            return
        }
        startBreathing(for: look)
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

    private func startBreathing(for look: PetLook) {
        let duration = look == .sleeping ? 1.8 : 1.4
        let inhale = SKAction.scaleY(to: 1.015, duration: duration)
        let exhale = SKAction.scaleY(to: 1, duration: duration)
        inhale.timingMode = .easeInEaseOut
        exhale.timingMode = .easeInEaseOut
        cat.run(.repeatForever(.sequence([inhale, exhale])))
    }

    private func showSymbol(for look: PetLook) {
        let symbol = look.catSymbol
        if let image = PetSymbolImage.make(preferred: symbol.preferred, fallback: symbol.fallback, pointSize: 180) {
            cat.texture = SKTexture(image: image)
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
