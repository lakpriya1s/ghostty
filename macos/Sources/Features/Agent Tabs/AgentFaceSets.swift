import SwiftUI

/// The face sets other than the original faces: Orbs, Shapes, Bots and Spark.
/// Each draws the same states on the same 40x40 grid as `AgentFaceView`, with
/// the same colors, so only the look changes.
/// See scope/designs/06-face-sets.md for the design.
extension AgentFaceView {
    // MARK: Orbs

    /// No face, just a glowing dot: it breathes, orbits, ripples, holds
    /// still or shakes.
    func drawOrb(in gc: inout GraphicsContext, time: TimeInterval) {
        let color = Self.color(for: state)
        let ink = GraphicsContext.Shading.color(Self.ink)
        let dot = { (inset: CGFloat) in AgentFaceSets.circle(inset: inset) }

        switch state {
        case .clear:
            break

        case .idle:
            // Dim, and breathes between 85% and full size every 3.2s.
            var orb = gc
            AgentFaceSets.scale(&orb, by: 0.85 + 0.15 * Self.wave(time, period: 3.2))
            orb.opacity = 0.75
            orb.fill(dot(10), with: .color(color))

        case .working:
            // Glowing, with a ring turning every 0.9s and a fainter outer
            // one turning back every 1.6s.
            var glow = gc
            glow.addFilter(.shadow(color: color.opacity(0.7), radius: 6))
            glow.fill(dot(12), with: .color(color))
            let turn = AgentFaceSets.phase(time, period: 0.9) * 360
            gc.stroke(AgentFaceSets.arc(radius: 16.5, from: -135 + turn, to: -45 + turn),
                      with: .color(color), lineWidth: 3)
            gc.stroke(AgentFaceSets.arc(radius: 16.5, from: -45 + turn, to: 45 + turn),
                      with: .color(color.opacity(0.35)), lineWidth: 3)
            let back = -AgentFaceSets.phase(time, period: 1.6) * 360
            gc.stroke(AgentFaceSets.arc(radius: 22, from: 45 + back, to: 135 + back),
                      with: .color(Color(agentHex: 0x9fd0ff, opacity: 0.7)), lineWidth: 2)

        case .blocked:
            // Two rings ripple out from the dot, 0.8s apart.
            var glow = gc
            glow.addFilter(.shadow(color: color.opacity(0.6), radius: 5))
            glow.fill(dot(10), with: .color(color))
            for delay in [0, 0.8] {
                let progress = AgentFaceSets.phase(time - delay, period: 1.6)
                let eased = 1 - (1 - progress) * (1 - progress)
                let grow = 1 + 1.1 * eased
                let radius = 9 * grow
                gc.stroke(
                    Path(ellipseIn: CGRect(x: 20 - radius, y: 20 - radius, width: radius * 2, height: radius * 2)),
                    with: .color(color.opacity(0.9 * (1 - eased))), lineWidth: 2 * grow)
            }

        case .done:
            gc.fill(dot(7), with: .color(color))
            gc.fill(AgentFaceSets.check(left: 16, top: 12), with: ink)
            drawUnreadDot(in: &gc)

        case .error:
            gc.translateBy(x: AgentFaceSets.shake(time), y: 0)
            gc.fill(dot(7), with: .color(color))
            gc.fill(Path(roundedRect: CGRect(x: 18.5, y: 13, width: 3, height: 9), cornerRadius: 1.5), with: ink)
            gc.fill(Path(roundedRect: CGRect(x: 18.5, y: 24, width: 3, height: 3), cornerRadius: 1.5), with: ink)
        }
    }

    // MARK: Shapes

