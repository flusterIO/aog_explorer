//
//  FlowPages.swift
//  AlphaOmegaGravityVisualizer
//
//  §2.9 Painlevé–Gullstrand form and the Hubble flow; §3.1–3.2 combined flows and the
//  Sciama identity.
//
//  Structured as small subviews with precomputed data: long builder expressions here
//  previously exceeded the type checker's limits.
//

import Foundation
import SwiftUI
import Charts

// MARK: - River model

struct RiverPage: View {
    @State private var mode: FlowMode = .schwarzschild
    @State private var speed: Double = 1.0
    @State private var showObservers: Bool = true
    @State private var probe: Double = 2.0
    @State private var hubbleProbe: Double = 0.5

    private var isInfall: Bool { mode == .schwarzschild }

    private var probeBeta: Double {
        isInfall ? (1.0 / probe).squareRoot() : hubbleProbe
    }

    var body: some View {
        PageScaffold(page: .river) {
            VisualWithControls {
                RiverStage(mode: mode, speed: speed, showObservers: showObservers)
            } controls: {
                RiverControls(mode: $mode, speed: $speed, showObservers: $showObservers, probe: $probe, hubbleProbe: $hubbleProbe)
                RiverReadouts(beta: probeBeta, infall: isInfall)
            }
            RiverEquations()
            RiverProfileChart(infall: isInfall, marker: isInfall ? probe : hubbleProbe)
            Callout(kind: .insight, title: "Binding and expansion", text: "For marginally bound dust (Lemaître–Tolman–Bondi with zero energy), β² = 2Gm(R, T)/(c²R) with m the Misner–Sharp mass. Schwarzschild and flat FLRW are two cases of one relation; the **sign of the flow** distinguishes infall from Hubble expansion.")
        }
    }
}

private struct RiverStage: View {
    let mode: FlowMode
    let speed: Double
    let showObservers: Bool

    private var headline: String {
        mode == .schwarzschild ? "Space flows inward at βc = √(2GM/R)" : "Space flows outward at β_H c = HR"
    }

    private var detail: String {
        mode == .schwarzschild
            ? "Slices T = const are flat; static observers (□) must accelerate against the flow."
            : "Same form as Schwarzschild, with the opposite sign of the shift."
    }

    var body: some View {
        StageCard(height: 540, dark: true) {
            RiverFlowView(mode: mode, speed: speed, showObservers: showObservers)
                .padding(12)
                .overlay(alignment: .topLeading) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(verbatim: headline).font(.headline).foregroundStyle(.white)
                        Text(verbatim: detail).font(.caption).foregroundStyle(.white.opacity(0.75))
                    }
                    .glassChip()
                    .padding(16)
                }
        }
    }
}

private struct RiverControls: View {
    @Binding var mode: FlowMode
    @Binding var speed: Double
    @Binding var showObservers: Bool
    @Binding var probe: Double
    @Binding var hubbleProbe: Double

    var body: some View {
        ControlPanel(title: "Flow") {
            Picker("Flow", selection: $mode) {
                ForEach(FlowMode.allCases) { m in
                    Text(verbatim: m.rawValue).tag(m)
                }
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()
            ParameterSlider(title: "Animation speed", value: $speed, range: 0.1...3, format: { Fmt.fixed($0, 1) + "×" })
            Toggle("Static observers", isOn: $showObservers)
        }
        ControlPanel(title: "Probe") {
            if mode == .schwarzschild {
                ParameterSlider(title: "Radius", symbol: "R/r_s", value: $probe, range: 1.01...8, tint: Theme.flow, format: { Fmt.fixed($0, 2) })
            } else {
                ParameterSlider(title: "Radius", symbol: "R/(c/H)", value: $hubbleProbe, range: 0.01...0.99, tint: Theme.geometry, format: { Fmt.fixed($0, 2) })
            }
        }
    }
}

private struct RiverReadouts: View {
    let beta: Double
    let infall: Bool

