//
//  GeometryPages.swift
//  AlphaOmegaGravityVisualizer
//
//  §2.3–2.4: the Flamm embedding, β² = 2Gm/(c²R) for three mass distributions,
//  the component G₄₄ and the four-potential 𝒜_μ = ∂_μ y.
//

import SwiftUI
import Charts

// MARK: - Flamm embedding

struct FlammPage: View {
    @State private var extent = 14.0
    @State private var probe = 3.0
    @State private var exaggeration = 1.0
    @State private var showFlow = true
    @State private var autoRotate = true

    var body: some View {
        let slice = Embedding.exteriorSlice(rMax: extent, count: 170)
        let r0 = min(max(probe, 1.02), extent)
        let b2 = 1 / r0
        let beta = b2.squareRoot()
        let gamma = 1 / (1 - b2).squareRoot()
        let slope = beta * gamma

        PageScaffold(page: .flamm) {
            VisualWithControls {
                SceneCard(
                    spec: .from(slice, rings: [
                        SurfaceRing(radius: 1.0005, style: .horizon),
                        SurfaceRing(radius: 1.5, style: .marker),
                        SurfaceRing(radius: 3, style: .accent),
                        SurfaceRing(radius: r0, style: .surface),
                    ], flow: showFlow ? .inward : .none, verticalScale: exaggeration),
                    height: 500,
                    autoRotate: autoRotate
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        LegendChip(label: "R = r_s (throat)", color: Color(red: 1, green: 0.35, blue: 0.45))
                        LegendChip(label: "R = 1.5 r_s (photon sphere)", color: Color(red: 0.45, green: 0.95, blue: 0.75))
                        LegendChip(label: "R = 3 r_s (ISCO)", color: .white)
                        LegendChip(label: "Probe R = \(Fmt.fixed(r0, 2)) r_s", color: Color(red: 1, green: 0.75, blue: 0.35))
                    }
                    .glassChip()
                }
            } controls: {
                ControlPanel(title: "Embedding") {
                    ParameterSlider(title: "Extent", symbol: "R_{max}/r_s", value: $extent, range: 4...40, format: { Fmt.fixed($0, 1) })
                    ParameterSlider(title: "Probe radius", symbol: "R/r_s", value: $probe, range: 1.02...40, scale: .log, tint: Theme.mass, format: { Fmt.fixed($0, 2) })
                    ParameterSlider(title: "Vertical exaggeration", value: $exaggeration, range: 0.25...3, format: { Fmt.fixed($0, 2) + "×" })
                    Toggle("Flow tracers (βc)", isOn: $showFlow)
                    Toggle("Auto-rotate", isOn: $autoRotate)
                }
                ReadoutGrid(minimum: 140) {
                    Readout(title: "Flow speed", value: Fmt.fixed(beta, 4), tint: Theme.flow, latex: "\\beta")
                    Readout(title: "Slope", value: Fmt.fixed(slope, 4), tint: Theme.time, latex: "\\partial_R y")
                    Readout(title: "Tilt", value: Fmt.fixed(asin(beta) * 180 / Double.pi, 2) + "°", latex: "\\theta")
                    Readout(title: "Lapse", value: Fmt.fixed(1 / gamma, 4), tint: Theme.geometry, latex: "N=\\cos\\theta")
                }
            }

            HStack(alignment: .top, spacing: 16) {
                ChartCard(title: "Cross-section y(R)", subtitle: "Both branches ±; the tangent at the probe has slope βγ and tilt θ with sin θ = β.", height: 300) {
                    let upper = slice.map { XY(id: $0.id, x: $0.r, y: $0.y, series: "+") }
                    let lower = slice.map { XY(id: $0.id + 10_000, x: $0.r, y: -$0.y, series: "−") }
                    let y0 = Embedding.yExterior(r0)
                    let tangent = Grid.linear(max(1, r0 - 2.5), min(extent, r0 + 2.5), 20).enumerated().map { i, r in
                        XY(id: 20_000 + i, x: r, y: y0 + slope * (r - r0), series: "tangent")
                    }
                    Chart {
                        ForEach(upper + lower) { p in
                            LineMark(x: .value("R / r_s", p.x), y: .value("y / r_s", p.y), series: .value("Branch", p.series))
                                .foregroundStyle(Theme.flow)
                                .lineStyle(StrokeStyle(lineWidth: 2.5))
                        }
                        ForEach(tangent) { p in
                            LineMark(x: .value("R / r_s", p.x), y: .value("y / r_s", p.y), series: .value("Branch", "tangent"))
                                .foregroundStyle(Theme.mass)
                                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                        }
                        PointMark(x: .value("R / r_s", r0), y: .value("y / r_s", y0))
                            .foregroundStyle(Theme.mass)
                            .symbolSize(90)
                        RuleMark(x: .value("R / r_s", 1.0))
                            .foregroundStyle(Color(red: 1, green: 0.35, blue: 0.45).opacity(0.7))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    }
                    .chartXAxisLabel("R / r_s")
                    .chartYAxisLabel("y / r_s")
                    .standardChartStyle()
                }
                ChartCard(title: "Slice functions", subtitle: "Exterior, β² = r_s/R", height: 300) {
                    let xs = Grid.log(1.02, extent, 180)
                    let data = sample(xs, series: "β") { (1 / $0).squareRoot() }
                        + sample(xs, series: "N = 1/γ") { (1 - 1 / $0).squareRoot() }
                        + sample(xs, series: "∂_R y = βγ") { min(4, (1 / ($0 - 1)).squareRoot()) }
                    Chart {
                        ForEach(data) { p in
                            LineMark(x: .value("R / r_s", p.x), y: .value("Value", p.y), series: .value("Curve", p.series))
                                .foregroundStyle(by: .value("Curve", p.series))
                        }
                        RuleMark(x: .value("R / r_s", r0))
                            .foregroundStyle(Theme.mass.opacity(0.7))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                    .chartXScale(type: .log)
                    .chartForegroundStyleScale(["β": Theme.flow, "N = 1/γ": Theme.geometry, "∂_R y = βγ": Theme.time])
                    .chartXAxisLabel("R / r_s")
                    .standardChartStyle()
                }
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                EquationCard(title: "Induced radial metric", latex: "h_{RR}=1+G_{44}\\left(\\frac{dy}{dR}\\right)^2=\\frac{1}{1-\\beta^2}=\\gamma^2", status: .equivalentGR, note: "Requiring the Schwarzschild radial component with ∂_R y = βγ fixes G₄₄ = 1 to all orders in r_s/R.", reference: "§2.3.4")
                EquationCard(title: "Embedding profile", latex: "\\frac{dy}{dR}=\\pm\\sqrt{\\frac{r_s}{R-r_s}},\\qquad y(R)=\\pm2\\sqrt{r_s(R-r_s)}+C", status: .equivalentGR, reference: "App. B")
                EquationCard(title: "Tilt of the slice", latex: "\\tan\\theta=\\partial_R y,\\quad \\sin\\theta=\\beta,\\quad \\cos\\theta=\\frac{1}{\\gamma}=\\frac{dR}{d\\ell}", status: .identity, reference: "§2.5")
                EquationCard(title: "Proper radial length", latex: "d\\ell=\\gamma\\,dR,\\qquad d\\ell^2=dR^2+dy^2", status: .identity, note: "At the probe, a coordinate step dR is \(Fmt.fixed(gamma, 3)) dR of proper length.", reference: "§2.9.1")
            }

            Callout(kind: .caveat, title: "A spatial metric is not a spacetime", text: "Reproducing the Schwarzschild slice does not by itself establish the four-dimensional field. The temporal function N(R) is supplied separately — see **Lapse from the Embedding**, where it follows in vacuum from the Gauss equation and the static field equations.")
        }
    }
}

