import SwiftUI
import UIKit

struct OnboardingView: View {
    @EnvironmentObject private var model: RoomViewModel
    @State private var name = ""

    var body: some View {
        VStack(spacing: 28) {
            TextField(String(localized: "Имя котёнка"), text: $name)
                .font(AppFonts.heading())
                .foregroundStyle(AppColors.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .frame(minHeight: AppMetrics.childButton)
                .background(Color.white.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.ink, lineWidth: 4)
                )
            HStack(spacing: 24) {
                FluffyIconButton(
                    symbol: "figure.and.child",
                    fallback: "face.smiling",
                    label: String(localized: "Малыш")
                ) {
                    model.finishOnboarding(name: name, mode: .toddler)
                }
                FluffyIconButton(
                    symbol: "backpack.fill",
                    fallback: "bag.fill",
                    label: String(localized: "Большой")
                ) {
                    model.finishOnboarding(name: name, mode: .older)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background.ignoresSafeArea())
        .onAppear {
            name = model.petName
        }
    }
}