    /// A silhouette per state, like road signs, so they read in grayscale
    /// and at tiny sizes.
    func drawShape(in gc: inout GraphicsContext, time: TimeInterval) {
        let color = Self.color(for: state)
        let ink = GraphicsContext.Shading.color(Self.ink)

        switch state {
        case .clear:
            break

        case .idle:
            // A hollow ring fading to 45% and back every 3s.
            var ring = gc
            ring.opacity = 1 - 0.55 * Self.wave(time, period: 3)
            ring.stroke(AgentFaceSets.circle(inset: 9.5), with: .color(color), lineWidth: 3)

        case .working:
            // Three dots hopping 6 units in turn, every 1s.
            for (index, left) in [5.0, 16, 27].enumerated() {
                let progress = AgentFaceSets.phase(time - 0.15 * Double(index), period: 1)
                let hop = AgentFaceSets.keyframes(progress, [(0, 0), (0.3, -6), (0.6, 0), (1, 0)])
                gc.fill(Path(ellipseIn: CGRect(x: left, y: 16 + hop, width: 8, height: 8)), with: .color(color))
            }

        case .blocked:
            // A warning triangle bobbing 2 units every 1.4s.
            gc.translateBy(x: 0, y: -2 * Self.wave(time, period: 1.4))
            var triangle = Path()
            triangle.addLines([CGPoint(x: 20, y: 4.28), CGPoint(x: 37.28, y: 33.72), CGPoint(x: 2.72, y: 33.72)])
            triangle.closeSubpath()
            gc.fill(triangle, with: .color(color))
            gc.fill(Path(roundedRect: CGRect(x: 18.5, y: 14, width: 3, height: 10), cornerRadius: 1.5), with: ink)
            gc.fill(Path(roundedRect: CGRect(x: 18.5, y: 27, width: 3, height: 3), cornerRadius: 1.5), with: ink)

        case .done:
            gc.fill(AgentFaceSets.circle(inset: 5), with: .color(color))
            gc.fill(AgentFaceSets.check(left: 15.5, top: 11), with: ink)
            drawUnreadDot(in: &gc)

        case .error:
            // A stop sign with an X.
            var octagon = Path()
            octagon.addLines([
                CGPoint(x: 14, y: 5), CGPoint(x: 26, y: 5), CGPoint(x: 35, y: 14), CGPoint(x: 35, y: 26),
                CGPoint(x: 26, y: 35), CGPoint(x: 14, y: 35), CGPoint(x: 5, y: 26), CGPoint(x: 5, y: 14),
            ])
            octagon.closeSubpath()
            gc.fill(octagon, with: .color(color))
            let bar = CGRect(x: 18.5, y: 12, width: 3, height: 16)
            for angle in [45.0, -45] {
                gc.fill(AgentFaceSets.rotated(Path(roundedRect: bar, cornerRadius: 1.5), by: angle), with: ink)
            }
        }
    }

    // MARK: Bots

