import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var model: RoomViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var name = ""
    @State private var selectedMode: AgeMode = .toddler

    var body: some View {
        ZStack {
            LaunchSceneBackdrop()
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        Text(String(localized: "Давай знакомиться!"))
                            .font(AppFonts.heading(27))
                            .foregroundStyle(AppColors.ink)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                            .background(AppColors.background.opacity(0.96))
                            .clipShape(Capsule())
                            .overlay { Capsule().stroke(AppColors.ink, lineWidth: 3) }
                            .padding(.top, 20)

                        Spacer(minLength: 180)

                        welcomeCard
                            .frame(maxWidth: 440)
                            .padding(.bottom, 20)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geometry.size.height)
                    .padding(.horizontal, 18)
                }
            }
        }
        .onAppear { name = model.petName }
    }

    private var welcomeCard: some View {
        VStack(spacing: 14) {
            Text(String(localized: "Как зовут котёнка?"))
                .font(AppFonts.heading(23))
                .foregroundStyle(AppColors.ink)

            TextField(String(localized: "Имя котёнка"), text: $name)
                .font(AppFonts.heading(24))
                .foregroundStyle(AppColors.ink)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .padding(.horizontal, 14)
                .frame(minHeight: 64)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .overlay { RoundedRectangle(cornerRadius: 18).stroke(AppColors.ink, lineWidth: 3) }
                .accessibilityLabel(Text(String(localized: "Имя котёнка")))

            Text(String(localized: "Кто будет играть?"))
                .font(AppFonts.body(17))
                .foregroundStyle(AppColors.ink)

            HStack(spacing: 12) {
                ageOption(.toddler, title: "Малыш", years: "3–5 лет", symbol: "teddybear.fill")
                ageOption(.older, title: "Большой", years: "6–7 лет", symbol: "backpack.fill")
            }

            Button {
                model.finishOnboarding(name: name, mode: selectedMode)
            } label: {
                Label(String(localized: "Играть"), systemImage: "pawprint.fill")
                    .font(AppFonts.heading(25))
                    .foregroundStyle(AppColors.ink)
                    .frame(maxWidth: .infinity, minHeight: 72)
                    .background(AppColors.yellow)
                    .clipShape(Capsule())
                    .overlay { Capsule().stroke(AppColors.ink, lineWidth: 3) }
            }
            .buttonStyle(FluffyPressStyle(reduceMotion: reduceMotion))
        }
        .padding(18)
        .background(AppColors.background.opacity(0.97))
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay { RoundedRectangle(cornerRadius: 28).stroke(AppColors.ink, lineWidth: 3) }
    }

    private func ageOption(_ mode: AgeMode, title: String, years: String, symbol: String) -> some View {
        Button { selectedMode = mode } label: {
            VStack(spacing: 3) {
                Image(systemName: symbol)
                    .font(.system(size: 27, weight: .semibold))
                Text(String(localized: String.LocalizationValue(title)))
                    .font(AppFonts.heading(19))
                Text(years)
                    .font(AppFonts.body(15))
            }
            .foregroundStyle(AppColors.ink)
            .frame(maxWidth: .infinity, minHeight: 86)
            .background(selectedMode == mode ? AppColors.mint : .white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay { RoundedRectangle(cornerRadius: 20).stroke(AppColors.ink, lineWidth: selectedMode == mode ? 3 : 2) }
        }
        .buttonStyle(FluffyPressStyle(reduceMotion: reduceMotion))
        .accessibilityLabel(Text("\(title), \(years)"))
        .accessibilityAddTraits(selectedMode == mode ? [.isSelected] : [])
    }
}
