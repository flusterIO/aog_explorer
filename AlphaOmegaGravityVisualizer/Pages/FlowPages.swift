//
//  FlowPages.swift
//  AlphaOmegaGravityVisualizer
//
//  §2.9 Painlevé–Gullstrand form and the Hubble flow; §3.1–3.2 combined flows and the
//  Sciama identity.
//

import Foundation
import SwiftUI
import Charts

// MARK: - River model

struct RiverPage: View {
    @Environment(ParameterStore.self) private var params
    @State private var mode: FlowMode = .schwarzschild
    @State private var speed = 1.0
    @State private var showObservers = true
    @State private var probe = 2.0
    @State private var hubbleProbe = 0.5

    var body: some View {
        let isInfall = mode == .schwarzschild
        let beta = isInfall ? (1 / probe).squareRoot() : hubbleProbe
        let gamma = beta < 1 ? 1 / (1 - beta * beta).squareRoot() : Double.infinity

        PageScaffold(page: .river) {
            VisualWithControls {
                StageCard(height: 540, dark: true) {
                    RiverFlowView(mode: mode, speed: speed, showObservers: showObservers)
                        .padding(12)
                        .overlay(alignment: .topLeading) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(isInfall ? "Space flows inward at βc = √(2GM/R)" : "Space flows outward at β_H c = HR")
                                    .font(.headline).foregroundStyle(.white)
                                Text(isInfall ? "Slices T = const are flat; static observers (□) must accelerate against the flow." : "Same form as Schwarzschild, with the opposite sign of the shift.")
                                    .font(.caption).foregroundStyle(.white.opacity(0.75))
                            }
                            .glassChip()
                            .padding(16)
                        }
                }
            } controls: {
                ControlPanel(title: "Flow") {
                    Picker("Flow", selection: $mode) {
                        ForEach(FlowMode.allCases) { m in Text(m.rawValue).tag(m) }
                    }
                    .pickerStyle(.radioGroup)
                    .labelsHidden()
                    ParameterSlider(title: "Animation speed", value: $speed, range: 0.1...3, format: { Fmt.fixed($0, 1) + "×" })
                    Toggle("Static observers", isOn: $showObservers)
                }
                ControlPanel(title: "Probe") {
                    if isInfall {
                        ParameterSlider(title: "Radius", symbol: "R/r_s", value: $probe, range: 1.01...8, tint: Theme.flow, format: { Fmt.fixed($0, 2) })
                    } else {
                        ParameterSlider(title: "Radius", symbol: "R/(c/H)", value: $hubbleProbe, range: 0.01...0.99, tint: Theme.geometry, format: { Fmt.fixed($0, 2) })
                    }
                }
                ReadoutGrid(minimum: 140) {
                    Readout(title: "Flow speed", value: Fmt.fixed(beta, 4), tint: isInfall ? Theme.flow : Theme.geometry, latex: "\\beta")
                    Readout(title: "Flow vs static", value: Fmt.fixed(gamma, 4), caption: "Lorentz factor", latex: "\\gamma")
                    Readout(title: "Along free fall", value: Fmt.fixed((isInfall ? -1 : 1) * beta * beta * gamma, 4), unit: "c", latex: "dy/dT")
                    Readout(title: "Static lapse", value: Fmt.fixed(1 / gamma, 4), tint: Theme.geometry, latex: "1/\\gamma")
                }
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                EquationCard(title: "Schwarzschild in Painlevé–Gullstrand form", latex: "ds^2=-c^2dT^2+\\left(dR+\\beta c\\,dT\\right)^2+R^2d\\Omega^2,\\quad \\beta^2=\\frac{r_s}{R}", status: .equivalentGR, note: "T is the proper time of observers falling from rest at infinity; the time-equivalent τ plays its role.", reference: "Eq. (85)")
                EquationCard(title: "Rest space of a static observer", latex: "h_{RR}=g_{RR}-\\frac{g_{TR}^2}{g_{TT}}=1+\\beta^2\\gamma^2=\\gamma^2", status: .equivalentGR, note: "So dS² = dx² + dy² = γ²dx² with x = R of the flat slices and y the Flamm embedding.", reference: "§2.9.1")
                EquationCard(title: "Temporal relation", latex: "dT=dt+\\frac{\\beta\\,dR}{c(1-\\beta^2)}\\;\\Rightarrow\\;N^2=\\frac{1}{A}=1-\\beta^2", status: .equivalentGR, note: "The closure N = 1/γ is the statement that the frame moving at βc has unit lapse and flat slices — exact for dust.", reference: "§2.9.1")
                EquationCard(title: "Flat FLRW in the same form", latex: "ds^2=-c^2dt^2+\\left(dR-\\beta_Hc\\,dt\\right)^2+R^2d\\Omega^2,\\quad \\beta_H=\\frac{HR}{c}", status: .equivalentGR, note: "With H² = 8πGρ/3, β_H² = 2Gm/(c²R). The Hubble radius is the apparent horizon.", reference: "Eq. (87)")
            }

