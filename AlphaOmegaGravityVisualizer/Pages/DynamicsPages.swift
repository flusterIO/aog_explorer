//
//  DynamicsPages.swift
//  AlphaOmegaGravityVisualizer
//
//  §2.5 lapse from the embedding, §2.5.1 interior lapse & Buchdahl bound, §2.7 orbits,
//  §2.6 rotation and frame dragging.
//

import Foundation
import SwiftUI
import Charts

// MARK: - Lapse from the embedding

struct LapsePage: View {
    @Environment(ParameterStore.self) private var params
    @State private var probe = 2.5
    @State private var release = 6.0
    @State private var fromInfinity = false

    private static let radii = Sampling.log(1.02, 60, 70)
    private static let numericLapse = Lapse.integrateVacuum(at: radii)

    var body: some View {
        let r = probe
        let n = Embedding.lapseExterior(r)
        let beta = (1 / r).squareRoot()
        let gamma = 1 / n
        let theta = asin(beta)
        let numeric = Self.numericLapse
        let maxResidual = zip(Self.radii, numeric).map { abs($1 - Embedding.lapseExterior($0)) }.max() ?? 0
        let r0 = fromInfinity ? Double.infinity : max(release, 1.05)

        PageScaffold(page: .lapse) {
            VisualWithControls {
                StageCard(height: 420) {
                    ForeshorteningDiagram(probe: r)
                        .padding(16)
                }
            } controls: {
                ControlPanel(title: "Static observer") {
                    ParameterSlider(title: "Radius", symbol: "R/r_s", value: $probe, range: 1.02...20, scale: .log, tint: Theme.time, format: { Fmt.fixed($0, 3) })
                }
                ReadoutGrid(minimum: 140) {
                    Readout(title: "Lapse", value: Fmt.fixed(n, 5), tint: Theme.geometry, latex: "N")
                    Readout(title: "Foreshortening", value: Fmt.fixed(cos(theta), 5), tint: Theme.time, latex: "\\cos\\theta")
                    Readout(title: "Redshift", value: Fmt.sig(gamma - 1, 4), latex: "z = \\gamma - 1")
                    Readout(title: "Circular speed", value: Fmt.fixed(r > 1.5 ? (1 / (2 * (r - 1))).squareRoot() : .nan, 4), unit: "c", caption: r > 1.5 ? "v² = c²R N′/N" : "no circular orbit", latex: "v_{local}")
                }
            }

            HStack(alignment: .top, spacing: 16) {
                ChartCard(title: "Integrating the lapse from the slope of y", subtitle: "Points: N′/N = γ²(ββ′ + β²/R) integrated inward from N(∞) = 1. Line: √(1 − r_s/R).", height: 300) {
                    let closed = sample(Sampling.log(1.02, 60, 200), series: "√(1 − r_s/R)") { Embedding.lapseExterior($0) }
                    let points = zip(Self.radii, numeric).enumerated().map { i, pair in XY(id: i, x: pair.0, y: pair.1, series: "numerical") }
                    Chart {
                        ForEach(closed) { p in
                            LineMark(x: .value("R / r_s", p.x), y: .value("N", p.y))
                                .foregroundStyle(Theme.geometry)
                                .lineStyle(StrokeStyle(lineWidth: 2.5))
                        }
                        ForEach(points) { p in
                            PointMark(x: .value("R / r_s", p.x), y: .value("N", p.y))
                                .foregroundStyle(Theme.time)
                                .symbolSize(22)
                        }
                        RuleMark(x: .value("R / r_s", r))
                            .foregroundStyle(Color.secondary)
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    }
                    .chartXScale(type: .log)
                    .chartXAxisLabel("R / r_s")
                    .chartYAxisLabel("N")
                    .standardChartStyle()
                }
                VStack(spacing: 16) {
                    Readout(title: "Max |numerical − closed form|", value: Fmt.sci(maxResidual, 2), caption: "over 70 radii between 1.02 and 60 r_s", tint: .green)
                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Proposition").font(.headline)
                                Spacer()
                                StatusBadge(status: .derived, compact: true)
                            }
                            Text("Let the exterior slice of a static, spherically symmetric vacuum region be the embedding with ∂_R y = βγ and β² = r_s/R, and N → 1 as R → ∞. Then")
                                .font(.callout).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Equation("N(R)=\\sqrt{1-\\frac{r_s}{R}}=\\frac{1}{\\gamma}", size: 22)
                                .frame(maxWidth: .infinity)
                            Text("so g₀₀ h_RR = −1 is a theorem of the construction in this region.")
                                .font(.callout).foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(width: 360)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                EquationCard(title: "Static vacuum equations in embedding form", latex: "\\nabla_i\\nabla_jN=N\\left(K\\,K_{ij}-K_{ik}K^k{}_j\\right),\\qquad K_{ij}=\\frac{\\partial_i\\partial_j y}{\\sqrt{1+\\mathcal{A}_k\\mathcal{A}^k}}", status: .imported, note: "The Hessian of the lapse is fixed by the Hessian of the fourth coordinate — a linear equation for N once y is known.", reference: "Eq. (71)")
                EquationCard(title: "Principal curvatures of the slice", latex: "\\kappa_\\theta=\\kappa_\\phi=\\frac{\\beta}{R},\\qquad \\kappa_R=\\frac{d\\theta}{d\\ell}=\\beta'", status: .identity, reference: "Eq. (72)")
                EquationCard(title: "Angular component", latex: "\\frac{N'}{N}=\\gamma^2\\left(\\beta\\beta'+\\frac{\\beta^2}{R}\\right)=\\frac{1}{2}\\frac{d}{dR}\\ln\\left(1-\\frac{r_s}{R}\\right)", status: .derived, note: "For β² = r_s/R, β′ = −β/(2R). The radial component N_{,ℓℓ}/N = 2ββ′/R is then satisfied identically.", reference: "Proof of Prop. 1")
                EquationCard(title: "Marginal binding", latex: "E=N\\gamma_{rel},\\qquad \\gamma_{rel}(R)=\\frac{N(R_0)}{N(R)},\\qquad \\beta_{rel}^2=1-\\frac{N(R)^2}{N(R_0)^2}", status: .equivalentGR, note: "The slope βγ equals β_rel γ_rel only for release from rest at infinity (E = 1).", reference: "§2.5")
            }

            VisualWithControls {
                ChartCard(title: "Free fall: who rides the slope?", subtitle: "β_rel for release from rest at R₀ compared with the flow β of the embedding.", height: 280) {
                    let xs = Sampling.log(1.02, fromInfinity ? 60 : r0, 160)
                    let flow = sample(xs, series: "embedding β (E = 1)") { (1 / $0).squareRoot() }
                    let fall = sample(xs, series: "released from R₀") { Lapse.releaseFromRest(r: $0, r0: r0).betaRel }
                    Chart {
                        ForEach(flow + fall) { p in
                            LineMark(x: .value("R / r_s", p.x), y: .value("β", p.y), series: .value("Curve", p.series))
                                .foregroundStyle(by: .value("Curve", p.series))
                        }
                    }
                    .chartXScale(type: .log)
                    .chartForegroundStyleScale(["embedding β (E = 1)": Theme.flow, "released from R₀": Theme.mass])
                    .chartXAxisLabel("R / r_s")
                    .standardChartStyle()
                }
            } controls: {
                ControlPanel(title: "Release") {
                    Toggle("Release from rest at infinity", isOn: $fromInfinity)
                    ParameterSlider(title: "Release radius", symbol: "R_0/r_s", value: $release, range: 1.2...60, scale: .log, tint: Theme.mass, format: { Fmt.fixed($0, 2) })
                        .disabled(fromInfinity)
                }
                Readout(title: "Energy per unit mass", value: Fmt.fixed(fromInfinity ? 1 : Embedding.lapseExterior(r0), 4), latex: "E = N(R_0)")
                Callout(kind: .note, text: "Bound orbits are not a different embedding of the same slice but a different relation between flow and slope. The reading of y as “the displacement of the infalling frame” is specific to E = 1.")
            }

            HStack(alignment: .top, spacing: 16) {
                Callout(kind: .result, title: "Established", text: "Given the slope of y on a static vacuum slice, the lapse is fixed: the closure N = 1/γ is equivalent to the second static field equation expressed through the embedding.")
                Callout(kind: .caveat, title: "Not established", text: "The static equations are imported from GR, so this is a restatement, not a prediction. A closed theory needs one 5D action yielding both ³R = 0 and the lapse equation; terms from G₄₄ ≠ 1 or a_μ ≠ 0 are the candidate departures from GR.")
            }
        }
    }
}

