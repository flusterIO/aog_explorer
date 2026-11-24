//
//  ExplorePages.swift
//  AlphaOmegaGravityVisualizer
//
//  Exploration beyond the paper's explicit results, kept within established physics:
//  non-uniform static stars (extending §2.5.1), rapidity composition (extending §1),
//  and a reference page with the paper's dictionaries.
//

import Foundation
import SwiftUI
import Charts

// MARK: - Star Lab

struct StarLabPage: View {
    @State private var exponent = 1.0
    @State private var compactness = 0.6
    @State private var critical = 0.7724

    var body: some View {
        let solution = StarLab.solve(compactness: compactness, exponent: exponent, outerRadius: 3)
        let s = solution.samples
        let redshift = 1 / (1 - compactness).squareRoot() - 1
        let slice = s.map { SliceSample(id: $0.id, r: $0.x, beta2: $0.beta2, y: $0.y) }

        PageScaffold(page: .starLab) {
            Callout(kind: .insight, title: "An avenue the paper opens", text: "§2.5.1 derives the interior lapse for any static perfect fluid but solves it only for uniform density, noting that Buchdahl's theorem for general profiles is **not derived**. Here the same equations — β² = 2Gm/(c²R) for the slice, N′/N = γ²(β²/2R + 4πGpR/c⁴) and p′ = −(ρc² + p)N′/N — are integrated numerically for ρ = ρ_c(1 − x²)ⁿ.")

            VisualWithControls {
                SceneCard(spec: .from(slice, rings: solution.diverged ? [] : [SurfaceRing(radius: 1, style: .surface)], flow: .none, hue: .star), height: 460) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profileName).font(.headline).foregroundStyle(.white)
                        Text(solution.diverged ? "No static solution: central pressure diverges" : "Slice embedding, lengths in R*")
                            .font(.caption)
                            .foregroundStyle(solution.diverged ? Color(red: 1, green: 0.5, blue: 0.5) : .white.opacity(0.75))
                    }
                    .glassChip()
                }
            } controls: {
                ControlPanel(title: "Density profile ρ = ρ_c(1 − x²)ⁿ") {
                    ParameterSlider(title: "Exponent", symbol: "n", value: $exponent, range: 0...3, tint: Theme.mass, format: { Fmt.fixed($0, 2) })
                    HStack {
                        Button("Uniform") { exponent = 0 }
                        Button("Tolman VII") { exponent = 1 }
                        Button("n = 2") { exponent = 2 }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    ParameterSlider(title: "Compactness", symbol: "r_s/R_*", value: $compactness, range: 0.02...0.95, tint: Theme.time, format: { Fmt.fixed($0, 3) })
                }
                ReadoutGrid(minimum: 140) {
                    Readout(title: "Limiting compactness", value: Fmt.fixed(critical, 4), caption: "uniform: 8/9 = 0.8889", tint: Theme.mass, latex: "C_{max}")
                    Readout(title: "Central pressure", value: solution.diverged ? "∞" : Fmt.sig(solution.centralPressure, 4), unit: "ρ_c c²", tint: solution.diverged ? .red : .primary, latex: "p_c")
                    Readout(title: "Central lapse", value: solution.diverged ? "—" : Fmt.fixed(solution.centralLapse, 4), tint: Theme.geometry, latex: "N(0)")
                    Readout(title: "Surface redshift", value: Fmt.fixed(redshift, 4), latex: "z_*")
                }
            }
            .task(id: exponent) {
                critical = StarLab.criticalCompactness(exponent: exponent)
            }

            HStack(alignment: .top, spacing: 16) {
                ChartCard(title: "Density and pressure", subtitle: "ρ/ρ_c and p/(ρ_c c²) against x = R/R*", height: 260) {
                    let dens = s.filter { $0.x <= 1 }.map { XY(id: $0.id, x: $0.x, y: $0.density, series: "ρ / ρ_c") }
                    let pres = s.filter { $0.x <= 1 }.map { XY(id: $0.id + 100_000, x: $0.x, y: min($0.pressure, 5), series: "p / ρ_c c²") }
                    Chart {
                        ForEach(dens + pres) { p in
                            LineMark(x: .value("x", p.x), y: .value("Value", p.y), series: .value("Curve", p.series))
                                .foregroundStyle(by: .value("Curve", p.series))
                        }
                    }
                    .chartForegroundStyleScale(["ρ / ρ_c": Theme.mass, "p / ρ_c c²": Theme.time])
                    .chartXScale(domain: 0...1)
                    .chartXAxisLabel("x = R / R*")
                    .standardChartStyle()
                }
                ChartCard(title: "Lapse vs slice foreshortening", subtitle: "Outside, N = 1/γ exactly; inside, pressure adds redshift.", height: 260) {
                    let lapse = s.map { XY(id: $0.id, x: $0.x, y: $0.lapse, series: "N") }
                    let tilt = s.map { XY(id: $0.id + 100_000, x: $0.x, y: $0.slopeLapse, series: "1/γ = cos θ") }
                    Chart {
                        ForEach(lapse + tilt) { p in
                            LineMark(x: .value("x", p.x), y: .value("Value", p.y), series: .value("Curve", p.series))
                                .foregroundStyle(by: .value("Curve", p.series))
                                .lineStyle(StrokeStyle(lineWidth: p.series == "N" ? 3 : 1.5, dash: p.series == "N" ? [] : [5, 4]))
                        }
                        RuleMark(x: .value("x", 1.0))
                            .foregroundStyle(Theme.mass.opacity(0.6))
                            .annotation(position: .top, alignment: .leading) { Text("R*").font(.caption2).foregroundStyle(Theme.mass) }
                    }
                    .chartForegroundStyleScale(["N": Theme.geometry, "1/γ = cos θ": Theme.time])
                    .chartYScale(domain: 0...1)
                    .chartXAxisLabel("x = R / R*")
                    .standardChartStyle()
                }
            }

            ChartCard(title: "β² = 2Gm(R)/(c²R) across the star", subtitle: "Its maximum sits inside the surface for centrally concentrated profiles.", height: 220) {
                Chart {
                    ForEach(s) { p in
                        AreaMark(x: .value("x", p.x), y: .value("β²", p.beta2))
                            .foregroundStyle(LinearGradient(colors: [Theme.flow.opacity(0.4), Theme.flow.opacity(0.03)], startPoint: .top, endPoint: .bottom))
                        LineMark(x: .value("x", p.x), y: .value("β²", p.beta2))
                            .foregroundStyle(Theme.flow)
                    }
                }
                .chartXAxisLabel("x = R / R*")
                .standardChartStyle()
            }

            HStack(alignment: .top, spacing: 16) {
                Callout(kind: .result, title: "Checks", text: "n = 0 reproduces the interior Schwarzschild solution and the bound r_s/R* < 8/9. n = 1 (Tolman VII) gives a limit near 0.772, the value known for that solution.")
                Callout(kind: .caveat, title: "Scope", text: "The density profile is prescribed rather than derived from an equation of state, and the equations are those of GR expressed through the embedding — this probes the construction's GR sector, not a departure from it.")
            }
        }
    }

    private var profileName: String {
        switch exponent {
        case 0: "Uniform density (n = 0)"
        case 1: "Tolman VII (n = 1)"
        default: "ρ ∝ (1 − x²)^\(Fmt.fixed(exponent, 2))"
        }
    }
}

