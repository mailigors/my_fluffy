import SwiftUI
import UIKit

struct RGB {
    var red: Double
    var green: Double
    var blue: Double
}

enum AppPalette {
    static let background = RGB(red: 255 / 255, green: 246 / 255, blue: 234 / 255)
    static let ink = RGB(red: 91 / 255, green: 58 / 255, blue: 41 / 255)
    static let pink = RGB(red: 255 / 255, green: 111 / 255, blue: 165 / 255)
    static let mint = RGB(red: 127 / 255, green: 216 / 255, blue: 190 / 255)
    static let yellow = RGB(red: 255 / 255, green: 211 / 255, blue: 77 / 255)
    static let sky = RGB(red: 127 / 255, green: 181 / 255, blue: 240 / 255)
    static let night = RGB(red: 44 / 255, green: 62 / 255, blue: 92 / 255)
}

enum AppColors {
    static let background = Color(AppPalette.background)
    static let ink = Color(AppPalette.ink)
    static let pink = Color(AppPalette.pink)
    static let mint = Color(AppPalette.mint)
    static let yellow = Color(AppPalette.yellow)
    static let sky = Color(AppPalette.sky)
    static let night = Color(AppPalette.night)
}

enum AppUIColors {
    static let ink = UIColor(AppPalette.ink)
    static let pink = UIColor(AppPalette.pink)
    static let yellow = UIColor(AppPalette.yellow)
    static let sky = UIColor(AppPalette.sky)
}

private extension Color {
    init(_ rgb: RGB) {
        self.init(red: rgb.red, green: rgb.green, blue: rgb.blue)
    }
}

private extension UIColor {
    convenience init(_ rgb: RGB) {
        self.init(red: rgb.red, green: rgb.green, blue: rgb.blue, alpha: 1)
    }
}
