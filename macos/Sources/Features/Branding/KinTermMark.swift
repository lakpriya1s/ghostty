import SwiftUI

/// KinTerm's colors, from the "Name & logo" design.
enum KinTermBrand {
    static let teal = Color(red: 0x2f / 255, green: 0xd3 / 255, blue: 0xb8 / 255)
    static let blue = Color(red: 0x5c / 255, green: 0xa0 / 255, blue: 0xff / 255)
    static let ink = Color(red: 0x15 / 255, green: 0x16 / 255, blue: 0x1b / 255)
    static let tile = Color(red: 0x1b / 255, green: 0x1c / 255, blue: 0x21 / 255)
    static let tileEdge = Color(red: 0x2c / 255, green: 0x2e / 255, blue: 0x35 / 255)
    static let term = Color(red: 0x8b / 255, green: 0x90 / 255, blue: 0x99 / 255)
}

/// The KinTerm mark: two agent faces. The one in front has a small smile,
/// the one behind is a sibling peeking over its shoulder. As a status light
/// the front face takes the state's color and expression.
struct KinTermMark: View {
    var front: Color = KinTermBrand.blue
    var expression: Expression = .smile

    /// The front face's expression: the logo's smile, or an agent state's
    /// face from the Square faces set.
    enum Expression {
        case smile, working, waiting, done, error
    }

    var body: some View {
        Canvas { context, size in
            Self.draw(in: &context, size: size, front: front, expression: expression)
        }
        .aspectRatio(1, contentMode: .fit)
        .compositingGroup()
        .accessibilityLabel("KinTerm")
    }

    /// Draws the mark into a square of `size`. Units are 1/168 of the side:
    /// each face is 120 square, the back one offset 48 up and to the right.
    static func draw(
        in context: inout GraphicsContext, size: CGSize, front: Color, expression: Expression = .smile
    ) {
        let side = min(size.width, size.height)
        let unit = side / 168
        let origin = CGPoint(x: (size.width - side) / 2, y: (size.height - side) / 2)
        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
            CGRect(x: origin.x + x * unit, y: origin.y + y * unit, width: w * unit, height: h * unit)
        }
        func face(_ r: CGRect, radius: CGFloat) -> Path {
            Path(roundedRect: r, cornerRadius: radius * unit, style: .continuous)
        }

        // The sibling behind, looking off to the right.
        context.fill(face(rect(48, 0, 120, 120), radius: 30), with: .color(KinTermBrand.teal))
        for x in [114.0, 144.0] {
            context.fill(
                Path(roundedRect: rect(x - 4.5, 19, 9, 17), cornerRadius: 4.5 * unit),
                with: .color(KinTermBrand.ink))
        }

        // A gap between the two faces, cut out so it works on any background.
        var cut = context
        cut.blendMode = .destinationOut
        cut.fill(face(rect(-8, 40, 136, 136), radius: 38), with: .color(.black))

