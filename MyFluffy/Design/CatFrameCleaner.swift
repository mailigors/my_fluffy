import UIKit

enum CatFrameCleaner {
    /// Убирает обрезок с краёв, выкидывает кувырок и ставит лапы на одну линию, не срезая хвост.
    static func prepare(_ images: [UIImage], dropRolls: Bool) -> [UIImage] {
        let stripped = images.compactMap { image -> Bitmap? in
            guard var bitmap = Bitmap(image) else { return nil }
            bitmap.eraseBorderFragments()
            bitmap.sourceScale = image.scale
            return bitmap
        }
        guard stripped.isEmpty == false else { return images }
        let chosen = dropRolls ? withoutRolls(stripped) : stripped
        let fitted = fitOnBaseline(chosen.isEmpty ? stripped : chosen)
        return fitted.compactMap { $0.image(scale: $0.sourceScale) }
    }

    private static func withoutRolls(_ bitmaps: [Bitmap]) -> [Bitmap] {
        bitmaps.filter { $0.isLyingDown == false }
    }

    private static func fitOnBaseline(_ bitmaps: [Bitmap]) -> [Bitmap] {
        guard let width = bitmaps.first?.width, let height = bitmaps.first?.height else {
            return bitmaps
        }
        let frames = bitmaps.map { FrameMeasure(bitmap: $0) }
        guard frames.allSatisfy({ $0.box != nil && $0.bodyX != nil }) else { return bitmaps }
        let margin = max(8, width / 24)
        var scale = 1.0
        if let maxW = frames.compactMap({ $0.box.map { $0.maxX - $0.minX + 1 } }).max(),
           let maxH = frames.compactMap({ $0.box.map { $0.maxY - $0.minY + 1 } }).max(),
           maxW > 0, maxH > 0 {
            scale = min(
                1,
                Double(width - margin * 2) / Double(maxW),
                Double(height - margin * 2) / Double(maxH)
            )
        }
        var placed: [Bitmap] = []
        for _ in 0..<5 {
            if let targets = targets(frames: frames, scale: scale, width: width, height: height, margin: margin) {
                placed = zip(bitmaps, frames).map { bitmap, frame in
                    guard let box = frame.box, let bodyX = frame.bodyX else { return bitmap }
                    let dx = targets.x - Int((Double(bodyX) * scale).rounded())
                    let dy = targets.y - Int((Double(box.maxY) * scale).rounded())
                    var copy = bitmap
                    copy.place(scale: scale, dx: dx, dy: dy)
                    return copy
                }
                return placed
            }
            scale *= 0.9
        }
        return bitmaps
    }

    private static func targets(
        frames: [FrameMeasure],
        scale: Double,
        width: Int,
        height: Int,
        margin: Int
    ) -> (x: Int, y: Int)? {
        var x0 = 0
        var x1 = width - 1
        var y0 = 0
        var y1 = height - 1 - margin
        for frame in frames {
            guard let box = frame.box, let bodyX = frame.bodyX else { return nil }
            let body = Double(bodyX) * scale
            let feet = Double(box.maxY) * scale
            let minX = Double(box.minX) * scale
            let maxX = Double(box.maxX) * scale
            let minY = Double(box.minY) * scale
            let left = margin + Int((body - minX).rounded())
            let right = width - 1 - margin - Int((maxX - body).rounded())
            x0 = max(x0, left)
            x1 = min(x1, right)
            let top = margin + Int((feet - minY).rounded())
            y0 = max(y0, top)
            y1 = min(y1, height - 1 - margin)
        }
        guard x0 <= x1, y0 <= y1 else { return nil }
        return ((x0 + x1) / 2, y1)
    }
}

private struct FrameMeasure {
    var box: PixelBox?
    var bodyX: Int?

    init(bitmap: Bitmap) {
        box = bitmap.opaqueBounds()
        if let box {
            bodyX = bitmap.bodyAnchorX(in: box)
        }
    }
}

private struct PixelBox {
    var minX: Int
    var minY: Int
    var maxX: Int
    var maxY: Int

    var midX: Int { (minX + maxX) / 2 }
}

private struct Bitmap {
    var pixels: [UInt8]
    let width: Int
    let height: Int
    var sourceScale: CGFloat = 1

