//
//  GalacticPage.swift
//  AlphaOmegaGravityVisualizer
//
//  §3 Hypothesis M — horizon-limited Machian inertia — and Appendix A.6, the Milky Way
//  rotation curve (Eilers et al. 2019) against an approximate baryonic model.
//

import Foundation
import SwiftUI
import Charts

struct HypothesisMPage: View {
    @Environment(ParameterStore.self) private var params
    @State private var baryonScale = 1.0
    @State private var fractionalError = 0.05
    @State private var showFlow = true
    @State private var showNewton = true
    @State private var showBestFit = true

    var body: some View {
        let G = params.G
        let model = BaryonModel(scale: baryonScale)
        let g0 = params.g0
        let fit = GalacticDynamics.fitG0(model: model, G: G, fractionalError: fractionalError)
        let n = Double(Eilers2019.points.count)
        let chiM = GalacticDynamics.chiSquared(model: model, g0: g0, G: G, fractionalError: fractionalError).chi2
        let chiFlow = GalacticDynamics.chiSquaredFlow(model: model, G: G, fractionalError: fractionalError)
        let r0 = SI.solarGalactocentricRadiusKpc
        let vFlowSun = GalacticDynamics.flowVelocity(mass: model.enclosedMass(rKpc: r0), r: r0 * SI.kpc, G: G)
        let totalMass = model.enclosedMass(rKpc: 200)
        let vFlat = pow(G * totalMass * g0, 0.25)

        PageScaffold(page: .hypothesisM) {
            Card {
                HStack(alignment: .top, spacing: 16) {
                    Image(systemName: "quote.opening")
                        .font(.title)
                        .foregroundStyle(Theme.hypothesis)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Hypothesis M").font(.headline)
                            StatusBadge(status: .hypothesis, compact: true)
                        }
                        Text("The inertial resistance of a body accelerating at g is supplied by the cosmic flow potential within the radius c²/g. When c²/g ≤ c/H, that is g ≳ cH, the radius lies inside the Hubble radius and the resistance has its full value. When g ≲ cH, part of the contribution is absent and the inertial mass is reduced.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            VisualWithControls {
                ChartCard(title: "Milky Way rotation curve", subtitle: "Points: Eilers et al. (2019). Curves from the rescaled baryonic model.", height: 380) {
                    let curves = rotationCurves(model: model, g0: g0, fitG0: fit.g0, G: G)
                    Chart {
                        ForEach(curves) { p in
                            LineMark(x: .value("R (kpc)", p.x), y: .value("v (km/s)", p.y), series: .value("Model", p.series))
                                .foregroundStyle(by: .value("Model", p.series))
                                .lineStyle(StrokeStyle(lineWidth: p.series.contains("best") ? 1.5 : 2.5, dash: p.series.contains("best") ? [5, 4] : []))
                        }
                        ForEach(Eilers2019.points) { p in
                            RuleMark(x: .value("R (kpc)", p.rKpc), yStart: .value("v (km/s)", p.vKms * (1 - fractionalError)), yEnd: .value("v (km/s)", p.vKms * (1 + fractionalError)))
                                .foregroundStyle(Color.primary.opacity(0.18))
                            PointMark(x: .value("R (kpc)", p.rKpc), y: .value("v (km/s)", p.vKms))
                                .foregroundStyle(Color.primary.opacity(0.8))
                                .symbolSize(18)
                        }
                        PointMark(x: .value("R (kpc)", r0), y: .value("v (km/s)", vFlowSun / 1_000))
                            .symbol(.diamond)
                            .foregroundStyle(Theme.observation)
                            .symbolSize(120)
                            .annotation(position: .top) { Text("Sun").font(.caption2).foregroundStyle(.secondary) }
                    }
                    .chartForegroundStyleScale([
                        "Hypothesis M (κ′cH₀)": Theme.hypothesis,
                        "Hypothesis M (best-fit g₀)": Theme.time,
                        "v_orbit = √(2GM/R)": Theme.flow,
                        "Newtonian √(GM/R)": Color.secondary,
                    ])
                    .chartYScale(domain: 100...280)
                    .chartXAxisLabel("Galactocentric radius R (kpc)")
                    .chartYAxisLabel("v (km/s)")
                    .standardChartStyle()
                }
            } controls: {
                ControlPanel(title: "Baryons & errors") {
                    ParameterSlider(title: "Baryonic normalisation", symbol: "s", value: $baryonScale, range: 0.6...2.0, tint: Theme.mass, format: { Fmt.fixed($0, 2) })
                    ParameterSlider(title: "Fractional error", symbol: "\\sigma/v", value: $fractionalError, range: 0.02...0.15, format: { Fmt.percent($0, 0) })
                    Toggle("Flow velocity v_orbit", isOn: $showFlow)
                    Toggle("Newtonian", isOn: $showNewton)
                    Toggle("Best-fit g₀", isOn: $showBestFit)
                }
                ReadoutGrid(minimum: 140) {
                    Readout(title: "Best-fit scale", value: Fmt.fixed(fit.g0 / params.cH0, 3), caption: "χ²/dof = \(Fmt.fixed(fit.chi2 / (n - 1), 2))", tint: Theme.time, latex: "g_0/cH_0")
                    Readout(title: "With κ′ = \(Fmt.fixed(params.kappaPrime, 3))", value: Fmt.fixed(chiM / n, 2), caption: "χ² per point", tint: Theme.hypothesis, latex: "\\chi^2/N")
                    Readout(title: "Flow velocity alone", value: Fmt.fixed(chiFlow / n, 1), caption: "χ² per point", tint: Theme.flow)
                    Readout(title: "v_orbit at R₀", value: Fmt.fixed(vFlowSun / 1_000, 1), unit: "km/s", caption: "paper: 216.9 at s = 1")
                }
                Text("M_b(< 8.12 kpc) = \(Fmt.sig(baryonScale * SI.enclosedBaryonicMassSolar, 3)) M☉ · κ′ and H₀ in the inspector")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .top, spacing: 16) {
                ChartCard(title: "Enclosed mass needed by the flow velocity", subtitle: "v_obs²R/2G against the baryonic model — the data need more mass outside the solar circle.", height: 280) {
                    let required = Eilers2019.points.map { p in
                        XY(id: p.id, x: p.rKpc, y: GalacticDynamics.requiredMassForFlow(v: p.vKms * 1_000, r: p.rKpc * SI.kpc, G: G) / SI.solarMass / 1e10, series: "required")
                    }
                    let modelMass = sample(Sampling.linear(4.5, 26, 120), series: "baryonic model") { model.enclosedMass(rKpc: $0) / SI.solarMass / 1e10 }
                    Chart {
                        ForEach(modelMass) { p in
                            LineMark(x: .value("R (kpc)", p.x), y: .value("M (10¹⁰ M☉)", p.y))
                                .foregroundStyle(Theme.mass)
                        }
                        ForEach(required) { p in
                            PointMark(x: .value("R (kpc)", p.x), y: .value("M (10¹⁰ M☉)", p.y))
                                .foregroundStyle(Theme.flow)
                                .symbolSize(22)
                        }
                    }
                    .chartXAxisLabel("R (kpc)")
                    .chartYAxisLabel("M (10¹⁰ M☉)")
                    .standardChartStyle()
                }
                ChartCard(title: "Radial acceleration relation", subtitle: "g_obs = v²/R against g_N = GM_b/R². Deep-MOND limit g = √(g_N g₀).", height: 280) {
                    let pts = Eilers2019.points.map { p in
                        let r = p.rKpc * SI.kpc
                        let gObs = pow(p.vKms * 1_000, 2) / r
                        let gN = G * model.enclosedMass(rKpc: p.rKpc) / (r * r)
                        return XY(id: p.id, x: log10(gN), y: log10(gObs), series: "data")
                    }
                    let gx = Sampling.linear(-11.5, -9.0, 100)
                    let rar = sample(gx, series: "RAR, g₀ = κ′cH₀") { lg in log10(GalacticDynamics.rar(gN: pow(10, lg), g0: g0)) }
                    let unity = sample(gx, series: "g = g_N") { $0 }
                    Chart {
                        ForEach(rar + unity) { p in
                            LineMark(x: .value("log g_N", p.x), y: .value("log g", p.y), series: .value("Curve", p.series))
                                .foregroundStyle(by: .value("Curve", p.series))
                        }
                        ForEach(pts) { p in
                            PointMark(x: .value("log g_N", p.x), y: .value("log g", p.y))
                                .foregroundStyle(Theme.flow)
                                .symbolSize(22)
                        }
                        RuleMark(x: .value("log g_N", log10(g0)))
                            .foregroundStyle(Theme.hypothesis.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .annotation(position: .top, alignment: .leading) { Text("g₀").font(.caption2).foregroundStyle(Theme.hypothesis) }
                    }
                    .chartForegroundStyleScale(["RAR, g₀ = κ′cH₀": Theme.hypothesis, "g = g_N": Color.secondary])
                    .chartXAxisLabel("log₁₀ g_N (m/s²)")
                    .chartYAxisLabel("log₁₀ g (m/s²)")
                    .standardChartStyle()
                }
            }

            HStack(alignment: .top, spacing: 16) {
                ChartCard(title: "Prediction: g₀ evolves with H(z)", subtitle: "g₀(z) = κ′cH(z), flat ΛCDM with Ω_m = 0.3. A constant acceleration scale would be flat.", height: 240) {
                    let zs = Sampling.linear(0, 3, 120)
                    let evolving = sample(zs, series: "g₀ ∝ H(z)") { z in params.kappaPrime * params.c * Cosmology.hubble(z: z, H0: params.H0, omegaM: 0.3) / 1e-10 }
                    let constant = sample(zs, series: "constant g₀") { _ in g0 / 1e-10 }
                    Chart {
                        ForEach(evolving + constant) { p in
                            LineMark(x: .value("z", p.x), y: .value("g₀ (10⁻¹⁰ m/s²)", p.y), series: .value("Curve", p.series))
                                .foregroundStyle(by: .value("Curve", p.series))
                        }
                    }
                    .chartForegroundStyleScale(["g₀ ∝ H(z)": Theme.hypothesis, "constant g₀": Color.secondary])
                    .chartXAxisLabel("redshift z")
                    .chartYAxisLabel("g₀ (10⁻¹⁰ m/s²)")
                    .standardChartStyle()
                }
                VStack(spacing: 16) {
                    EquationCard(title: "Flat rotation curve from the flows", latex: "\\left(\\frac{v}{c}\\right)^4=\\frac{\\kappa'}{2}\\beta_N^2\\beta_H,\\qquad \\beta_N^2\\beta_H=\\frac{2GMH}{c^3}", status: .derived, note: "Given Hypothesis M. The product is independent of R: v⁴ ∝ M, the baryonic Tully–Fisher relation.", reference: "Eq. (92)", size: 18)
                    Readout(title: "Asymptotic speed (GM_b g₀)^¼", value: Fmt.fixed(vFlat / 1_000, 1), unit: "km/s", caption: "M_b(< 200 kpc) = \(Fmt.sci(totalMass / SI.solarMass, 2)) M☉", tint: Theme.hypothesis)
                }
                .frame(width: 420)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                EquationCard(title: "Testable form", latex: "m_i=m\\,\\mu\\left(\\frac{g}{g_0}\\right),\\qquad g\\,\\mu\\left(\\frac{g}{g_0}\\right)=g_N,\\qquad g_0=\\kappa' cH_0", status: .hypothesis, note: "μ → 1 for g ≫ g₀ and μ → g/g₀ for g ≪ g₀, so g = √(g_N g₀) in the deep limit.", reference: "Eq. (90)")
                EquationCard(title: "Interpolation used for the fit", latex: "g_{obs}=\\frac{g_N}{1-e^{-\\sqrt{g_N/g_0}}}", status: .assumption, note: "Empirical (McGaugh et al. 2016); the paper's candidate κ′ = 1/2π gives g₀ ≈ 1.1 × 10⁻¹⁰ m/s².", reference: "App. A.6")
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                Callout(kind: .result, title: "Derived", text: "The Sciama identity; the size of the cosmological correction within the paper's flow structure; the Newtonian limit of Hypothesis M in the Solar System; and the Tully–Fisher form, given Hypothesis M.")
                Callout(kind: .caveat, title: "Assumed", text: "The horizon cutoff of inertial resistance, the interpolation function μ, the proportionality g₀ ∝ cH, and the value of κ′.")
                Callout(kind: .note, title: "Not claimed", text: "That Hypothesis M explains the Galactic data, or that it follows from the embedding. It has the structure of modified inertia, with the known difficulties at cluster scales and in relativistic completion.")
                Callout(kind: .insight, title: "What would count against it", text: "A systematic variation of κ′ between galaxies beyond baryonic-mass uncertainty; no evolution of g₀ with H(z) in adequate high-redshift data; or a derivation of κ′ from the embedding outside the empirical range.")
            }

            Callout(kind: .caveat, title: "About this comparison", text: "One galaxy; an approximate baryonic model (Hernquist bulge plus exponential discs treated as spherical shells, rescaled to 4.44 × 10¹⁰ M☉ inside 8.12 kpc). Eilers et al. per-point uncertainties are not bundled, so χ² here uses a uniform fractional error. The paper's own fit (Table 4) gives g₀/cH₀ = 0.35, 0.22 and 0.15 for s = 1, 1.31 and 1.60.")
        }
    }

    private func rotationCurves(model: BaryonModel, g0: Double, fitG0: Double, G: Double) -> [XY] {
        let xs = Sampling.linear(4.5, 26, 140)
        func curve(_ name: String, _ v: (Double, Double) -> Double) -> [XY] {
            sample(xs, series: name) { r in v(model.enclosedMass(rKpc: r), r * SI.kpc) / 1_000 }
        }
        var curves = curve("Hypothesis M (κ′cH₀)") { m, r in GalacticDynamics.hypothesisM(mass: m, r: r, g0: g0, G: G) }
        if showBestFit {
            curves += curve("Hypothesis M (best-fit g₀)") { m, r in GalacticDynamics.hypothesisM(mass: m, r: r, g0: fitG0, G: G) }
        }
        if showFlow {
            curves += curve("v_orbit = √(2GM/R)") { m, r in GalacticDynamics.flowVelocity(mass: m, r: r, G: G) }
        }
        if showNewton {
            curves += curve("Newtonian √(GM/R)") { m, r in GalacticDynamics.newtonian(mass: m, r: r, G: G) }
        }
        return curves
    }
}
