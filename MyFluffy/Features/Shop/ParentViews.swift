import SwiftUI

struct ParentGateView: View {
    @EnvironmentObject private var model: RoomViewModel
    @State private var lockOpened = false
    @State private var wrongAnswer = false

    var body: some View {
        ActivityScene(art: "parent_scene", title: "Для родителей") {
            VStack(spacing: 25) {
                Spacer()
                if lockOpened {
                    Text("Сколько будет 7 + 5?")
                        .font(AppFonts.heading(28))
                        .foregroundStyle(AppColors.ink)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15) {
                        ForEach([10, 12, 14, 15], id: \.self) { answer in
                            Button {
                                model.unlockParentSettings(answer: answer)
                                if answer != 12 { wrongAnswer = true; lockOpened = false }
                            } label: {
                                Text("\(answer)")
                                    .font(AppFonts.heading(30))
                                    .foregroundStyle(AppColors.ink)
                                    .frame(maxWidth: .infinity, minHeight: 76)
                                    .background(AppColors.yellow, in: RoundedRectangle(cornerRadius: 25))
                                    .overlay { RoundedRectangle(cornerRadius: 25).stroke(AppColors.ink, lineWidth: 3) }
                            }
                        }
                    }
                } else {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundStyle(AppColors.ink)
                        .frame(width: 150, height: 150)
                        .background(AppColors.yellow, in: Circle())
                        .overlay { Circle().stroke(AppColors.ink, lineWidth: 4) }
                        .onLongPressGesture(minimumDuration: 3) {
                            model.completeParentHold()
                            lockOpened = true
                            wrongAnswer = false
                        }
                        .accessibilityLabel("Удерживайте замок три секунды")
                    Text(wrongAnswer ? "Попробуйте ещё раз" : "Удерживайте замок 3 секунды")
                        .font(AppFonts.heading(23))
                        .foregroundStyle(AppColors.ink)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.top, 100)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 30))
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
    }
}

struct ParentSettingsView: View {
    @EnvironmentObject private var model: RoomViewModel
    @State private var name = ""

    var body: some View {
        ActivityScene(art: "parent_scene", title: "Для родителей") {
            ScrollView {
                VStack(spacing: 16) {
                    section("Питомец") {
                        HStack {
                            TextField("Имя котёнка", text: $name)
                                .font(AppFonts.body(20))
                                .textFieldStyle(.roundedBorder)
                            Button("Сохранить") { model.saveParentName(name) }
                                .font(AppFonts.heading(17))
                                .foregroundStyle(AppColors.ink)
                                .padding(12)
                                .background(AppColors.yellow, in: Capsule())
                        }
                        HStack(spacing: 12) {
                            ageButton(.toddler, title: "Малыш")
                            ageButton(.older, title: "Большой")
                        }
                    }
                    section("Звук и тихий час") {
                        Toggle("Звуки и голос", isOn: binding(\.effectsEnabled))
                        volumeSlider("Музыка", symbol: "music.note", value: binding(\.musicVolume))
                        volumeSlider("Эффекты", symbol: "speaker.wave.2.fill", value: binding(\.effectsVolume))
                        volumeSlider("Голос", symbol: "waveform", value: binding(\.voiceVolume))
                        Toggle("Тихий час", isOn: binding(\.quietHoursEnabled))
                        if model.parentOptions.quietHoursEnabled {
                            HStack {
                                hourPicker("С", value: binding(\.quietStart))
                                hourPicker("До", value: binding(\.quietEnd))
                            }
                        }
                    }
                    section("Добровольные награды") {
                        ForEach(RewardOption.allCases, id: \.self) { option in
                            Toggle(option.title, isOn: Binding(
                                get: { model.parentOptions.allowedRewards.contains(option) },
                                set: { enabled in
                                    model.updateParentOptions { options in
                                        if enabled { options.allowedRewards.insert(option) }
                                        else { options.allowedRewards.remove(option) }
                                    }
                                }
                            ))
                        }
                    }
                    section("Статистика") {
                        HStack {
                            stat("🪙", value: "\(model.kitchen.coins)", label: "монет")
                            stat("🎁", value: "\(model.shop.owned.count)", label: "покупок")
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 100)
                .padding(.bottom, 25)
            }
        }
        .onAppear { name = model.petName }
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<ParentOptions, Value>) -> Binding<Value> {
        Binding(get: { model.parentOptions[keyPath: keyPath] },
                set: { value in model.updateParentOptions { $0[keyPath: keyPath] = value } })
    }

    private func ageButton(_ mode: AgeMode, title: String) -> some View {
        Button { model.setParentAge(mode) } label: {
            Text(title).font(AppFonts.heading(19)).foregroundStyle(AppColors.ink)
                .frame(maxWidth: .infinity, minHeight: 64)
                .background(model.ageMode == mode ? AppColors.mint : AppColors.background, in: Capsule())
                .overlay { Capsule().stroke(AppColors.ink, lineWidth: 2) }
        }
    }

    private func hourPicker(_ label: String, value: Binding<Int>) -> some View {
        Picker(label, selection: value) {
            ForEach(0..<24, id: \.self) { hour in
                Text(String(format: "%02d:00", hour)).tag(hour)
            }
        }
        .pickerStyle(.menu)
        .frame(maxWidth: .infinity, minHeight: 52)
        .background(AppColors.background, in: RoundedRectangle(cornerRadius: 16))
    }

    private func volumeSlider(_ title: String, symbol: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: symbol)
                .font(AppFonts.body(17))
                .foregroundStyle(AppColors.ink)
            Slider(value: value, in: 0...1)
                .tint(AppColors.mint)
                .accessibilityLabel(title)
        }
    }

    private func stat(_ icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(icon).font(.system(size: 28))
            Text(value).font(AppFonts.heading(25))
            Text(label).font(AppFonts.body(15))
        }
        .foregroundStyle(AppColors.ink)
        .frame(maxWidth: .infinity)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            Text(title).font(AppFonts.heading(23)).foregroundStyle(AppColors.ink)
            content()
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.97), in: RoundedRectangle(cornerRadius: 27))
        .overlay { RoundedRectangle(cornerRadius: 27).stroke(AppColors.ink, lineWidth: 2) }
    }
}
