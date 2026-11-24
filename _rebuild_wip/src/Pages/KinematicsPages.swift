//
//  KinematicsPages.swift
//  AlphaOmegaGravityVisualizer
//
//  §1.1 the lighthouse & clock-tower, §2.2 γ as a slope, §2.2.1 the Minkowski interval.
//

import SwiftUI
import Charts

// MARK: - Lighthouse & clock-tower

struct LighthousePage: View {
    @Environment(ParameterStore.self) private var params
    @State private var beta = 0.6
    @State private var distanceLightSeconds = 1.0
    @State private var animate = true

    var body: some View {
        let gamma = Lorentz.gamma(beta: beta)
        let v = beta * params.c
        let d = distanceLightSeconds * params.c
        let classical = d / v
        let dilated = gamma * d / v

        PageScaffold(page: .lighthouse) {
            VisualWithControls {
                StageCard(height: 460, dark: true) {
                    LighthouseDiagram(beta: beta, animate: animate)
                        .padding(20)
                }
            } controls: {
                ControlPanel(title: "Experiment") {
                    ParameterSlider(title: "Agreed velocity", symbol: "\\beta = v'/c", value: $beta, range: 0.01...0.98, tint: Theme.time, format: { Fmt.fixed($0, 3) })
                    ParameterSlider(title: "Distance p₁ → p₂", symbol: "d", value: $distanceLightSeconds, range: 0.1...10, unit: "light-s", format: { Fmt.fixed($0, 2) })
                    Toggle("Animate traveller B", isOn: $animate)
                }
                ReadoutGrid(minimum: 140) {
                    Readout(title: "Lorentz factor", value: Fmt.fixed(gamma, 4), latex: "\\gamma")
                    Readout(title: "Elapsed, both agree", value: Fmt.sig(dilated, 4), unit: "s", tint: Theme.time, latex: "\\Delta t")
                    Readout(title: "Classical d/v′", value: Fmt.sig(classical, 4), unit: "s", latex: "d/v'")
                    Readout(title: "Seen by A", value: Fmt.kms(v / gamma, 0), latex: "v'^{(S)}")
                }
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                EquationCard(
                    title: "Coordinate transformations for each observer",
                    latex: "\\Delta t=\\frac{d\\cdot\\gamma}{v^{(U)}}=\\frac{d}{v^{(S)}}=\\frac{d}{v^{(U)}\\left(\\frac{1}{\\gamma}\\right)}",
                    status: .assumption,
                    note: "B computes the left side, A the right. Velocity dilates inversely with coordinate density, so v′⁽ˢ⁾ = v′⁽ᵁ⁾/γ — consistent with a measuring rod in each frame, as c is treated now.",
                    reference: "§1.1"
                )
                EquationCard(
                    title: "Displacement carried by the fourth coordinate",
                    latex: "dy=v\\tau\\sqrt{\\gamma^2-1},\\qquad dx^{(U)}=\\sqrt{dx^2+dy^2}=\\gamma\\,dx",
                    status: .identity,
                    note: "Simultaneity is kept classical in ℝ³; the extra separation lives along y. Here Δy = \(Fmt.fixed(beta * gamma * distanceLightSeconds, 3)) light-seconds.",
                    reference: "§1, Fig. 1"
                )
            }

            ChartCard(title: "Elapsed time for the trip", subtitle: "Both observers agree on Δt = γd/v′, the value required by lifetime-dilation experiments.", height: 280) {
                let xs = Grid.linear(0.05, 0.98, 160)
                let data = sample(xs, series: "γ d / v′") { b in Lorentz.gamma(beta: b) * distanceLightSeconds / b }
                    + sample(xs, series: "d / v′ (Galilean)") { b in distanceLightSeconds / b }
                Chart {
                    ForEach(data.filter { $0.y < 40 }) { p in
                        LineMark(x: .value("β", p.x), y: .value("Δt (s)", p.y), series: .value("Curve", p.series))
                            .foregroundStyle(by: .value("Curve", p.series))
                            .interpolationMethod(.catmullRom)
                    }
                    RuleMark(x: .value("β", beta))
                        .foregroundStyle(Color.secondary)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    PointMark(x: .value("β", beta), y: .value("Δt (s)", min(dilated, 40)))
                        .foregroundStyle(Theme.time)
                        .symbolSize(90)
                }
                .chartForegroundStyleScale(["γ d / v′": Theme.time, "d / v′ (Galilean)": Theme.flow])
                .chartYScale(domain: .automatic(includesZero: true))
                .chartXAxisLabel("β = v′/c")
                .chartYAxisLabel("Δt (s)")
                .standardChartStyle()
            }

            HStack(alignment: .top, spacing: 16) {
                Callout(kind: .note, title: "Assertions of the thought experiment", text: "1. To keep a classical model of simultaneity in ℝ³, A and B must agree on the time at which B reaches p₂.\n2. To satisfy the measured additional γ factor (Rossi 1941; Frisch & Smith 1963; Bailey 1977, 1979; Botermann 2014), Δt = γd/v.")
                Callout(kind: .caveat, title: "Open question", text: "Whether this classical simultaneity is consistent for finite intervals and for clock synchronisation is **not established** in the paper (Discussion §4.1).")
            }
            Callout(kind: .result, title: "Muon storage ring", text: "At γ = 29.33 (CERN, Bailey et al. 1977) the dilated lifetime is γτ₀ = 29.33 × 2.197 μs ≈ \(Fmt.fixed(29.33 * 2.197, 1)) μs, matching the measured lifetime — the factor this construction is required to reproduce.")
        }
    }
}