/// Cross-section of the slice with the tangent element dℓ and its projection dR = dℓ cos θ.
struct ForeshorteningDiagram: View {
    let probe: Double

    var body: some View {
        Canvas { ctx, size in
            let w = Double(size.width), h = Double(size.height)
            let rMax = 20.0
            let yMax = Embedding.yExterior(rMax)
            let sx = (w - 80) / rMax
            let sy = (h - 80) / yMax
            let scale = min(sx, sy * 2.2)
            func pt(_ r: Double, _ y: Double) -> CGPoint { CGPoint(x: 40 + r * scale, y: h - 40 - y * scale) }

            ctx.arrow(from: pt(0, 0), to: pt(rMax * 1.02, 0), color: .secondary, width: 1)
            ctx.label("R", at: pt(rMax * 1.04, 0), anchor: .leading)
            ctx.arrow(from: pt(0, 0), to: pt(0, (h - 60) / scale), color: .secondary, width: 1)
            ctx.label("y", at: pt(0.3, (h - 60) / scale), anchor: .leading)

            var curve = Path()
            for (i, r) in Embedding.clusteredRadii(from: 1, to: rMax, count: 200).enumerated() {
                let p = pt(r, Embedding.yExterior(r))
                if i == 0 { curve.move(to: p) } else { curve.addLine(to: p) }
            }
            ctx.stroke(curve, with: .color(Theme.flow), lineWidth: 3)

            let r0 = min(max(probe, 1.02), rMax - 2)
            let y0 = Embedding.yExterior(r0)
            let slope = (1 / (r0 - 1)).squareRoot()
            let theta = atan(slope)
            let len = 3.2
            let a = pt(r0, y0)
            let b = pt(r0 + len * cos(theta), y0 + len * sin(theta))
            let foot = pt(r0 + len * cos(theta), y0)
            ctx.line(a, b, color: Theme.time, width: 4)
            ctx.line(a, foot, color: Theme.geometry, width: 3)
            ctx.line(foot, b, color: .secondary, width: 1, dash: [3, 3])
            ctx.dot(a, radius: 5, color: Theme.time)

            var arc = Path()
            for (i, t) in Sampling.linear(0, theta, 30).enumerated() {
                let p = pt(r0 + 1.1 * cos(t), y0 + 1.1 * sin(t))
                if i == 0 { arc.move(to: p) } else { arc.addLine(to: p) }
            }
            ctx.stroke(arc, with: .color(Theme.observation), lineWidth: 2)
            ctx.label("θ", at: pt(r0 + 1.45 * cos(theta / 2), y0 + 1.45 * sin(theta / 2)), color: Theme.observation, font: .headline)
            ctx.label("dℓ = γ dR", at: pt(r0 + len * cos(theta) / 2 - 0.3, y0 + len * sin(theta) / 2 + 0.5), color: Theme.time, font: .callout.weight(.semibold), anchor: .trailing)
            ctx.label("dR = dℓ cos θ", at: pt(r0 + len * cos(theta) / 2, y0 - 0.7), color: Theme.geometry, font: .callout.weight(.semibold))
            ctx.label("redshift factor N = cos θ = \(Fmt.fixed(cos(theta), 4))", at: CGPoint(x: 20, y: 22), color: .primary, font: .headline, anchor: .leading)
            ctx.label("Flamm profile y = 2√(r_s(R − r_s))", at: CGPoint(x: 20, y: 46), color: .secondary, font: .caption, anchor: .leading)
        }
    }
}

