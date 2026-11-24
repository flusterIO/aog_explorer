//
//  Diagrams.swift
//  AlphaOmegaGravityVisualizer
//
//  Canvas-based diagrams: the slope triangle (Fig. 1), the Minkowski hyperbola and the
//  two temporal surfaces of the lighthouse thought experiment.
//

import SwiftUI

// MARK: - Helpers

extension GraphicsContext {
    func label(_ string: String, at point: CGPoint, color: Color = .secondary, font: Font = .caption, anchor: UnitPoint = .center) {
        draw(Text(string).font(font).foregroundStyle(color), at: point, anchor: anchor)
    }

    func line(_ a: CGPoint, _ b: CGPoint, color: Color, width: CGFloat = 2, dash: [CGFloat] = []) {
        var p = Path()
        p.move(to: a)
        p.addLine(to: b)
        stroke(p, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, dash: dash))
    }

    func dot(_ c: CGPoint, radius: CGFloat, color: Color) {
        fill(Path(ellipseIn: CGRect(x: c.x - radius, y: c.y - radius, width: 2 * radius, height: 2 * radius)), with: .color(color))
    }

    func arrow(from a: CGPoint, to b: CGPoint, color: Color, width: CGFloat = 1.6, head: CGFloat = 6) {
        line(a, b, color: color, width: width)
        let angle = atan2(b.y - a.y, b.x - a.x)
        var p = Path()
        p.move(to: b)
        p.addLine(to: CGPoint(x: b.x - head * cos(angle - 0.45), y: b.y - head * sin(angle - 0.45)))
        p.addLine(to: CGPoint(x: b.x - head * cos(angle + 0.45), y: b.y - head * sin(angle + 0.45)))
        p.closeSubpath()
        fill(p, with: .color(color))
    }
}

// MARK: - Slope triangle (Figure 1)

struct SlopeTriangleDiagram: View {
    let beta: Double

    var body: some View {
        Canvas { ctx, size in
            let gamma = Lorentz.gamma(beta: beta)
            let dy = Lorentz.slope(beta: beta)
            let pad = 56.0
            let w = Double(size.width), h = Double(size.height)
            let availW = w - 2 * pad - 140
            let availH = h - 2 * pad
            let unit = min(availW, availH / max(dy, 0.4))
            let ox = pad + 20, oy = h - pad
            let origin = CGPoint(x: ox, y: oy)
            let right = CGPoint(x: ox + unit, y: oy)
            let top = CGPoint(x: ox + unit, y: oy - unit * dy)

            var tri = Path()
            tri.move(to: origin)
            tri.addLine(to: right)
            tri.addLine(to: top)
            tri.closeSubpath()
            ctx.fill(tri, with: .linearGradient(
                Gradient(colors: [Theme.flow.opacity(0.10), Theme.time.opacity(0.22)]),
                startPoint: origin, endPoint: top))

            // Right-angle marker
            let m = 14.0
            var sq = Path()
            sq.move(to: CGPoint(x: ox + unit - m, y: oy))
            sq.addLine(to: CGPoint(x: ox + unit - m, y: oy - m))
            sq.addLine(to: CGPoint(x: ox + unit, y: oy - m))
            ctx.stroke(sq, with: .color(.secondary), lineWidth: 1)

            ctx.line(origin, right, color: Theme.flow, width: 4)
            ctx.line(right, top, color: Theme.time, width: 4)
            ctx.line(origin, top, color: .primary, width: 3)

            // Tilt angle θ, tan θ = βγ, sin θ = β
            let theta = atan(dy)
            var arc = Path()
            for (i, a) in Grid.linear(0, theta, 40).enumerated() {
                let p = CGPoint(x: ox + 46 * cos(a), y: oy - 46 * sin(a))
                if i == 0 { arc.move(to: p) } else { arc.addLine(to: p) }
            }
            ctx.stroke(arc, with: .color(Theme.observation), lineWidth: 2)
            ctx.label("θ", at: CGPoint(x: ox + 60 * cos(theta / 2), y: oy - 60 * sin(theta / 2)), color: Theme.observation, font: .headline)

            ctx.label("dx = vτ", at: CGPoint(x: ox + unit / 2, y: oy + 22), color: Theme.flow, font: .callout.weight(.semibold))
            ctx.label("dy = vτ√(γ² − 1)", at: CGPoint(x: ox + unit + 14, y: oy - unit * dy / 2), color: Theme.time, font: .callout.weight(.semibold), anchor: .leading)
            ctx.label("dx⁽ᵁ⁾ = γ dx = \(Fmt.fixed(gamma, 3)) dx", at: CGPoint(x: ox + unit / 2 - 14, y: oy - unit * dy / 2 - 14), color: .primary, font: .callout.weight(.semibold), anchor: .trailing)
        }
    }
}