// MARK: - Rapidity composition

struct RapidityPage: View {
    @State private var beta1 = 0.6
    @State private var beta2 = 0.5

    var body: some View {
        let g1 = Lorentz.gamma(beta: beta1), g2 = Lorentz.gamma(beta: beta2)
        let s1 = Lorentz.slope(beta: beta1), s2 = Lorentz.slope(beta: beta2)
        let composed = Lorentz.compose(beta1, beta2)
        let sComposed = Lorentz.slope(beta: composed)
        let sRule = s1 * g2 + g1 * s2
        let eta1 = Lorentz.rapidity(beta: beta1), eta2 = Lorentz.rapidity(beta: beta2)

        PageScaffold(page: .rapidity) {
            VisualWithControls {
                StageCard(height: 440) {
                    RapidityHyperbola(eta1: eta1, eta2: eta2)
                        .padding(16)
                }
            } controls: {
                ControlPanel(title: "Two boosts") {
                    ParameterSlider(title: "First boost", symbol: "\\beta_1", value: $beta1, range: 0...0.95, tint: Theme.flow, format: { Fmt.fixed($0, 3) })
                    ParameterSlider(title: "Second boost", symbol: "\\beta_2", value: $beta2, range: 0...0.95, tint: Theme.time, format: { Fmt.fixed($0, 3) })
                }
                ReadoutGrid(minimum: 140) {
                    Readout(title: "Composed velocity", value: Fmt.fixed(composed, 4), tint: Theme.hypothesis, latex: "\\beta_1\\oplus\\beta_2")
                    Readout(title: "Galilean sum", value: Fmt.fixed(beta1 + beta2, 4), caption: beta1 + beta2 > 1 ? "exceeds c" : nil, latex: "\\beta_1+\\beta_2")
                    Readout(title: "Composed slope", value: Fmt.fixed(sComposed, 4), tint: Theme.hypothesis, latex: "\\sinh(\\eta_1+\\eta_2)")
                    Readout(title: "Slope rule", value: Fmt.fixed(sRule, 4), caption: "s₁γ₂ + γ₁s₂", latex: "\\partial_x y")
                }
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                EquationCard(title: "Rapidities add", latex: "\\eta=\\eta_1+\\eta_2,\\qquad \\beta=\\tanh\\eta=\\frac{\\beta_1+\\beta_2}{1+\\beta_1\\beta_2}", status: .identity, note: "Standard special relativity.")
                EquationCard(title: "…so slopes compose hyperbolically", latex: "\\partial_x y=\\sinh(\\eta_1+\\eta_2)=s_1\\gamma_2+\\gamma_1 s_2,\\qquad \\gamma=\\gamma_1\\gamma_2+s_1s_2", status: .exploration, note: "In the slope language of §2.2, two successive embeddings with slopes s₁, s₂ combine with γ-weights; the slope never needs a speed limit, γ = √(1 + s²) stays finite for any finite s.")
            }

            ChartCard(title: "Composed velocity against the second boost", subtitle: "β₁ fixed; relativistic composition saturates at 1, Galilean addition does not.", height: 260) {
                let xs = Sampling.linear(0, 0.99, 140)
                let rel = sample(xs, series: "β₁ ⊕ β₂") { Lorentz.compose(beta1, $0) }
                let gal = sample(xs, series: "β₁ + β₂") { beta1 + $0 }
                Chart {
                    ForEach(rel + gal) { p in
                        LineMark(x: .value("β₂", p.x), y: .value("β", p.y), series: .value("Curve", p.series))
                            .foregroundStyle(by: .value("Curve", p.series))
                    }
                    RuleMark(y: .value("β", 1.0))
                        .foregroundStyle(Color.red.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    PointMark(x: .value("β₂", beta2), y: .value("β", composed))
                        .foregroundStyle(Theme.hypothesis)
                        .symbolSize(100)
                }
                .chartForegroundStyleScale(["β₁ ⊕ β₂": Theme.hypothesis, "β₁ + β₂": Color.secondary])
                .chartXAxisLabel("β₂")
                .standardChartStyle()
            }

            Callout(kind: .note, text: "Composition of non-collinear boosts adds a Wigner rotation, which the one-dimensional slope picture does not capture. Extending y to that case is one of the open questions the paper lists for finite intervals and clock synchronisation.")
        }
    }
}

/// Unit hyperbola (cosh η, sinh η) with the two boosts and their composition.
struct RapidityHyperbola: View {
    let eta1: Double
    let eta2: Double