            ChartCard(title: isInfall ? "Flow and lapse around a mass" : "Flow and lapse in a flat universe", height: 260) {
                let xs = isInfall ? Sampling.log(1.01, 8, 160) : Sampling.linear(0.0, 0.99, 160)
                let flow = sample(xs, series: "β") { isInfall ? (1 / $0).squareRoot() : $0 }
                let lapse = sample(xs, series: "1/γ = √(1 − β²)") { r in
                    let b2 = isInfall ? 1 / r : r * r
                    return (1 - b2).squareRoot()
                }
                let dy = sample(xs, series: "|dy/dT| / c = β²γ") { r in
                    let b2 = isInfall ? 1 / r : r * r
                    return min(3, b2 / (1 - b2).squareRoot())
                }
                Chart {
                    ForEach(flow + lapse + dy) { p in
                        LineMark(x: .value("R", p.x), y: .value("Value", p.y), series: .value("Curve", p.series))
                            .foregroundStyle(by: .value("Curve", p.series))
                    }
                    RuleMark(x: .value("R", isInfall ? probe : hubbleProbe))
                        .foregroundStyle(Color.secondary)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
                .chartForegroundStyleScale(["β": Theme.flow, "1/γ = √(1 − β²)": Theme.geometry, "|dy/dT| / c = β²γ": Theme.time])
                .chartXAxisLabel(isInfall ? "R / r_s" : "R / (c/H)")
                .standardChartStyle()
            }

            Callout(kind: .insight, title: "Binding and expansion", text: "For marginally bound dust (Lemaître–Tolman–Bondi with zero energy), β² = 2Gm(R, T)/(c²R) with m the Misner–Sharp mass. Schwarzschild and flat FLRW are two cases of one relation; the **sign of the flow** distinguishes infall from Hubble expansion.")
        }
    }
}

// MARK: - Cosmology

struct CosmologyPage: View {
    @Environment(ParameterStore.self) private var params
    @State private var galaxyMass = 6.0e10
    @State private var radiusKpc = 8.0

