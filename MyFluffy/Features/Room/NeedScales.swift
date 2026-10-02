import SwiftUI

struct NeedScales: View {
    let needs: PetNeeds
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Need.allCases, id: \.self) { need in
                if CareAccess.showsScale(need, value: needs.value(need)) {
                    NeedBar(need: need, value: needs.value(need))
                }
            }
        }
        .animation(reduceMotion ? nil : AppMetrics.spring, value: needs)
        .padding(.horizontal, 20)
    }
}

struct NeedBar: View {
    let need: Need
    let value: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: need.symbolName)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppColors.ink)
                .frame(width: AppMetrics.systemButton, height: AppMetrics.systemButton)
                .accessibilityLabel(Text(need.spokenName))
            Capsule()
                .fill(AppColors.ink.opacity(0.12))
                .overlay(alignment: .leading) {
                    GeometryReader { proxy in
                        Capsule()
                            .fill(need.isInRedZone(value) ? AppColors.pink : AppColors.mint)
                            .frame(width: proxy.size.width * fraction)
                    }
                }
                .frame(height: 18)
                .accessibilityValue(Text("\(Int(value.rounded()))"))
        }
        .frame(minHeight: AppMetrics.systemButton)
    }

    private var fraction: CGFloat {
        CGFloat(min(100, max(0, value)) / 100)
    }
}

struct BlinkingNeedIcon: View {
    let need: Need
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dim = false

    var body: some View {
        Image(systemName: need.symbolName)
            .font(.system(size: 36, weight: .bold))
            .foregroundStyle(AppColors.pink)
            .opacity(reduceMotion || dim == false ? 1 : 0.35)
            .accessibilityLabel(Text(need.spokenName))
            .onAppear {
                guard reduceMotion == false else { return }
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    dim = true
                }
            }
    }
}

extension Need {
    var symbolName: String {
        switch self {
        case .satiety:
            return "fork.knife"
        case .cleanliness:
            return "drop.fill"
        case .mood:
            return "face.smiling"
        case .energy:
            return "bolt.fill"
        case .toilet:
            return "toilet"
        }
    }

    var spokenName: String {
        switch self {
        case .satiety:
            return String(localized: "Сытость")
        case .cleanliness:
            return String(localized: "Чистота")
        case .mood:
            return String(localized: "Настроение")
        case .energy:
            return String(localized: "Энергия")
        case .toilet:
            return String(localized: "Туалет")
        }
    }
}
