import SwiftUI

struct LaunchSceneBackdrop: View {
    var body: some View {
        GeometryReader { geometry in
            Image("LaunchScene")
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

struct StartView: View {
    @EnvironmentObject private var model: RoomViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LaunchSceneBackdrop()
            VStack {
                VStack(spacing: 2) {
                    Text(String(localized: "Мой питомец"))
                        .font(AppFonts.heading(26))
                    Text(model.petName)
                        .font(AppFonts.heading(38))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .foregroundStyle(AppColors.ink)
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background(AppColors.background.opacity(0.94))
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(AppColors.ink, lineWidth: 3)
                }
                .padding(.top, 20)

                Spacer(minLength: 0)

                Button(action: { model.startGame() }) {
                    HStack(spacing: 14) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 30, weight: .bold))
                        Text(String(localized: "Играть"))
                            .font(AppFonts.action)
                    }
                    .foregroundStyle(AppColors.ink)
                    .frame(minWidth: 220, minHeight: 80)
                    .background(AppColors.yellow)
                    .clipShape(Capsule())
                    .overlay { Capsule().stroke(AppColors.ink, lineWidth: 4) }
                }
                .buttonStyle(FluffyPressStyle(reduceMotion: reduceMotion))
                .accessibilityLabel(Text(String(localized: "Играть")))
                .padding(.bottom, 28)
            }
            .padding(.horizontal, 20)
        }
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            LaunchSceneBackdrop()
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(AppColors.pink)
                    Text(String(localized: "Мурзик просыпается…"))
                        .font(AppFonts.heading(20))
                        .foregroundStyle(AppColors.ink)
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 16)
                .background(AppColors.background.opacity(0.94))
                .clipShape(Capsule())
                .accessibilityLabel(Text(String(localized: "Загрузка")))
                .padding(.bottom, 40)
            }
        }
    }
}