        // The face in front.
        context.fill(face(rect(0, 48, 120, 120), radius: 30), with: .color(front))
        let ink = GraphicsContext.Shading.color(KinTermBrand.ink)
        guard expression == .smile else {
            drawExpression(expression, in: &context, origin: CGPoint(x: origin.x, y: origin.y + 48 * unit),
                           scale: 3 * unit, ink: ink)
            return
        }
        for x in [36.0, 84.0] {
            context.fill(Path(ellipseIn: rect(x - 7, 84, 14, 23)), with: ink)
        }
        var smile = Path()
        smile.move(to: CGPoint(x: origin.x + 40 * unit, y: origin.y + 127 * unit))
        smile.addQuadCurve(
            to: CGPoint(x: origin.x + 80 * unit, y: origin.y + 127 * unit),
            control: CGPoint(x: origin.x + 60 * unit, y: origin.y + 143 * unit))
        context.stroke(smile, with: ink, style: StrokeStyle(lineWidth: 8.5 * unit, lineCap: .round))
    }

    /// A state's face from the Square faces set (`drawSquare`), still, on the
    /// front face. Units are its 40x40 grid: `origin` is the face's top left
    /// and `scale` the size of one unit.
    private static func drawExpression(
        _ expression: Expression, in context: inout GraphicsContext, origin: CGPoint, scale: CGFloat,
        ink: GraphicsContext.Shading
    ) {
        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
            CGRect(x: origin.x + x * scale, y: origin.y + y * scale, width: w * scale, height: h * scale)
        }
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: origin.x + x * scale, y: origin.y + y * scale)
        }
        func pill(_ r: CGRect) -> Path {
            Path(roundedRect: r, cornerRadius: min(r.width, r.height) / 2)
        }
        let line = StrokeStyle(lineWidth: 2.5 * scale, lineCap: .round)

        switch expression {
        case .smile:
            break

        case .working:
            // Pill eyes glancing to the side.
            context.fill(pill(rect(11.5, 13, 6, 10)), with: ink)
            context.fill(pill(rect(25.5, 13, 6, 10)), with: ink)
            context.fill(pill(rect(16.5, 27, 7, 2.5)), with: ink)

        case .waiting:
            // Surprised: tall eyes and an "o" mouth.
            context.fill(pill(rect(10, 11, 6, 11)), with: ink)
            context.fill(pill(rect(24, 11, 6, 11)), with: ink)
            context.stroke(Path(roundedRect: rect(17.25, 27.25, 5.5, 5.5), cornerRadius: 1.75 * scale),
                           with: ink, lineWidth: 2.5 * scale)

        case .done:
            // Happy: arched eyes and a smile.
            var eyes = Path()
            for center in [12.5, 27.5] {
                eyes.move(to: point(center - 3.25, 19))
                eyes.addArc(center: point(center, 18.5), radius: 3.25 * scale,
                            startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                eyes.addLine(to: point(center + 3.25, 19))
            }
            context.stroke(eyes, with: ink, style: line)
            var smile = Path()
            smile.addArc(center: point(20, 22), radius: 6.75 * scale,
                         startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
            context.stroke(smile, with: ink, style: line)

        case .error:
            // X eyes and a frown.
            var eyes = Path()
            for center in [13.25, 27.25] {
                eyes.move(to: point(center - 3.2, 13.8))
                eyes.addLine(to: point(center + 3.2, 20.2))
                eyes.move(to: point(center + 3.2, 13.8))
                eyes.addLine(to: point(center - 3.2, 20.2))
            }
            context.stroke(eyes, with: ink, style: line)
            var frown = Path()
            frown.addArc(center: point(20, 33), radius: 4.75 * scale,
                         startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
            context.stroke(frown, with: ink, style: line)
        }
    }
}

/// The app icon: the mark on a dark tile, inside the macOS icon grid
/// (an 824 tile in a 1024 canvas).
struct KinTermAppIcon: View {
    var front: Color = KinTermBrand.blue
    var expression: KinTermMark.Expression = .smile

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let tile = side * 824 / 1024
            ZStack {
                RoundedRectangle(cornerRadius: tile * 0.225, style: .continuous)
                    .fill(KinTermBrand.tile)
                    .overlay(
                        RoundedRectangle(cornerRadius: tile * 0.225, style: .continuous)
                            .strokeBorder(KinTermBrand.tileEdge, lineWidth: max(1, side / 256)))
                    .frame(width: tile, height: tile)
                KinTermMark(front: front, expression: expression)
                    .frame(width: tile * 0.74, height: tile * 0.74)
            }
            .frame(width: side, height: side)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// The icon as an image, for the dock.
    @MainActor
    static func image(front: Color, expression: KinTermMark.Expression = .smile, side: CGFloat = 512) -> NSImage? {
        let renderer = ImageRenderer(
            content: KinTermAppIcon(front: front, expression: expression).frame(width: side, height: side))
        renderer.scale = 2
        guard let cgImage = renderer.cgImage else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: side, height: side))
    }
}

/// The wordmark: "Kin" bright, "Term" muted, ending in a cursor.
struct KinTermWordmark: View {
    var size: CGFloat = 28

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: size * 0.06) {
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                Text("Kin").foregroundColor(.primary)
                Text("Term").foregroundColor(KinTermBrand.term)
            }
            .font(.system(size: size, weight: .heavy))
            .kerning(-size * 0.02)
            RoundedRectangle(cornerRadius: size * 0.04)
                .fill(KinTermBrand.blue)
                .frame(width: size * 0.42, height: size * 0.09)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("KinTerm")
    }
}
