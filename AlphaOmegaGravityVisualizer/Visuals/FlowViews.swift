//
//  FlowViews.swift
//  AlphaOmegaGravityVisualizer
//
//  Animated river-model flow, orbit tracer and vector-field canvases.
//

import Foundation
import SwiftUI

extension CGPoint {
    /// Point at polar offset (r, angle) from self, with screen y pointing down.
    func polar(_ r: Double, _ angle: Double) -> CGPoint {
        CGPoint(x: Double(x) + r * cos(angle), y: Double(y) + r * sin(angle))
    }

    func circleRect(_ r: Double) -> CGRect {
        CGRect(x: Double(x) - r, y: Double(y) - r, width: 2 * r, height: 2 * r)
    }
}

// MARK: - River model (Painlevé–Gullstrand)

enum FlowMode: String, CaseIterable, Identifiable {
    case schwarzschild = "Schwarzschild (infall)"
    case hubble = "Hubble (outflow)"
    var id: String { rawValue }
}

/// Tracers carried by a radial flow at βc. Inward: β² = r_s/R (r_s = 1). Outward: β = HR/c (c/H = 1).
struct RiverFlowView: View {
    let mode: FlowMode
    var speed: Double = 1
    var showObservers = true

    private struct Seed { let angle: Double; let phase: Double; let wobble: Double }
    private let seeds: [Seed] = {
        var g = SplitMix(seed: 7)
        return (0..<320).map { _ in Seed(angle: g.next() * 2 * Double.pi, phase: g.next(), wobble: g.next()) }
    }()

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSinceReferenceDate * speed
                switch mode {
                case .schwarzschild: drawInfall(&ctx, size: size, t: t)
                case .hubble: drawHubble(&ctx, size: size, t: t)
                }
            }
        }
    }

    private func colorFor(beta: Double) -> Color {
        if beta >= 1 { return Color(red: 1, green: 0.35, blue: 0.45) }
        let x = min(max(beta, 0), 1)
        return Color(red: 0.30 + 0.65 * x, green: 0.75 - 0.15 * x, blue: 1.0 - 0.35 * x)
    }

    private func drawInfall(_ ctx: inout GraphicsContext, size: CGSize, t: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let rMax = 8.0
        let unit = Double(min(size.width, size.height)) / 2 / rMax * 0.96
        let k = 0.55
        let rEnd = 0.2
        let period = (pow(rMax, 1.5) - pow(rEnd, 1.5)) / (1.5 * k)

        // Central glow and horizon
        let glow = Gradient(colors: [Color.black, Color(red: 0.25, green: 0.05, blue: 0.15).opacity(0.6), .clear])
        ctx.fill(Path(ellipseIn: center.circleRect(2.2 * unit)),
                 with: .radialGradient(glow, center: center, startRadius: 0, endRadius: CGFloat(2.2 * unit)))
        let horizon = Path(ellipseIn: center.circleRect(unit))
        ctx.fill(horizon, with: .color(.black))
        ctx.stroke(horizon, with: .color(Color(red: 1, green: 0.35, blue: 0.45)), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
        ctx.label("β = 1  (R = r_s)", at: center.polar(unit + 12, -Double.pi / 2), color: Color(red: 1, green: 0.45, blue: 0.5), font: .caption.weight(.semibold))

        for r in [2.0, 4.0, 6.0] {
            let ring = Path(ellipseIn: center.circleRect(r * unit))
            ctx.stroke(ring, with: .color(.secondary.opacity(0.18)), lineWidth: 0.8)
            ctx.label("\(Int(r)) r_s", at: center.polar(r * unit + 6, -Double.pi / 4), color: .secondary, font: .caption2, anchor: .leading)
        }

        for s in seeds {
            let tau = (t + s.phase * period).truncatingRemainder(dividingBy: period)
            let r = pow(max(pow(rMax, 1.5) - 1.5 * k * tau, 1e-6), 2.0 / 3.0)
            let beta = (1 / r).squareRoot()
            let a = s.angle + 0.02 * sin(t + s.wobble * 6)
            let p = center.polar(r * unit, a)
            let trail = min(0.9, 0.18 * beta * 2)
            let q = center.polar((r + trail) * unit, a)
            let fade = min(1, (rMax - r) / 1.2) * (r < 1 ? max(0.15, r) : 1)
            ctx.line(q, p, color: colorFor(beta: beta).opacity(0.55 * fade), width: 1.6)
            ctx.dot(p, radius: 1.9, color: colorFor(beta: beta).opacity(fade))
        }

        if showObservers { drawObservers(&ctx, center: center, unit: unit, radii: [3, 5, 7]) }
    }

    private func drawHubble(_ ctx: inout GraphicsContext, size: CGSize, t: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let rMax = 1.7
        let unit = Double(min(size.width, size.height)) / 2 / rMax * 0.96
        let h = 0.32
        let r0 = 0.03
        let period = log(rMax / r0) / h

        let horizon = Path(ellipseIn: center.circleRect(unit))
        ctx.stroke(horizon, with: .color(Theme.geometry), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
        ctx.label("β = 1  (R = c/H, apparent horizon)", at: center.polar(unit + 12, -Double.pi / 2), color: Theme.geometry, font: .caption.weight(.semibold))

        for r in [0.5, 1.5] {
            let ring = Path(ellipseIn: center.circleRect(r * unit))
            ctx.stroke(ring, with: .color(.secondary.opacity(0.18)), lineWidth: 0.8)
        }

        for s in seeds {
            let tau = (t + s.phase * period).truncatingRemainder(dividingBy: period)
            let r = r0 * exp(h * tau)
            let beta = r
            let a = s.angle
            let p = center.polar(r * unit, a)
            let trail = min(0.25, 0.08 * beta)
            let q = center.polar(max(0, r - trail) * unit, a)
            let fade = min(1, r / 0.15) * min(1, (rMax - r) / 0.25)
            let col = beta >= 1 ? Color(red: 1, green: 0.45, blue: 0.55) : Color(red: 0.42 + 0.4 * beta, green: 0.86, blue: 0.72 + 0.2 * (1 - beta))
            ctx.line(q, p, color: col.opacity(0.55 * fade), width: 1.4)
            ctx.dot(p, radius: 1.8, color: col.opacity(fade))
        }

        if showObservers { drawObservers(&ctx, center: center, unit: unit, radii: [0.4, 0.8, 1.25]) }
    }

    private func drawObservers(_ ctx: inout GraphicsContext, center: CGPoint, unit: Double, radii: [Double]) {
        for (k, r) in radii.enumerated() {
            for j in 0..<6 {
                let a = Double(j) / 6 * 2 * Double.pi + Double(k) * 0.4
                let p = center.polar(r * unit, a)
                let rect = p.circleRect(3.5)
                ctx.stroke(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(Theme.observation), lineWidth: 1.3)
            }
        }
    }
}

/// Deterministic generator for stable layouts.
struct SplitMix {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> Double {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        z = z ^ (z >> 31)
        return Double(z >> 11) / Double(1 << 53)
    }
}

// MARK: - Orbit canvas

struct OrbitCanvas: View {
    let trace: Schwarzschild.Trace
    var animate = true

    var body: some View {
        TimelineView(.animation(paused: !animate)) { timeline in
            Canvas { ctx, size in
                draw(&ctx, size: size, t: timeline.date.timeIntervalSinceReferenceDate)
            }
        }
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, t: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let extent = trace.points.reduce(8.0) { max($0, abs(Double($1.x)), abs(Double($1.y))) }
        let unit = Double(min(size.width, size.height)) / 2 / extent * 0.92
        func map(_ p: CGPoint) -> CGPoint { CGPoint(x: Double(center.x) + Double(p.x) * unit, y: Double(center.y) - Double(p.y) * unit) }
        func circle(_ r: Double) -> Path { Path(ellipseIn: center.circleRect(r * unit)) }

        ctx.stroke(circle(6), with: .color(Theme.geometry.opacity(0.7)), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
        ctx.label("ISCO 6GM/c²", at: center.polar(6 * unit + 10, Double.pi / 4), color: Theme.geometry, font: .caption2, anchor: .leading)
        ctx.stroke(circle(3), with: .color(Theme.observation.opacity(0.7)), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
        ctx.fill(circle(2), with: .color(.black))
        ctx.stroke(circle(2), with: .color(Color(red: 1, green: 0.35, blue: 0.45)), lineWidth: 1.5)

        // Periapsis directions
        for (i, angle) in trace.periapsisAngles.prefix(12).enumerated() {
            let end = center.polar(extent * unit, -angle)
            ctx.line(center, end, color: Theme.time.opacity(0.18 + 0.5 * Double(i) / 12), width: 1, dash: [3, 4])
        }

        guard trace.points.count > 1 else { return }
        var path = Path()
        path.move(to: map(trace.points[0]))
        for p in trace.points.dropFirst() { path.addLine(to: map(p)) }
        ctx.stroke(path, with: .linearGradient(
            Gradient(colors: [Theme.flow.opacity(0.25), Theme.hypothesis.opacity(0.9), Theme.time]),
            startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: size.width, y: size.height)), lineWidth: 1.4)

        // Moving test particle (uniform in step index — schematic, not proper time).
        let n = trace.points.count
        let idx = Int((t * 240).truncatingRemainder(dividingBy: Double(n)))
        let p = map(trace.points[max(0, min(n - 1, idx))])
        ctx.dot(p, radius: 7, color: .white.opacity(0.25))
        ctx.dot(p, radius: 4, color: .white)
    }
}

// MARK: - Vector field

struct VectorFieldCanvas: View {
    /// Field in the plane; coordinates span −extent…extent.
    let extent: Double
    let field: (Double, Double) -> (Double, Double)
    var density = 21
    var bodyRadius: Double = 0
    var excludeRadius: Double = 0
    var tint: Color = Theme.flow
    var logScale = true
    var axisLabels: (String, String) = ("x", "y")

    var body: some View {
        Canvas { ctx, size in
            let side = Double(min(size.width, size.height))
            let origin = CGPoint(x: size.width / 2, y: size.height / 2)
            let unit = side / 2 / extent
            let step = 2 * extent / Double(density)
            var samples: [(Double, Double, Double, Double, Double)] = []
            var maxLog = -Double.infinity, minLog = Double.infinity
            for i in 0..<density {
                for j in 0..<density {
                    let x = -extent + step * (Double(i) + 0.5)
                    let y = -extent + step * (Double(j) + 0.5)
                    if (x * x + y * y).squareRoot() < excludeRadius { continue }
                    let (vx, vy) = field(x, y)
                    let mag = (vx * vx + vy * vy).squareRoot()
                    guard mag > 0, mag.isFinite else { continue }
                    let lm = log10(mag)
                    maxLog = max(maxLog, lm)
                    minLog = min(minLog, lm)
                    samples.append((x, y, vx / mag, vy / mag, mag))
                }
            }
            let maxMag = samples.map { $0.4 }.max() ?? 1
            for s in samples {
                let norm: Double = logScale
                    ? (maxLog > minLog ? (log10(s.4) - minLog) / (maxLog - minLog) : 1)
                    : s.4 / maxMag
                let len = step * unit * (0.35 + 0.55 * norm)
                let px = Double(origin.x) + s.0 * unit, py = Double(origin.y) - s.1 * unit
                let a = CGPoint(x: px - s.2 * len / 2, y: py + s.3 * len / 2)
                let b = CGPoint(x: px + s.2 * len / 2, y: py - s.3 * len / 2)
                ctx.arrow(from: a, to: b, color: tint.opacity(0.25 + 0.75 * norm), width: 1.3, head: 4.5)
            }
            if bodyRadius > 0 {
                let r = bodyRadius * unit
                ctx.fill(Path(ellipseIn: origin.circleRect(r)),
                         with: .radialGradient(Gradient(colors: [Theme.mass, Theme.mass.opacity(0.3)]), center: origin, startRadius: 0, endRadius: CGFloat(r)))
            }
            ctx.label(axisLabels.0, at: CGPoint(x: Double(size.width) - 12, y: Double(origin.y) - 10), font: .caption, anchor: .trailing)
            ctx.label(axisLabels.1, at: CGPoint(x: Double(origin.x) + 10, y: 12), font: .caption, anchor: .leading)
        }
    }
}
