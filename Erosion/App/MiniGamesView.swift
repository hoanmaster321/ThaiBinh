//
//  MiniGamesView.swift
//  Thái Bình (ErosionWQ)
//
//  Bản quyền © 2026 Thái Bình (hoanmaster321)
//

import SwiftUI
import Combine

struct MiniGamesView: View {
    @AppStorage("game_2048_best") private var best2048: Int = 0
    @AppStorage("game_snake_best") private var bestSnake: Int = 0
    @AppStorage("game_mines_wins") private var minesWins: Int = 0
    @AppStorage("game_caro_wins") private var caroWins: Int = 0
    @AppStorage("game_memory_best") private var bestMemory: Int = 0

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                        Image(systemName: "gamecontroller.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trung tâm Giải trí Thái Bình")
                            .font(.headline)
                        Text("5 tựa game mini cổ điển tích hợp sẵn — Chơi mượt mà, không cần mạng, tự động lưu kỷ lục.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                NavigationLink {
                    Game2048View()
                } label: {
                    MiniGameRow(
                        title: "2048 Thái Bình",
                        subtitle: "Ghép các ô số cùng giá trị để đạt mốc 2048+",
                        icon: "square.grid.4x3.fill",
                        color: .orange,
                        badge: "Kỷ lục: \(best2048)"
                    )
                }

                NavigationLink {
                    SnakeGameView()
                } label: {
                    MiniGameRow(
                        title: "Rắn Săn Mồi",
                        subtitle: "Điều khiển rắn ăn táo, tránh va chạm tường và thân",
                        icon: "scribble.variable",
                        color: .green,
                        badge: "Kỷ lục: \(bestSnake)"
                    )
                }

                NavigationLink {
                    MinesweeperGameView()
                } label: {
                    MiniGameRow(
                        title: "Dò Mìn Cổ Điển",
                        subtitle: "Mở toàn bộ các ô an toàn và cắm cờ đánh dấu 10 quả mìn",
                        icon: "Burst",
                        systemIcon: "flame.fill",
                        color: .red,
                        badge: "Thắng: \(minesWins)"
                    )
                }

                NavigationLink {
                    TicTacToeGameView()
                } label: {
                    MiniGameRow(
                        title: "Cờ Caro (3×3 & 5×5)",
                        subtitle: "Đấu trí với Máy (AI thông minh) hoặc 2 người chơi cùng máy",
                        icon: "grid",
                        color: .blue,
                        badge: "Thắng: \(caroWins)"
                    )
                }

                NavigationLink {
                    MemoryMatchGameView()
                } label: {
                    MiniGameRow(
                        title: "Lật Hình Trí Nhớ",
                        subtitle: "Tìm các cặp biểu tượng giống nhau với số lượt lật ít nhất",
                        icon: "rectangle.grid.2x2.fill",
                        color: .purple,
                        badge: bestMemory > 0 ? "Tốt nhất: \(bestMemory) lượt" : "Mới"
                    )
                }
            } header: {
                HeaderLabel("Danh sách Trò chơi", symbol: "sparkles")
            }

            Section {
                Button(role: .destructive) {
                    Haptic.shared.notify(.warning)
                    best2048 = 0
                    bestSnake = 0
                    minesWins = 0
                    caroWins = 0
                    bestMemory = 0
                } label: {
                    Label("Đặt lại toàn bộ kỷ lục điểm số", systemImage: "arrow.counterclockwise")
                }
            } header: {
                HeaderLabel("Dữ liệu kỷ lục", symbol: "trophy.fill")
            } footer: {
                Text("Thái Bình · Trung tâm Giải trí Mini Games phát triển bởi hoanmaster321")
            }
        }
        .navigationTitle("Giải trí")
    }
}

private struct MiniGameRow: View {
    let title: String
    let subtitle: String
    var icon: String = ""
    var systemIcon: String? = nil
    let color: Color
    let badge: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: systemIcon ?? icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(title)
                        .font(.body.weight(.semibold))
                    Spacer()
                    Text(badge)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(color.opacity(0.14), in: Capsule())
                        .foregroundStyle(color)
                }
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 1. GAME 2048 THÁI BÌNH