// MARK: - γ as a slope

struct SlopePage: View {
    @Environment(ParameterStore.self) private var params
    @State private var beta = 0.6

    var body: some View {
        let gamma = Lorentz.gamma(beta: beta)
        let slope = Lorentz.slope(beta: beta)
        let eta = Lorentz.rapidity(beta: beta)
        let dyDtau = Lorentz.dyDtau(beta: beta, c: params.c)
        let check = Lorentz.beta(gamma: gamma) * params.c * slope

        PageScaffold(page: .slope) {
            VisualWithControls {
                StageCard(height: 440) {
                    SlopeTriangleDiagram(beta: beta)
                }
            } controls: {
                ControlPanel(title: "Velocity") {
                    ParameterSlider(title: "Velocity", symbol: "\\beta = v/c", value: $beta, range: 0...0.97, tint: Theme.time, format: { Fmt.fixed($0, 3) })
                }
                ReadoutGrid(minimum: 140) {
                    Readout(title: "Lorentz factor", value: Fmt.fixed(gamma, 4), tint: Theme.geometry, latex: "\\gamma")
                    Readout(title: "Slope", value: Fmt.fixed(slope, 4), tint: Theme.time, latex: "\\partial_x y")
                    Readout(title: "Rapidity", value: Fmt.fixed(eta, 4), latex: "\\eta")
                    Readout(title: "Tilt", value: Fmt.fixed(atan(slope) * 180 / Double.pi, 2) + "°", latex: "\\theta")
                }
                Card(padding: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Closure check").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        Equation("v(\\gamma)\\,\\partial_x y=\\partial_\\tau y", size: 16)
                        Text("\(Fmt.sig(check, 6)) = \(Fmt.sig(dyDtau, 6)) m/s")
                            .font(.callout.monospacedDigit())
                        Text("Relative difference \(Fmt.sci(abs(check - dyDtau) / max(dyDtau, 1e-300), 2))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                EquationCard(title: "The additional coordinate", latex: "y=\\tau\\frac{v^2}{\\sqrt{c^2-v^2}}=x\\frac{v}{\\sqrt{c^2-v^2}}", status: .assumption, reference: "Eq. (8)", size: 18)
                EquationCard(title: "Its two gradients", latex: "\\partial_\\tau y=\\frac{v^2}{\\sqrt{c^2-v^2}},\\quad \\partial_x y=\\frac{\\gamma v}{c}", status: .identity, reference: "§2.2", size: 18)
                EquationCard(title: "γ as the slope", latex: "\\gamma=\\sqrt{1+(\\partial_x y)^2}", status: .identity, note: "With γ = cosh η and ∂ₓy = sinh η this is cosh²η = 1 + sinh²η.", reference: "Eq. (21)", size: 22)
            }

            HStack(alignment: .top, spacing: 16) {
                ChartCard(title: "γ, ∂ₓy and ∂_τy against β", height: 300) {
                    let xs = Grid.linear(0, 0.97, 200)
                    let data = sample(xs, series: "γ") { Lorentz.gamma(beta: $0) }
                        + sample(xs, series: "∂ₓy = βγ") { Lorentz.slope(beta: $0) }
                        + sample(xs, series: "∂τy / c = β²γ") { $0 * Lorentz.slope(beta: $0) }
                    Chart {
                        ForEach(data) { p in
                            LineMark(x: .value("β", p.x), y: .value("Value", p.y), series: .value("Curve", p.series))
                                .foregroundStyle(by: .value("Curve", p.series))
                        }
                        RuleMark(x: .value("β", beta))
                            .foregroundStyle(Color.secondary)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                    .chartForegroundStyleScale(["γ": Theme.geometry, "∂ₓy = βγ": Theme.time, "∂τy / c = β²γ": Theme.flow])
                    .chartXAxisLabel("β")
                    .standardChartStyle()
                }
                ChartCard(title: "γ as a function of the slope", subtitle: "Hyperbola γ = √(1 + s²) with asymptote γ = s", height: 300) {
                    let xs = Grid.linear(0, 4.2, 160)
                    let data = sample(xs, series: "γ = √(1 + s²)") { Lorentz.gammaFromSlope($0) }
                        + sample(xs, series: "γ = s") { $0 }
                    Chart {
                        ForEach(data) { p in
                            LineMark(x: .value("∂ₓy", p.x), y: .value("γ", p.y), series: .value("Curve", p.series))
                                .foregroundStyle(by: .value("Curve", p.series))
                                .lineStyle(StrokeStyle(lineWidth: p.series == "γ = s" ? 1 : 2.5, dash: p.series == "γ = s" ? [4, 4] : []))
                        }
                        PointMark(x: .value("∂ₓy", slope), y: .value("γ", gamma))
                            .foregroundStyle(Theme.time)
                            .symbolSize(110)
                            .annotation(position: .topLeading) {
                                Text("β = \(Fmt.fixed(beta, 2))").font(.caption).foregroundStyle(.secondary)
                            }
                    }
                    .chartForegroundStyleScale(["γ = √(1 + s²)": Theme.geometry, "γ = s": Color.secondary])
                    .chartXAxisLabel("slope s = ∂ₓy")
                    .standardChartStyle()
                }
            }

            Callout(kind: .insight, title: "Where the content lies", text: "The identity itself is elementary. The construction's content is in using it as the **slope of an embedding** — the same βγ reappears as ∂_R y of the Flamm paraboloid, where β c is the Painlevé–Gullstrand flow velocity.")
        }
    }
}

// MARK: - Minkowski interval

struct IntervalPage: View {
    @State private var beta = 0.6

    var body: some View {
        let gamma = Lorentz.gamma(beta: beta)
        let ct = -gamma * beta
        let dx = gamma
        let interval = ct * ct - dx * dx

        PageScaffold(page: .interval) {
            VisualWithControls {
                StageCard(height: 440) {
                    MinkowskiDiagram(beta: beta)
                        .padding(12)
                }
            } controls: {
                ControlPanel(title: "Boost") {
                    ParameterSlider(title: "Velocity", symbol: "\\beta", value: $beta, range: 0...0.95, tint: Theme.time, format: { Fmt.fixed($0, 3) })
                }
                ReadoutGrid(minimum: 140) {
                    Readout(title: "dx′ / dx", value: Fmt.fixed(dx, 4), tint: Theme.flow, latex: "\\gamma")
                    Readout(title: "c dt′ / dx", value: Fmt.fixed(ct, 4), tint: Theme.time, latex: "-\\gamma\\beta")
                    Readout(title: "ds′² / dx²", value: Fmt.fixed(interval, 6), caption: "invariant: always −1", tint: Theme.geometry)
                }
                Callout(kind: .note, text: "For dt = 0 these coincide with the standard Lorentz transformation of an event separated by dx — a **consistency check**, not an independent derivation.")
            }

            HStack(alignment: .top, spacing: 16) {
                EquationCard(
                    title: "Instantaneous transformations (dt → 0)",
                    latex: "dx'=\\gamma\\,dx=v^{(U)},\\qquad c\\,dt'=-\\gamma\\frac{v}{c}dx=-\\partial_\\tau y",
                    status: .identity,
                    reference: "§2.2"
                )
                EquationCard(
                    title: "Invariance",
                    latex: "ds'^2=\\gamma^2dx^2\\left(\\frac{v^2}{c^2}-1\\right)=-dx^2=ds^2",
                    status: .identity,
                    reference: "§2.2.1"
                )
            }

            ChartCard(title: "Components grow, the interval does not", subtitle: "(c dt′)² and (dx′)² diverge as β → 1; their difference stays at −dx².", height: 300) {
                let xs = Grid.linear(0, 0.95, 160)
                let data = sample(xs, series: "(dx′)²") { b in pow(Lorentz.gamma(beta: b), 2) }
                    + sample(xs, series: "(c dt′)²") { b in pow(Lorentz.slope(beta: b), 2) }
                    + sample(xs, series: "ds′² = (c dt′)² − (dx′)²") { _ in -1 }
                Chart {
                    ForEach(data) { p in
                        LineMark(x: .value("β", p.x), y: .value("Value", p.y), series: .value("Curve", p.series))
                            .foregroundStyle(by: .value("Curve", p.series))
                    }
                    RuleMark(x: .value("β", beta))
                        .foregroundStyle(Color.secondary)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
                .chartForegroundStyleScale(["(dx′)²": Theme.flow, "(c dt′)²": Theme.time, "ds′² = (c dt′)² − (dx′)²": Theme.geometry])
                .chartXAxisLabel("β")
                .chartYAxisLabel("in units of dx²")
                .standardChartStyle()
            }
        }
    }
}
