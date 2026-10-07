import Combine
import SwiftUI

private enum PuzzleArt {
    static let names = ["puzzle_playroom", "puzzle_picnic", "puzzle_space", "puzzle_dinosaurs"]
    static let titles = ["Игрушки", "Пикник", "Космос", "Динозавры"]
}

struct PuzzleSelectionView: View {
    @EnvironmentObject private var model: RoomViewModel

    var body: some View {
        ActivityScene(art: "room_day", title: "Пазлы") {
            ScrollView {
                VStack(spacing: 18) {
                    ActivityPrompt(text: "Выбери картинку")
                    ForEach(PuzzleArt.names.indices, id: \.self) { index in
                    Button { model.startPuzzle(imageIndex: index) } label: {
                        HStack(spacing: 18) {
                            if let image = ArtImage.named(PuzzleArt.names[index]) {
                                Image(uiImage: image).resizable().scaledToFill()
                                    .frame(width: 100, height: 100).clipShape(RoundedRectangle(cornerRadius: 18))
                            }
                            VStack(alignment: .leading, spacing: 5) {
                                Text(PuzzleArt.titles[index]).font(AppFonts.heading(25))
                                Text(index >= 2 ? "Сложный пазл" : "Простой пазл").font(AppFonts.body(17))
                            }
                            Spacer()
                        }
                        .foregroundStyle(AppColors.ink).padding(12)
                        .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 26))
                        .overlay { RoundedRectangle(cornerRadius: 26).stroke(AppColors.ink, lineWidth: 3) }
                    }
                    .buttonStyle(FluffyPressStyle(reduceMotion: false))
                    }
                }
                .padding(.horizontal, 22).padding(.top, 100).padding(.bottom, 25)
            }
        }
    }
}

struct PuzzleGameView: View {
    @EnvironmentObject private var model: RoomViewModel