// MARK: - Mass distributions

struct DistributionsPage: View {
    @Environment(ParameterStore.self) private var params
    @State private var distribution: MassDistribution = .uniformStar
    @State private var starRadius = 2.5
    @State private var showFlow = true

    private var slice: [SliceSample] {
        switch distribution {
        case .pointMass: Embedding.exteriorSlice(rMax: 12, count: 170)
        case .uniformStar: Embedding.uniformStarSlice(starRadius: starRadius, rMax: max(10, 3.5 * starRadius), count: 220)
        case .criticalDensity: Embedding.hubbleSlice(rMax: 0.995, count: 170)
        }
    }

    private var spec: SurfaceSpec {
        switch distribution {
        case .pointMass:
            return .from(slice, rings: [SurfaceRing(radius: 1.0005, style: .horizon)], flow: showFlow ? .inward : .none)
        case .uniformStar:
            return .from(slice, rings: [SurfaceRing(radius: starRadius, style: .surface)], flow: showFlow ? .inward : .none, hue: .star)
        case .criticalDensity:
            return .from(slice, rings: [SurfaceRing(radius: 0.5, style: .marker), SurfaceRing(radius: 0.99, style: .horizon)], flow: showFlow ? .outward : .none, hue: .cosmos)
        }
    }

    var body: some View {
        let s = slice
        let curvature = Embedding.scalarCurvature(s)
        let unit = distribution == .criticalDensity ? "L = c/H" : "r_s"

        PageScaffold(page: .distributions) {
            VisualWithControls {
                SceneCard(spec: spec, height: 480) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(distribution.rawValue).font(.headline).foregroundStyle(.white)
                        Text("Static-slice embedding: \(distribution.embeddingDescription)")
                            .font(.caption).foregroundStyle(.white.opacity(0.75))
                        Text("Flow: \(distribution.flowDescription)")
                            .font(.caption).foregroundStyle(.white.opacity(0.75))
                    }
                    .glassChip()
                }
            } controls: {
                ControlPanel(title: "Mass distribution") {
                    Picker("Distribution", selection: $distribution) {
                        ForEach(MassDistribution.allCases) { d in Text(d.rawValue).tag(d) }
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()
                    if distribution == .uniformStar {
                        ParameterSlider(title: "Star radius", symbol: "R_*/r_s", value: $starRadius, range: 1.13...8, tint: Theme.mass, format: { Fmt.fixed($0, 2) })
                    }
                    Toggle("Flow tracers", isOn: $showFlow)
                }
                ReadoutGrid(minimum: 140) {
                    switch distribution {
                    case .pointMass:
                        Readout(title: "Throat", value: "R = r_s", latex: "\\beta=1")
                        Readout(title: "³R outside", value: "0", caption: "vacuum: flat in the mean", latex: "{}^{(3)}R")
                    case .uniformStar:
                        let star = UniformStar(radius: starRadius)
                        Readout(title: "Cap radius", value: Fmt.fixed(star.L2.squareRoot(), 3), unit: "r_s", latex: "L")
                        Readout(title: "Surface tilt", value: Fmt.fixed(star.surfaceTiltDegrees, 1) + "°", tint: star.isStable ? .primary : .red, latex: "\\theta_*")
                        Readout(title: "Surface γ", value: Fmt.fixed(star.surfaceGamma, 3), latex: "\\gamma_*")
                        Readout(title: "³R inside", value: Fmt.fixed(6 / star.L2, 4), unit: "/r_s²", latex: "6/L^2")
                    case .criticalDensity:
                        Readout(title: "Hubble radius", value: Fmt.fixed(params.hubbleRadius / (SI.Mpc * 1_000), 3), unit: "Gpc", latex: "c/H_0")
                        Readout(title: "Critical density", value: Fmt.sci(params.criticalDensity, 3), unit: "kg/m³", latex: "\\rho_c")
                    }
                }
            }

            HStack(alignment: .top, spacing: 16) {
                ChartCard(title: "β²(R) = 2Gm(R)/(c²R)", subtitle: "The same relation applied to a different m(R).", height: 280) {
                    Chart {
                        ForEach(s) { p in
                            LineMark(x: .value("R", p.r), y: .value("β²", p.beta2))
                                .foregroundStyle(distribution == .uniformStar ? Theme.mass : Theme.flow)
                                .interpolationMethod(.monotone)
                        }
                        RuleMark(y: .value("β²", 1))
                            .foregroundStyle(Color.red.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("β = 1 horizon").font(.caption2).foregroundStyle(.red)
                            }
                        if distribution == .uniformStar {
                            RuleMark(x: .value("R", starRadius))
                                .foregroundStyle(Theme.mass.opacity(0.6))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        }
                    }
                    .chartXAxisLabel("R / \(unit)")
                    .chartYScale(domain: 0...1.05)
                    .standardChartStyle()
                }
                ChartCard(title: "Density from the Hessian of y", subtitle: "Gauss: ³R = (2/R²) d(Rβ²)/dR = 16πGρ/c², computed numerically from the slice.", height: 280) {
                    Chart {
                        ForEach(curvature) { p in
                            AreaMark(x: .value("R", p.x), y: .value("³R", p.y))
                                .foregroundStyle(LinearGradient(colors: [Theme.geometry.opacity(0.45), Theme.geometry.opacity(0.05)], startPoint: .top, endPoint: .bottom))
                            LineMark(x: .value("R", p.x), y: .value("³R", p.y))
                                .foregroundStyle(Theme.geometry)
                        }
                    }
                    .chartXAxisLabel("R / \(unit)")
                    .chartYAxisLabel("³R  (1/\(unit)²)")
                    .standardChartStyle()
                }
            }

            Card {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cases of β² = 2Gm/(c²R) with unit lapse and flat slices").font(.headline)
                    Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 10) {
                        GridRow {
                            Text("Configuration").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                            Text("m(R)").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                            Text("Flow").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                            Text("Static-slice embedding").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        }
                        Divider().gridCellUnsizedAxes(.horizontal)
                        ForEach(MassDistribution.allCases) { d in
                            GridRow {
                                Text(d.rawValue).fontWeight(d == distribution ? .semibold : .regular)
                                Equation(d.massLatex, size: 15)
                                Text(d.flowDescription)
                                Text(d.embeddingDescription)
                            }
                            .foregroundStyle(d == distribution ? Color.primary : Color.secondary)
                        }
                    }
                    Text("Table 2 of the manuscript.").font(.caption).foregroundStyle(.tertiary)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                EquationCard(title: "Gauss equation of the radial slice", latex: "{}^{(3)}R=K^2-K_{ij}K^{ij}=\\frac{2}{R^2}\\frac{d}{dR}\\left(R\\,\\beta^2\\right)", status: .identity, reference: "Eq. (66)")
                EquationCard(title: "With the Hamiltonian constraint ³R = 16πGρ/c²", latex: "\\beta^2(R)=\\frac{2G\\,m(R)}{c^2R},\\quad m(R)=\\int_0^R4\\pi\\rho R'^2dR'", status: .imported, note: "What the embedding adds: mass density tied to the second derivative of the fourth coordinate.", reference: "Eq. (67)")
            }
            Callout(kind: .insight, title: "Critical density", text: "For ρ = 3H²/(8πG) the cap radius is L = c/H and β = HR/c — the Hubble flow. The Schwarzschild radius of a critical-density ball of radius c/H equals c/H.")
        }
    }
}