// MARK: - Interior & Buchdahl

struct BuchdahlPage: View {
    @State private var starRadius = 2.0

    var body: some View {
        let star = UniformStar(radius: starRadius)
        let rMax = 3 * starRadius
        let xs = Sampling.linear(0, rMax, 240)
        let lapse = sample(xs, series: "N(R)") { star.lapse($0) }
        let foreshortening = sample(xs, series: "1/γ = cos θ (slice)") { r in
            r <= starRadius ? star.s(r) : Embedding.lapseExterior(r)
        }
        let pressure = sample(xs.filter { $0 < starRadius }, series: "p / ρc²") { min(star.pressure($0), 10) }
        let slice = Embedding.uniformStarSlice(starRadius: starRadius, rMax: rMax, count: 200)

        PageScaffold(page: .buchdahl) {
            VisualWithControls {
                SceneCard(spec: .from(slice, rings: [SurfaceRing(radius: starRadius, style: .surface)], flow: .none, hue: .star), height: 440) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Uniform-density star").font(.headline).foregroundStyle(.white)
                        Text("Spherical cap inside R*, paraboloid outside").font(.caption).foregroundStyle(.white.opacity(0.75))
                    }
                    .glassChip()
                }
            } controls: {
                ControlPanel(title: "Compactness") {
                    ParameterSlider(title: "Star radius", symbol: "R_*/r_s", value: $starRadius, range: 1.1...6, tint: Theme.mass, format: { Fmt.fixed($0, 3) })
                }
                ReadoutGrid(minimum: 140) {
                    Readout(title: "Central pressure", value: star.isStable ? Fmt.sig(star.centralPressure, 4) : "∞", unit: "ρc²", tint: star.isStable ? Theme.mass : .red, latex: "p_c")
                    Readout(title: "Central lapse", value: Fmt.fixed(max(0, star.centralLapse), 4), tint: Theme.geometry, latex: "N(0)")
                    Readout(title: "Surface tilt", value: Fmt.fixed(star.surfaceTiltDegrees, 2) + "°", caption: "limit 70.53°", tint: star.isStable ? .primary : .red, latex: "\\theta_*")
                    Readout(title: "Surface γ", value: Fmt.fixed(star.surfaceGamma, 3), caption: "limit 3", latex: "\\gamma_*")
                }
                Callout(kind: star.isStable ? .note : .caveat, text: star.isStable
                        ? "Static: R* = \(Fmt.fixed(starRadius, 3)) r_s > 9r_s/8 = 1.125 r_s."
                        : "Below the Buchdahl bound: N(0) → 0 and the central pressure diverges. No static uniform-density star exists.")
            }

