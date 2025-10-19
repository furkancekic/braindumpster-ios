import SwiftUI

/// Confetti animation view for celebrating task completions
struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    let pieceCount: Int

    init(pieceCount: Int = 50) {
        self.pieceCount = pieceCount
    }

    var body: some View {
        ZStack {
            ForEach(confettiPieces) { piece in
                ConfettiPieceView(piece: piece)
            }
        }
        .onAppear {
            generateConfetti()
        }
    }

    private func generateConfetti() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        for i in 0..<pieceCount {
            let randomX = CGFloat.random(in: 0...screenWidth)
            let randomDelay = Double.random(in: 0...0.3)
            let randomDuration = Double.random(in: 1.5...2.5)
            let randomRotation = Double.random(in: 0...360)
            let randomColor = ConfettiColor.allCases.randomElement()!
            let randomShape = ConfettiShape.allCases.randomElement()!

            let piece = ConfettiPiece(
                id: i,
                x: randomX,
                y: -20,
                targetY: screenHeight + 50,
                color: randomColor,
                shape: randomShape,
                rotation: randomRotation,
                duration: randomDuration,
                delay: randomDelay
            )

            confettiPieces.append(piece)
        }
    }
}

// MARK: - Confetti Piece View
struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    @State private var yPosition: CGFloat = -20
    @State private var rotation: Double = 0
    @State private var xOffset: CGFloat = 0
    @State private var opacity: Double = 1.0

    var body: some View {
        piece.shape.shape
            .fill(piece.color.color)
            .frame(width: 10, height: 10)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .position(x: piece.x + xOffset, y: yPosition)
            .onAppear {
                withAnimation(
                    .easeIn(duration: piece.duration)
                    .delay(piece.delay)
                ) {
                    yPosition = piece.targetY
                    rotation = piece.rotation + 720 // Multiple rotations
                    opacity = 0.0
                }

                // Add horizontal drift
                withAnimation(
                    .easeInOut(duration: piece.duration * 0.6)
                    .repeatForever(autoreverses: true)
                    .delay(piece.delay)
                ) {
                    xOffset = CGFloat.random(in: -30...30)
                }
            }
    }
}

// MARK: - Confetti Models
struct ConfettiPiece: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let targetY: CGFloat
    let color: ConfettiColor
    let shape: ConfettiShape
    let rotation: Double
    let duration: Double
    let delay: Double
}

enum ConfettiColor: CaseIterable {
    case blue, green, yellow, red, purple, pink, orange

    var color: Color {
        switch self {
        case .blue:
            return Color(red: 0.4, green: 0.75, blue: 0.95)
        case .green:
            return Color(red: 0.2, green: 0.8, blue: 0.4)
        case .yellow:
            return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .red:
            return Color(red: 1.0, green: 0.3, blue: 0.3)
        case .purple:
            return Color(red: 0.7, green: 0.4, blue: 0.95)
        case .pink:
            return Color(red: 1.0, green: 0.5, blue: 0.8)
        case .orange:
            return Color(red: 1.0, green: 0.6, blue: 0.2)
        }
    }
}

enum ConfettiShape: CaseIterable {
    case circle, square, triangle, diamond

    var shape: AnyShape {
        switch self {
        case .circle:
            return AnyShape(Circle())
        case .square:
            return AnyShape(Rectangle())
        case .triangle:
            return AnyShape(Triangle())
        case .diamond:
            return AnyShape(Diamond())
        }
    }
}

// MARK: - Custom Shapes
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - AnyShape Type Eraser
struct AnyShape: Shape {
    private let _path: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
    }

    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

// MARK: - Confetti Modifier
struct ConfettiModifier: ViewModifier {
    @Binding var isPresented: Bool
    let pieceCount: Int

    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isPresented {
                        ConfettiView(pieceCount: pieceCount)
                            .allowsHitTesting(false)
                            .ignoresSafeArea()
                            .onAppear {
                                // Auto-dismiss after animation completes
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    isPresented = false
                                }
                            }
                    }
                }
            )
    }
}

// MARK: - View Extension
extension View {
    /// Shows confetti animation overlay when isPresented is true
    /// - Parameters:
    ///   - isPresented: Binding to control confetti visibility
    ///   - pieceCount: Number of confetti pieces (default: 50)
    func confetti(isPresented: Binding<Bool>, pieceCount: Int = 50) -> some View {
        modifier(ConfettiModifier(isPresented: isPresented, pieceCount: pieceCount))
    }
}

#Preview {
    struct ConfettiPreview: View {
        @State private var showConfetti = false

        var body: some View {
            ZStack {
                Color(white: 0.95)
                    .ignoresSafeArea()

                Button("Celebrate! 🎉") {
                    showConfetti = true
                }
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.35, green: 0.75, blue: 0.95),
                            Color(red: 0.45, green: 0.55, blue: 0.95)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .confetti(isPresented: $showConfetti)
        }
    }

    return ConfettiPreview()
}
