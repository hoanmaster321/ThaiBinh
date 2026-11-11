//
//  MiniGamesView.swift
//  Thái Bình (ErosionWQ)
//
//  Trung tâm Giải trí Thái Bình — 6 tựa game cảm ứng sinh động (100% Touch / Swipe / Drag, không dùng phím mũi tên)
//  Bản quyền © 2026 Thái Bình (hoanmaster321)
//

import SwiftUI
import Combine

// MARK: - DANH SÁCH TRÒ CHƠI TRUNG TÂM GIẢI TRÍ

struct MiniGamesView: View {
    @AppStorage("game_2048_best") private var best2048: Int = 0
    @AppStorage("game_snake_best") private var bestSnake: Int = 0
    @AppStorage("game_breaker_best") private var bestBreaker: Int = 0
    @AppStorage("game_mines_wins") private var minesWins: Int = 0
    @AppStorage("game_caro_wins") private var caroWins: Int = 0
    @AppStorage("game_memory_best") private var bestMemory: Int = 0

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .indigo, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                            .shadow(color: .purple.opacity(0.35), radius: 8, x: 0, y: 4)
                        Image(systemName: "gamecontroller.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Trung tâm Giải trí Thái Bình")
                            .font(.headline)
                        Text("6 tựa game cảm ứng sinh động — Vuốt, chạm & kéo trực tiếp mượt mà, hiệu ứng hạt Neon, tự động lưu kỷ lục.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                NavigationLink {
                    SnakeGameView()
                } label: {
                    MiniGameRow(
                        title: "Rắn Săn Mồi Neon",
                        subtitle: "Vuốt hoặc chạm trực tiếp trên sân để lái rắn ăn táo & sao vàng, hiệu ứng hạt nổ sinh động",
                        systemIcon: "scribble.variable",
                        gradient: [.green, .mint],
                        badge: "Kỷ lục: \(bestSnake)"
                    )
                }

                NavigationLink {
                    BrickBreakerGameView()
                } label: {
                    MiniGameRow(
                        title: "Phá Gạch Neon",
                        subtitle: "Kéo ngón tay điều khiển thanh đỡ, hứng vật phẩm nhân đôi bóng & tia lửa xuyên phá",
                        systemIcon: "sparkles.rectangle.stack.fill",
                        gradient: [.pink, .orange],
                        badge: "Kỷ lục: \(bestBreaker)"
                    )
                }

                NavigationLink {
                    Game2048View()
                } label: {
                    MiniGameRow(
                        title: "2048 Thái Bình",
                        subtitle: "Vuốt cảm ứng 4 hướng trên toàn màn hình, hiệu ứng nảy khối & nhân điểm Combo",
                        systemIcon: "square.grid.4x3.fill",
                        gradient: [.orange, .yellow],
                        badge: "Kỷ lục: \(best2048)"
                    )
                }

                NavigationLink {
                    MemoryMatchGameView()
                } label: {
                    MiniGameRow(
                        title: "Lật Hình 3D Trí Nhớ",
                        subtitle: "Lật thẻ bài 3D sống động, tích lũy chuỗi Combo và tìm cặp biểu tượng nhanh nhất",
                        systemIcon: "rectangle.grid.2x2.fill",
                        gradient: [.purple, .indigo],
                        badge: bestMemory > 0 ? "Tốt nhất: \(bestMemory) lượt" : "Mới"
                    )
                }

                NavigationLink {
                    MinesweeperGameView()
                } label: {
                    MiniGameRow(
                        title: "Dò Mìn Chiến Thuật",
                        subtitle: "Chạm để mở ô, nhấn giữ cắm cờ hoặc chạm đúp ô số để mở nhanh vùng lân cận",
                        systemIcon: "flame.fill",
                        gradient: [.red, .orange],
                        badge: "Thắng: \(minesWins)"
                    )
                }

                NavigationLink {
                    TicTacToeGameView()
                } label: {
                    MiniGameRow(
                        title: "Cờ Caro Neon (3×3 & 5×5)",
                        subtitle: "Đấu trí cùng AI thông minh hoặc 2 người chơi với hiệu ứng quân cờ phát sáng",
                        systemIcon: "grid",
                        gradient: [.blue, .cyan],
                        badge: "Thắng: \(caroWins)"
                    )
                }
            } header: {
                HeaderLabel("Trò chơi Cảm ứng", symbol: "hand.tap.fill")
            }

            Section {
                Button(role: .destructive) {
                    Haptic.shared.notify(.warning)
                    best2048 = 0
                    bestSnake = 0
                    bestBreaker = 0
                    minesWins = 0
                    caroWins = 0
                    bestMemory = 0
                } label: {
                    Label("Đặt lại toàn bộ kỷ lục điểm số", systemImage: "arrow.counterclockwise")
                }
            } header: {
                HeaderLabel("Dữ liệu kỷ lục", symbol: "trophy.fill")
            } footer: {
                Text("Thái Bình · Trung tâm Giải trí Cảm ứng phát triển bởi hoanmaster321")
            }
        }
        .navigationTitle("Giải trí")
    }
}

private struct MiniGameRow: View {
    let title: String
    let subtitle: String
    let systemIcon: String
    let gradient: [Color]
    let badge: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: (gradient.first ?? .blue).opacity(0.3), radius: 5, x: 0, y: 3)
                Image(systemName: systemIcon)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.body.weight(.semibold))
                    Spacer()
                    Text(badge)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background((gradient.first ?? .blue).opacity(0.14), in: Capsule())
                        .foregroundStyle(gradient.first ?? .blue)
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

// MARK: - HIỆU ỨNG HẠT NỔ & ĐIỂM BAY (PARTICLES & FLOATING TEXT)

private struct ParticleBurst: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var color: Color
    var text: String
}

private struct FloatingScoreBadge: View {
    let text: String
    let color: Color
    @State private var appear = false

    var body: some View {
        ZStack {
            ForEach(0..<6, id: \.self) { i in
                let angle = Double(i) * (.pi / 3.0)
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .offset(
                        x: appear ? CGFloat(cos(angle)) * 28 : 0,
                        y: appear ? CGFloat(sin(angle)) * 28 : 0
                    )
                    .opacity(appear ? 0 : 0.9)
            }
            Text(text)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(color)
                .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
                .offset(y: appear ? -26 : 0)
                .opacity(appear ? 0 : 1)
                .scaleEffect(appear ? 1.25 : 0.8)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.65)) {
                appear = true
            }
        }
    }
}

// MARK: - 1. RẮN SĂN MỒI NEON (VUỐT & CHẠM TRỰC TIẾP, KHÔNG MŨI TÊN)

struct SnakeGameView: View {
    private let gridSize = 16

    struct GridPoint: Equatable, Hashable {
        var x: Int
        var y: Int
    }

    enum Direction {
        case up, down, left, right
    }