    var body: some View {
        let H = params.H0
        let c = params.c
        let G = params.G
        let M = galaxyMass * SI.solarMass
        let r = radiusKpc * SI.kpc
        let rH = params.hubbleRadius
        let mH = 4.0 / 3.0 * Double.pi * params.criticalDensity * pow(rH, 3)
        let sciama = G * mH / (c * c * rH)
        let balance = Cosmology.balanceRadius(mass: M, H: H, G: G)
        let ratio = H * H * r / (G * M / (r * r))

        PageScaffold(page: .cosmology) {
            HStack(alignment: .top, spacing: 16) {
                ReadoutGrid(minimum: 170) {
                    Readout(title: "Hubble radius", value: Fmt.fixed(rH / (SI.Mpc * 1_000), 3), unit: "Gpc", latex: "R_H=c/H_0")
                    Readout(title: "Critical density", value: Fmt.sci(params.criticalDensity, 3), unit: "kg/m³", latex: "\\rho_c")
                    Readout(title: "Sciama ratio", value: Fmt.fixed(sciama, 6), caption: "exactly ½ at the Hubble radius", tint: Theme.geometry, latex: "\\frac{Gm_H}{c^2R_H}")
                    Readout(title: "β_N = β_H at", value: Fmt.sig(balance / SI.kpc / 1_000, 4), unit: "Mpc", caption: "for the galaxy mass below", tint: Theme.flow)
                }
            }

            VisualWithControls {
                ChartCard(title: "Local and cosmological flows", subtitle: "In Schwarzschild–de Sitter PG form the squares add: β² = β_N² + β_H².", height: 340) {
                    let xs = Sampling.log(0.5 * SI.kpc, 5e3 * SI.Mpc, 220)
                    let local = sample(xs, series: "β_N² = 2GM/(c²R)") { R in log10(2 * G * M / (c * c * R)) }
                    let cosmic = sample(xs, series: "β_H² = H²R²/c²") { R in log10(H * H * R * R / (c * c)) }
                    let total = sample(xs, series: "β² = β_N² + β_H²") { R in log10(2 * G * M / (c * c * R) + H * H * R * R / (c * c)) }
                    let toKpc: (XY) -> XY = { XY(id: $0.index, x: log10($0.x / SI.kpc), y: $0.y, series: $0.series) }
                    Chart {
                        ForEach((local + cosmic + total).map(toKpc).filter { $0.y > -14 }) { p in
                            LineMark(x: .value("log₁₀ R (kpc)", p.x), y: .value("log₁₀ β²", p.y), series: .value("Curve", p.series))
                                .foregroundStyle(by: .value("Curve", p.series))
                                .lineStyle(StrokeStyle(lineWidth: p.series.hasPrefix("β² =") ? 3.5 : 1.5, dash: p.series.hasPrefix("β² =") ? [] : [5, 4]))
                        }
                        RuleMark(x: .value("log₁₀ R (kpc)", log10(r / SI.kpc)))
                            .foregroundStyle(Theme.mass.opacity(0.6))
                            .annotation(position: .top, alignment: .leading) { Text("R").font(.caption2).foregroundStyle(Theme.mass) }
                        RuleMark(x: .value("log₁₀ R (kpc)", log10(rH / SI.kpc)))
                            .foregroundStyle(Theme.geometry.opacity(0.6))
                            .annotation(position: .top, alignment: .trailing) { Text("c/H₀").font(.caption2).foregroundStyle(Theme.geometry) }
                        RuleMark(y: .value("log₁₀ β²", 0))
                            .foregroundStyle(Color.red.opacity(0.4))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    }
                    .chartForegroundStyleScale(["β_N² = 2GM/(c²R)": Theme.mass, "β_H² = H²R²/c²": Theme.geometry, "β² = β_N² + β_H²": Theme.flow])
                    .chartXAxisLabel("log₁₀ (R / kpc)")
                    .chartYAxisLabel("log₁₀ β²")
                    .standardChartStyle()
                }
            } controls: {
                ControlPanel(title: "Galaxy") {
                    ParameterSlider(title: "Baryonic mass", symbol: "M/M_\\odot", value: $galaxyMass, range: 1e9...1e12, scale: .log, tint: Theme.mass, format: { Fmt.sci($0, 2) })
                    ParameterSlider(title: "Radius", symbol: "R", value: $radiusKpc, range: 1...50, scale: .log, unit: "kpc", tint: Theme.mass, format: { Fmt.fixed($0, 1) })
                }
                ReadoutGrid(minimum: 140) {
                    Readout(title: "H₀²R / g_N", value: Fmt.sci(ratio, 2), caption: "cosmic flow correction", tint: Theme.mass)
                    Readout(title: "Hubble speed", value: Fmt.fixed(H * r / 1_000, 2), unit: "km/s", latex: "H_0R")
                }
                Callout(kind: .result, text: "At galactic radii the cosmological flow is ~10⁻⁵–10⁻⁴ of the Newtonian acceleration — far too small to shape rotation curves. Any such correction is an **additional hypothesis** (Hypothesis M).")
            }

            ChartCard(title: "The Sciama identity", subtitle: "Dimensionless potential of the cosmic flow, Gm_H(R)/(c²R) = ½(R/R_H)², reaches ½ only at the Hubble radius.", height: 240) {
                let xs = Sampling.linear(0, 1.3, 140)
                let data = sample(xs) { 0.5 * $0 * $0 }
                Chart {
                    ForEach(data) { p in
                        AreaMark(x: .value("R / R_H", p.x), y: .value("Gm/c²R", p.y))
                            .foregroundStyle(LinearGradient(colors: [Theme.geometry.opacity(0.4), Theme.geometry.opacity(0.03)], startPoint: .top, endPoint: .bottom))
                        LineMark(x: .value("R / R_H", p.x), y: .value("Gm/c²R", p.y))
                            .foregroundStyle(Theme.geometry)
                    }
                    PointMark(x: .value("R / R_H", 1.0), y: .value("Gm/c²R", 0.5))
                        .foregroundStyle(Theme.time)
                        .symbolSize(110)
                        .annotation(position: .topLeading) { Text("½ at c/H").font(.caption).foregroundStyle(.secondary) }
                }
                .chartXAxisLabel("R / R_H")
                .standardChartStyle()
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                EquationCard(title: "Hubble flow from the enclosed mass", latex: "m_H=\\frac{4\\pi}{3}\\rho R^3,\\quad H^2=\\frac{8\\pi G\\rho}{3}\\;\\Rightarrow\\;\\beta_H^2=\\frac{H^2R^2}{c^2}=\\frac{2Gm_H}{c^2R}", status: .imported, note: "The Newtonian counterpart is the Milne–McCrea zero-energy condition: the Hubble velocity equals the escape velocity from the enclosed mass.", reference: "§2.9.2")
                EquationCard(title: "Sciama identity", latex: "\\frac{G\\,m_H(R_H)}{c^2R_H}=\\frac{1}{2}", status: .derived, note: "Follows in one line from β_H = 1 at R_H = c/H.", reference: "Eq. (88)")
            }
        }
    }
}