    /// Little robot heads. The antenna lamp is a second signal: off,
    /// blinking, flashing, steady, or on a bent antenna.
    func drawBot(in gc: inout GraphicsContext, time: TimeInterval) {
        guard state != .clear else { return }
        let color = Self.color(for: state)
        let ink = GraphicsContext.Shading.color(Self.ink)
        let lampOff = Color(agentHex: 0x4a4e59)

        // The lamp's color, and how often it blinks off, if it does.
        let lamp: (color: Color, blink: Double?)
        switch state {
        case .working: lamp = (Color(agentHex: 0xbfe0ff), 0.8)
        case .blocked: lamp = (Color(agentHex: 0xffd27a), 0.5)
        case .done: lamp = (Color(agentHex: 0x9be9a8), nil)
        case .error: lamp = (Color(agentHex: 0x5a2b2b), nil)
        default: lamp = (lampOff, nil)
        }
        let lit = lamp.blink.map { AgentFaceSets.phase(time, period: $0) < 0.5 } ?? true

        switch state {
        case .blocked: gc.translateBy(x: 0, y: -2 * Self.wave(time, period: 1.4))
        case .error: gc.translateBy(x: AgentFaceSets.shake(time), y: 0)
        default: break
        }

        // Head, then the antenna and its lamp, bent on error.
        gc.fill(Path(roundedRect: CGRect(x: 5, y: 13, width: 30, height: 23), cornerRadius: 7), with: .color(color))
        var antenna = gc
        if state == .error {
            antenna.translateBy(x: 20, y: 13)
            antenna.rotate(by: .degrees(28))
            antenna.translateBy(x: -20, y: -13)
        }
        antenna.fill(Path(CGRect(x: 19, y: 5, width: 2, height: 8)), with: .color(Color(agentHex: 0x8a8f99)))
        antenna.fill(Path(ellipseIn: CGRect(x: 16, y: -1, width: 8, height: 8)), with: .color(lit ? lamp.color : lampOff))

        switch state {
        case .clear:
            break

        case .idle:
            // Eyes shut.
            gc.fill(Path(roundedRect: CGRect(x: 11, y: 24, width: 7, height: 2.5), cornerRadius: 1.25), with: ink)
            gc.fill(Path(roundedRect: CGRect(x: 22, y: 24, width: 7, height: 2.5), cornerRadius: 1.25), with: ink)

        case .working:
            // A visor with a light scanning across and back every 2.2s.
            gc.fill(Path(roundedRect: CGRect(x: 10, y: 20, width: 20, height: 8), cornerRadius: 4), with: ink)
            var sweep = AgentFaceSets.phase(time, period: 2.2) * 2
            if sweep > 1 { sweep = 2 - sweep }
            gc.fill(Path(roundedRect: CGRect(x: 12 + 11 * AgentFaceSets.ease(sweep), y: 22, width: 5, height: 4),
                         cornerRadius: 2),
                    with: .color(Color(agentHex: 0xbfe0ff)))

        case .blocked:
            // Wide eyes.
            gc.fill(Path(roundedRect: CGRect(x: 12, y: 19, width: 6, height: 9), cornerRadius: 3), with: ink)
            gc.fill(Path(roundedRect: CGRect(x: 22, y: 19, width: 6, height: 9), cornerRadius: 3), with: ink)

        case .done:
            // Happy, arched eyes.
            var eyes = Path()
            for center in [16.0, 26.5] {
                eyes.addArc(center: CGPoint(x: center, y: 27.5), radius: 4.75,
                            startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
            }
            gc.stroke(eyes, with: ink, lineWidth: 2.5)
            drawUnreadDot(in: &gc, at: CGPoint(x: 26, y: 8))

        case .error:
            // X eyes.
            var eyes = Path()
            for center in [15.5, 25.5] {
                eyes.move(to: CGPoint(x: center - 3, y: 20.5))
                eyes.addLine(to: CGPoint(x: center + 3, y: 26.5))
                eyes.move(to: CGPoint(x: center + 3, y: 20.5))
                eyes.addLine(to: CGPoint(x: center - 3, y: 26.5))
            }
            gc.stroke(eyes, with: ink, lineWidth: 2.5)
        }
    }

    // MARK: Spark

    /// One asterisk that changes form: small when asleep, spinning while it
    /// works, petals when done, broken into an X on error.
    func drawSpark(in gc: inout GraphicsContext, time: TimeInterval) {
        let color = Self.color(for: state)
        let rays = { (gc: GraphicsContext, width: CGFloat, height: CGFloat, angles: [Double], fill: GraphicsContext.Shading) in
            AgentFaceSets.drawRays(in: gc, width: width, height: height, angles: angles, fill: fill)
        }

        switch state {
        case .clear:
            break

        case .idle:
            // Small and dim, breathing every 3.2s.
            let breath = Self.wave(time, period: 3.2)
            var spark = gc
            AgentFaceSets.scale(&spark, by: 0.9 + 0.1 * breath)
            spark.opacity = 0.7 + 0.3 * breath
            rays(spark, 4, 16, [0, 60, 120], .color(color))

        case .working:
            // Spins once every 2.2s, each ray lit from one end.
            var spark = gc
            spark.translateBy(x: 20, y: 20)
            spark.rotate(by: .degrees(AgentFaceSets.phase(time, period: 2.2) * 360))
            spark.translateBy(x: -20, y: -20)
            let gradient = Gradient(stops: [
                .init(color: Color(agentHex: 0xcfe6ff), location: 0),
                .init(color: color, location: 0.5),
                .init(color: Color(agentHex: 0x2f6fd0), location: 1),
            ])
            rays(spark, 4, 28, [0, 60, 120],
                 .linearGradient(gradient, startPoint: CGPoint(x: 20, y: 6), endPoint: CGPoint(x: 20, y: 34)))

        case .blocked:
            // Throbs between 82% and 108% every 1s, with a "?".
            AgentFaceSets.scale(&gc, by: 0.82 + 0.26 * Self.wave(time, period: 1))
            rays(gc, 4, 28, [0, 60, 120], .color(color))
            gc.draw(
                Text("?").font(.system(size: 14, weight: .heavy)).foregroundColor(color),
                at: CGPoint(x: 42, y: -1.5))

        case .done:
            // Wide petals.
            rays(gc, 8, 32, [0, 60, 120], .color(color))
            drawUnreadDot(in: &gc)

        case .error:
            // Two rays crossed into an X.
            gc.translateBy(x: AgentFaceSets.shake(time), y: 0)
            rays(gc, 4, 28, [45, -45], .color(color))
        }
    }
}

/// Shapes and motion shared by the face sets, on the 40x40 grid.
enum AgentFaceSets {
    /// Where `time` is in a repeating period, from 0 up to 1.
    static func phase(_ time: TimeInterval, period: Double) -> Double {
        let value = (time / period).truncatingRemainder(dividingBy: 1)
        return value < 0 ? value + 1 : value
    }