            HStack(alignment: .top, spacing: 16) {
                ChartCard(title: "Lapse vs foreshortening", subtitle: "Outside, N = 1/γ. Inside, the pressure adds redshift beyond the tilt of the slice.", height: 300) {
                    Chart {
                        ForEach(lapse + foreshortening) { p in
                            LineMark(x: .value("R / r_s", p.x), y: .value("Value", p.y), series: .value("Curve", p.series))
                                .foregroundStyle(by: .value("Curve", p.series))
                                .lineStyle(StrokeStyle(lineWidth: p.series == "N(R)" ? 3 : 1.5, dash: p.series == "N(R)" ? [] : [5, 4]))
                        }
                        RuleMark(x: .value("R / r_s", starRadius))
                            .foregroundStyle(Theme.mass.opacity(0.6))
                            .annotation(position: .top, alignment: .leading) {
                                Text("R*").font(.caption2).foregroundStyle(Theme.mass)
                            }
                    }
                    .chartForegroundStyleScale(["N(R)": Theme.geometry, "1/γ = cos θ (slice)": Theme.time])
                    .chartYScale(domain: 0...1)
                    .chartXAxisLabel("R / r_s")
                    .standardChartStyle()
                }
                ChartCard(title: "Pressure profile", subtitle: "p/ρc² = (s − s*)/(3s* − s), s = cos θ", height: 300) {
                    Chart {
                        ForEach(pressure) { p in
                            AreaMark(x: .value("R / r_s", p.x), y: .value("p / ρc²", p.y))
                                .foregroundStyle(LinearGradient(colors: [Theme.mass.opacity(0.55), Theme.mass.opacity(0.05)], startPoint: .top, endPoint: .bottom))
                            LineMark(x: .value("R / r_s", p.x), y: .value("p / ρc²", p.y))
                                .foregroundStyle(Theme.mass)
                        }
                    }
                    .chartXScale(domain: 0...rMax)
                    .chartXAxisLabel("R / r_s")
                    .standardChartStyle()
                }
            }