    var body: some View {
        Canvas { ctx, size in
            let w = Double(size.width), h = Double(size.height)
            let etaMax = asinh(3.6)
            let unit = min((w - 60) / (cosh(etaMax) + 0.4), (h - 40) / 4.0)
            let ox = 40.0, oy = h - 30
            func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: ox + x * unit, y: oy - y * unit) }

            ctx.arrow(from: pt(0, 0), to: pt(cosh(etaMax) + 0.3, 0), color: .secondary, width: 1)
            ctx.arrow(from: pt(0, 0), to: pt(0, 3.85), color: .secondary, width: 1)
            ctx.label("γ = cosh η", at: pt(cosh(etaMax) + 0.3, -0.18), anchor: .trailing)
            ctx.label("∂ₓy = sinh η", at: pt(0.08, 3.85), anchor: .leading)

            var hyp = Path()
            for (i, e) in Sampling.linear(0, etaMax, 120).enumerated() {
                let p = pt(cosh(e), sinh(e))
                if i == 0 { hyp.move(to: p) } else { hyp.addLine(to: p) }
            }
            ctx.stroke(hyp, with: .color(Theme.geometry), lineWidth: 2.5)

            func marker(_ eta: Double, _ color: Color, _ label: String) {
                let e = min(eta, etaMax)
                let p = pt(cosh(e), sinh(e))
                ctx.line(pt(0, 0), p, color: color.opacity(0.7), width: 1.5)
                ctx.line(p, pt(cosh(e), 0), color: color.opacity(0.4), width: 1, dash: [3, 3])
                ctx.dot(p, radius: 6, color: color)
                ctx.label(label, at: CGPoint(x: Double(p.x) + 10, y: Double(p.y)), color: color, font: .caption.weight(.semibold), anchor: .leading)
            }
            marker(eta1, Theme.flow, "η₁")
            marker(eta2, Theme.time, "η₂")
            marker(eta1 + eta2, Theme.hypothesis, "η₁ + η₂")
            ctx.label("cosh²η − sinh²η = 1: every boost lies on this curve", at: CGPoint(x: 16, y: 18), color: .secondary, font: .callout, anchor: .leading)
        }
    }
}