// MARK: - G₄₄

struct FifthMetricPage: View {
    @Environment(ParameterStore.self) private var params
    @State private var g44 = 1.0
    @State private var omegaBD = 4.0e4
    @State private var source = 0.004
    @State private var bodyRadius = 3.0

    var body: some View {
        let gammaPPN = (1 + omegaBD) / (2 + omegaBD)
        let limb = 4 * params.G * SI.solarMass / (params.c * params.c * Body.sun.radius) * SI.radToArcsec
        let q = -source * pow(bodyRadius, 3) / 9
        let g44Surface = pow(1 + q * log(1 - 1 / bodyRadius), 2)

        PageScaffold(page: .fifthMetric) {
            SectionHeading(title: "1 · Why G₄₄ = 1", subtitle: "Only the product G₄₄(dy/dR)² enters h_RR. With y fixed kinematically (∂_R y = βγ), matching Schwarzschild fixes G₄₄.")
            VisualWithControls {
                ChartCard(title: "h_RR against R", subtitle: "Schwarzschild 1/(1 − r_s/R) vs 1 + G₄₄(βγ)²", height: 300) {
                    let xs = Grid.log(1.05, 30, 160)
                    let data = sample(xs, series: "Schwarzschild") { 1 / (1 - 1 / $0) }
                        + sample(xs, series: "1 + G₄₄(βγ)²") { r in 1 + g44 / (r - 1) }
                    Chart {
                        ForEach(data.filter { $0.y < 12 }) { p in
                            LineMark(x: .value("R / r_s", p.x), y: .value("h_RR", p.y), series: .value("Curve", p.series))
                                .foregroundStyle(by: .value("Curve", p.series))
                                .lineStyle(StrokeStyle(lineWidth: p.series == "Schwarzschild" ? 4 : 2, dash: p.series == "Schwarzschild" ? [] : [6, 4]))
                        }
                    }
                    .chartXScale(type: .log)
                    .chartForegroundStyleScale(["Schwarzschild": Theme.geometry.opacity(0.5), "1 + G₄₄(βγ)²": Theme.time])
                    .chartXAxisLabel("R / r_s")
                    .standardChartStyle()
                }
            } controls: {
                ControlPanel(title: "Trial G₄₄") {
                    ParameterSlider(title: "Fifth metric component", symbol: "G_{44}", value: $g44, range: 0.5...1.5, tint: Theme.time, format: { Fmt.fixed($0, 3) })
                }
                Readout(title: "Mismatch at R = 3r_s", value: Fmt.signedPercent((1 + g44 / 2) / 1.5 - 1), tint: abs(g44 - 1) < 1e-3 ? .green : Theme.mass, latex: "\\Delta h_{RR}")
                Callout(kind: .result, text: "Only G₄₄ = 1 reproduces the Schwarzschild radial metric at every radius.")
            }

            SectionHeading(title: "2 · Measured by light deflection", subtitle: "To first order G₄₄ = γ_PPN; a varying G₄₄ = Φ² is a Brans–Dicke-type scalar with γ_PPN = (1 + ω)/(2 + ω).")
            VisualWithControls {
                ChartCard(title: "|γ_PPN − 1| against the Brans–Dicke coupling", subtitle: "Shaded: excluded by Cassini at 2σ (γ_PPN − 1 > −2.5 × 10⁻⁵).", height: 300) {
                    let xs = Grid.log(1, 1e7, 200)
                    let data = sample(xs) { 1 / (2 + $0) }
                    Chart {
                        RectangleMark(xStart: .value("ω", 1.0), xEnd: .value("ω", 4.0e4), yStart: .value("|γ−1|", 2.5e-5), yEnd: .value("|γ−1|", 1.0))
                            .foregroundStyle(Color.red.opacity(0.08))
                        ForEach(data) { p in
                            LineMark(x: .value("ω", p.x), y: .value("|γ−1|", p.y))
                                .foregroundStyle(Theme.hypothesis)
                        }
                        RuleMark(y: .value("|γ−1|", 2.5e-5))
                            .foregroundStyle(Color.red.opacity(0.6))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .annotation(position: .top, alignment: .leading) {
                                Text("Cassini 2σ").font(.caption2).foregroundStyle(.red)
                            }
                        PointMark(x: .value("ω", omegaBD), y: .value("|γ−1|", 1 / (2 + omegaBD)))
                            .foregroundStyle(Theme.time)
                            .symbolSize(110)
                    }
                    .chartXScale(type: .log)
                    .chartYScale(type: .log)
                    .chartXAxisLabel("ω_BD")
                    .chartYAxisLabel("|γ_PPN − 1| ≈ |G₄₄ − 1|")
                    .standardChartStyle()
                }
            } controls: {
                ControlPanel(title: "Scalar coupling") {
                    ParameterSlider(title: "Brans–Dicke ω", symbol: "\\omega_{BD}", value: $omegaBD, range: 1...1e7, scale: .log, tint: Theme.hypothesis, format: { Fmt.sig($0, 3) })
                }
                ReadoutGrid(minimum: 140) {
                    Readout(title: "PPN parameter", value: Fmt.fixed(gammaPPN, 7), latex: "\\gamma_{PPN}")
                    Readout(title: "Limb deflection", value: Fmt.fixed(limb * (1 + gammaPPN) / 2, 4) + "″", caption: "GR: \(Fmt.fixed(limb, 4))″", tint: Theme.flow)
                    Readout(title: "Cassini", value: gammaPPN - 1 >= -2.5e-5 ? "allowed" : "excluded", caption: "(2.1 ± 2.3) × 10⁻⁵", tint: gammaPPN - 1 >= -2.5e-5 ? .green : .red)
                }
            }

            SectionHeading(title: "3 · The scalar charge", subtitle: "Exact Schwarzschild-exterior solution of the scalar equation; its charge is fixed by the integrated interior source.")
            VisualWithControls {
                ChartCard(title: "G₄₄(R) = [Φ∞ + (𝒬/r_s) ln(1 − r_s/R)]²", subtitle: "Exact exterior vs the weak-field 1/R profile. Grey: interior of the body.", height: 300) {
                    let xs = Grid.log(1.002, 40, 220)
                    let exact = sample(xs, series: "exact") { r in pow(1 + q * log(1 - 1 / r), 2) }
                    let weak = sample(xs, series: "weak field 1/R") { r in pow(1 - q / r, 2) }
                    let shown = (exact + weak).filter { abs($0.y - 1) < 3 }
                    let yLo = min(0.98, shown.map(\.y).min() ?? 0.98)
                    let yHi = max(1.02, shown.map(\.y).max() ?? 1.02)
                    Chart {
                        RectangleMark(xStart: .value("R / r_s", 1.002), xEnd: .value("R / r_s", bodyRadius), yStart: .value("G₄₄", yLo), yEnd: .value("G₄₄", yHi))
                            .foregroundStyle(Color.gray.opacity(0.12))
                        ForEach(shown) { p in
                            LineMark(x: .value("R / r_s", p.x), y: .value("G₄₄", p.y), series: .value("Curve", p.series))
                                .foregroundStyle(by: .value("Curve", p.series))
                        }
                        RuleMark(y: .value("G₄₄", 1))
                            .foregroundStyle(Color.secondary.opacity(0.5))
                    }
                    .chartXScale(type: .log)
                    .chartForegroundStyleScale(["exact": Theme.time, "weak field 1/R": Theme.flow])
                    .chartXAxisLabel("R / r_s")
                    .standardChartStyle()
                }
            } controls: {
                ControlPanel(title: "Constant-density source") {
                    ParameterSlider(title: "Source strength", symbol: "\\kappa_5\\sigma_0 r_s^2", value: $source, range: -0.02...0.02, tint: Theme.time, format: { Fmt.fixed($0, 4) })
                    ParameterSlider(title: "Body radius", symbol: "R_*/r_s", value: $bodyRadius, range: 1.05...10, tint: Theme.mass, format: { Fmt.fixed($0, 2) })
                }
                ReadoutGrid(minimum: 140) {
                    Readout(title: "Charge", value: Fmt.fixed(q, 4), latex: "\\mathcal{Q}^{ext}_\\Phi/r_s")
                    Readout(title: "At the surface", value: Fmt.sci(g44Surface - 1, 2), tint: Theme.time, latex: "G_{44}-1")
                }
                Callout(kind: .note, text: "For vacuum down to R = r_s the log diverges, so regularity forces q = 0 and G₄₄ = 1. For a star with R* > r_s the exterior never reaches the horizon, and the charge comes from matching to the interior.")
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                EquationCard(title: "Effective 4D field equation", latex: "G^{(4)}_{\\mu\\nu}=\\kappa_5T^{(5)}_{\\mu\\nu}+\\frac{1}{\\Phi}\\left(\\nabla_\\mu\\nabla_\\nu\\Phi-g_{\\mu\\nu}\\square\\Phi\\right)", status: .derived, note: "Reduction of the 5D Einstein equations for dS² = g dx dx + Φ²dy² in the y-independent sector.", reference: "Eq. (43)")
                EquationCard(title: "Scalar source", latex: "\\square\\Phi=-\\frac{\\kappa_5\\Phi}{3}\\left(\\epsilon-3p+2p_y\\right)", status: .derived, note: "Not fixed by energy density alone — pressure along y enters.", reference: "Eq. (49)")
                EquationCard(title: "Radial conservation", latex: "p_r'+(\\epsilon+p_r)\\frac{N'}{N}+\\frac{2}{R}(p_r-p_t)+\\frac{\\Phi'}{\\Phi}(p_r-p_y)=0", status: .derived, reference: "Eq. (51)")
                EquationCard(title: "Exterior solution", latex: "\\Phi_{ext}=\\Phi_\\infty+\\frac{\\mathcal{Q}^{ext}_\\Phi}{r_s}\\ln\\left(1-\\frac{r_s}{R}\\right)\\simeq\\Phi_\\infty+\\frac{Q_\\Phi}{R}", status: .derived, note: "The Schwarzschild N, B are adopted here, not generated by the sourced equations.", reference: "Eq. (60)")
            }
        }
    }
}