struct Game2048View: View {
    @AppStorage("game_2048_best") private var bestScore: Int = 0
    @State private var board: [[Int]] = Array(repeating: Array(repeating: 0, count: 4), count: 4)
    @State private var previousBoard: [[Int]]? = nil
    @State private var previousScore: Int = 0
    @State private var score: Int = 0
    @State private var isGameOver: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Điểm số
                HStack(spacing: 12) {
                    ScoreCardView(title: "ĐIỂM HIỆN TẠI", value: "\(score)", color: .orange)
                    ScoreCardView(title: "KỶ LỤC", value: "\(bestScore)", color: .blue)
                }
                .padding(.horizontal)

                // Bàn cờ 4x4
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.systemGray5))
                        .padding(4)

                    VStack(spacing: 8) {
                        ForEach(0..<4, id: \.self) { r in
                            HStack(spacing: 8) {
                                ForEach(0..<4, id: \.self) { c in
                                    Tile2048Cell(value: board[r][c])
                                }
                            }
                        }
                    }
                    .padding(12)

                    if isGameOver {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay {
                                VStack(spacing: 12) {
                                    Image(systemName: "flag.checkered.2.crossed")
                                        .font(.largeTitle)
                                        .foregroundStyle(.orange)
                                    Text("Hết nước đi!")
                                        .font(.title2.bold())
                                    Text("Tổng điểm: \(score)")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Button {
                                        startNewGame()
                                    } label: {
                                        Label("Chơi ván mới", systemImage: "arrow.clockwise")
                                            .font(.headline)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.orange)
                                }
                            }
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal)
                .gesture(
                    DragGesture(minimumDistance: 24)
                        .onEnded { value in
                            let dx = value.translation.width
                            let dy = value.translation.height
                            if abs(dx) > abs(dy) {
                                move(dx > 0 ? .right : .left)
                            } else {
                                move(dy > 0 ? .down : .up)
                            }
                        }
                )

                // Phím điều hướng và công cụ
                VStack(spacing: 10) {
                    Button {
                        move(.up)
                    } label: {
                        Image(systemName: "chevron.up.circle.fill")
                            .font(.system(size: 44))
                    }
                    HStack(spacing: 48) {
                        Button {
                            move(.left)
                        } label: {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 44))
                        }
                        Button {
                            move(.right)
                        } label: {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.system(size: 44))
                        }
                    }
                    Button {
                        move(.down)
                    } label: {
                        Image(systemName: "chevron.down.circle.fill")
                            .font(.system(size: 44))
                    }
                }
                .foregroundStyle(.orange)

                HStack(spacing: 14) {
                    Button {
                        undoMove()
                    } label: {
                        Label("Hoàn tác", systemImage: "arrow.uturn.backward")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(previousBoard == nil)

                    Button {
                        startNewGame()
                    } label: {
                        Label("Ván mới", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                }
                .padding(.horizontal)

                Text("Mẹo: Vuốt trực tiếp trên bàn cờ hoặc dùng các nút mũi tên để dồn các ô số cùng giá trị.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("2048 Thái Bình")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if board.flatMap({ $0 }).allSatisfy({ $0 == 0 }) {
                startNewGame()
            }
        }
    }

    private enum Direction {
        case up, down, left, right
    }

    private func startNewGame() {
        Haptic.shared.play(.medium)
        board = Array(repeating: Array(repeating: 0, count: 4), count: 4)
        previousBoard = nil
        score = 0
        isGameOver = false
        spawnTile()
        spawnTile()
    }

    private func undoMove() {
        guard let prev = previousBoard else { return }
        Haptic.shared.play(.light)
        board = prev
        score = previousScore
        previousBoard = nil
        isGameOver = false
    }

    private func spawnTile() {
        var empty: [(Int, Int)] = []
        for r in 0..<4 {
            for c in 0..<4 where board[r][c] == 0 {
                empty.append((r, c))
            }
        }
        guard let chosen = empty.randomElement() else { return }
        board[chosen.0][chosen.1] = Int.random(in: 1...10) == 10 ? 4 : 2
    }

    private func slideAndMerge(_ line: [Int]) -> ([Int], Int) {
        let nonZero = line.filter { $0 != 0 }
        var merged: [Int] = []
        var gained = 0
        var i = 0
        while i < nonZero.count {
            if i + 1 < nonZero.count && nonZero[i] == nonZero[i + 1] {
                let val = nonZero[i] * 2
                merged.append(val)
                gained += val
                i += 2
            } else {
                merged.append(nonZero[i])
                i += 1
            }
        }
        while merged.count < 4 {
            merged.append(0)
        }
        return (merged, gained)
    }

    private func move(_ dir: Direction) {
        guard !isGameOver else { return }
        let savedBoard = board
        let savedScore = score
        var totalGained = 0

        var newBoard = board
        switch dir {
        case .left:
            for r in 0..<4 {
                let (row, gained) = slideAndMerge(newBoard[r])
                newBoard[r] = row
                totalGained += gained
            }
        case .right:
            for r in 0..<4 {
                let (row, gained) = slideAndMerge(newBoard[r].reversed())
                newBoard[r] = row.reversed()
                totalGained += gained
            }
        case .up:
            for c in 0..<4 {
                let col = (0..<4).map { newBoard[$0][c] }
                let (mergedCol, gained) = slideAndMerge(col)
                for r in 0..<4 { newBoard[r][c] = mergedCol[r] }
                totalGained += gained
            }
        case .down:
            for c in 0..<4 {
                let col = (0..<4).map { newBoard[$0][c] }.reversed()
                let (mergedCol, gained) = slideAndMerge(Array(col))
                let finalCol = Array(mergedCol.reversed())
                for r in 0..<4 { newBoard[r][c] = finalCol[r] }
                totalGained += gained
            }
        }

        if newBoard != savedBoard {
            Haptic.shared.play(.light)
            previousBoard = savedBoard
            previousScore = savedScore
            board = newBoard
            score += totalGained
            if score > bestScore {
                bestScore = score
            }
            spawnTile()
            checkGameOver()
        }
    }

    private func checkGameOver() {
        for r in 0..<4 {
            for c in 0..<4 {
                if board[r][c] == 0 { return }
                if r + 1 < 4 && board[r][c] == board[r + 1][c] { return }
                if c + 1 < 4 && board[r][c] == board[r][c + 1] { return }
            }
        }
        Haptic.shared.notify(.error)
        isGameOver = true
    }
}

