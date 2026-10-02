import SwiftUI
import UIKit

enum AppFonts {
    static func heading(_ size: CGFloat = 22) -> Font {
        // В текущем файле Fredoka нет кириллицы, поэтому заголовок — Nunito Bold.
        custom("Nunito-Bold", size: size, weight: .bold)
    }

    static func body(_ size: CGFloat = 17) -> Font {
        custom("Nunito-Regular", size: size, weight: .regular)
    }

    static var action: Font {
        custom("Nunito-Bold", size: 22, weight: .bold)
    }

    private static func custom(_ name: String, size: CGFloat, weight: Font.Weight) -> Font {
        if UIFont(name: name, size: size) != nil {
            return Font.custom(name, size: size)
        }
        return Font.system(size: size, weight: weight, design: .rounded)
    }
}