            ChartCard(title: "Central pressure against compactness", subtitle: "Finite only for 3s* > 1, i.e. γ* < 3, θ* < 70.5°, R* > 9r_s/8.", height: 260) {
                let rs = Sampling.log(1.1255, 8, 200)
                let data = sample(rs) { min(UniformStar(radius: $0).centralPressure, 1e3) }
                Chart {
                    ForEach(data) { p in
                        LineMark(x: .value("R* / r_s", p.x), y: .value("p_c / ρc²", p.y))
                            .foregroundStyle(Theme.mass)
                    }
                    RuleMark(x: .value("R* / r_s", 1.125))
                        .foregroundStyle(Color.red.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("9/8").font(.caption2).foregroundStyle(.red)
                        }
                    if star.isStable {
                        PointMark(x: .value("R* / r_s", starRadius), y: .value("p_c / ρc²", min(star.centralPressure, 1e3)))
                            .foregroundStyle(Theme.time)
                            .symbolSize(100)
                    }
                }
                .chartXScale(type: .log)
                .chartYScale(type: .log)
                .chartXAxisLabel("R* / r_s")
                .standardChartStyle()
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                EquationCard(title: "Interior lapse", latex: "\\frac{N'}{N}=\\gamma^2\\left(\\frac{\\beta^2}{2R}+\\frac{4\\pi G\\,pR}{c^4}\\right)=\\frac{G\\left(m+4\\pi R^3p/c^2\\right)}{c^2R^2\\left(1-2Gm/c^2R\\right)}", status: .equivalentGR, note: "The TOV potential gradient; the radial component then holds iff p′ = −(ρc² + p)N′/N.", reference: "Eq. (74)")
                EquationCard(title: "Uniform density", latex: "N(R)=\\frac{3s_*-s(R)}{2},\\qquad p(R)=\\rho c^2\\frac{s(R)-s_*}{3s_*-s(R)}", status: .equivalentGR, note: "The interior Schwarzschild solution, with s = cos θ = √(1 − R²/L²).", reference: "Eq. (75)")
            }
            Callout(kind: .insight, title: "Beyond uniform density", text: "The paper derives the bound only for ρ = const. The **Star Lab** page integrates the same equations for ρ ∝ (1 − x²)ⁿ and finds each profile's limiting compactness numerically.")
        }
    }
}

// MARK: - Orbits & precession

struct OrbitsPage: View {
    @Environment(ParameterStore.self) private var params
    @State private var p = 24.0
    @State private var e = 0.5
    @State private var revolutions = 6.0
    @State private var angularMomentum = 4.3

