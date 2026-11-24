//
//  AppendixPages.swift
//  AlphaOmegaGravityVisualizer
//
//  Appendix A: numerical alignments kept "as rough approximations that a dynamical
//  theory would have to explain or discard". Everything here carries the
//  .numerical status badge.
//

import Foundation
import SwiftUI
import Charts

private struct BodyPicker: View {
    @Binding var selection: CelestialBody

    var body: some View {
        Picker("CelestialBody", selection: $selection) {
            ForEach(CelestialBody.all) { b in Text(b.name).tag(b) }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }
}

private struct AppendixStatusBanner: View {
    var body: some View {
        Callout(kind: .caveat, title: "Numerical alignments, not predictions", text: "These relations were found while developing the model and then discarded as derivations. The paper keeps them only as rough approximations a dynamical theory would have to explain or discard: with a handful of bodies and a handful of numerical factors, agreement at the 0.5% level is not impossible by chance.")
    }
}

// MARK: - Characteristic velocities

struct VelocitiesPage: View {
    @Environment(ParameterStore.self) private var params
    @State private var body_: CelestialBody = .earth

    var body: some View {
        let nums = BodyNumerics(body: body_, G: params.G, c: params.c, tauHat: params.tauHat)
        let earth = BodyNumerics(body: .earth, G: params.G, c: params.c, tauHat: params.tauHat)
        let dipoleOffset = earth.vKinematic / SI.cmbDipole - 1

        PageScaffold(page: .velocities) {
            AppendixStatusBanner()

            VisualWithControls {
                ChartCard(title: "Velocities as a function of mean density", subtitle: "Both depend only on GM/R³ = (4π/3)Gρ and on L_τ. Band: Planck 2018 CMB dipole.", height: 340) {
                    let rhos = Sampling.log(300, 12_000, 160)
                    let kin = sample(rhos, series: "v_kinematic") { rho in
                        let x = 0.5 * 4.0 / 3.0 * Double.pi * params.G * rho * params.tauHat * params.tauHat
                        return params.c * (1 - 1 / pow(1 + x, 2)).squareRoot() / 1_000
                    }
                    let cosmo = sample(rhos, series: "v_cosmo") { rho in
                        let x = 4.0 / 3.0 * Double.pi * params.G * rho * params.tauHat * params.tauHat
                        return params.c * (1 - 1 / pow(1 + x, 2)).squareRoot() / 1_000
                    }
                    let bodies = CelestialBody.all.map { b in
                        XY(id: b.id.hashValue, x: b.density, y: BodyNumerics(body: b, G: params.G, c: params.c, tauHat: params.tauHat).vKinematic / 1_000, series: b.name)
                    }
                    Chart {
                        RectangleMark(xStart: .value("ρ", 300.0), xEnd: .value("ρ", 12_000.0), yStart: .value("v", (SI.cmbDipole - 3 * SI.cmbDipoleSigma) / 1_000), yEnd: .value("v", (SI.cmbDipole + 3 * SI.cmbDipoleSigma) / 1_000))
                            .foregroundStyle(Theme.observation.opacity(0.35))
                        ForEach(kin + cosmo) { p in
                            LineMark(x: .value("ρ", p.x), y: .value("v", p.y), series: .value("Curve", p.series))
                                .foregroundStyle(by: .value("Curve", p.series))
                        }
                        ForEach(bodies) { p in
                            PointMark(x: .value("ρ", p.x), y: .value("v", p.y))
                                .foregroundStyle(p.series == body_.name ? Theme.time : Color.secondary)
                                .symbolSize(p.series == body_.name ? 120 : 50)
                                .annotation(position: .top) { Text(p.series).font(.caption2).foregroundStyle(.secondary) }
                        }
                    }
                    .chartXScale(type: .log)
                    .chartForegroundStyleScale(["v_kinematic": Theme.flow, "v_cosmo": Theme.hypothesis])
                    .chartXAxisLabel("mean density ρ (kg/m³)")
                    .chartYAxisLabel("km/s")
                    .standardChartStyle()
                }
            } controls: {
                ControlPanel(title: "CelestialBody") {
                    BodyPicker(selection: $body_)
                    Text("ρ = \(Fmt.fixed(body_.density, 0)) kg/m³ · R = \(Fmt.fixed(body_.radius / 1_000, 0)) km")
                        .font(.caption).foregroundStyle(.secondary)
                }
                ReadoutGrid(minimum: 140) {
                    Readout(title: "Cosmological", value: Fmt.fixed(nums.vCosmo / 1_000, 2), unit: "km/s", tint: Theme.hypothesis, latex: "v_{cosmo}")
                    Readout(title: "Kinematic", value: Fmt.fixed(nums.vKinematic / 1_000, 2), unit: "km/s", tint: Theme.flow, latex: "v_{kin}")
                    Readout(title: "Ratio", value: Fmt.fixed(nums.vCosmo / nums.vKinematic, 6), caption: "√2 = 1.414214", latex: "v_{cosmo}/v_{kin}")
                    Readout(title: "φ − 1", value: Fmt.sci(nums.varphi - 1, 4), latex: "GM\\hat{\\tau}^2/R^3")
                }
                Readout(title: "Earth v_kin vs CMB dipole", value: Fmt.signedPercent(dipoleOffset, 2), caption: "369.82 ± 0.11 km/s; the offset exceeds the quoted error", tint: Theme.observation, latex: "\\Delta")
            }

            HStack(alignment: .top, spacing: 16) {
                ChartCard(title: "The agreement fixes L_τ, it does not test it", subtitle: "Earth's v_kinematic scales with L_τ = cτ̂. Crossing the dipole determines τ̂ to ~0.5%.", height: 280) {
                    let taus = Sampling.linear(0.9, 1.1, 120)
                    let data = sample(taus) { t in BodyNumerics(body: .earth, G: params.G, c: params.c, tauHat: t).vKinematic / 1_000 }
                    let crossing = SI.cmbDipole / BodyNumerics(body: .earth, G: params.G, c: params.c, tauHat: 1).vKinematic
                    Chart {
                        ForEach(data) { p in
                            LineMark(x: .value("τ̂ (s)", p.x), y: .value("v_kin (km/s)", p.y))
                                .foregroundStyle(Theme.flow)
                        }
                        RuleMark(y: .value("v_kin (km/s)", SI.cmbDipole / 1_000))
                            .foregroundStyle(Theme.observation)
                            .annotation(position: .top, alignment: .leading) { Text("CMB dipole").font(.caption2).foregroundStyle(Theme.observation) }
                        RuleMark(x: .value("τ̂ (s)", crossing))
                            .foregroundStyle(Theme.observation.opacity(0.6))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .annotation(position: .top, alignment: .trailing) { Text("τ̂ ≈ \(Fmt.fixed(crossing, 4)) s").font(.caption2).foregroundStyle(.secondary) }
                        PointMark(x: .value("τ̂ (s)", params.tauHat), y: .value("v_kin (km/s)", earth.vKinematic / 1_000))
                            .foregroundStyle(Theme.time)
                            .symbolSize(100)
                    }
                    .chartXAxisLabel("τ̂ (s)  ·  set in the inspector")
                    .standardChartStyle()
                }
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Standard counterparts").font(.headline)
                        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                            GridRow {
                                Equation("v_{orbit}", size: 15)
                                Text("βc, the flow velocity of the enclosed mass (numerically its escape velocity)").font(.callout).foregroundStyle(.secondary)
                            }
                            GridRow {
                                Equation("v_{cosmo}", size: 15)
                                Text("c(v_esc/R)τ, with v_esc/R the Hubble-like rate of the flow at R").font(.callout).foregroundStyle(.secondary)
                            }
                            GridRow {
                                Equation("v_{kin}", size: 15)
                                Text("cΩτ with Ω = √(GM/R³) the circular-orbit angular frequency").font(.callout).foregroundStyle(.secondary)
                            }
                        }
                        Text("Hence the √2 between them: the ratio of escape to circular speed. Table 3.")
                            .font(.caption).foregroundStyle(.tertiary)
                    }
                }
                .frame(width: 420)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                EquationCard(title: "Cosmological velocity", latex: "\\varphi=1+\\frac{GM}{R^3},\\qquad v_{cosmo}=c\\sqrt{1-\\frac{1}{\\varphi^2}}", status: .numerical, note: "Earth: \(Fmt.fixed(earth.vCosmo, 2)) m/s. Compared in the paper with SNe bulk-flow estimates, which carry large uncertainties.", reference: "Eq. (A6)")
                EquationCard(title: "Kinematic velocity", latex: "v_{kin}=c\\sqrt{1-\\frac{1}{\\left(1+\\frac{1}{2}\\frac{GM}{R^3}\\right)^2}}", status: .numerical, note: "Earth: \(Fmt.fixed(earth.vKinematic, 0)) m/s, within 0.5% of the CMB dipole — but the difference exceeds the measurement error.", reference: "Eq. (A8)")
                EquationCard(title: "Length-only form", latex: "\\frac{v}{c}=\\sqrt{\\frac{GM}{c^2}}\\,\\frac{L_\\tau}{R^{3/2}},\\qquad L_\\tau=c\\hat{\\tau}", status: .identity, note: "Every quantity built with τ inherits the one fixed reference length L_τ.", reference: "Eq. (2)")
                EquationCard(title: "Same quantity from the orbit equation", latex: "dt=\\frac{2R^3}{GM-2R^3},\\qquad |dt|=1+\\frac{GM}{2R^3}", status: .numerical, note: "Not an independent confirmation: it is v_kin again.", reference: "App. A.4")
            }
            Callout(kind: .note, text: "Different observables: the CMB dipole measures the observer's motion relative to the CMB rest frame; SNe bulk flows are reconstructed peculiar velocities. Numerical agreement alone does not establish that these describe the same physical motion.")
        }
    }
}