    enum FoodKind {
        case apple      // +10đ
        case goldenStar // +30đ
        case lightning  // +20đ
    }

    @AppStorage("game_snake_best") private var bestScore: Int = 0
    @State private var snake: [GridPoint] = [
        GridPoint(x: 8, y: 8),
        GridPoint(x: 7, y: 8),
        GridPoint(x: 6, y: 8)
    ]
    @State private var food: GridPoint = GridPoint(x: 12, y: 8)
    @State private var foodKind: FoodKind = .apple
    @State private var direction: Direction = .right
    @State private var nextDirection: Direction = .right
    @State private var score: Int = 0
    @State private var comboCount: Int = 0
    @State private var isRunning: Bool = false
    @State private var isGameOver: Bool = false
    @State private var speedLevel: Int = 1 // 0: Thư giãn, 1: Chuẩn, 2: Siêu tốc
    @State private var foodPulse: Bool = false
    @State private var bursts: [ParticleBurst] = []
    @State private var touchOrigin: CGPoint? = nil
    @State private var touchCurrent: CGPoint? = nil

    private let timer = Timer.publish(every: 0.045, on: .main, in: .common).autoconnect()
    @State private var tickCounter: Int = 0

    private var ticksPerStep: Int {
        switch speedLevel {
        case 0: return 4 // ~0.18s
        case 2: return 2 // ~0.09s
        default: return 3 // ~0.135s
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Thanh điểm số & điều khiển nhanh
            HStack(spacing: 10) {
                ScoreCardView(title: "ĐIỂM SỐ", value: "\(score)", color: .green)
                ScoreCardView(title: "KỶ LỤC", value: "\(bestScore)", color: .mint)
                Button {
                    Haptic.shared.play(.light)
                    if isGameOver {
                        resetGame()
                        isRunning = true
                    } else {
                        isRunning.toggle()
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(isRunning ? "TẠM DỪNG" : "CHẠY")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.title3.weight(.heavy))
                            .foregroundStyle(.orange)
                    }
                    .frame(width: 82)
                    .padding(.vertical, 10)
                    .background(Color.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)

            Picker("Tốc độ", selection: $speedLevel) {
                Text("🐢 Thư giãn").tag(0)
                Text("⚡ Chuẩn").tag(1)
                Text("🔥 Siêu tốc").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Bàn cờ cảm ứng trực tiếp (Vuốt hoặc Chạm vào hướng muốn rẽ)
            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height)
                let cellSize = side / CGFloat(gridSize)

                ZStack {
                    // Nền sân đấu caro Neon tối
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.07, green: 0.11, blue: 0.15),
                                    Color(red: 0.04, green: 0.07, blue: 0.10)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(
                                    LinearGradient(colors: [.green.opacity(0.7), .mint.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: 2.5
                                )
                        )
                        .shadow(color: .green.opacity(0.2), radius: 12, x: 0, y: 6)

                    // Lưới caro mờ
                    Path { path in
                        for i in 1..<gridSize {
                            let pos = CGFloat(i) * cellSize
                            path.move(to: CGPoint(x: pos, y: 0))
                            path.addLine(to: CGPoint(x: pos, y: side))
                            path.move(to: CGPoint(x: 0, y: pos))
                            path.addLine(to: CGPoint(x: side, y: pos))
                        }
                    }
                    .stroke(Color.white.opacity(0.045), lineWidth: 1)

                    // Vẽ Mồi sinh động
                    ZStack {
                        Circle()
                            .fill(foodColor.opacity(0.28))
                            .frame(width: cellSize * (foodPulse ? 1.45 : 1.05), height: cellSize * (foodPulse ? 1.45 : 1.05))
                        Image(systemName: foodSymbol)
                            .font(.system(size: cellSize * 0.68, weight: .bold))
                            .foregroundStyle(foodColor)
                            .shadow(color: foodColor, radius: 6)
                            .scaleEffect(foodPulse ? 1.15 : 0.92)
                    }
                    .position(
                        x: (CGFloat(food.x) + 0.5) * cellSize,
                        y: (CGFloat(food.y) + 0.5) * cellSize
                    )
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: foodPulse)

                    // Vẽ Thân Rắn Gradient + Đầu Rắn có mắt
                    ForEach(Array(snake.enumerated().reversed()), id: \.offset) { idx, pt in
                        let ratio = Double(idx) / Double(max(1, snake.count - 1))
                        let segColor = Color(
                            hue: 0.36 + ratio * 0.14,
                            saturation: 0.88,
                            brightness: 0.95 - ratio * 0.25
                        )
                        let cx = (CGFloat(pt.x) + 0.5) * cellSize
                        let cy = (CGFloat(pt.y) + 0.5) * cellSize

                        ZStack {
                            RoundedRectangle(cornerRadius: idx == 0 ? cellSize * 0.38 : cellSize * 0.28, style: .continuous)
                                .fill(segColor)
                                .frame(
                                    width: cellSize * (idx == 0 ? 0.96 : max(0.62, 0.90 - CGFloat(ratio) * 0.22)),
                                    height: cellSize * (idx == 0 ? 0.96 : max(0.62, 0.90 - CGFloat(ratio) * 0.22))
                                )
                                .shadow(color: idx == 0 ? .green.opacity(0.7) : .clear, radius: 5)

                            // Vẽ 2 mắt trên đầu rắn
                            if idx == 0 {
                                HStack(spacing: cellSize * 0.22) {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: cellSize * 0.24, height: cellSize * 0.24)
                                        .overlay(Circle().fill(Color.black).frame(width: cellSize * 0.12, height: cellSize * 0.12))
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: cellSize * 0.24, height: cellSize * 0.24)
                                        .overlay(Circle().fill(Color.black).frame(width: cellSize * 0.12, height: cellSize * 0.12))
                                }
                                .rotationEffect(headAngle)
                            }
                        }
                        .position(x: cx, y: cy)
                        .animation(.linear(duration: 0.08), value: snake)
                    }

                    // Hiệu ứng nổ hạt & điểm cộng bay lên
                    ForEach(bursts) { burst in
                        FloatingScoreBadge(text: burst.text, color: burst.color)
                            .position(x: burst.x * cellSize, y: burst.y * cellSize)
                    }

                    // Vòng tròn cần gạt cảm ứng ảo khi giữ & kéo trên sân
                    if let origin = touchOrigin, let current = touchCurrent {
                        Circle()
                            .stroke(Color.white.opacity(0.25), lineWidth: 2)
                            .frame(width: 64, height: 64)
                            .position(origin)
                        Circle()
                            .fill(Color.green.opacity(0.55))
                            .frame(width: 28, height: 28)
                            .position(
                                x: origin.x + max(-28, min(28, current.x - origin.x)),
                                y: origin.y + max(-28, min(28, current.y - origin.y))
                            )
                    }

                    // Màn hình chờ / Kết thúc
                    if !isRunning || isGameOver {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay {
                                VStack(spacing: 14) {
                                    Image(systemName: isGameOver ? "flame.circle.fill" : "hand.draw.fill")
                                        .font(.system(size: 52))
                                        .foregroundStyle(isGameOver ? .red : .green)
                                        .shadow(color: (isGameOver ? Color.red : Color.green).opacity(0.4), radius: 8)
                                    Text(isGameOver ? "Va chạm! Điểm: \(score)" : (score > 0 ? "Đang tạm dừng" : "Chạm hoặc Vuốt để Lái Rắn"))
                                        .font(.title3.bold())
                                    Text("Vuốt theo hướng bất kỳ hoặc chạm vào phía trước đầu rắn để đổi hướng ngay lập tức.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 24)
                                    Button {
                                        Haptic.shared.play(.medium)
                                        if isGameOver {
                                            resetGame()
                                        }
                                        isRunning = true
                                    } label: {
                                        Label(isGameOver ? "Chơi ván mới" : "Chạm để Bắt đầu", systemImage: "play.fill")
                                            .font(.headline)
                                            .padding(.horizontal, 22)
                                            .padding(.vertical, 10)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.green)
                                }
                            }
                    }
                }
                .frame(width: side, height: side)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let dx = value.translation.width
                            let dy = value.translation.height
                            let dist = hypot(dx, dy)
                            if touchOrigin == nil {
                                touchOrigin = value.startLocation
                            }
                            touchCurrent = value.location
                            if dist >= 14 {
                                if abs(dx) > abs(dy) {
                                    changeDirection(dx > 0 ? .right : .left)
                                } else {
                                    changeDirection(dy > 0 ? .down : .up)
                                }
                                // Đặt lại tâm joystick ảo để người chơi đổi hướng liên tục mượt mà không cần nhấc tay
                                touchOrigin = value.location
                            }
                        }
                        .onEnded { value in
                            let dx = value.translation.width
                            let dy = value.translation.height
                            touchOrigin = nil
                            touchCurrent = nil
                            if hypot(dx, dy) < 14 {
                                // Chạm nhẹ (Tap-to-Steer): lái rắn về phía điểm chạm so với đầu rắn
                                steerTowardTap(at: value.location, cellSize: cellSize)
                            }
                        }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal)

            // Hướng dẫn cảm ứng ngắn gọn thay cho D-pad
            HStack(spacing: 8) {
                Image(systemName: "hand.point.up.left.fill")
                    .foregroundStyle(.green)
                Text("Cảm ứng toàn phần: Giữ & kéo ngón tay như Joystick hoặc chạm vào vị trí bất kỳ trên bàn cờ để rẽ hướng.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 6)
        }
        .navigationTitle("Rắn Săn Mồi Neon")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            foodPulse = true
        }
        .onReceive(timer) { _ in
            guard isRunning && !isGameOver else { return }
            tickCounter += 1
            if tickCounter >= ticksPerStep {
                tickCounter = 0
                stepSnake()
            }
        }
    }

    private var headAngle: Angle {
        switch direction {
        case .up: return .degrees(0)
        case .down: return .degrees(180)
        case .left: return .degrees(-90)
        case .right: return .degrees(90)
        }
    }

    private var foodSymbol: String {
        switch foodKind {
        case .apple: return "apple.logo"
        case .goldenStar: return "star.fill"
        case .lightning: return "bolt.fill"
        }
    }

    private var foodColor: Color {
        switch foodKind {
        case .apple: return .red
        case .goldenStar: return .yellow
        case .lightning: return .cyan
        }
    }

    private func steerTowardTap(at point: CGPoint, cellSize: CGFloat) {
        guard let head = snake.first else { return }
        if !isRunning && !isGameOver {
            isRunning = true
            return
        }
        let headX = (CGFloat(head.x) + 0.5) * cellSize
        let headY = (CGFloat(head.y) + 0.5) * cellSize
        let dx = point.x - headX
        let dy = point.y - headY

        switch direction {
        case .left, .right:
            changeDirection(dy < 0 ? .up : .down)
        case .up, .down:
            changeDirection(dx < 0 ? .left : .right)
        }
    }

    private func changeDirection(_ newDir: Direction) {
        switch (direction, newDir) {
        case (.up, .down), (.down, .up), (.left, .right), (.right, .left):
            return
        default:
            if nextDirection != newDir {
                Haptic.shared.play(.light, intensity: 0.55)
                nextDirection = newDir
            }
            if !isRunning && !isGameOver {
                isRunning = true
            }
        }
    }

    private func resetGame() {
        snake = [
            GridPoint(x: 8, y: 8),
            GridPoint(x: 7, y: 8),
            GridPoint(x: 6, y: 8)
        ]
        direction = .right
        nextDirection = .right
        score = 0
        comboCount = 0
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
            let roll = Int.random(in: 1...10)
            if roll == 10 {
                foodKind = .goldenStar
            } else if roll >= 8 {
                foodKind = .lightning
            } else {
                foodKind = .apple
            }
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

        if nextHead.x < 0 || nextHead.x >= gridSize || nextHead.y < 0 || nextHead.y >= gridSize || snake.dropLast().contains(nextHead) {
            Haptic.shared.notify(.error)
            isGameOver = true
            isRunning = false
            return
        }

        snake.insert(nextHead, at: 0)
        if nextHead == food {
            Haptic.shared.play(.medium)
            comboCount += 1
            let gained: Int
            switch foodKind {
            case .apple: gained = 10
            case .lightning: gained = 20
            case .goldenStar: gained = 30
            }
            score += gained
            if score > bestScore {
                bestScore = score
            }
            let burst = ParticleBurst(
                x: CGFloat(nextHead.x) + 0.5,
                y: CGFloat(nextHead.y) + 0.5,
                color: foodColor,
                text: "+\(gained)"
            )
            bursts.append(burst)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                bursts.removeAll { $0.id == burst.id }
            }
            spawnFood()
        } else {
            snake.removeLast()
        }
    }
}