    /// CSS `ease-in-out` from 0 to 1.
    static func ease(_ x: Double) -> Double {
        (1 - cos(.pi * x)) / 2
    }

    /// The value at `progress` (0 to 1) between keyframes of
    /// (progress, value), eased like CSS `ease-in-out` between each pair.
    static func keyframes(_ progress: Double, _ frames: [(Double, Double)]) -> Double {
        for index in 1..<frames.count where progress <= frames[index].0 {
            let (start, from) = frames[index - 1]
            let (end, to) = frames[index]
            let fraction = end > start ? (progress - start) / (end - start) : 1
            return from + (to - from) * ease(fraction)
        }
        return frames.last?.1 ?? 0
    }

    /// The error shake: still for most of 2.4s, then a quick left, right,
    /// left.
    static func shake(_ time: TimeInterval) -> CGFloat {
        keyframes(phase(time, period: 2.4), [(0, 0), (0.88, 0), (0.91, -2), (0.94, 2), (0.97, -1), (1, 0)])
    }

    /// Scales everything drawn after it about the center of the grid.
    static func scale(_ gc: inout GraphicsContext, by factor: Double) {
        gc.translateBy(x: 20, y: 20)
        gc.scaleBy(x: factor, y: factor)
        gc.translateBy(x: -20, y: -20)
    }