    var body: some View {
        ActivityScene(art: "room_day", title: "Пазлы") {
            if let round = model.puzzleRound, let image = ArtImage.named(PuzzleArt.names[round.imageIndex]) {
                GeometryReader { geometry in
                    let boardWidth = min(geometry.size.width - 36, 388)
                    let spacing: CGFloat = 3
                    let tile = (boardWidth - spacing * CGFloat(round.side - 1)) / CGFloat(round.side)
                    ZStack {
                        ScrollView {
                            VStack(spacing: 17) {
                                ActivityPrompt(text: round.finished ? "Картинка собрана!" : "Нажми две части, чтобы поменять их местами")
                                Image(uiImage: image).resizable().scaledToFill()
                                    .frame(width: 96, height: 96).clipShape(RoundedRectangle(cornerRadius: 15))
                                    .overlay { RoundedRectangle(cornerRadius: 15).stroke(AppColors.ink, lineWidth: 2) }
                                    .accessibilityLabel("Образец картинки")
                                LazyVGrid(columns: Array(repeating: GridItem(.fixed(tile), spacing: spacing), count: round.side), spacing: spacing) {
                                    ForEach(round.pieces.indices, id: \.self) { index in
                                        Button { model.tapPuzzlePiece(index) } label: {
                                            PuzzlePiece(image: image, sourceIndex: round.pieces[index], side: round.side)
                                                .frame(width: tile, height: tile)
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: 5)
                                                        .stroke(round.selected == index ? AppColors.yellow : AppColors.ink,
                                                                lineWidth: round.selected == index ? 6 : 2)
                                                }
                                        }
                                        .accessibilityLabel("Часть картинки \(index + 1)")
                                    }
                                }
                                .frame(width: boardWidth)
                                .padding(8).background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 15))
                            }
                            .frame(maxWidth: .infinity).padding(.top, 102).padding(.bottom, 35)
                        }
                        if round.finished {
                            VStack {
                                Spacer()
                                ActivityResult(title: "Собралось!", detail: "Отличная работа!",
                                               home: { model.closeActivity() },
                                               again: { model.startPuzzle(imageIndex: round.imageIndex) })
                                    .padding(.bottom, 15)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct PuzzlePiece: View {
    let image: UIImage
    let sourceIndex: Int
    let side: Int

    var body: some View {
        return GeometryReader { area in
            if let source = image.cgImage {
                let width = source.width / side
                let height = source.height / side
                let crop = CGRect(x: sourceIndex % side * width, y: sourceIndex / side * height,
                                  width: width, height: height)
                if let piece = source.cropping(to: crop) {
                    Image(uiImage: UIImage(cgImage: piece)).resizable().scaledToFill()
                        .frame(width: area.size.width, height: area.size.height).clipped()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

private enum MemoryFaces {
    static let symbols = ["🐟", "🧶", "⭐️", "🍓", "🦋", "🌼", "🥕", "🐾",
                          "🎈", "🍎", "🌈", "🧸", "🍪", "🎀", "🚀", "🍌",
                          "🐝", "🍄", "🦆", "🍉", "🐞", "🪁", "🍇", "🌻",
                          "🐢", "🍒", "🌙", "🍋", "🐰", "🧩", "🎨", "🍦"]
}

struct MemoryGameView: View {
    @EnvironmentObject private var model: RoomViewModel

    var body: some View {
        ActivityScene(art: "room_day", title: "Мемори") {
            if let round = model.memoryRound {
                VStack(spacing: 13) {
                    ActivityPrompt(text: "Уровень \(round.level) · Ты \(round.childPairs) : \(round.catPairs) Котёнок")
                    Text(round.phase == .catReveal ? "Котёнок открывает карточки" : "Найди одинаковые картинки")
                        .font(AppFonts.heading(19)).foregroundStyle(AppColors.ink)
                        .padding(10).background(.white.opacity(0.9), in: Capsule())
                    memoryBoard(round)
                    Spacer(minLength: 0)
                }
                .padding(.top, 102)
                .onChange(of: model.memoryRound?.phase) { phase in
                    let id = model.memoryRound?.id
                    if phase == .childMismatch {
                        Task { try? await Task.sleep(nanoseconds: 850_000_000); if let id { model.revealMemoryCatTurn(id: id) } }
                    } else if phase == .catReveal {
                        Task { try? await Task.sleep(nanoseconds: 950_000_000); if let id { model.finishMemoryCatTurn(id: id) } }
                    }
                }
                .overlay {
                    if round.phase == .finished {
                        ActivityResult(title: round.outcome == .child ? "Ты победил!" : (round.outcome == .cat ? "Котёнок победил!" : "Ничья!"),
                                       detail: round.outcome == .child && round.level < MemoryRound.sizes.count ? "Открыт следующий уровень" : "Сыграем ещё?",
                                       home: { model.closeActivity() },
                                       again: { model.startMemoryRound() })
                    }
                }
            }
        }
    }

    private func memoryBoard(_ round: MemoryRound) -> some View {
        let tile: CGFloat = 64
        let gap: CGFloat = 5
        let boardWidth = CGFloat(round.columns) * tile + CGFloat(round.columns - 1) * gap
        return ScrollView([.horizontal, .vertical]) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(tile), spacing: gap), count: round.columns), spacing: gap) {
                ForEach(round.symbols.indices, id: \.self) { index in
                    Button { model.flipMemoryCard(index) } label: {
                        let shown = round.faceUp.contains(index) || round.matched.contains(index)
                        Text(shown ? MemoryFaces.symbols[round.symbols[index]] : "🐾")
                            .font(.system(size: 34))
                            .frame(width: tile, height: tile)
                            .background(round.matched.contains(index) ? AppColors.mint : (shown ? .white : AppColors.pink),
                                        in: RoundedRectangle(cornerRadius: 12))
                            .overlay { RoundedRectangle(cornerRadius: 12).stroke(AppColors.ink, lineWidth: 2) }
                    }
                    .disabled(round.phase != .child || round.matched.contains(index))
                    .accessibilityLabel(round.faceUp.contains(index) || round.matched.contains(index)
                                        ? "Открыта карточка \(index + 1)" : "Закрыта карточка \(index + 1)")
                }
            }
            .frame(width: boardWidth).padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: 490)
        .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 22))
        .padding(.horizontal, 14)
    }
}

struct TicTacToeGameView: View {
    @EnvironmentObject private var model: RoomViewModel

    var body: some View {
        ActivityScene(art: "room_day", title: "Крестики-нолики") {
            if let round = model.ticTacToeRound {
                GeometryReader { area in
                    let tile = min((area.size.width - 64) / 3, 105)
                    ZStack {
                        VStack(spacing: 24) {
                            ActivityPrompt(text: round.waitingForCat ? "Ход котёнка…" : "Твой ход — крестики")
                            HStack(spacing: 18) {
                                Text("Ты: ✕").font(AppFonts.heading(25))
                                if let image = ArtImage.named("cat_plush_awake") {
                                    Image(uiImage: image).resizable().scaledToFit().frame(width: 65, height: 65)
                                }
                                Text("Кот: ○").font(AppFonts.heading(25))
                            }
                            .foregroundStyle(AppColors.ink).padding(10)
                            .background(.white.opacity(0.94), in: Capsule())
                            LazyVGrid(columns: Array(repeating: GridItem(.fixed(tile), spacing: 8), count: 3), spacing: 8) {
                                ForEach(0..<9, id: \.self) { index in
                                    Button { model.tapTicTacToe(index) } label: {
                                        Text(round.board[index] == .child ? "✕" : (round.board[index] == .cat ? "○" : ""))
                                            .font(.system(size: tile * 0.66, weight: .bold, design: .rounded))
                                            .foregroundStyle(round.board[index] == .child ? AppColors.pink : AppColors.sky)
                                            .frame(width: tile, height: tile)
                                            .background(.white, in: RoundedRectangle(cornerRadius: 20))
                                            .overlay { RoundedRectangle(cornerRadius: 20).stroke(AppColors.ink, lineWidth: 3) }
                                    }
                                    .disabled(round.waitingForCat || round.outcome != nil || round.board[index] != nil)
                                    .accessibilityLabel("Клетка \(index + 1)")
                                }
                            }
                            .frame(width: tile * 3 + 16)
                            Spacer(minLength: 0)
                        }
                        .padding(.top, 105)
                        .onChange(of: model.ticTacToeRound?.waitingForCat) { waiting in
                            guard waiting == true, let id = model.ticTacToeRound?.id else { return }
                            Task { try? await Task.sleep(nanoseconds: 500_000_000); model.playTicTacToeCat(id: id) }
                        }
                        if let outcome = round.outcome {
                            ActivityResult(title: outcome == .child ? "Ты победил!" : (outcome == .cat ? "Котёнок победил!" : "Ничья!"),
                                           detail: "Спасибо за игру!", home: { model.closeActivity() },
                                           again: { model.startTicTacToeRound() })
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

struct BeaverGameView: View {
    @EnvironmentObject private var model: RoomViewModel
    private let ticker = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()
    private let faces = ["🦫", "🦊", "🐸", "🐰"]

    var body: some View {
        ActivityScene(art: "room_day", title: "Бобёр") {
            if let round = model.beaverRound {
                GeometryReader { area in
                    let columns = round.holeCount == 6 ? 3 : 4
                    let rows = (round.holeCount + columns - 1) / columns
                    let hole = max(54, min((area.size.width - 54) / CGFloat(columns),
                                           (area.size.height - 300 - CGFloat(rows - 1) * 10) / CGFloat(rows), 110))
                    ZStack {
                        VStack(spacing: 18) {
                            ActivityPrompt(text: "Успей коснуться головы! Норок: \(round.holeCount)")
                            meter(round.meter)
                            LazyVGrid(columns: Array(repeating: GridItem(.fixed(hole), spacing: 8), count: columns), spacing: 10) {
                                ForEach(0..<round.holeCount, id: \.self) { index in
                                    Button { model.tapBeaverHole(index) } label: {
                                        ZStack {
                                            Circle().fill(AppColors.ink).frame(width: hole, height: hole * 0.8)
                                                .overlay { Circle().stroke(AppColors.yellow, lineWidth: 7) }
                                            if let face = round.activeHoles[index] {
                                                Text(faces[face]).font(.system(size: hole * 0.63))
                                                    .offset(y: -hole * 0.1)
                                            }
                                        }
                                        .frame(width: hole, height: hole)
                                    }
                                    .disabled(round.activeHoles[index] == nil || round.outcome != nil)
                                    .accessibilityLabel(round.activeHoles[index] != nil ? "Коснуться зверька в норке \(index + 1)" : "Пустая норка \(index + 1)")
                                }
                            }
                            .frame(width: hole * CGFloat(columns) + CGFloat(columns - 1) * 8)
                            Spacer(minLength: 0)
                        }
                        .padding(.top, 102)
                        if let outcome = round.outcome {
                            ActivityResult(title: outcome == .win ? "Ты победил!" : "Зверьки спрятались!",
                                           detail: outcome == .win ? "Шкала стала зелёной" : "Попробуем ещё раз?",
                                           home: { model.closeActivity() },
                                           again: { model.startBeaverRound() })
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .onReceive(ticker) { _ in model.tickBeaverRound() }
            }
        }
    }

    private func meter(_ value: Double) -> some View {
        let fraction = (value - BeaverRound.loseThreshold) /
                       (BeaverRound.winThreshold - BeaverRound.loseThreshold)
        return GeometryReader { area in
            ZStack(alignment: .leading) {
                Capsule().fill(LinearGradient(colors: [.red, AppColors.yellow, AppColors.mint],
                                               startPoint: .leading, endPoint: .trailing))
                Circle().fill(.white).frame(width: 35, height: 35)
                    .overlay { Circle().stroke(AppColors.ink, lineWidth: 3) }
                    .offset(x: CGFloat(fraction) * max(0, area.size.width - 35))
            }
        }
        .frame(height: 35).padding(.horizontal, 33)
        .accessibilityLabel("Шкала игры: \(value)")
    }
}