private struct Tile2048Cell: View {
    let value: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(tileColor)
            if value > 0 {
                Text("\(value)")
                    .font(.system(size: value >= 1024 ? 20 : 24, weight: .bold, design: .rounded))
                    .foregroundStyle(value <= 4 ? Color.primary : Color.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var tileColor: Color {
        switch value {
        case 0: return Color(.systemGray4).opacity(0.6)
        case 2: return Color.orange.opacity(0.25)
        case 4: return Color.orange.opacity(0.4)
        case 8: return .orange
        case 16: return Color(red: 0.96, green: 0.49, blue: 0.24)
        case 32: return Color(red: 0.96, green: 0.36, blue: 0.23)
        case 64: return .red
        case 128: return .yellow
        case 256: return .green
        case 512: return .teal
        case 1024: return .blue
        default: return .purple
        }
    }
}

// MARK: - 2. RẮN SĂN MỒI (SNAKE)

struct SnakeGameView: View {
    private let gridSize = 15

    struct GridPoint: Equatable, Hashable {
        var x: Int
        var y: Int
    }

    enum Direction {
        case up, down, left, right
    }

    @AppStorage("game_snake_best") private var bestScore: Int = 0
    @State private var snake: [GridPoint] = [
        GridPoint(x: 7, y: 7),
        GridPoint(x: 6, y: 7),
        GridPoint(x: 5, y: 7)
    ]
    @State private var food: GridPoint = GridPoint(x: 10, y: 7)
    @State private var direction: Direction = .right
    @State private var nextDirection: Direction = .right
    @State private var score: Int = 0
    @State private var isRunning: Bool = false
    @State private var isGameOver: Bool = false
    @State private var speedLevel: Int = 1 // 0: Chậm, 1: Chuẩn, 2: Nhanh

    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    @State private var tickCounter: Int = 0

    private var ticksPerStep: Int {
        switch speedLevel {
        case 0: return 5 // 0.25s
        case 2: return 2 // 0.10s
        default: return 3 // 0.15s
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    ScoreCardView(title: "ĐIỂM SỐ", value: "\(score)", color: .green)
                    ScoreCardView(title: "KỶ LỤC", value: "\(bestScore)", color: .blue)
                }
                .padding(.horizontal)

                Picker("Tốc độ", selection: $speedLevel) {
                    Text("Chậm").tag(0)
                    Text("Chuẩn").tag(1)
                    Text("Siêu tốc").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Màn hình lưới 15x15
                GeometryReader { geo in
                    let boardWidth = geo.size.width
                    let cellSize = boardWidth / CGFloat(gridSize)

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.green.opacity(0.4), lineWidth: 2)
                            )

                        // Vẽ mồi (Táo đỏ)
                        Circle()
                            .fill(Color.red)
                            .frame(width: cellSize * 0.85, height: cellSize * 0.85)
                            .position(
                                x: (CGFloat(food.x) + 0.5) * cellSize,
                                y: (CGFloat(food.y) + 0.5) * cellSize
                            )

                        // Vẽ thân rắn
                        ForEach(Array(snake.enumerated()), id: \.offset) { idx, pt in
                            RoundedRectangle(cornerRadius: idx == 0 ? 6 : 4, style: .continuous)
                                .fill(idx == 0 ? Color.green : Color.green.opacity(0.75))
                                .frame(width: cellSize * 0.9, height: cellSize * 0.9)
                                .position(
                                    x: (CGFloat(pt.x) + 0.5) * cellSize,
                                    y: (CGFloat(pt.y) + 0.5) * cellSize
                                )
                        }

                        if !isRunning || isGameOver {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay {
                                    VStack(spacing: 12) {
                                        Image(systemName: isGameOver ? "xmark.octagon.fill" : "play.circle.fill")
                                            .font(.system(size: 44))
                                            .foregroundStyle(isGameOver ? .red : .green)
                                        Text(isGameOver ? "Va chạm! Kết thúc" : (score > 0 ? "Đang tạm dừng" : "Rắn Săn Mồi"))
                                            .font(.title3.bold())
                                        Button {
                                            if isGameOver {
                                                resetGame()
                                            }
                                            isRunning = true
                                        } label: {
                                            Label(isGameOver ? "Chơi lại" : "Bắt đầu chạy", systemImage: "play.fill")
                                                .font(.headline)
                                                .padding(.horizontal, 18)
                                                .padding(.vertical, 8)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(.green)
                                    }
                                }
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 18)
                            .onEnded { value in
                                let dx = value.translation.width
                                let dy = value.translation.height
                                if abs(dx) > abs(dy) {
                                    changeDirection(dx > 0 ? .right : .left)
                                } else {
                                    changeDirection(dy > 0 ? .down : .up)
                                }
                            }
                    )
                }
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal)

                // Phím D-Pad điều khiển
                VStack(spacing: 8) {
                    Button {
                        changeDirection(.up)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 46))
                    }
                    HStack(spacing: 54) {
                        Button {
                            changeDirection(.left)
                        } label: {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.system(size: 46))
                        }
                        Button {
                            isRunning.toggle()
                        } label: {
                            Image(systemName: isRunning ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.orange)
                        }
                        Button {
                            changeDirection(.right)
                        } label: {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 46))
                        }
                    }
                    Button {
                        changeDirection(.down)
                    } label: {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 46))
                    }
                }
                .foregroundStyle(.green)
            }
            .padding(.vertical)
        }
        .navigationTitle("Rắn Săn Mồi")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { _ in
            guard isRunning && !isGameOver else { return }
            tickCounter += 1
            if tickCounter >= ticksPerStep {
                tickCounter = 0
                stepSnake()
            }
        }
    }

    private func changeDirection(_ newDir: Direction) {
        switch (direction, newDir) {
        case (.up, .down), (.down, .up), (.left, .right), (.right, .left):
            return
        default:
            Haptic.shared.play(.light, intensity: 0.6)
            nextDirection = newDir
            if !isRunning && !isGameOver {
                isRunning = true
            }
        }
    }

    private func resetGame() {
        snake = [
            GridPoint(x: 7, y: 7),
            GridPoint(x: 6, y: 7),
            GridPoint(x: 5, y: 7)
        ]
        direction = .right
        nextDirection = .right
        score = 0
        isGameOver = false
        spawnFood()
    }

    private func spawnFood() {
        var candidates: [GridPoint] = []
        for x in 0..<gridSize {
            for y in 0..<gridSize {
                let pt = GridPoint(x: x, y: y)
                if !snake.contains(pt) {
                    candidates.append(pt)
                }
            }
        }
        if let chosen = candidates.randomElement() {
            food = chosen
        }
    }

    private func stepSnake() {
        direction = nextDirection
        guard let head = snake.first else { return }
        var nextHead = head
        switch direction {
        case .up: nextHead.y -= 1
        case .down: nextHead.y += 1
        case .left: nextHead.x -= 1
        case .right: nextHead.x += 1
        }

        // Kiểm tra đâm tường hoặc tự cắn thân
        if nextHead.x < 0 || nextHead.x >= gridSize || nextHead.y < 0 || nextHead.y >= gridSize || snake.dropLast().contains(nextHead) {
            Haptic.shared.notify(.error)
            isGameOver = true
            isRunning = false
            return
        }

        snake.insert(nextHead, at: 0)
        if nextHead == food {
            Haptic.shared.play(.medium)
            score += 10
            if score > bestScore {
                bestScore = score
            }
            spawnFood()
        } else {
            snake.removeLast()
        }
    }
}