// MARK: - Minkowski hyperbola

struct MinkowskiDiagram: View {
    let beta: Double

    var body: some View {
        Canvas { ctx, size in
            let cx = Double(size.width) * 0.28, cy = Double(size.height) / 2
            let center = CGPoint(x: cx, y: cy)
            let unit = min(Double(size.width) * 0.2, Double(size.height) / 7.2)
            func pt(_ x: Double, _ ct: Double) -> CGPoint { CGPoint(x: cx + x * unit, y: cy - ct * unit) }

            // Axes
            ctx.arrow(from: pt(-1.2, 0), to: pt(4.2, 0), color: .secondary, width: 1)
            ctx.arrow(from: pt(0, -3.4), to: pt(0, 3.4), color: .secondary, width: 1)
            ctx.label("x′", at: pt(4.45, 0), font: .callout)
            ctx.label("ct′", at: pt(0, 3.65), font: .callout)

            // Light cone
            ctx.line(pt(-1.2, -1.2), pt(3.4, 3.4), color: Theme.observation.opacity(0.6), width: 1, dash: [5, 4])
            ctx.line(pt(-1.2, 1.2), pt(3.4, -3.4), color: Theme.observation.opacity(0.6), width: 1, dash: [5, 4])
            ctx.label("light cone", at: pt(3.0, 3.25), color: Theme.observation, font: .caption2)

            // Invariant hyperbola x′² − (ct′)² = dx²
            var hyp = Path()
            let etaMax = asinh(3.3)
            for (i, eta) in Grid.linear(-etaMax, etaMax, 160).enumerated() {
                let p = pt(cosh(eta), sinh(eta))
                if i == 0 { hyp.move(to: p) } else { hyp.addLine(to: p) }
            }
            ctx.stroke(hyp, with: .color(Theme.geometry), lineWidth: 2.5)
            ctx.label("x′² − (ct′)² = dx²", at: pt(3.35, 2.55), color: Theme.geometry, font: .callout.weight(.semibold), anchor: .leading)

            let gamma = Lorentz.gamma(beta: beta)
            let event = pt(gamma, -gamma * beta)
            let rest = pt(1, 0)
            // Components
            ctx.line(event, pt(gamma, 0), color: Theme.time, width: 1.5, dash: [3, 3])
            ctx.line(event, pt(0, -gamma * beta), color: Theme.flow, width: 1.5, dash: [3, 3])
            ctx.label("c dt′ = −γβ dx", at: pt(-0.08, -gamma * beta), color: Theme.time, font: .caption.weight(.semibold), anchor: .trailing)
            ctx.label("dx′ = γ dx", at: pt(gamma, 0.22), color: Theme.flow, font: .caption.weight(.semibold))
            ctx.line(center, event, color: .primary.opacity(0.5), width: 1)
            ctx.dot(rest, radius: 5, color: .secondary)
            ctx.label("(dx, 0)", at: pt(1.08, -0.3), anchor: .leading)
            ctx.dot(event, radius: 7, color: Theme.time)
            ctx.label("event in moving frame", at: pt(gamma + 0.15, -gamma * beta), color: .primary, font: .caption.weight(.semibold), anchor: .leading)
        }
    }
}

// MARK: - Lighthouse & clock-tower

struct LighthouseDiagram: View {
    let beta: Double
    var animate = true

