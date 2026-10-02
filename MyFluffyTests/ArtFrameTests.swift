import UIKit
import XCTest
@testable import MyFluffy

final class ArtFrameTests: XCTestCase {
    func testIdleFramesLoseTheLeftFragmentAndStayPut() {
        let frames = ArtImage.frames(prefix: "cat_idle")
        XCTAssertEqual(frames.count, 8)
        guard frames.count == 8 else { return }
        for frame in frames {
            XCTAssertTrue(edgeIsClear(frame, x: 0))
            XCTAssertTrue(edgeIsClear(frame, x: (frame.cgImage?.width ?? 1) - 1))
        }
        let feet = frames.compactMap { footLine(of: $0) }
        XCTAssertEqual(feet.count, 8)
        guard let first = feet.first else { return }
        for line in feet {
            XCTAssertEqual(line, first, accuracy: 0.02)
        }
    }

    func testHappyFramesDoNotRoll() {
        let frames = ArtImage.frames(prefix: "cat_happy")
        XCTAssertGreaterThanOrEqual(frames.count, 2)
        XCTAssertLessThan(frames.count, 8)
        for frame in frames {
            XCTAssertTrue(headStaysUp(frame))
            XCTAssertTrue(edgeIsClear(frame, x: (frame.cgImage?.width ?? 1) - 1))
        }
    }

    private func edgeIsClear(_ image: UIImage, x: Int) -> Bool {
        guard let pixels = Pixels(image), x >= 0, x < pixels.width else { return false }
        let neighbor = x == 0 ? 1 : x - 1
        for y in 0..<pixels.height {
            if pixels.alpha(x: x, y: y) >= 40 || pixels.alpha(x: neighbor, y: y) >= 40 {
                return false
            }
        }
        return true
    }

    private func footLine(of image: UIImage) -> CGFloat? {
        guard let pixels = Pixels(image), pixels.height > 0 else { return nil }
        var lowest = 0
        for y in 0..<pixels.height {
            var x = 0
            while x < pixels.width {
                if pixels.alpha(x: x, y: y) >= 40 {
                    lowest = y
                }
                x += 4
            }
        }
        return CGFloat(lowest) / CGFloat(pixels.height)
    }

    private func headStaysUp(_ image: UIImage) -> Bool {
        guard let pixels = Pixels(image), pixels.height > 0 else { return false }
        let limit = pixels.height / 6
        for y in 0..<limit {
            var x = 0
            while x < pixels.width {
                if pixels.alpha(x: x, y: y) >= 40 {
                    return true
                }
                x += 4
            }
        }
        return false
    }
}

private struct Pixels {
    let width: Int
    let height: Int
    private let data: [UInt8]

    init?(_ image: UIImage) {
        guard let source = image.cgImage else { return nil }
        width = source.width
        height = source.height
        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        let info = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(
            data: &buffer,
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
        data = buffer
    }

    func alpha(x: Int, y: Int) -> UInt8 {
        data[(y * width + x) * 4 + 3]
    }
}