// MARK: - Four-potential

struct FourPotentialPage: View {
    @State private var spin = 0.0
    @State private var loopRadius = 3.0

    var body: some View {
        // Equatorial plane, r_s = 1. Gradient part βγ r̂; rotational part ∝ j/r² φ̂.
        let j = spin
        let circulation = 2 * Double.pi * j / loopRadius

        PageScaffold(page: .fourPotential) {
            VisualWithControls {
                StageCard(height: 480, dark: true) {
                    ZStack {
                        VectorFieldCanvas(extent: 8, field: { x, y in
                            let r2 = x * x + y * y
                            let r = r2.squareRoot()
                            guard r > 1 else { return (0, 0) }
                            let radial = (1 / (r - 1)).squareRoot()
                            let swirl = j / r2
                            return (radial * x / r - swirl * y / r, radial * y / r + swirl * x / r)
                        }, density: 23, bodyRadius: 1, excludeRadius: 1.15, tint: j == 0 ? Theme.flow : Theme.hypothesis, axisLabels: ("x / r_s", "y / r_s"))
                        Canvas { ctx, size in
                            let unit = Double(min(size.width, size.height)) / 2 / 8
                            let c = CGPoint(x: size.width / 2, y: size.height / 2)
                            ctx.stroke(Path(ellipseIn: c.circleRect(loopRadius * unit)), with: .color(Theme.observation), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                        }
                    }
                    .padding(16)
                }
            } controls: {
                ControlPanel(title: "Potential") {
                    ParameterSlider(title: "Rotation (non-gradient part)", symbol: "a_i", value: $spin, range: 0...3, tint: Theme.hypothesis, format: { Fmt.fixed($0, 2) })
                    ParameterSlider(title: "Loop radius", symbol: "R/r_s", value: $loopRadius, range: 1.3...7.5, tint: Theme.observation, format: { Fmt.fixed($0, 2) })
                }
                ReadoutGrid(minimum: 140) {
                    Readout(title: "Circulation", value: Fmt.fixed(circulation, 4), tint: j == 0 ? .green : Theme.hypothesis, latex: "\\oint\\mathcal{A}\\cdot d\\ell")
                    Readout(title: "Field strength", value: j == 0 ? "0" : "≠ 0", tint: j == 0 ? .green : Theme.hypothesis, latex: "\\mathcal{F}_{ij}")
                }
                Callout(kind: j == 0 ? .result : .insight, text: j == 0
                        ? "Pure gradient: 𝒜 = ∇y has zero circulation around every loop, so 𝓕 = 0 — the sector is **pure gauge**."
                        : "With a rotational part the loop integral no longer vanishes. For a slowly rotating source this vorticity is the **gravitomagnetic field** (see Rotation & Frame Dragging).")
            }

            ChartCard(title: "γ² = 1 + 𝒜ᵢ𝒜ⁱ along a radius", subtitle: "Gradient sector, exterior slice", height: 260) {
                let xs = Grid.log(1.05, 30, 160)
                let data = sample(xs, series: "𝒜_R = βγ") { (1 / ($0 - 1)).squareRoot() }
                    + sample(xs, series: "γ² = 1 + 𝒜_R²") { 1 + 1 / ($0 - 1) }
                Chart {
                    ForEach(data.filter { $0.y < 8 }) { p in
                        LineMark(x: .value("R / r_s", p.x), y: .value("Value", p.y), series: .value("Curve", p.series))
                            .foregroundStyle(by: .value("Curve", p.series))
                    }
                }
                .chartXScale(type: .log)
                .chartForegroundStyleScale(["𝒜_R = βγ": Theme.flow, "γ² = 1 + 𝒜_R²": Theme.geometry])
                .chartXAxisLabel("R / r_s")
                .standardChartStyle()
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                EquationCard(title: "Restoring the off-diagonal terms", latex: "dS^2=g_{\\mu\\nu}dx^\\mu dx^\\nu+G_{44}\\left(dy+\\mathcal{A}_\\mu dx^\\mu\\right)^2", status: .identity, note: "Invariant under y → y + Λ(x), 𝒜_μ → 𝒜_μ − ∂_μΛ.", reference: "Eq. (63)")
                EquationCard(title: "The potential generated by y", latex: "\\mathcal{A}_\\mu\\equiv\\partial_\\mu y,\\qquad \\mathcal{A}_0=0,\\quad \\mathcal{A}_i=\\beta\\gamma\\,\\hat{n}_i", status: .assumption, note: "∂_τ y = u^μ𝒜_μ is a directional derivative along the moving worldline, not a component 𝒜₀.", reference: "Eq. (64)")
                EquationCard(title: "Three identities", latex: "\\gamma^2=1+\\mathcal{A}_i\\mathcal{A}^i,\\quad \\mathcal{A}_\\mu w^\\mu=0,\\quad \\mathcal{F}_{\\mu\\nu}=0", status: .identity, reference: "Eq. (65)")
                EquationCard(title: "Induced geometry and the general potential", latex: "h_{\\mu\\nu}=g_{\\mu\\nu}+G_{44}\\mathcal{A}_\\mu\\mathcal{A}_\\nu,\\qquad \\mathcal{A}_\\mu=\\partial_\\mu y+a_\\mu", status: .identity, note: "A non-zero a_μ is the only way for the 5D geometry to carry field strength; 𝓕 acts on a body only through its fifth momentum p_y.", reference: "§2.4.6")
            }
        }
    }
}