    var body: some View {
        let trace = Schwarzschild.integrateOrbit(p: p, e: e, revolutions: revolutions)
        let measured = trace.measuredAdvance
        let formula = Schwarzschild.advanceFormula(p: p)
        let firstOrder = Schwarzschild.advanceFirstOrderExact(p: p)
        let radii = Schwarzschild.circularRadii(l: angularMomentum)

        PageScaffold(page: .orbits) {
            VisualWithControls {
                StageCard(height: 520, dark: true) {
                    OrbitCanvas(trace: trace)
                        .padding(18)
                        .overlay(alignment: .topLeading) {
                            VStack(alignment: .leading, spacing: 6) {
                                LegendChip(label: "R = r_s", color: Color(red: 1, green: 0.35, blue: 0.45))
                                LegendChip(label: "photon sphere 3GM/c²", color: Theme.observation, dashed: true)
                                LegendChip(label: "ISCO 6GM/c²", color: Theme.geometry, dashed: true)
                                LegendChip(label: "periapsis directions", color: Theme.time, dashed: true)
                            }
                            .glassChip()
                            .padding(16)
                        }
                }
            } controls: {
                ControlPanel(title: "Orbit (units GM/c²)") {
                    ParameterSlider(title: "Semilatus rectum", symbol: "p", value: $p, range: 9...80, tint: Theme.hypothesis, format: { Fmt.fixed($0, 1) })
                    ParameterSlider(title: "Eccentricity", symbol: "e", value: $e, range: 0...0.8, tint: Theme.time, format: { Fmt.fixed($0, 2) })
                    ParameterSlider(title: "Revolutions", value: $revolutions, range: 1...14, format: { Fmt.fixed($0, 0) })
                }
                ReadoutGrid(minimum: 140) {
                    Readout(title: "Measured advance", value: measured.map { Fmt.fixed($0 * 180 / Double.pi, 2) + "°" } ?? "—", caption: trace.plunged ? "orbit plunges" : "per orbit, numerical", tint: Theme.time, latex: "\\Delta\\phi")
                    Readout(title: "6πGM/pc²", value: Fmt.fixed(formula * 180 / Double.pi, 2) + "°", caption: "leading order")
                    Readout(title: "2π[1/(1−3/p) − 1]", value: Fmt.fixed(firstOrder * 180 / Double.pi, 2) + "°", caption: "first-order solution")
                    Readout(title: "Mercury", value: Fmt.fixed(Schwarzschild.mercuryArcsecPerCentury(G: params.G, c: params.c), 2) + "″", caption: "per century; observed ≈ 43″", tint: Theme.flow)
                }
            }

            HStack(alignment: .top, spacing: 16) {
                VisualWithControls(controlWidth: 260) {
                    ChartCard(title: "Effective potential", subtitle: "V_eff = N²(c² + L²/R²); extrema are circular orbits", height: 300) {
                        let xs = Sampling.log(2.05, 60, 260)
                        let v = sample(xs, series: "GR") { Schwarzschild.effectivePotential(r: $0, l: angularMomentum) }
                        let newton = sample(xs, series: "Newtonian") { r in 1 - 2 / r + angularMomentum * angularMomentum / (r * r) }
                        Chart {
                            ForEach((v + newton).filter { $0.y > 0.7 && $0.y < 1.15 }) { pt in
                                LineMark(x: .value("R", pt.x), y: .value("V/c²", pt.y), series: .value("Curve", pt.series))
                                    .foregroundStyle(by: .value("Curve", pt.series))
                            }
                            if let s = radii.stable {
                                PointMark(x: .value("R", s), y: .value("V/c²", Schwarzschild.effectivePotential(r: s, l: angularMomentum)))
                                    .foregroundStyle(Theme.geometry).symbolSize(90)
                                    .annotation(position: .bottom) { Text("stable").font(.caption2).foregroundStyle(.secondary) }
                            }
                            if let u = radii.unstable {
                                PointMark(x: .value("R", u), y: .value("V/c²", Schwarzschild.effectivePotential(r: u, l: angularMomentum)))
                                    .foregroundStyle(Color.red).symbolSize(90)
                                    .annotation(position: .top) { Text("unstable").font(.caption2).foregroundStyle(.secondary) }
                            }
                            RuleMark(x: .value("R", 6.0))
                                .foregroundStyle(Theme.geometry.opacity(0.5))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        }
                        .chartXScale(type: .log)
                        .chartForegroundStyleScale(["GR": Theme.hypothesis, "Newtonian": Color.secondary])
                        .chartXAxisLabel("R  (GM/c²)")
                        .standardChartStyle()
                    }
                } controls: {
                    ControlPanel(title: "Angular momentum") {
                        ParameterSlider(title: "L", symbol: "L\\,c/GM", value: $angularMomentum, range: 3.3...8, tint: Theme.hypothesis, format: { Fmt.fixed($0, 3) })
                    }
                    Readout(title: "Circular orbits", value: radii.stable == nil ? "none" : "\(Fmt.fixed(radii.unstable ?? 0, 2)), \(Fmt.fixed(radii.stable ?? 0, 2))", caption: "L² < 12 (GM/c)²: no circular orbit")
                }
            }

            ChartCard(title: "Locally measured circular speed", subtitle: "v²_local = c²R N′/N = GM/(R − r_s), compared with Newtonian GM/R", height: 240) {
                let xs = Sampling.log(3, 60, 200)
                let gr = sample(xs, series: "v_local (GR)") { (1 / ($0 - 2)).squareRoot() }
                let nt = sample(xs, series: "Newtonian √(GM/R)") { (1 / $0).squareRoot() }
                Chart {
                    ForEach(gr + nt) { pt in
                        LineMark(x: .value("R", pt.x), y: .value("v/c", pt.y), series: .value("Curve", pt.series))
                            .foregroundStyle(by: .value("Curve", pt.series))
                    }
                    RuleMark(x: .value("R", 6.0))
                        .foregroundStyle(Theme.geometry.opacity(0.5))
                        .annotation(position: .top, alignment: .leading) { Text("ISCO").font(.caption2).foregroundStyle(.secondary) }
                }
                .chartXScale(type: .log)
                .chartForegroundStyleScale(["v_local (GR)": Theme.time, "Newtonian √(GM/R)": Color.secondary])
                .chartXAxisLabel("R  (GM/c²)")
                .chartYAxisLabel("v / c")
                .standardChartStyle()
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                EquationCard(title: "Orbit equation", latex: "\\frac{d^2u}{d\\phi^2}+u=\\frac{GM}{L^2}+\\frac{3GM}{c^2}u^2,\\qquad u=\\frac{1}{R}", status: .equivalentGR, reference: "App. B")
                EquationCard(title: "Circular orbits", latex: "L^2=\\frac{GMR^2}{R-3GM/c^2},\\qquad R_{ISCO}=\\frac{6GM}{c^2}", status: .equivalentGR, reference: "App. B")
                EquationCard(title: "Perihelion advance", latex: "\\Delta\\phi=\\frac{6\\pi GM}{a(1-e^2)c^2}", status: .equivalentGR, reference: "§2.7")
                EquationCard(title: "Static exterior metric", latex: "ds^2=-\\left(1-\\frac{r_s}{R}\\right)c^2dt^2+\\frac{dR^2}{1-r_s/R}+R^2d\\Omega^2", status: .derived, note: "A = γ² from the embedding, N = 1/γ from §2.5. These are consequences, not independent tests.", reference: "§2.7")
            }
        }
    }
}