// MARK: - 3. DÒ MÌN CỔ ĐIỂN (MINESWEEPER)

struct MinesweeperGameView: View {
    private let rows = 9
    private let cols = 9
    private let totalMines = 10

    struct Cell {
        var isMine: Bool = false
        var isRevealed: Bool = false
        var isFlagged: Bool = false
        var neighborMines: Int = 0
    }

    @AppStorage("game_mines_wins") private var totalWins: Int = 0
    @State private var grid: [[Cell]] = Array(
        repeating: Array(repeating: Cell(), count: 9),
        count: 9
    )
    @State private var isFirstTap: Bool = true
    @State private var flagMode: Bool = false
    @State private var gameState: GameState = .playing

    enum GameState {
        case playing, won, lost
    }

    private var flagsPlaced: Int {
        grid.flatMap { $0 }.filter { $0.isFlagged }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    ScoreCardView(title: "MÌN CÒN LẠI", value: "\(max(0, totalMines - flagsPlaced))", color: .red)
                    ScoreCardView(title: "SỐ TRẬN THẮNG", value: "\(totalWins)", color: .green)
                }
                .padding(.horizontal)

                // Chuyển đổi chế độ Mở ô / Cắm cờ
                Picker("Chế độ chạm", selection: $flagMode) {
                    Text("⛏️ Mở ô").tag(false)
                    Text("🚩 Cắm cờ").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Bàn cờ Dò Mìn 9x9
                VStack(spacing: 4) {
                    ForEach(0..<rows, id: \.self) { r in
                        HStack(spacing: 4) {
                            ForEach(0..<cols, id: \.self) { c in
                                MineCellView(cell: grid[r][c])
                                    .onTapGesture {
                                        handleTap(r: r, c: c)
                                    }
                                    .onLongPressGesture(minimumDuration: 0.3) {
                                        toggleFlag(r: r, c: c)
                                    }
                            }
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal)

                if gameState != .playing {
                    HStack(spacing: 12) {
                        Image(systemName: gameState == .won ? "trophy.fill" : "Burst")
                            .foregroundStyle(gameState == .won ? .yellow : .red)
                        Text(gameState == .won ? "Chúc mừng! Bạn đã phá đảo bãi mìn!" : "Bùm! Bạn đã chạm phải mìn!")
                            .font(.subheadline.bold())
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(
                        (gameState == .won ? Color.green : Color.red).opacity(0.15),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .padding(.horizontal)
                }

                Button {
                    resetBoard()
                } label: {
                    Label("Tạo bãi mìn mới", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding(.horizontal)

                Text("Mẹo: Nhấn giữ vào một ô bất kỳ để cắm cờ nhanh, hoặc chuyển sang chế độ 🚩 Cắm cờ ở thanh phía trên.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Dò Mìn Cổ Điển")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func resetBoard() {
        Haptic.shared.play(.medium)
        grid = Array(repeating: Array(repeating: Cell(), count: cols), count: rows)
        isFirstTap = true
        gameState = .playing
    }

    private func placeMines(excluding safeR: Int, safeC: Int) {
        var placed = 0
        while placed < totalMines {
            let r = Int.random(in: 0..<rows)
            let c = Int.random(in: 0..<cols)
            if abs(r - safeR) <= 1 && abs(c - safeC) <= 1 { continue }
            if !grid[r][c].isMine {
                grid[r][c].isMine = true
                placed += 1
            }
        }
        for r in 0..<rows {
            for c in 0..<cols where !grid[r][c].isMine {
                var count = 0
                for dr in -1...1 {
                    for dc in -1...1 {
                        let nr = r + dr, nc = c + dc
                        if nr >= 0 && nr < rows && nc >= 0 && nc < cols && grid[nr][nc].isMine {
                            count += 1
                        }
                    }
                }
                grid[r][c].neighborMines = count
            }
        }
    }

    private func toggleFlag(r: Int, c: Int) {
        guard gameState == .playing, !grid[r][c].isRevealed else { return }
        Haptic.shared.play(.rigid)
        grid[r][c].isFlagged.toggle()
    }

    private func handleTap(r: Int, c: Int) {
        guard gameState == .playing else { return }
        if flagMode {
            toggleFlag(r: r, c: c)
            return
        }
        guard !grid[r][c].isFlagged, !grid[r][c].isRevealed else { return }

        if isFirstTap {
            isFirstTap = false
            placeMines(excluding: r, safeC: c)
        }

        if grid[r][c].isMine {
            Haptic.shared.notify(.error)
            for row in 0..<rows {
                for col in 0..<cols where grid[row][col].isMine {
                    grid[row][col].isRevealed = true
                }
            }
            gameState = .lost
            return
        }

        Haptic.shared.play(.light)
        revealDFS(r: r, c: c)
        checkWin()
    }

    private func revealDFS(r: Int, c: Int) {
        guard r >= 0, r < rows, c >= 0, c < cols else { return }
        guard !grid[r][c].isRevealed, !grid[r][c].isFlagged, !grid[r][c].isMine else { return }
        grid[r][c].isRevealed = true
        if grid[r][c].neighborMines == 0 {
            for dr in -1...1 {
                for dc in -1...1 where !(dr == 0 && dc == 0) {
                    revealDFS(r: r + dr, c: c + dc)
                }
            }
        }
    }

    private func checkWin() {
        for r in 0..<rows {
            for c in 0..<cols {
                if !grid[r][c].isMine && !grid[r][c].isRevealed {
                    return
                }
            }
        }
        Haptic.shared.notify(.success)
        gameState = .won
        totalWins += 1
    }
}

private struct MineCellView: View {
    let cell: MinesweeperGameView.Cell

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(cell.isRevealed ? Color(.systemBackground) : Color.blue.opacity(0.22))

            if cell.isRevealed {
                if cell.isMine {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.red)
                } else if cell.neighborMines > 0 {
                    Text("\(cell.neighborMines)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(numberColor(cell.neighborMines))
                }
            } else if cell.isFlagged {
                Image(systemName: "flag.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.red)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func numberColor(_ n: Int) -> Color {
        switch n {
        case 1: return .blue
        case 2: return .green
        case 3: return .red
        case 4: return .purple
        default: return .orange
        }
    }
}

// MARK: - 4. CỜ CARO (3x3 & 5x5)

struct TicTacToeGameView: View {
    @AppStorage("game_caro_wins") private var xWins: Int = 0
    @State private var oWins: Int = 0
    @State private var boardSize: Int = 5 // 3 hoặc 5
    @State private var vsAI: Bool = true
    @State private var cells: [String] = Array(repeating: "", count: 25)
    @State private var isXTurn: Bool = true
    @State private var winner: String? = nil
    @State private var winningIndices: Set<Int> = []

    private var winLength: Int {
        boardSize == 3 ? 3 : 4
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    ScoreCardView(title: "NGƯỜI CHƠI (X)", value: "\(xWins)", color: .blue)
                    ScoreCardView(title: vsAI ? "MÁY AI (O)" : "NGƯỜI CHƠI 2 (O)", value: "\(oWins)", color: .red)
                }
                .padding(.horizontal)

                HStack(spacing: 12) {
                    Picker("Chế độ", selection: $vsAI) {
                        Text("🤖 Đấu với Máy").tag(true)
                        Text("👥 2 Người chơi").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: vsAI) { _, _ in resetGame() }

                    Picker("Kích thước", selection: $boardSize) {
                        Text("3×3").tag(3)
                        Text("5×5").tag(5)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 110)
                    .onChange(of: boardSize) { _, _ in resetGame() }
                }
                .padding(.horizontal)

                Text(statusTitle)
                    .font(.headline)
                    .foregroundStyle(winner == "X" ? .blue : (winner == "O" ? .red : .primary))

                // Bàn cờ Caro
                VStack(spacing: 6) {
                    ForEach(0..<boardSize, id: \.self) { r in
                        HStack(spacing: 6) {
                            ForEach(0..<boardSize, id: \.self) { c in
                                let idx = r * boardSize + c
                                let val = idx < cells.count ? cells[idx] : ""
                                let isWinCell = winningIndices.contains(idx)

                                Button {
                                    playerTap(idx)
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(isWinCell ? Color.green.opacity(0.28) : Color(.systemBackground))
                                        Text(val)
                                            .font(.system(size: boardSize == 3 ? 38 : 26, weight: .heavy, design: .rounded))
                                            .foregroundStyle(val == "X" ? Color.blue : Color.red)
                                    }
                                    .aspectRatio(1, contentMode: .fit)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal)

                Button {
                    resetGame()
                } label: {
                    Label("Ván mới", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                Text(boardSize == 5 ? "Luật 5×5: Bên nào xếp được 4 quân liên tiếp (ngang, dọc, chéo) trước sẽ chiến thắng." : "Luật 3×3: Bên nào xếp được 3 quân liên tiếp trước sẽ chiến thắng.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Cờ Caro")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statusTitle: String {
        if let w = winner {
            if w == "Draw" { return "⚖️ Ván đấu Hòa!" }
            if w == "X" { return "🎉 Người chơi X chiến thắng!" }
            return vsAI ? "🤖 Máy (O) chiến thắng!" : "🎉 Người chơi O chiến thắng!"
        }
        return isXTurn ? "Lượt của X" : (vsAI ? "Máy đang suy nghĩ..." : "Lượt của O")
    }

    private func resetGame() {
        Haptic.shared.play(.light)
        cells = Array(repeating: "", count: boardSize * boardSize)
        isXTurn = true
        winner = nil
        winningIndices = []
    }

    private func playerTap(_ idx: Int) {
        guard winner == nil, idx < cells.count, cells[idx].isEmpty else { return }
        if vsAI && !isXTurn { return }

        Haptic.shared.play(.light)
        cells[idx] = isXTurn ? "X" : "O"

        if evaluateBoard() { return }

        isXTurn.toggle()

        if vsAI && !isXTurn {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                makeAIMove()
            }
        }
    }

    private func makeAIMove() {
        guard winner == nil else { return }
        let emptyIndices = cells.indices.filter { cells[$0].isEmpty }
        guard !emptyIndices.isEmpty else { return }

        // 1. Nước đi thắng ngay cho O
        for idx in emptyIndices {
            cells[idx] = "O"
            if findWinningLine(for: "O") != nil {
                Haptic.shared.play(.medium)
                _ = evaluateBoard()
                isXTurn = true
                return
            }
            cells[idx] = ""
        }

        // 2. Chặn nước thắng ngay của X
        for idx in emptyIndices {
            cells[idx] = "X"
            if findWinningLine(for: "X") != nil {
                cells[idx] = "O"
                Haptic.shared.play(.light)
                _ = evaluateBoard()
                isXTurn = true
                return
            }
            cells[idx] = ""
        }

        // 3. Ưu tiên ô trung tâm hoặc gần quân đã đánh
        let center = (boardSize * boardSize) / 2
        let chosen: Int
        if cells[center].isEmpty {
            chosen = center
        } else {
            chosen = emptyIndices.randomElement()!
        }

        cells[chosen] = "O"
        Haptic.shared.play(.light)
        _ = evaluateBoard()
        isXTurn = true
    }

    private func evaluateBoard() -> Bool {
        if let line = findWinningLine(for: "X") {
            Haptic.shared.notify(.success)
            winner = "X"
            winningIndices = Set(line)
            xWins += 1
            return true
        }
        if let line = findWinningLine(for: "O") {
            Haptic.shared.notify(.warning)
            winner = "O"
            winningIndices = Set(line)
            oWins += 1
            return true
        }
        if cells.allSatisfy({ !$0.isEmpty }) {
            winner = "Draw"
            return true
        }
        return false
    }

    private func findWinningLine(for symbol: String) -> [Int]? {
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
        for r in 0..<boardSize {
            for c in 0..<boardSize {
                for (dr, dc) in directions {
                    var indices: [Int] = []
                    for step in 0..<winLength {
                        let nr = r + dr * step
                        let nc = c + dc * step
                        if nr >= 0 && nr < boardSize && nc >= 0 && nc < boardSize {
                            let idx = nr * boardSize + nc
                            if idx < cells.count && cells[idx] == symbol {
                                indices.append(idx)
                            }
                        }
                    }
                    if indices.count == winLength {
                        return indices
                    }
                }
            }
        }
        return nil
    }
}

// MARK: - 5. LẬT HÌNH TRÍ NHỚ (MEMORY MATCH)

struct MemoryMatchGameView: View {
    struct MemoryCard: Identifiable {
        let id = UUID()
        let icon: String
        var isFaceUp: Bool = false
        var isMatched: Bool = false
    }

    private let icons = [
        "bolt.fill", "flame.fill", "star.fill", "heart.fill",
        "moon.stars.fill", "leaf.fill", "crown.fill", "sparkles"
    ]

    @AppStorage("game_memory_best") private var bestMoves: Int = 0
    @State private var cards: [MemoryCard] = []
    @State private var firstFlippedIndex: Int? = nil
    @State private var moves: Int = 0
    @State private var isBusy: Bool = false

    private var isAllMatched: Bool {
        !cards.isEmpty && cards.allSatisfy { $0.isMatched }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack(spacing: 12) {
                    ScoreCardView(title: "SỐ LƯỢT LẬT", value: "\(moves)", color: .purple)
                    ScoreCardView(title: "KỶ LỤC ÍT NHẤT", value: bestMoves > 0 ? "\(bestMoves)" : "--", color: .blue)
                }
                .padding(.horizontal)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                    ForEach(cards.indices, id: \.self) { idx in
                        let card = cards[idx]
                        Button {
                            flipCard(at: idx)
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(card.isFaceUp || card.isMatched ? Color(.systemBackground) : Color.purple)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(card.isMatched ? Color.green : Color.purple.opacity(0.4), lineWidth: 2)
                                    )

                                if card.isFaceUp || card.isMatched {
                                    Image(systemName: card.icon)
                                        .font(.title)
                                        .foregroundStyle(card.isMatched ? .green : .purple)
                                } else {
                                    Image(systemName: "questionmark")
                                        .font(.title2.bold())
                                        .foregroundStyle(.white.opacity(0.85))
                                }
                            }
                            .aspectRatio(1, contentMode: .fit)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal)

                if isAllMatched {
                    Text("🎉 Hoàn thành xuất sắc sau \(moves) lượt lật!")
                        .font(.headline)
                        .foregroundStyle(.green)
                }

                Button {
                    setupNewGame()
                } label: {
                    Label("Trộn bài mới", systemImage: "shuffle")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Lật Hình Trí Nhớ")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if cards.isEmpty {
                setupNewGame()
            }
        }
    }

    private func setupNewGame() {
        Haptic.shared.play(.medium)
        let paired = (icons + icons).shuffled()
        cards = paired.map { MemoryCard(icon: $0) }
        firstFlippedIndex = nil
        moves = 0
        isBusy = false
    }

    private func flipCard(at idx: Int) {
        guard !isBusy, !cards[idx].isFaceUp, !cards[idx].isMatched else { return }
        Haptic.shared.play(.light)
        cards[idx].isFaceUp = true

        if let firstIdx = firstFlippedIndex {
            moves += 1
            firstFlippedIndex = nil
            if cards[firstIdx].icon == cards[idx].icon {
                Haptic.shared.notify(.success)
                cards[firstIdx].isMatched = true
                cards[idx].isMatched = true
                if cards.allSatisfy({ $0.isMatched }) {
                    if bestMoves == 0 || moves < bestMoves {
                        bestMoves = moves
                    }
                }
            } else {
                isBusy = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                    cards[firstIdx].isFaceUp = false
                    cards[idx].isFaceUp = false
                    isBusy = false
                }
            }
        } else {
            firstFlippedIndex = idx
        }
    }
}

// MARK: - SHARED SCORE CARD

private struct ScoreCardView: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.heavy))
                .foregroundStyle(color)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