    /// A circle `inset` units in from each edge of the grid.
    static func circle(inset: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: inset, y: inset, width: 40 - inset * 2, height: 40 - inset * 2))
    }

    /// An arc around the center of the grid. 0 degrees points right and
    /// angles turn clockwise, so -90 is the top.
    static func arc(radius: CGFloat, from start: Double, to end: Double) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: 20, y: 20), radius: radius,
                    startAngle: .degrees(start), endAngle: .degrees(end), clockwise: false)
        return path
    }

    /// `path` turned clockwise by `degrees` about `center`, the middle of
    /// its bounds if not given.
    static func rotated(_ path: Path, by degrees: Double, about center: CGPoint? = nil) -> Path {
        let center = center ?? CGPoint(x: path.boundingRect.midX, y: path.boundingRect.midY)
        let transform = CGAffineTransform(translationX: center.x, y: center.y)
            .rotated(by: degrees * .pi / 180)
            .translatedBy(x: -center.x, y: -center.y)
        return path.applying(transform)
    }

    /// A check mark: the right and bottom edges of a 9x15 box, 3 units
    /// thick, turned 45 degrees. `left` and `top` place the box.
    static func check(left: CGFloat, top: CGFloat) -> Path {
        var path = Path()
        path.addRect(CGRect(x: left + 6, y: top, width: 3, height: 15))
        path.addRect(CGRect(x: left, y: top + 12, width: 9, height: 3))
        return rotated(path, by: 45, about: CGPoint(x: left + 4.5, y: top + 7.5))
    }

    /// Spark's rays: rounded bars centered on the grid, one per angle.
    static func drawRays(
        in gc: GraphicsContext, width: CGFloat, height: CGFloat, angles: [Double],
        fill: GraphicsContext.Shading
    ) {
        let bar = Path(
            roundedRect: CGRect(x: 20 - width / 2, y: 20 - height / 2, width: width, height: height),
            cornerRadius: width / 2)
        for angle in angles {
            var ray = gc
            ray.translateBy(x: 20, y: 20)
            ray.rotate(by: .degrees(angle))
            ray.translateBy(x: -20, y: -20)
            ray.fill(bar, with: fill)
        }
    }

    /// The face for a tab without an agent, in each set's style. Only the
    /// Orbs cursor moves: it blinks every 1.1s.
    static func drawShell(_ style: AgentTabBarSettings.FaceStyle, in gc: inout GraphicsContext, time: TimeInterval) {
        let ink = GraphicsContext.Shading.color(AgentFaceView.ink)
        let well = GraphicsContext.Shading.color(Color(agentHex: 0x2a2c33))
        let edge = GraphicsContext.Shading.color(Color(agentHex: 0x4a4e59))
        let prompt = Color(agentHex: 0xc2c6cf)

        switch style {
        case .faces:
            // Drawn by ShellGlyphView itself.
            break

        case .orbs:
            // A dark square with a blinking cursor block.
            gc.fill(Path(roundedRect: CGRect(x: 6, y: 6, width: 28, height: 28), cornerRadius: 9), with: well)
            gc.stroke(Path(roundedRect: CGRect(x: 6.75, y: 6.75, width: 26.5, height: 26.5), cornerRadius: 8.25),
                      with: edge, lineWidth: 1.5)
            if phase(time, period: 1.1) < 0.5 {
                gc.fill(Path(roundedRect: CGRect(x: 14, y: 13, width: 7, height: 13), cornerRadius: 1),
                        with: .color(prompt))
            }

        case .shapes:
            // A solid square with a ">" and "_".
            gc.fill(Path(roundedRect: CGRect(x: 6, y: 6, width: 28, height: 28), cornerRadius: 5),
                    with: .color(AgentFaceView.color(for: .idle)))
            var chevron = Path()
            chevron.addRect(CGRect(x: 11, y: 15, width: 9, height: 3))
            chevron.addRect(CGRect(x: 17, y: 15, width: 3, height: 9))
            gc.fill(rotated(chevron, by: 45, about: CGPoint(x: 15.5, y: 19.5)), with: ink)
            gc.fill(Path(roundedRect: CGRect(x: 20, y: 24, width: 9, height: 3), cornerRadius: 1.5), with: ink)

        case .bots:
            // An empty head with no antenna, and a prompt.
            let head = CGRect(x: 5, y: 13, width: 30, height: 23)
            gc.fill(Path(roundedRect: head, cornerRadius: 7), with: well)
            gc.stroke(Path(roundedRect: head.insetBy(dx: 0.75, dy: 0.75), cornerRadius: 6.25), with: edge, lineWidth: 1.5)
            gc.draw(
                Text(">_").font(.system(size: 11, weight: .semibold, design: .monospaced)).foregroundColor(prompt),
                at: CGPoint(x: 20, y: 24.5))

        case .spark:
            // The rays form a ">" and "_".
            let gray = GraphicsContext.Shading.color(Color(agentHex: 0xa8adb7))
            let ray = { (rect: CGRect) in Path(roundedRect: rect, cornerRadius: 2) }
            gc.fill(rotated(ray(CGRect(x: 12.5, y: 7.5, width: 4, height: 14)), by: -45), with: gray)
            gc.fill(rotated(ray(CGRect(x: 12.5, y: 16.5, width: 4, height: 14)), by: 45), with: gray)
            gc.fill(ray(CGRect(x: 22, y: 27, width: 12, height: 4)), with: gray)
        }
    }
}