// MARK: - Rotation & frame dragging

struct FrameDraggingPage: View {
    @Environment(ParameterStore.self) private var params
    @State private var orbitKm = 7_027.0
    @State private var spinScale = 1.0

    var body: some View {
        let J = SI.earthAngularMomentum * spinScale
        let a = orbitKm * 1_000
        let avg = FrameDragging.toMasPerYear(FrameDragging.polarOrbitAverage(J: J, a: a, G: params.G, c: params.c))
        let pole = FrameDragging.toMasPerYear(2 * params.G * J / (params.c * params.c * pow(a, 3)))
        let surfaceOmega = FrameDragging.zamoAngularVelocity(J: J, R: CelestialBody.earth.radius, G: params.G, c: params.c)
        let tidal = (2 * params.G * CelestialBody.earth.mass / pow(CelestialBody.earth.radius, 3)).squareRoot()

        PageScaffold(page: .frameDragging) {
            VisualWithControls {
                StageCard(height: 480, dark: true) {
                    VectorFieldCanvas(extent: 3.2, field: { x, z in
                        FrameDragging.precession(x: x, z: z, J: 1, G: 1, c: 1)
                    }, density: 25, bodyRadius: 1, excludeRadius: 1.08, tint: Theme.hypothesis, axisLabels: ("x / R⊕", "z ∥ J"))
                    .padding(16)
                    .overlay(alignment: .topLeading) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Gyroscope precession Ω_LT").font(.headline).foregroundStyle(.white)
                            Text("Meridional plane, J along z: a dipole field").font(.caption).foregroundStyle(.white.opacity(0.75))
                        }
                        .glassChip()
                        .padding(16)
                    }
                }
            } controls: {
                ControlPanel(title: "Polar orbit") {
                    ParameterSlider(title: "Orbit radius", symbol: "a", value: $orbitKm, range: 6_600...30_000, scale: .log, unit: "km", tint: Theme.hypothesis, format: { Fmt.fixed($0, 0) })
                    ParameterSlider(title: "Angular momentum", symbol: "J/J_\\oplus", value: $spinScale, range: 0.2...3, format: { Fmt.fixed($0, 2) })
                }
                ReadoutGrid(minimum: 140) {
                    Readout(title: "Orbit-averaged", value: Fmt.fixed(avg, 1), unit: "mas/yr", caption: "GP-B: 37.2 ± 7.2", tint: Theme.hypothesis, latex: "\\langle\\Omega\\rangle")
                    Readout(title: "Over the pole", value: Fmt.fixed(pole, 1), unit: "mas/yr", latex: "2GJ/c^2a^3")
                    Readout(title: "Drag at surface", value: Fmt.sci(surfaceOmega, 2), unit: "s⁻¹", latex: "\\omega(R_\\oplus)")
                    Readout(title: "vs √δ⊕", value: Fmt.sci(surfaceOmega / tidal, 2), caption: "≈ 8 orders too small", tint: Theme.mass)
                }
            }