    var body: some View {
        let b2: Double = beta * beta
        let gamma: Double = beta < 1 ? 1.0 / (1.0 - b2).squareRoot() : Double.infinity
        let sign: Double = infall ? -1.0 : 1.0
        let dyDT: Double = sign * b2 * gamma
        let tint: Color = infall ? Theme.flow : Theme.geometry
        ReadoutGrid(minimum: 140) {
            Readout(title: "Flow speed", value: Fmt.fixed(beta, 4), tint: tint, latex: "\\beta")
            Readout(title: "Flow vs static", value: Fmt.fixed(gamma, 4), caption: "Lorentz factor", latex: "\\gamma")
            Readout(title: "Along free fall", value: Fmt.fixed(dyDT, 4), unit: "c", latex: "dy/dT")
            Readout(title: "Static lapse", value: Fmt.fixed(1.0 / gamma, 4), tint: Theme.geometry, latex: "1/\\gamma")
        }
    }
}

private struct RiverEquations: View {
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
            EquationCard(title: "Schwarzschild in Painlevé–Gullstrand form", latex: "ds^2=-c^2dT^2+\\left(dR+\\beta c\\,dT\\right)^2+R^2d\\Omega^2,\\quad \\beta^2=\\frac{r_s}{R}", status: .equivalentGR, note: "T is the proper time of observers falling from rest at infinity; the time-equivalent τ plays its role.", reference: "Eq. (85)")
            EquationCard(title: "Rest space of a static observer", latex: "h_{RR}=g_{RR}-\\frac{g_{TR}^2}{g_{TT}}=1+\\beta^2\\gamma^2=\\gamma^2", status: .equivalentGR, note: "So dS² = dx² + dy² = γ²dx² with x = R of the flat slices and y the Flamm embedding.", reference: "§2.9.1")
            EquationCard(title: "Temporal relation", latex: "dT=dt+\\frac{\\beta\\,dR}{c(1-\\beta^2)}\\;\\Rightarrow\\;N^2=\\frac{1}{A}=1-\\beta^2", status: .equivalentGR, note: "The closure N = 1/γ is the statement that the frame moving at βc has unit lapse and flat slices — exact for dust.", reference: "§2.9.1")
            EquationCard(title: "Flat FLRW in the same form", latex: "ds^2=-c^2dt^2+\\left(dR-\\beta_Hc\\,dt\\right)^2+R^2d\\Omega^2,\\quad \\beta_H=\\frac{HR}{c}", status: .equivalentGR, note: "With H² = 8πGρ/3, β_H² = 2Gm/(c²R). The Hubble radius is the apparent horizon.", reference: "Eq. (87)")
        }
    }
}

private struct RiverProfileChart: View {
    let infall: Bool
    let marker: Double

    private static func beta2(_ r: Double, infall: Bool) -> Double {
        infall ? 1.0 / r : r * r
    }

    private var data: [XY] {
        let xs: [Double] = infall ? Sampling.log(1.01, 8, 160) : Sampling.linear(0.0, 0.99, 160)
        var out: [XY] = []
        for (i, r) in xs.enumerated() {
            let b2: Double = Self.beta2(r, infall: infall)
            let lapse: Double = (1.0 - b2).squareRoot()
            let dy: Double = min(3.0, b2 / lapse)
            out.append(XY(id: i, x: r, y: b2.squareRoot(), series: "β"))
            out.append(XY(id: i, x: r, y: lapse, series: "1/γ = √(1 − β²)"))
            out.append(XY(id: i, x: r, y: dy, series: "|dy/dT| / c = β²γ"))
        }
        return out
    }