// MARK: - 2. PHÁ GẠCH NEON (BRICK BREAKER — KÉO CẢM ỨNG TRỰC TIẾP)

struct BrickBreakerGameView: View {
    struct Brick: Identifiable {
        let id = UUID()
        var row: Int
        var col: Int
        var hp: Int
        var color: Color
        var powerUp: PowerUpKind?
    }

    enum PowerUpKind {
        case widePaddle
        case fireBall
        case bonusPoints
    }

    struct FallingPowerUp: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var kind: PowerUpKind
    }

    @AppStorage("game_breaker_best") private var bestScore: Int = 0
    @State private var paddleX: CGFloat = 0.5 // Tỷ lệ 0...1
    @State private var paddleWidthRatio: CGFloat = 0.26
    @State private var ballPos: CGPoint = CGPoint(x: 0.5, y: 0.78)
    @State private var ballVel: CGPoint = CGPoint(x: 0.0085, y: -0.0125)
    @State private var isFireBall: Bool = false
    @State private var bricks: [Brick] = []
    @State private var powerUps: [FallingPowerUp] = []
    @State private var bursts: [ParticleBurst] = []
    @State private var score: Int = 0
    @State private var lives: Int = 3
    @State private var level: Int = 1
    @State private var isRunning: Bool = false
    @State private var isGameOver: Bool = false

    private let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                ScoreCardView(title: "ĐIỂM SỐ", value: "\(score)", color: .pink)
                ScoreCardView(title: "KỶ LỤC", value: "\(bestScore)", color: .orange)
                ScoreCardView(title: "MẠNG", value: String(repeating: "❤️", count: max(0, lives)), color: .red)
            }
            .padding(.horizontal)

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                ZStack {
                    // Nền Vũ trụ Neon
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.08, green: 0.05, blue: 0.16),
                                    Color(red: 0.03, green: 0.03, blue: 0.08)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(
                                    LinearGradient(colors: [.pink.opacity(0.7), .orange.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: 2
                                )
                        )

                    // Vẽ các viên gạch Neon
                    ForEach(bricks) { brick in
                        let cols = 7
                        let spacing: CGFloat = 6
                        let totalSpacing = spacing * CGFloat(cols + 1)
                        let brickW = (w - totalSpacing) / CGFloat(cols)
                        let brickH: CGFloat = 22
                        let bx = spacing + CGFloat(brick.col) * (brickW + spacing) + brickW / 2
                        let by = 46 + CGFloat(brick.row) * (brickH + spacing) + brickH / 2

                        ZStack {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [brick.color, brick.color.opacity(0.65)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: brickW, height: brickH)
                                .shadow(color: brick.color.opacity(0.45), radius: 4)

                            if brick.hp > 1 {
                                Text("\(brick.hp)")
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                            } else if brick.powerUp != nil {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .position(x: bx, y: by)
                    }

                    // Vật phẩm rơi xuống
                    ForEach(powerUps) { item in
                        ZStack {
                            Circle()
                                .fill(powerUpColor(item.kind))
                                .frame(width: 26, height: 26)
                                .shadow(color: powerUpColor(item.kind), radius: 6)
                            Image(systemName: powerUpIcon(item.kind))
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .position(x: item.x * w, y: item.y * h)
                    }

                    // Hiệu ứng nổ điểm
                    ForEach(bursts) { burst in
                        FloatingScoreBadge(text: burst.text, color: burst.color)
                            .position(x: burst.x * w, y: burst.y * h)
                    }

                    // Quả bóng năng lượng
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: isFireBall ? [.yellow, .orange, .red] : [.white, .cyan, .blue],
                                center: .center,
                                startRadius: 1,
                                endRadius: 10
                            )
                        )
                        .frame(width: 18, height: 18)
                        .shadow(color: isFireBall ? .orange : .cyan, radius: 8)
                        .position(x: ballPos.x * w, y: ballPos.y * h)

                    // Thanh đỡ cảm ứng (Paddle)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: isFireBall ? [.orange, .red] : [.pink, .purple, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: w * paddleWidthRatio, height: 16)
                        .shadow(color: .pink.opacity(0.6), radius: 8)
                        .position(x: paddleX * w, y: h * 0.88)

                    // Chỉ dẫn kéo ngón tay dưới thanh đỡ
                    Text("⟷ Chạm & kéo ngang để điều khiển thanh đỡ ⟷")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                        .position(x: w * 0.5, y: h * 0.95)

                    if !isRunning {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay {
                                VStack(spacing: 14) {
                                    Image(systemName: isGameOver ? "Burst" : "sparkles.rectangle.stack.fill")
                                        .font(.system(size: 48))
                                        .foregroundStyle(.pink)
                                    Text(isGameOver ? "Kết thúc! Điểm: \(score)" : "Phá Gạch Neon — Màn \(level)")
                                        .font(.title3.bold())
                                    Text("Chạm và trượt ngón tay trực tiếp trên màn hình để đỡ bóng và hứng vật phẩm cường hóa.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 28)
                                    Button {
                                        Haptic.shared.play(.medium)
                                        if isGameOver || bricks.isEmpty {
                                            startNewGame()
                                        }
                                        isRunning = true
                                    } label: {
                                        Label(isGameOver ? "Chơi lại từ đầu" : "Chạm để Phóng bóng", systemImage: "play.fill")
                                            .font(.headline)
                                            .padding(.horizontal, 22)
                                            .padding(.vertical, 10)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.pink)
                                }
                            }
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let halfPaddle = paddleWidthRatio / 2
                            let normalizedX = value.location.x / max(1, w)
                            paddleX = min(1.0 - halfPaddle, max(halfPaddle, normalizedX))
                            if !isRunning && !isGameOver {
                                isRunning = true
                            }
                        }
                )
                .onReceive(timer) { _ in
                    guard isRunning && !isGameOver else { return }
                    stepPhysics(width: w, height: h)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .navigationTitle("Phá Gạch Neon")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if bricks.isEmpty {
                startNewGame()
            }
        }
    }

    private func powerUpColor(_ kind: PowerUpKind) -> Color {
        switch kind {
        case .widePaddle: return .green
        case .fireBall: return .orange
        case .bonusPoints: return .yellow
        }
    }

    private func powerUpIcon(_ kind: PowerUpKind) -> String {
        switch kind {
        case .widePaddle: return "arrow.left.and.right"
        case .fireBall: return "flame.fill"
        case .bonusPoints: return "star.fill"
        }
    }

    private func startNewGame() {
        score = 0
        lives = 3
        level = 1
        isGameOver = false
        setupLevel()
    }

    private func setupLevel() {
        paddleWidthRatio = 0.26
        isFireBall = false
        powerUps.removeAll()
        ballPos = CGPoint(x: paddleX, y: 0.82)
        let speedBoost = CGFloat(min(level - 1, 4)) * 0.0012
        ballVel = CGPoint(x: (Bool.random() ? 1 : -1) * (0.0085 + speedBoost), y: -(0.0125 + speedBoost))

        let palette: [Color] = [.pink, .orange, .yellow, .green, .cyan, .purple]
        var newBricks: [Brick] = []
        let rows = min(5 + (level - 1), 7)
        for r in 0..<rows {
            for c in 0..<7 {
                let hp = (r == 0 && level >= 1) ? 2 : 1
                var pUp: PowerUpKind? = nil
                let roll = Int.random(in: 1...12)
                if roll == 1 { pUp = .widePaddle }
                else if roll == 2 { pUp = .fireBall }
                else if roll == 3 { pUp = .bonusPoints }

                newBricks.append(
                    Brick(
                        row: r,
                        col: c,
                        hp: hp,
                        color: palette[r % palette.count],
                        powerUp: pUp
                    )
                )
            }
        }
        bricks = newBricks
    }

    private func stepPhysics(width w: CGFloat, height h: CGFloat) {
        guard w > 10 && h > 10 else { return }
        var nextPos = CGPoint(x: ballPos.x + ballVel.x, y: ballPos.y + ballVel.y)

        // Va chạm tường trái / phải / trên
        if nextPos.x <= 0.03 {
            nextPos.x = 0.03
            ballVel.x = abs(ballVel.x)
        } else if nextPos.x >= 0.97 {
            nextPos.x = 0.97
            ballVel.x = -abs(ballVel.x)
        }
        if nextPos.y <= 0.03 {
            nextPos.y = 0.03
            ballVel.y = abs(ballVel.y)
        }

        // Va chạm thanh đỡ (Paddle ở y = 0.88)
        let halfPaddle = paddleWidthRatio / 2
        if ballVel.y > 0 && nextPos.y >= 0.855 && nextPos.y <= 0.895 && abs(nextPos.x - paddleX) <= halfPaddle + 0.025 {
            Haptic.shared.play(.light, intensity: 0.65)
            let hitOffset = (nextPos.x - paddleX) / halfPaddle // -1 ... 1
            ballVel.x = hitOffset * 0.0135
            ballVel.y = -abs(ballVel.y)
            nextPos.y = 0.854
        }

        // Va chạm gạch
        let cols = 7
        let spacing: CGFloat = 6
        let totalSpacing = spacing * CGFloat(cols + 1)
        let brickW = (w - totalSpacing) / CGFloat(cols)
        let brickH: CGFloat = 22

        for idx in bricks.indices.reversed() {
            let b = bricks[idx]
            let bx = (spacing + CGFloat(b.col) * (brickW + spacing) + brickW / 2) / w
            let by = (46 + CGFloat(b.row) * (brickH + spacing) + brickH / 2) / h
            let halfBW = (brickW / 2) / w + 0.018
            let halfBH = (brickH / 2) / h + 0.016

            if abs(nextPos.x - bx) <= halfBW && abs(nextPos.y - by) <= halfBH {
                Haptic.shared.play(.light)
                if !isFireBall {
                    ballVel.y = -ballVel.y
                }
                bricks[idx].hp -= (isFireBall ? 2 : 1)
                if bricks[idx].hp <= 0 {
                    let removed = bricks.remove(at: idx)
                    score += 15
                    if score > bestScore { bestScore = score }
                    if let kind = removed.powerUp {
                        powerUps.append(FallingPowerUp(x: bx, y: by, kind: kind))
                    }
                    let burst = ParticleBurst(x: bx, y: by, color: removed.color, text: "+15")
                    bursts.append(burst)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        bursts.removeAll { $0.id == burst.id }
                    }
                }
                break
            }
        }

        // Cập nhật vật phẩm rơi
        for i in powerUps.indices.reversed() {
            powerUps[i].y += 0.0055
            if abs(powerUps[i].y - 0.88) <= 0.035 && abs(powerUps[i].x - paddleX) <= halfPaddle + 0.03 {
                Haptic.shared.notify(.success)
                let item = powerUps.remove(at: i)
                switch item.kind {
                case .widePaddle:
                    paddleWidthRatio = min(0.42, paddleWidthRatio + 0.08)
                case .fireBall:
                    isFireBall = true
                case .bonusPoints:
                    score += 50
                    if score > bestScore { bestScore = score }
                }
            } else if powerUps[i].y > 1.0 {
                powerUps.remove(at: i)
            }
        }

        // Kiểm tra qua màn
        if bricks.isEmpty {
            Haptic.shared.notify(.success)
            level += 1
            isRunning = false
            setupLevel()
            return
        }

        // Rơi bóng xuống đáy
        if nextPos.y >= 0.98 {
            lives -= 1
            Haptic.shared.notify(.warning)
            if lives <= 0 {
                isGameOver = true
                isRunning = false
            } else {
                isRunning = false
                paddleWidthRatio = 0.26
                isFireBall = false
                ballPos = CGPoint(x: paddleX, y: 0.82)
                ballVel = CGPoint(x: 0.0085, y: -0.0125)
            }
            return
        }

        ballPos = nextPos
    }
}