            ChartCard(title: "Frame dragging along a polar orbit", subtitle: "GJ/(2c²a³) against orbit radius; Gravity Probe B at a = 7027 km.", height: 260) {
                let xs = Sampling.log(6_600, 30_000, 120)
                let data = sample(xs) { km in FrameDragging.toMasPerYear(FrameDragging.polarOrbitAverage(J: J, a: km * 1_000, G: params.G, c: params.c)) }
                Chart {
                    ForEach(data) { p in
                        LineMark(x: .value("a (km)", p.x), y: .value("mas/yr", p.y))
                            .foregroundStyle(Theme.hypothesis)
                    }
                    RuleMark(x: .value("a (km)", 7_027.0), yStart: .value("mas/yr", SI.gpbFrameDragging - SI.gpbSigma), yEnd: .value("mas/yr", SI.gpbFrameDragging + SI.gpbSigma))
                        .foregroundStyle(Theme.observation)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                    PointMark(x: .value("a (km)", 7_027.0), y: .value("mas/yr", SI.gpbFrameDragging))
                        .foregroundStyle(Theme.observation)
                        .symbolSize(80)
                        .annotation(position: .trailing) { Text("Gravity Probe B").font(.caption2).foregroundStyle(.secondary) }
                    PointMark(x: .value("a (km)", orbitKm), y: .value("mas/yr", avg))
                        .foregroundStyle(Theme.time)
                        .symbolSize(90)
                }
                .chartXScale(type: .log)
                .chartYScale(type: .log)
                .chartXAxisLabel("orbit radius a (km)")
                .chartYAxisLabel("mas / yr")
                .standardChartStyle()
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                EquationCard(title: "Slow rotation adds a shift only", latex: "ds^2=-N^2c^2dt^2+\\gamma^2dR^2+R^2d\\theta^2+R^2\\sin^2\\theta\\left(d\\phi-\\omega\\,dt\\right)^2", status: .equivalentGR, note: "To first order in J the slice and its embedding are unchanged.", reference: "Eq. (76)")
                EquationCard(title: "Momentum constraint on the Flamm slice", latex: "\\frac{d}{dR}\\left(R^4\\omega'\\right)=0\\;\\Rightarrow\\;\\omega(R)=\\frac{2GJ}{c^2R^3}", status: .equivalentGR, note: "The factors of r_s drop out — the Lense–Thirring result, exact on the slice at this order.", reference: "Eq. (78)")
                EquationCard(title: "The non-gradient component is the vorticity", latex: "a_i\\simeq\\frac{v_{s,i}}{c},\\qquad \\mathcal{F}=\\nabla\\times\\mathbf{a}=\\frac{2GJ}{c^3}\\frac{3(\\hat{z}\\cdot\\hat{r})\\hat{r}-\\hat{z}}{R^3}", status: .derived, reference: "Eq. (79)")
                EquationCard(title: "Gyroscope precession", latex: "\\mathbf{\\Omega}_{LT}=\\frac{c}{2}\\mathcal{F}=\\frac{G}{c^2R^3}\\left[3(\\mathbf{J}\\cdot\\hat{r})\\hat{r}-\\mathbf{J}\\right]", status: .equivalentGR, reference: "Eq. (80)")
            }
            Callout(kind: .caveat, title: "What this does not give", text: "At Earth's surface ω ≈ 3.4 × 10⁻¹⁴ s⁻¹, about 1.9 × 10⁻¹¹ of √δ⊕. The spin factor 1/(2 − α) of Appendix A differs from ½ by α/2 ≈ 3.7 × 10⁻³, so the gravitomagnetic component is roughly eight orders of magnitude too small to explain Γ(σ).")
        }
    }
}
