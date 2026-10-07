import UIKit

enum ArtImage {
    private static var cache: [String: UIImage] = [:]
    private static var frameCache: [String: [UIImage]] = [:]

    static func named(_ name: String) -> UIImage? {
        if let cached = cache[name] {
            return cached
        }
        guard let image = load(name) else { return nil }
        cache[name] = image
        return image
    }

    // Fitted art is converted to a much smaller transparent layer on first use.
    // Keeping the original full-scene images in the shared cache wastes memory.
    static func uncached(_ name: String) -> UIImage? { load(name) }

    static func frames(prefix: String) -> [UIImage] {
        if let cached = frameCache[prefix] {
            return cached
        }
        // Эти три кадра сохраняют сидячую позу. Промежуточные кадры
        // содержат наклон, кувырок и стойку, из-за чего цикл дёргается.
        let indices = prefix == "cat_happy" ? [6, 7, 8] : Array(1...8)
        let loaded = indices.compactMap { index in
            load(String(format: "%@_%02d", prefix, index))
        }
        let prepared = CatFrameCleaner.prepare(loaded, dropRolls: false)
        frameCache[prefix] = prepared
        return prepared
    }

    private static func load(_ name: String) -> UIImage? {
        let scale = UIScreen.main.scale
        let ranked: [(String, CGFloat)]
        if scale >= 3 {
            ranked = [("\(name)@3x", 3), ("\(name)@2x", 2), (name, 1)]
        } else if scale >= 2 {
            ranked = [("\(name)@2x", 2), ("\(name)@3x", 3), (name, 1)]
        } else {
            ranked = [(name, 1), ("\(name)@2x", 2), ("\(name)@3x", 3)]
        }
        for (resource, resourceScale) in ranked {
            guard let url = BundleFile.url(name: resource, extension: "png", subdirectory: "Resources/Art") else {
                continue
            }
            guard let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data, scale: resourceScale) else {
                continue
            }
            return image
        }
        return nil
    }
}