    var body: some View {
        let title: String = infall ? "Flow and lapse around a mass" : "Flow and lapse in a flat universe"
        let axis: String = infall ? "R / r_s" : "R / (c/H)"
        let points: [XY] = data
        ChartCard(title: title, height: 260) {
            Chart {
                ForEach(points) { p in
                    LineMark(x: .value("R", p.x), y: .value("Value", p.y), series: .value("Curve", p.series))
                        .foregroundStyle(by: .value("Curve", p.series))
                }
                RuleMark(x: .value("R", marker))
                    .foregroundStyle(Color.secondary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            .chartForegroundStyleScale(["β": Theme.flow, "1/γ = √(1 − β²)": Theme.geometry, "|dy/dT| / c = β²γ": Theme.time])
            .chartXAxisLabel { Text(verbatim: axis) }
            .standardChartStyle()
        }
    }
}

// MARK: - Cosmology

struct CosmologyPage: View {
    @Environment(ParameterStore.self) private var params
    @State private var galaxyMass: Double = 6.0e10
    @State private var radiusKpc: Double = 8.0

    var body: some View {
        let inputs = CosmologyInputs(
            G: params.G, c: params.c, H: params.H0,
            hubbleRadius: params.hubbleRadius, criticalDensity: params.criticalDensity,
            mass: galaxyMass * SI.solarMass, radius: radiusKpc * SI.kpc
        )
        PageScaffold(page: .cosmology) {
            CosmologyReadouts(inputs: inputs)
            VisualWithControls {
                CosmologyFlowChart(inputs: inputs)
            } controls: {
                CosmologyControls(galaxyMass: $galaxyMass, radiusKpc: $radiusKpc, inputs: inputs)
            }
            SciamaChart()
            CosmologyEquations()
        }
    }
}

/// Plain value bundle so subviews never re-derive physics inside builders.
private struct CosmologyInputs {
    let G: Double
    let c: Double
    let H: Double
    let hubbleRadius: Double
    let criticalDensity: Double
    let mass: Double
    let radius: Double

    var c2: Double { c * c }

    func localBeta2(_ r: Double) -> Double { 2.0 * G * mass / (c2 * r) }
    func cosmicBeta2(_ r: Double) -> Double { (H * r) * (H * r) / c2 }

    var sciamaRatio: Double {
        let rH: Double = hubbleRadius
        let mH: Double = 4.0 / 3.0 * Double.pi * criticalDensity * rH * rH * rH
        return G * mH / (c2 * rH)
    }

    var balanceRadius: Double { Cosmology.balanceRadius(mass: mass, H: H, G: G) }

    /// H₀²R / g_N at the chosen radius.
    var correctionRatio: Double {
        let gN: Double = G * mass / (radius * radius)
        return H * H * radius / gN
    }

    var hubbleSpeedKms: Double { H * radius / 1_000.0 }
}

private struct CosmologyReadouts: View {
    let inputs: CosmologyInputs

    var body: some View {
        let gpc: Double = inputs.hubbleRadius / (SI.Mpc * 1_000.0)
        let balanceMpc: Double = inputs.balanceRadius / SI.Mpc
        ReadoutGrid(minimum: 170) {
            Readout(title: "Hubble radius", value: Fmt.fixed(gpc, 3), unit: "Gpc", latex: "R_H=c/H_0")
            Readout(title: "Critical density", value: Fmt.sci(inputs.criticalDensity, 3), unit: "kg/m³", latex: "\\rho_c")
            Readout(title: "Sciama ratio", value: Fmt.fixed(inputs.sciamaRatio, 6), caption: "exactly ½ at the Hubble radius", tint: Theme.geometry, latex: "\\frac{Gm_H}{c^2R_H}")
            Readout(title: "β_N = β_H at", value: Fmt.sig(balanceMpc, 4), unit: "Mpc", caption: "for the galaxy mass below", tint: Theme.flow)
        }
    }
}

private struct CosmologyControls: View {
    @Binding var galaxyMass: Double
    @Binding var radiusKpc: Double
    let inputs: CosmologyInputs

    var body: some View {
        ControlPanel(title: "Galaxy") {
            ParameterSlider(title: "Baryonic mass", symbol: "M/M_\\odot", value: $galaxyMass, range: 1e9...1e12, scale: .log, tint: Theme.mass, format: { Fmt.sci($0, 2) })
            ParameterSlider(title: "Radius", symbol: "R", value: $radiusKpc, range: 1...50, scale: .log, unit: "kpc", tint: Theme.mass, format: { Fmt.fixed($0, 1) })
        }
        ReadoutGrid(minimum: 140) {
            Readout(title: "H₀²R / g_N", value: Fmt.sci(inputs.correctionRatio, 2), caption: "cosmic flow correction", tint: Theme.mass)
            Readout(title: "Hubble speed", value: Fmt.fixed(inputs.hubbleSpeedKms, 2), unit: "km/s", latex: "H_0R")
        }
        Callout(kind: .result, text: "At galactic radii the cosmological flow is ~10⁻⁵–10⁻⁴ of the Newtonian acceleration — far too small to shape rotation curves. Any such correction is an **additional hypothesis** (Hypothesis M).")
    }
}

private struct CosmologyFlowChart: View {
    let inputs: CosmologyInputs

    private static let localName = "β_N² = 2GM/(c²R)"
    private static let cosmicName = "β_H² = H²R²/c²"
    private static let totalName = "β² = β_N² + β_H²"

    /// Series in log₁₀ space (x: log₁₀ R/kpc, y: log₁₀ β²).
    private var data: [XY] {
        let radii: [Double] = Sampling.log(0.5 * SI.kpc, 5e3 * SI.Mpc, 220)
        var out: [XY] = []
        for (i, r) in radii.enumerated() {
            let x: Double = log10(r / SI.kpc)
            let local: Double = inputs.localBeta2(r)
            let cosmic: Double = inputs.cosmicBeta2(r)
            let total: Double = local + cosmic
            let ly: Double = log10(local)
            let cy: Double = log10(cosmic)
            let ty: Double = log10(total)
            if ly > -14 { out.append(XY(id: i, x: x, y: ly, series: Self.localName)) }
            if cy > -14 { out.append(XY(id: i, x: x, y: cy, series: Self.cosmicName)) }
            if ty > -14 { out.append(XY(id: i, x: x, y: ty, series: Self.totalName)) }
        }
        return out
    }

    var body: some View {
        let points: [XY] = data
        let rMark: Double = log10(inputs.radius / SI.kpc)
        let hMark: Double = log10(inputs.hubbleRadius / SI.kpc)
        ChartCard(title: "Local and cosmological flows", subtitle: "In Schwarzschild–de Sitter PG form the squares add: β² = β_N² + β_H².", height: 340) {
            Chart {
                ForEach(points) { p in
                    LineMark(x: .value("log R", p.x), y: .value("log β²", p.y), series: .value("Curve", p.series))
                        .foregroundStyle(by: .value("Curve", p.series))
                        .lineStyle(Self.style(for: p.series))
                }
                RuleMark(x: .value("log R", rMark))
                    .foregroundStyle(Theme.mass.opacity(0.6))
                    .annotation(position: .top, alignment: .leading) {
                        Text(verbatim: "R").font(.caption2).foregroundStyle(Theme.mass)
                    }
                RuleMark(x: .value("log R", hMark))
                    .foregroundStyle(Theme.geometry.opacity(0.6))
                    .annotation(position: .top, alignment: .trailing) {
                        Text(verbatim: "c/H₀").font(.caption2).foregroundStyle(Theme.geometry)
                    }
                RuleMark(y: .value("log β²", 0.0))
                    .foregroundStyle(Color.red.opacity(0.4))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }
            .chartForegroundStyleScale([Self.localName: Theme.mass, Self.cosmicName: Theme.geometry, Self.totalName: Theme.flow])
            .chartXAxisLabel { Text(verbatim: "log₁₀ (R / kpc)") }
            .chartYAxisLabel { Text(verbatim: "log₁₀ β²") }
            .standardChartStyle()
        }
    }

    private static func style(for series: String) -> StrokeStyle {
        series == totalName
            ? StrokeStyle(lineWidth: 3.5)
            : StrokeStyle(lineWidth: 1.5, dash: [5, 4])
    }
}

private struct SciamaChart: View {
    private static let data: [XY] = Sampling.linear(0, 1.3, 140).enumerated().map { i, x in
        XY(id: i, x: x, y: 0.5 * x * x)
    }

    var body: some View {
        ChartCard(title: "The Sciama identity", subtitle: "Dimensionless potential of the cosmic flow, Gm_H(R)/(c²R) = ½(R/R_H)², reaches ½ only at the Hubble radius.", height: 240) {
            Chart {
                ForEach(Self.data) { p in
                    AreaMark(x: .value("R / R_H", p.x), y: .value("Gm/c²R", p.y))
                        .foregroundStyle(LinearGradient(colors: [Theme.geometry.opacity(0.4), Theme.geometry.opacity(0.03)], startPoint: .top, endPoint: .bottom))
                    LineMark(x: .value("R / R_H", p.x), y: .value("Gm/c²R", p.y))
                        .foregroundStyle(Theme.geometry)
                }
                PointMark(x: .value("R / R_H", 1.0), y: .value("Gm/c²R", 0.5))
                    .foregroundStyle(Theme.time)
                    .symbolSize(110)
                    .annotation(position: .topLeading) {
                        Text(verbatim: "½ at c/H").font(.caption).foregroundStyle(.secondary)
                    }
            }
            .chartXAxisLabel { Text(verbatim: "R / R_H") }
            .standardChartStyle()
        }
    }
}

private struct CosmologyEquations: View {
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
            EquationCard(title: "Hubble flow from the enclosed mass", latex: "m_H=\\frac{4\\pi}{3}\\rho R^3,\\quad H^2=\\frac{8\\pi G\\rho}{3}\\;\\Rightarrow\\;\\beta_H^2=\\frac{H^2R^2}{c^2}=\\frac{2Gm_H}{c^2R}", status: .imported, note: "The Newtonian counterpart is the Milne–McCrea zero-energy condition: the Hubble velocity equals the escape velocity from the enclosed mass.", reference: "§2.9.2")
            EquationCard(title: "Sciama identity", latex: "\\frac{G\\,m_H(R_H)}{c^2R_H}=\\frac{1}{2}", status: .derived, note: "Follows in one line from β_H = 1 at R_H = c/H.", reference: "Eq. (88)")
        }
    }
}