    init?(_ image: UIImage) {
        guard let source = image.cgImage else { return nil }
        width = source.width
        height = source.height
        pixels = [UInt8](repeating: 0, count: width * height * 4)
        let info = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: info
        ) else { return nil }
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        context.draw(source, in: CGRect(x: 0, y: 0, width: width, height: height))
    }

    func image(scale: CGFloat) -> UIImage? {
        var pixels = pixels
        let info = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: info
        ), let rendered = context.makeImage() else { return nil }
        return UIImage(cgImage: rendered, scale: scale, orientation: .up)
    }

    mutating func eraseBorderFragments() {
        let count = width * height
        var owner = [Int](repeating: -1, count: count)
        var areas: [Int] = []
        var touchesBorder: [Bool] = []
        var stack: [Int] = []
        stack.reserveCapacity(1024)

        for start in 0..<count {
            if owner[start] != -1 || pixels[start * 4 + 3] < 40 {
                continue
            }
            let id = areas.count
            var area = 0
            var touches = false
            owner[start] = id
            stack.append(start)
            while let current = stack.popLast() {
                let x = current % width
                let y = current / width
                area += 1
                if x == 0 || y == 0 || x == width - 1 || y == height - 1 {
                    touches = true
                }
                let neighbors = [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]
                for (nx, ny) in neighbors {
                    guard nx >= 0, ny >= 0, nx < width, ny < height else { continue }
                    let next = ny * width + nx
                    if owner[next] == -1, pixels[next * 4 + 3] >= 40 {
                        owner[next] = id
                        stack.append(next)
                    }
                }
            }
            areas.append(area)
            touchesBorder.append(touches)
        }

        guard let largest = areas.max(), largest > 0 else { return }
        for index in 0..<count {
            let id = owner[index]
            guard id >= 0, touchesBorder[id], areas[id] * 5 < largest else { continue }
            pixels[index * 4] = 0
            pixels[index * 4 + 1] = 0
            pixels[index * 4 + 2] = 0
            pixels[index * 4 + 3] = 0
        }
    }

    func opaqueBounds() -> PixelBox? {
        var box: PixelBox?
        for y in 0..<height {
            for x in 0..<width {
                guard pixels[(y * width + x) * 4 + 3] >= 40 else { continue }
                if var current = box {
                    current.minX = min(current.minX, x)
                    current.minY = min(current.minY, y)
                    current.maxX = max(current.maxX, x)
                    current.maxY = max(current.maxY, y)
                    box = current
                } else {
                    box = PixelBox(minX: x, minY: y, maxX: x, maxY: y)
                }
            }
        }
        return box
    }

    var isLyingDown: Bool {
        guard let box = opaqueBounds() else { return false }
        let boxWidth = box.maxX - box.minX + 1
        let boxHeight = box.maxY - box.minY + 1
        if box.minY > height / 8 {
            return true
        }
        return boxHeight * 100 < boxWidth * 105
    }

    func bodyAnchorX(in box: PixelBox) -> Int {
        let y0 = box.minY + (box.maxY - box.minY) * 55 / 100
        let x1 = box.minX + max(1, (box.maxX - box.minX) * 65 / 100)
        var sum = 0
        var count = 0
        var y = y0
        while y <= box.maxY {
            var x = box.minX
            while x <= x1 {
                if alpha(x: x, y: y) >= 40 {
                    sum += x
                    count += 1
                }
                x += 2
            }
            y += 2
        }
        guard count > 0 else { return box.midX }
        return sum / count
    }

    mutating func place(scale: Double, dx: Int, dy: Int) {
        guard scale > 0, let source = image(scale: 1) else { return }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: width, height: height),
            format: format
        )
        let rendered = renderer.image { _ in
            source.draw(
                in: CGRect(
                    x: CGFloat(dx),
                    y: CGFloat(dy),
                    width: CGFloat(width) * CGFloat(scale),
                    height: CGFloat(height) * CGFloat(scale)
                )
            )
        }
        guard let replacement = Bitmap(rendered) else { return }
        pixels = replacement.pixels
    }

    private func alpha(x: Int, y: Int) -> UInt8 {
        guard x >= 0, y >= 0, x < width, y < height else { return 0 }
        return pixels[(y * width + x) * 4 + 3]
    }
}