// MARK: - 3. GAME 2048 THÁI BÌNH (VUỐT CẢM ỨNG TOÀN MÀN HÌNH, HIỆU ỨNG NẢY KHỐI)

struct Game2048View: View {
    @AppStorage("game_2048_best") private var bestScore: Int = 0
    @State private var board: [[Int]] = Array(repeating: Array(repeating: 0, count: 4), count: 4)
    @State private var mergedCells: Set<String> = []
    @State private var spawnedCell: String? = nil
    @State private var previousBoard: [[Int]]? = nil
    @State private var previousScore: Int = 0
    @State private var score: Int = 0
    @State private var lastGained: Int = 0
    @State private var comboStreak: Int = 0
    @State private var isGameOver: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            // Điểm số & Kỷ lục
            HStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    ScoreCardView(title: "ĐIỂM HIỆN TẠI", value: "\(score)", color: .orange)
                    if lastGained > 0 {
                        Text("+\(lastGained)")
                            .font(.caption.weight(.black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.orange, in: Capsule())
                            .offset(x: -8, y: 6)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                ScoreCardView(title: "KỶ LỤC", value: "\(bestScore)", color: .blue)
            }
            .padding(.horizontal)

            if comboStreak >= 2 {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("Chuỗi ghép liên tiếp Combo x\(comboStreak)!")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.14), in: Capsule())
                .transition(.scale)
            }

            // Bàn cờ 4x4 cảm ứng vuốt trực tiếp
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.systemGray5))
                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 4)

                VStack(spacing: 10) {
                    ForEach(0..<4, id: \.self) { r in
                        HStack(spacing: 10) {
                            ForEach(0..<4, id: \.self) { c in
                                let key = "\(r)-\(c)"
                                Tile2048Cell(
                                    value: board[r][c],
                                    isMerged: mergedCells.contains(key),
                                    isSpawned: spawnedCell == key
                                )
                            }
                        }
                    }
                }
                .padding(12)

                if isGameOver {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            VStack(spacing: 14) {
                                Image(systemName: "flag.checkered.2.crossed")
                                    .font(.system(size: 46))
                                    .foregroundStyle(.orange)
                                Text("Hết nước đi!")
                                    .font(.title2.bold())
                                Text("Tổng điểm đạt được: \(score)")
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

            // Nút Hoàn tác & Ván mới
            HStack(spacing: 14) {
                Button {
                    undoMove()
                } label: {
                    Label("Hoàn tác bước trước", systemImage: "arrow.uturn.backward")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .disabled(previousBoard == nil)

                Button {
                    startNewGame()
                } label: {
                    Label("Ván mới", systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            .padding(.horizontal)

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                Image(systemName: "hand.draw.fill")
                    .foregroundStyle(.orange)
                Text("Vuốt nhẹ Lên, Xuống, Trái, Phải ở bất kỳ đâu trên màn hình để dồn các khối số.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .padding(.top, 8)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 16)
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
        mergedCells = []
        score = 0
        lastGained = 0
        comboStreak = 0
        isGameOver = false
        spawnTile()
        spawnTile()
    }

    private func undoMove() {
        guard let prev = previousBoard else { return }
        Haptic.shared.play(.light)
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            board = prev
            score = previousScore
            previousBoard = nil
            isGameOver = false
        }
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
        spawnedCell = "\(chosen.0)-\(chosen.1)"
    }

    private func slideAndMerge(_ line: [Int]) -> ([Int], Int, Set<Int>) {
        let nonZero = line.filter { $0 != 0 }
        var merged: [Int] = []
        var mergedIndices: Set<Int> = []
        var gained = 0
        var i = 0
        while i < nonZero.count {
            if i + 1 < nonZero.count && nonZero[i] == nonZero[i + 1] {
                let val = nonZero[i] * 2
                mergedIndices.insert(merged.count)
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
        return (merged, gained, mergedIndices)
    }

    private func move(_ dir: Direction) {
        guard !isGameOver else { return }
        let savedBoard = board
        let savedScore = score
        var totalGained = 0
        var newMerged: Set<String> = []
        var newBoard = board

        switch dir {
        case .left:
            for r in 0..<4 {
                let (row, gained, idxs) = slideAndMerge(newBoard[r])
                newBoard[r] = row
                totalGained += gained
                for c in idxs { newMerged.insert("\(r)-\(c)") }
            }
        case .right:
            for r in 0..<4 {
                let (row, gained, idxs) = slideAndMerge(newBoard[r].reversed())
                newBoard[r] = row.reversed()
                totalGained += gained
                for c in idxs { newMerged.insert("\(r)-\(3 - c)") }
            }
        case .up:
            for c in 0..<4 {
                let col = (0..<4).map { newBoard[$0][c] }
                let (mergedCol, gained, idxs) = slideAndMerge(col)
                for r in 0..<4 { newBoard[r][c] = mergedCol[r] }
                totalGained += gained
                for r in idxs { newMerged.insert("\(r)-\(c)") }
            }
        case .down:
            for c in 0..<4 {
                let col = (0..<4).map { newBoard[$0][c] }.reversed()
                let (mergedCol, gained, idxs) = slideAndMerge(Array(col))
                let finalCol = Array(mergedCol.reversed())
                for r in 0..<4 { newBoard[r][c] = finalCol[r] }
                totalGained += gained
                for r in idxs { newMerged.insert("\(3 - r)-\(c)") }
            }
        }

        if newBoard != savedBoard {
            Haptic.shared.play(totalGained > 0 ? .medium : .light)
            previousBoard = savedBoard
            previousScore = savedScore
            withAnimation(.spring(response: 0.24, dampingFraction: 0.76)) {
                board = newBoard
                mergedCells = newMerged
                lastGained = totalGained
                if totalGained > 0 {
                    comboStreak += 1
                } else {
                    comboStreak = 0
                }
                score += totalGained
                if score > bestScore {
                    bestScore = score
                }
                spawnTile()
            }
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
    let isMerged: Bool
    let isSpawned: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: tileGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: value >= 8 ? tileGradient.first!.opacity(0.35) : .clear, radius: 5, x: 0, y: 3)

            if value > 0 {
                Text("\(value)")
                    .font(.system(size: value >= 1024 ? 20 : 25, weight: .black, design: .rounded))
                    .foregroundStyle(value <= 4 ? Color.primary : Color.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        }
        .scaleEffect(isMerged ? 1.09 : (isSpawned ? 1.03 : 1.0))
        .aspectRatio(1, contentMode: .fit)
    }

    private var tileGradient: [Color] {
        switch value {
        case 0: return [Color(.systemGray4).opacity(0.55), Color(.systemGray4).opacity(0.4)]
        case 2: return [Color.orange.opacity(0.28), Color.orange.opacity(0.18)]
        case 4: return [Color.orange.opacity(0.48), Color.orange.opacity(0.32)]
        case 8: return [.orange, Color(red: 0.98, green: 0.55, blue: 0.18)]
        case 16: return [Color(red: 0.98, green: 0.45, blue: 0.20), .red]
        case 32: return [.red, .pink]
        case 64: return [.pink, .purple]
        case 128: return [.yellow, .orange]
        case 256: return [.green, .mint]
        case 512: return [.teal, .blue]
        case 1024: return [.blue, .indigo]
        default: return [.purple, .pink]
        }
    }
}

// MARK: - 4. LẬT HÌNH 3D TRÍ NHỚ (3D FLIP + COMBO STREAK)

struct MemoryMatchGameView: View {
    struct MemoryCard: Identifiable {
        let id = UUID()
        let icon: String
        let color: Color
        var isFaceUp: Bool = false
        var isMatched: Bool = false
    }

    private let iconPairs: [(String, Color)] = [
        ("bolt.fill", .yellow),
        ("flame.fill", .red),
        ("star.fill", .orange),
        ("heart.fill", .pink),
        ("moon.stars.fill", .indigo),
        ("leaf.fill", .green),
        ("crown.fill", .purple),
        ("sparkles", .cyan)
    ]

    @AppStorage("game_memory_best") private var bestMoves: Int = 0
    @State private var cards: [MemoryCard] = []
    @State private var firstFlippedIndex: Int? = nil
    @State private var moves: Int = 0
    @State private var combo: Int = 0
    @State private var isBusy: Bool = false

    private var isAllMatched: Bool {
        !cards.isEmpty && cards.allSatisfy { $0.isMatched }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 10) {
                ScoreCardView(title: "SỐ LƯỢT LẬT", value: "\(moves)", color: .purple)
                ScoreCardView(title: "COMBO", value: "x\(max(1, combo))", color: .orange)
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
                            // Mặt sau thẻ
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [.purple, .indigo],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Image(systemName: "sparkle")
                                        .font(.title2.bold())
                                        .foregroundStyle(.white.opacity(0.8))
                                )
                                .opacity(card.isFaceUp || card.isMatched ? 0 : 1)

                            // Mặt trước thẻ
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(card.isMatched ? Color.green : card.color.opacity(0.6), lineWidth: 2.5)
                                )
                                .overlay(
                                    Image(systemName: card.icon)
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundStyle(card.isMatched ? .green : card.color)
                                        .scaleEffect(card.isMatched ? 1.15 : 1.0)
                                )
                                .opacity(card.isFaceUp || card.isMatched ? 1 : 0)
                                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                        }
                        .aspectRatio(1, contentMode: .fit)
                        .rotation3DEffect(
                            .degrees(card.isFaceUp || card.isMatched ? 180 : 0),
                            axis: (x: 0, y: 1, z: 0),
                            perspective: 0.6
                        )
                        .shadow(color: (card.isMatched ? Color.green : Color.purple).opacity(0.22), radius: 5, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal)

            if isAllMatched {
                HStack(spacing: 8) {
                    Image(systemName: "party.popper.fill")
                        .foregroundStyle(.orange)
                    Text("Hoàn thành xuất sắc chỉ sau \(moves) lượt lật!")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                }
                .padding(.vertical, 6)
            }

            Button {
                setupNewGame()
            } label: {
                Label("Trộn ván bài mới", systemImage: "shuffle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .padding(.horizontal)

            Spacer(minLength: 0)
        }
        .padding(.top, 8)
        .navigationTitle("Lật Hình 3D Trí Nhớ")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if cards.isEmpty {
                setupNewGame()
            }
        }
    }

    private func setupNewGame() {
        Haptic.shared.play(.medium)
        let paired = (iconPairs + iconPairs).shuffled()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
            cards = paired.map { MemoryCard(icon: $0.0, color: $0.1) }
            firstFlippedIndex = nil
            moves = 0
            combo = 0
            isBusy = false
        }
    }

    private func flipCard(at idx: Int) {
        guard !isBusy, !cards[idx].isFaceUp, !cards[idx].isMatched else { return }
        Haptic.shared.play(.light)
        withAnimation(.spring(response: 0.32, dampingFraction: 0.75)) {
            cards[idx].isFaceUp = true
        }

        if let firstIdx = firstFlippedIndex {
            moves += 1
            firstFlippedIndex = nil
            if cards[firstIdx].icon == cards[idx].icon {
                Haptic.shared.notify(.success)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                    combo += 1
                    cards[firstIdx].isMatched = true
                    cards[idx].isMatched = true
                }
                if cards.allSatisfy({ $0.isMatched }) {
                    if bestMoves == 0 || moves < bestMoves {
                        bestMoves = moves
                    }
                }
            } else {
                combo = 0
                isBusy = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        cards[firstIdx].isFaceUp = false
                        cards[idx].isFaceUp = false
                    }
                    isBusy = false
                }
            }
        } else {
            firstFlippedIndex = idx
        }
    }
}