    var body: some View {
        TimelineView(.animation(paused: !animate)) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let progress = animate ? (t.truncatingRemainder(dividingBy: 4.0)) / 4.0 : 1.0
                draw(ctx: &ctx, size: size, progress: progress)
            }
        }
    }

    private func draw(ctx: inout GraphicsContext, size: CGSize, progress: Double) {
        let gamma = Lorentz.gamma(beta: beta)
        let slope = Lorentz.slope(beta: beta)
        let unit = min(Double(size.width) / 9.2, Double(size.height) / 7.4)
        let ox = Double(size.width) * 0.5, oy = Double(size.height) * 0.80
        let separation = min(slope, 2.6) * 1.25
        let c30 = cos(Double.pi / 6), s30 = sin(Double.pi / 6)
        func project(_ x: Double, _ z: Double, _ y: Double) -> CGPoint {
            CGPoint(x: ox + (x - z) * c30 * unit, y: oy - (x + z) * s30 * unit - y * unit)
        }
        func plane(_ y: Double, color: Color, label: String) {
            var p = Path()
            p.move(to: project(0, 0, y))
            p.addLine(to: project(4, 0, y))
            p.addLine(to: project(4, 4, y))
            p.addLine(to: project(0, 4, y))
            p.closeSubpath()
            ctx.fill(p, with: .color(color.opacity(0.12)))
            ctx.stroke(p, with: .color(color.opacity(0.55)), lineWidth: 1.2)
            for k in 1..<4 {
                ctx.line(project(Double(k), 0, y), project(Double(k), 4, y), color: color.opacity(0.15), width: 0.8)
                ctx.line(project(0, Double(k), y), project(4, Double(k), y), color: color.opacity(0.15), width: 0.8)
            }
            ctx.label(label, at: project(-0.25, 4.1, y), color: color, font: .title3.weight(.bold))
        }

        plane(0, color: Theme.flow, label: "𝐒")
        plane(separation, color: Theme.time, label: "𝐔")

        let p1 = (x: 0.6, z: 1.6), p2 = (x: 3.4, z: 1.6)
        let a = project(p1.x, p1.z, 0)
        let b2 = project(p2.x, p2.z, separation)
        let b2Shadow = project(p2.x, p2.z, 0)

        // dx on S and dy rising to U
        ctx.line(a, b2Shadow, color: Theme.flow, width: 2, dash: [5, 4])
        ctx.line(b2Shadow, b2, color: Theme.time, width: 2, dash: [5, 4])
        ctx.line(a, b2, color: .primary, width: 2.5)
        ctx.label("d", at: project((p1.x + p2.x) / 2, p1.z - 0.35, 0), color: Theme.flow, font: .callout.weight(.semibold))
        ctx.label("Δy", at: project(p2.x + 0.3, p2.z - 0.3, separation / 2), color: Theme.time, font: .callout.weight(.semibold))

        // Clock tower at p2 (in U)
        var tower = Path()
        let bx = Double(b2.x), by = Double(b2.y)
        tower.addRoundedRect(in: CGRect(x: bx - 7, y: by - 46, width: 14, height: 46), cornerSize: CGSize(width: 3, height: 3))
        ctx.fill(tower, with: .color(Theme.observation.opacity(0.85)))
        let clockFace = CGPoint(x: bx, y: by - 52)
        ctx.dot(clockFace, radius: 9, color: Theme.observation)
        ctx.label("clock-tower at p₂", at: CGPoint(x: bx + 16, y: by - 52), color: Theme.observation, font: .caption.weight(.semibold), anchor: .leading)

        // Observer A at p1, lighthouse beam
        ctx.dot(a, radius: 7, color: Theme.flow)
        ctx.label("A at p₁", at: project(p1.x - 0.2, p1.z, 0), color: Theme.flow, font: .caption.weight(.semibold), anchor: .trailing)
        var beam = Path()
        beam.move(to: a)
        beam.addLine(to: clockFace)
        ctx.stroke(beam, with: .color(Theme.observation.opacity(0.25)), style: StrokeStyle(lineWidth: 1, dash: [2, 4]))

        // Traveller B
        let x = p1.x + (p2.x - p1.x) * progress
        let pos = project(x, p1.z, separation * progress)
        ctx.dot(pos, radius: 8, color: .white)
        ctx.dot(pos, radius: 5, color: Theme.time)
        ctx.label("B", at: project(x, p1.z, separation * progress + 0.35), color: .primary, font: .callout.weight(.bold))

        ctx.label("γ = \(Fmt.fixed(gamma, 3))   ∂ₓy = βγ = \(Fmt.fixed(slope, 3))", at: CGPoint(x: 16, y: 18), color: .secondary, font: .callout.monospacedDigit(), anchor: .leading)
        if slope > 2.6 {
            ctx.label("Δy clipped for display", at: CGPoint(x: 16, y: 40), color: .secondary, font: .caption, anchor: .leading)
        }
    }
}