// MARK: - Fine-structure alignments

struct FineStructurePage: View {
    @Environment(ParameterStore.self) private var params

    var body: some View {
        let alpha = SI.fineStructure
        let earth = BodyNumerics(body: .earth, G: params.G, c: params.c, tauHat: 1)
        let sunHalfDelta = pow(0.5 * BodyNumerics(body: .sun, G: params.G, c: params.c, tauHat: 1).delta, 1.0 / 3.0)
        let fits = FineStructureAlignments.gravityFits(G: params.G)
        let vEM = FineStructureAlignments.vElectromagnetic(c: params.c)

        PageScaffold(page: .fineStructure) {
            AppendixStatusBanner()

            ReadoutGrid(minimum: 200) {
                Readout(title: "Earth: ω vs α(2 − α)", value: Fmt.signedPercent(earth.omega / (alpha * (2 - alpha)) - 1, 4), caption: "ω⊕ = \(Fmt.fixed(earth.omega, 6))", tint: Theme.observation, latex: "\\omega_\\oplus=\\delta^{1/3}")
                Readout(title: "Earth: ω vs 2α", value: Fmt.signedPercent(earth.omega / (2 * alpha) - 1, 3), caption: "less accurate", latex: "2\\alpha")
                Readout(title: "Sun: (½δ)^{1/3} vs α", value: Fmt.signedPercent(sunHalfDelta / alpha - 1, 3), caption: "Γ☉ ≈ 1/∛2", tint: Theme.observation, latex: "\\alpha_\\odot")
                Readout(title: "v(γ_em) vs CMB dipole", value: Fmt.signedPercent(vEM / SI.cmbDipole - 1, 2), caption: "\(Fmt.fixed(vEM, 0)) m/s", tint: Theme.observation, latex: "v_{\\gamma_{em}}")
            }

            HStack(alignment: .top, spacing: 16) {
                ChartCard(title: "ω = δ^{1/3} against mean density", subtitle: "Band: α ≲ ω ≲ α(2 − α). The least dense body sits near α, the most dense near α(2 − α).", height: 320) {
                    let rhos = Sampling.log(300, 12_000, 140)
                    let curve = sample(rhos) { FineStructureAlignments.omega(density: $0, G: params.G) }
                    let bodies = CelestialBody.all.map { b in
                        XY(id: b.id.hashValue, x: b.density, y: FineStructureAlignments.omega(density: b.density, G: params.G), series: b.name)
                    }
                    Chart {
                        RectangleMark(xStart: .value("ρ", 300.0), xEnd: .value("ρ", 12_000.0), yStart: .value("ω", alpha), yEnd: .value("ω", alpha * (2 - alpha)))
                            .foregroundStyle(Theme.observation.opacity(0.15))
                        RuleMark(y: .value("ω", alpha))
                            .foregroundStyle(Theme.observation.opacity(0.7))
                            .annotation(position: .bottom, alignment: .trailing) { Text("α").font(.caption).foregroundStyle(Theme.observation) }
                        RuleMark(y: .value("ω", alpha * (2 - alpha)))
                            .foregroundStyle(Theme.observation.opacity(0.7))
                            .annotation(position: .top, alignment: .trailing) { Text("α(2 − α)").font(.caption).foregroundStyle(Theme.observation) }
                        ForEach(curve) { p in
                            LineMark(x: .value("ρ", p.x), y: .value("ω", p.y))
                                .foregroundStyle(Theme.flow)
                        }
                        ForEach(bodies) { p in
                            PointMark(x: .value("ρ", p.x), y: .value("ω", p.y))
                                .foregroundStyle(Theme.time)
                                .annotation(position: .leading) { Text(p.series).font(.caption2).foregroundStyle(.secondary) }
                        }
                    }
                    .chartXScale(type: .log)
                    .chartXAxisLabel("mean density ρ (kg/m³)")
                    .chartYAxisLabel("ω  (τ̂ = 1 s)")
                    .standardChartStyle()
                }
                Card {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Surface gravity from α").font(.headline)
                        Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 12) {
                            GridRow {
                                Text("Relation").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                                Text("Model").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                                Text("GM/R²").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                                Text("Δ").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                            }
                            Divider().gridCellUnsizedAxes(.horizontal)
                            ForEach(fits) { f in
                                GridRow {
                                    Equation(f.latex, size: 14)
                                    Text(Fmt.fixed(f.predicted, 2)).monospacedDigit()
                                    Text(Fmt.fixed(f.observed, 2)).monospacedDigit()
                                    Text(Fmt.signedPercent(f.relativeError, 2)).monospacedDigit().foregroundStyle(Theme.observation)
                                }
                                .font(.callout)
                            }
                        }
                        Text("τ = 1. The Γ(σ) factor is chosen body by body, so the fits have about as many adjustable choices as data points. The paper notes the Saturn limit was found before the related data were available.")
                            .font(.caption).foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(width: 470)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                EquationCard(title: "Inverse determinant of a radial dilation", latex: "\\delta(M,R)=\\frac{d}{dR}g=\\frac{2GM}{R^3},\\qquad \\omega=\\delta^{1/3}", status: .numerical, note: "δ is the radial tidal eigenvalue; ω⊕ ≈ α(2 − α) ± 0.0253%.", reference: "App. A.1")
                EquationCard(title: "A spin-dependent factor", latex: "\\alpha=\\Gamma(\\sigma)\\,\\delta^{1/3},\\quad \\Gamma_\\oplus=\\frac{1}{2-\\alpha},\\quad \\Gamma_\\odot\\approx\\frac{1}{\\sqrt[3]{2}},\\quad \\Gamma_{\\mathrm{Sat}}\\approx1", status: .numerical, note: "Γ(σ) is an unknown function of spin. The gravitomagnetic sector is ~8 orders of magnitude too small to supply it (§2.6).", reference: "App. A.1")
                EquationCard(title: "Electromagnetic series", latex: "\\gamma_{em}=1+\\frac{e^6(\\mu_0/\\epsilon_0)^{3/2}}{4h^3}+\\frac{3\\mu_0e^{10}(\\mu_0/\\epsilon_0)^{3/2}}{64\\epsilon_0h^5}-\\frac{3\\mu_0^2e^8}{16\\epsilon_0^2h^4}-\\frac{\\mu_0^3e^{12}}{256\\epsilon_0^3h^6}", status: .numerical, note: "v(γ_em) = \(Fmt.fixed(vEM, 0)) m/s, within 0.52% of the Planck dipole; the difference exceeds the measurement error.", reference: "App. A.1", size: 15)
                EquationCard(title: "Units", latex: "\\varphi-1=\\frac{GM}{c^2}\\,\\frac{L_\\tau^2}{R^3}", status: .identity, note: "A dimensionless constant cannot be identified with a dimensionful gravitational quantity without an extra scale — here L_τ.", reference: "App. A")
            }

            Callout(kind: .note, title: "What would make these meaningful", text: "A dimensionally consistent higher-dimensional field equation from which they follow, a determination of whether they depend on the individual source, and predictions that can be tested independently (App. A.7).")
        }
    }
}