// MARK: - Reference

struct ReferencePage: View {
    @Environment(NavigationModel.self) private var navigation

    private let dictionary: [(String, String)] = [
        ("\\beta c=v", "shift vector (“river velocity”), escape velocity from the enclosed mass"),
        ("\\gamma", "Lorentz factor between the flow and static observers; 1/γ is the static lapse"),
        ("y(R),\\ \\partial_R y=\\beta\\gamma", "Flamm embedding of the static slice, dℓ² = dR² + dy²"),
        ("\\partial_\\tau y=\\frac{v^2}{\\sqrt{c^2-v^2}}", "dy/dT along a free-fall worldline"),
        ("\\delta(M,R)=\\frac{2GM}{R^3}", "radial tidal eigenvalue"),
    ]

    var body: some View {
        PageScaffold(page: .reference) {
            Card {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Quantities of the paper and their standard counterparts").font(.headline)
                    Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 14) {
                        ForEach(dictionary.indices, id: \.self) { i in
                            GridRow {
                                Equation(dictionary[i].0, size: 16)
                                Text(dictionary[i].1).foregroundStyle(.secondary)
                            }
                        }
                    }
                    Text("Table 1 of the manuscript.").font(.caption).foregroundStyle(.tertiary)
                }
            }

            SectionHeading(title: "Status badges")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 12)], alignment: .leading, spacing: 12) {
                ForEach(ClaimStatus.allCases) { status in
                    Card(padding: 14) {
                        VStack(alignment: .leading, spacing: 8) {
                            StatusBadge(status: status)
                            Text(status.blurb).font(.callout).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            SectionHeading(title: "Pages and where they live in the paper")
            Card {
                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                    ForEach(Page.allCases.filter { $0 != .home }) { page in
                        GridRow {
                            Button {
                                navigation.go(page)
                            } label: {
                                Label(page.title, systemImage: page.systemImage)
                            }
                            .buttonStyle(.link)
                            Text(page.paperReference).font(.callout.monospaced()).foregroundStyle(.secondary)
                            Text(page.section.title).font(.callout).foregroundStyle(page.section.color)
                        }
                    }
                }
            }

            SectionHeading(title: "Data and measurements used")
            Card {
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Milky Way circular velocities: Eilers et al. (2019), 38 radii from 5.3 to 24.8 kpc.")
                    Text("• Enclosed baryonic mass 4.44 × 10¹⁰ M☉ within R₀ = 8.12 kpc (Cautun et al. 2020; GRAVITY 2018).")
                    Text("• CMB dipole 369.82 ± 0.11 km/s (Planck 2018).")
                    Text("• γ_PPN − 1 = (2.1 ± 2.3) × 10⁻⁵ (Cassini, Bertotti et al. 2003).")
                    Text("• Frame dragging 37.2 ± 7.2 mas/yr (Gravity Probe B, Everitt et al. 2011).")
                    Text("• Radial acceleration relation interpolation (McGaugh et al. 2016).")
                    Text("• CODATA values for c, G, e, h, μ₀, ε₀ and α.")
                }
                .font(.callout)
                .foregroundStyle(.secondary)
            }
        }
    }
}