// MARK: - 5. DÒ MÌN CHIẾN THUẬT (CHẠM MỞ NHANH CHORD-TAP & ĐỒNG HỒ)

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
    @State private var elapsedSeconds: Int = 0
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    enum GameState {
        case playing, won, lost
    }

    private var flagsPlaced: Int {
        grid.flatMap { $0 }.filter { $0.isFlagged }.count
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                ScoreCardView(title: "MÌN CÒN LẠI", value: "\(max(0, totalMines - flagsPlaced))", color: .red)
                ScoreCardView(title: "THỜI GIAN", value: "\(elapsedSeconds)s", color: .orange)
                ScoreCardView(title: "THẮNG", value: "\(totalWins)", color: .green)
            }
            .padding(.horizontal)

            Picker("Chế độ chạm", selection: $flagMode) {
                Text("⛏️ Chạm Mở ô").tag(false)
                Text("🚩 Chạm Cắm cờ").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            VStack(spacing: 5) {
                ForEach(0..<rows, id: \.self) { r in
                    HStack(spacing: 5) {
                        ForEach(0..<cols, id: \.self) { c in
                            MineCellView(cell: grid[r][c])
                                .onTapGesture {
                                    handleTap(r: r, c: c)
                                }
                                .onLongPressGesture(minimumDuration: 0.25) {
                                    toggleFlag(r: r, c: c)
                                }
                        }
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.horizontal)

            if gameState != .playing {
                HStack(spacing: 10) {
                    Image(systemName: gameState == .won ? "trophy.fill" : "flame.fill")
                        .foregroundStyle(gameState == .won ? .yellow : .red)
                    Text(gameState == .won ? "Phá đảo bãi mìn trong \(elapsedSeconds) giây!" : "Bùm! Bạn đã chạm phải mìn!")
                        .font(.subheadline.bold())
                }
                .padding(10)
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
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .padding(.horizontal)

            Text("Mẹo: Nhấn giữ để cắm cờ, hoặc chạm vào ô số đã cắm đủ cờ xung quanh để mở nhanh toàn bộ vùng lân cận!")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer(minLength: 0)
        }
        .padding(.top, 8)
        .navigationTitle("Dò Mìn Chiến Thuật")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { _ in
            if gameState == .playing && !isFirstTap {
                elapsedSeconds += 1
            }
        }
    }

    private func resetBoard() {
        Haptic.shared.play(.medium)
        withAnimation(.easeInOut(duration: 0.2)) {
            grid = Array(repeating: Array(repeating: Cell(), count: cols), count: rows)
            isFirstTap = true
            elapsedSeconds = 0
            gameState = .playing
        }
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

        // Nếu chạm vào ô số đã mở và đã cắm đủ cờ xung quanh -> Mở nhanh (Chord Tap)
        if grid[r][c].isRevealed && grid[r][c].neighborMines > 0 {
            chordReveal(r: r, c: c)
            return
        }

        if flagMode {
            toggleFlag(r: r, c: c)
            return
        }
        guard !grid[r][c].isFlagged, !grid[r][c].isRevealed else { return }

        if isFirstTap {
            isFirstTap = false
            elapsedSeconds = 0
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
        withAnimation(.easeOut(duration: 0.18)) {
            revealDFS(r: r, c: c)
        }
        checkWin()
    }

    private func chordReveal(r: Int, c: Int) {
        var flagCount = 0
        for dr in -1...1 {
            for dc in -1...1 {
                let nr = r + dr, nc = c + dc
                if nr >= 0 && nr < rows && nc >= 0 && nc < cols && grid[nr][nc].isFlagged {
                    flagCount += 1
                }
            }
        }
        guard flagCount == grid[r][c].neighborMines else { return }
        Haptic.shared.play(.light)
        for dr in -1...1 {
            for dc in -1...1 {
                let nr = r + dr, nc = c + dc
                if nr >= 0 && nr < rows && nc >= 0 && nc < cols && !grid[nr][nc].isFlagged && !grid[nr][nc].isRevealed {
                    if grid[nr][nc].isMine {
                        Haptic.shared.notify(.error)
                        for row in 0..<rows {
                            for col in 0..<cols where grid[row][col].isMine {
                                grid[row][col].isRevealed = true
                            }
                        }
                        gameState = .lost
                        return
                    }
                    revealDFS(r: nr, c: nc)
                }
            }
        }
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
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: cell.isRevealed
                            ? [Color(.systemBackground), Color(.systemBackground)]
                            : [Color.blue.opacity(0.32), Color.indigo.opacity(0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if cell.isRevealed {
                if cell.isMine {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.red)
                        .shadow(color: .red, radius: 4)
                } else if cell.neighborMines > 0 {
                    Text("\(cell.neighborMines)")
                        .font(.system(size: 16, weight: .black, design: .rounded))
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

// MARK: - 6. CỜ CARO NEON (3x3 & 5x5)

struct TicTacToeGameView: View {
    @AppStorage("game_caro_wins") private var xWins: Int = 0
    @State private var oWins: Int = 0
    @State private var boardSize: Int = 5
    @State private var vsAI: Bool = true
    @State private var cells: [String] = Array(repeating: "", count: 25)
    @State private var lastMoveIndex: Int? = nil
    @State private var isXTurn: Bool = true
    @State private var winner: String? = nil
    @State private var winningIndices: Set<Int> = []

    private var winLength: Int {
        boardSize == 3 ? 3 : 4
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                ScoreCardView(title: "NGƯỜI CHƠI (X)", value: "\(xWins)", color: .blue)
                ScoreCardView(title: vsAI ? "MÁY AI (O)" : "NGƯỜI CHƠI 2 (O)", value: "\(oWins)", color: .pink)
            }
            .padding(.horizontal)

            HStack(spacing: 10) {
                Picker("Chế độ", selection: $vsAI) {
                    Text("🤖 Đấu với Máy").tag(true)
                    Text("👥 2 Người").tag(false)
                }
                .pickerStyle(.segmented)
                .onChange(of: vsAI) { _, _ in resetGame() }

                Picker("Bàn cờ", selection: $boardSize) {
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
                .foregroundStyle(winner == "X" ? .blue : (winner == "O" ? .pink : .primary))

            VStack(spacing: 7) {
                ForEach(0..<boardSize, id: \.self) { r in
                    HStack(spacing: 7) {
                        ForEach(0..<boardSize, id: \.self) { c in
                            let idx = r * boardSize + c
                            let val = idx < cells.count ? cells[idx] : ""
                            let isWinCell = winningIndices.contains(idx)
                            let isLastMove = lastMoveIndex == idx

                            Button {
                                playerTap(idx)
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(isWinCell ? Color.green.opacity(0.28) : Color(.systemBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(
                                                    isWinCell ? Color.green : (isLastMove ? Color.orange.opacity(0.8) : Color.clear),
                                                    lineWidth: 2.5
                                                )
                                        )

                                    if !val.isEmpty {
                                        Text(val)
                                            .font(.system(size: boardSize == 3 ? 40 : 28, weight: .black, design: .rounded))
                                            .foregroundStyle(val == "X" ? Color.blue : Color.pink)
                                            .shadow(color: (val == "X" ? Color.blue : Color.pink).opacity(0.45), radius: 6)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }
                                .aspectRatio(1, contentMode: .fit)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal)

            Button {
                resetGame()
            } label: {
                Label("Ván mới", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)

            Text(boardSize == 5 ? "Luật 5×5: Xếp được 4 quân liên tiếp (ngang, dọc, chéo) trước sẽ chiến thắng." : "Luật 3×3: Xếp được 3 quân liên tiếp trước sẽ chiến thắng.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer(minLength: 0)
        }
        .padding(.top, 8)
        .navigationTitle("Cờ Caro Neon")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statusTitle: String {
        if let w = winner {
            if w == "Draw" { return "⚖️ Ván đấu Hòa!" }
            if w == "X" { return "🎉 Người chơi X chiến thắng!" }
            return vsAI ? "🤖 Máy (O) chiến thắng!" : "🎉 Người chơi O chiến thắng!"
        }
        return isXTurn ? "Lượt của X (Chạm vào ô trống)" : (vsAI ? "Máy đang tính nước đi..." : "Lượt của O (Chạm vào ô trống)")
    }

    private func resetGame() {
        Haptic.shared.play(.light)
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            cells = Array(repeating: "", count: boardSize * boardSize)
            lastMoveIndex = nil
            isXTurn = true
            winner = nil
            winningIndices = []
        }
    }

    private func playerTap(_ idx: Int) {
        guard winner == nil, idx < cells.count, cells[idx].isEmpty else { return }
        if vsAI && !isXTurn { return }

        Haptic.shared.play(.light)
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            cells[idx] = isXTurn ? "X" : "O"
            lastMoveIndex = idx
        }

        if evaluateBoard() { return }

        isXTurn.toggle()

        if vsAI && !isXTurn {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
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
            if findWinningLine(for: "O", length: winLength) != nil {
                Haptic.shared.play(.medium)
                lastMoveIndex = idx
                _ = evaluateBoard()
                isXTurn = true
                return
            }
            cells[idx] = ""
        }

        // 2. Chặn nước thắng ngay của X
        for idx in emptyIndices {
            cells[idx] = "X"
            if findWinningLine(for: "X", length: winLength) != nil {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    cells[idx] = "O"
                    lastMoveIndex = idx
                }
                Haptic.shared.play(.light)
                _ = evaluateBoard()
                isXTurn = true
                return
            }
            cells[idx] = ""
        }

        // 3. Trên bàn 5x5, chặn chuỗi 3 của X hoặc tạo chuỗi 3 cho O
        if boardSize == 5 {
            for idx in emptyIndices {
                cells[idx] = "X"
                if findWinningLine(for: "X", length: 3) != nil {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        cells[idx] = "O"
                        lastMoveIndex = idx
                    }
                    Haptic.shared.play(.light)
                    _ = evaluateBoard()
                    isXTurn = true
                    return
                }
                cells[idx] = ""
            }
        }

        // 4. Ưu tiên ô trung tâm hoặc sát nước vừa đánh
        let center = (boardSize * boardSize) / 2
        let chosen: Int
        if cells[center].isEmpty {
            chosen = center
        } else {
            chosen = emptyIndices.randomElement()!
        }

        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            cells[chosen] = "O"
            lastMoveIndex = chosen
        }
        Haptic.shared.play(.light)
        _ = evaluateBoard()
        isXTurn = true
    }

    private func evaluateBoard() -> Bool {
        if let line = findWinningLine(for: "X", length: winLength) {
            Haptic.shared.notify(.success)
            winner = "X"
            winningIndices = Set(line)
            xWins += 1
            return true
        }
        if let line = findWinningLine(for: "O", length: winLength) {
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

    private func findWinningLine(for symbol: String, length: Int) -> [Int]? {
        let directions = [(0, 1), (1, 0), (1, 1), (1, -1)]
        for r in 0..<boardSize {
            for c in 0..<boardSize {
                for (dr, dc) in directions {
                    var indices: [Int] = []
                    for step in 0..<length {
                        let nr = r + dr * step
                        let nc = c + dc * step
                        if nr >= 0 && nr < boardSize && nc >= 0 && nc < boardSize {
                            let idx = nr * boardSize + nc
                            if idx < cells.count && cells[idx] == symbol {
                                indices.append(idx)
                            }
                        }
                    }
                    if indices.count == length {
                        return indices
                    }
                }
            }
        }
        return nil
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
                .lineLimit(1)
            Text(value)
                .font(.title3.weight(.heavy))
                .foregroundStyle(color)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
