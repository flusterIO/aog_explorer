//
//  Relativity.swift
//  AlphaOmegaGravityVisualizer
//
//  Kinematics of the additional coordinate y (§2.1–2.2) and the static radial
//  embedding of §2.4–2.5. Unless noted, radial functions use units with r_s = 1.
//

import Foundation

// MARK: - Lorentz factor as a slope

enum Lorentz {
    static func gamma(beta: Double) -> Double { 1 / (1 - beta * beta).squareRoot() }
    static func beta(gamma: Double) -> Double { (1 - 1 / (gamma * gamma)).squareRoot() }

    /// ∂ₓy = βγ = sinh η
    static func slope(beta: Double) -> Double { beta * gamma(beta: beta) }

    /// γ = √(1 + (∂ₓy)²)
    static func gammaFromSlope(_ s: Double) -> Double { (1 + s * s).squareRoot() }

    static func rapidity(beta: Double) -> Double { atanh(beta) }

    /// ∂_τ y = v² / √(c² − v²) = c β² γ
    static func dyDtau(beta: Double, c: Double) -> Double { c * beta * beta * gamma(beta: beta) }

    /// Relativistic velocity composition (rapidities add).
    static func compose(_ b1: Double, _ b2: Double) -> Double { (b1 + b2) / (1 + b1 * b2) }
}

// MARK: - Radial slices

struct SliceSample: Identifiable {
    let id: Int
    /// Areal radius.
    let r: Double
    /// β² = 2Gm(R)/(c²R)
    let beta2: Double
    /// Embedding height y(R).
    let y: Double

    var beta: Double { beta2.squareRoot() }
    var gamma: Double { 1 / max(1e-12, 1 - beta2).squareRoot() }
    /// ∂_R y = βγ
    var slope: Double { beta * gamma }
    /// Tilt of the slice, sin θ = β.
    var tiltDegrees: Double { asin(min(1, beta)) * 180 / Double.pi }
}

enum MassDistribution: String, CaseIterable, Identifiable {
    case pointMass = "Exterior of a mass"
    case uniformStar = "Uniform-density star"
    case criticalDensity = "Critical density (flat FLRW)"

    var id: String { rawValue }

    var flowDescription: String {
        switch self {
        case .pointMass: "inward"
        case .uniformStar: "inward or outward"
        case .criticalDensity: "outward"
        }
    }

    var embeddingDescription: String {
        switch self {
        case .pointMass: "paraboloid"
        case .uniformStar: "cap of a 3-sphere, L² = 3c²/8πGρ"
        case .criticalDensity: "cap with L = c/H"
        }
    }

    var massLatex: String {
        switch self {
        case .pointMass: "M"
        case .uniformStar: "\\tfrac{4\\pi}{3}\\rho R^3"
        case .criticalDensity: "\\tfrac{4\\pi}{3}\\rho_c R^3"
        }
    }
}

enum Embedding {
    // Exterior of a mass, r_s = 1.
    static func yExterior(_ r: Double) -> Double { 2 * max(0, r - 1).squareRoot() }
    static func beta2Exterior(_ r: Double) -> Double { 1 / r }
    static func lapseExterior(_ r: Double) -> Double { max(0, 1 - 1 / r).squareRoot() }

    /// Radii clustered near the throat for a smooth surface.
    static func clusteredRadii(from a: Double, to b: Double, count n: Int, power: Double = 2) -> [Double] {
        (0..<n).map { i in
            let t = Double(i) / Double(max(1, n - 1))
            return a + (b - a) * pow(t, power)
        }
    }

    /// Flamm paraboloid y = 2√(r_s (R − r_s)).
    static func exteriorSlice(rMax: Double, count: Int = 160) -> [SliceSample] {
        clusteredRadii(from: 1, to: rMax, count: count).enumerated().map { i, r in
            SliceSample(id: i, r: r, beta2: beta2Exterior(r), y: yExterior(r))
        }
    }

    /// Uniform-density star of radius R* (in r_s): spherical cap inside, paraboloid outside.
    static func uniformStarSlice(starRadius rStar: Double, rMax: Double, count: Int = 200) -> [SliceSample] {
        let L2 = rStar * rStar * rStar
        let cap = yExterior(rStar) + (L2 - rStar * rStar).squareRoot()
        let inner = max(20, Int(Double(count) * min(0.6, rStar / rMax + 0.2)))
        var out: [SliceSample] = []
        for (i, r) in Grid.linear(0, rStar, inner).enumerated() {
            out.append(SliceSample(id: i, r: r, beta2: r * r / L2, y: cap - max(0, L2 - r * r).squareRoot()))
        }
        let outer = Grid.linear(rStar, rMax, max(10, count - inner)).dropFirst()
        for (j, r) in outer.enumerated() {
            out.append(SliceSample(id: inner + j, r: r, beta2: beta2Exterior(r), y: yExterior(r)))
        }
        return out
    }

    /// Critical density: β = HR/c. Lengths in units of L = c/H.
    static func hubbleSlice(rMax: Double = 0.995, count: Int = 160) -> [SliceSample] {
        Grid.linear(0, rMax, count).enumerated().map { i, r in
            SliceSample(id: i, r: r, beta2: r * r, y: 1 - max(0, 1 - r * r).squareRoot())
        }
    }

    /// ³R = (2/R²) d(Rβ²)/dR, evaluated by central differences.
    static func scalarCurvature(_ s: [SliceSample]) -> [XY] {
        guard s.count > 2 else { return [] }
        var out: [XY] = []
        for i in 1..<(s.count - 1) {
            let a = s[i - 1], b = s[i + 1]
            let dr = b.r - a.r
            guard dr > 0, s[i].r > 0 else { continue }
            let d = (b.r * b.beta2 - a.r * a.beta2) / dr
            out.append(XY(id: i, x: s[i].r, y: 2 / (s[i].r * s[i].r) * d))
        }
        return out
    }

    /// Principal curvatures κ_θ = β/R and κ_R = β′.
    static func principalCurvatures(_ s: [SliceSample]) -> (angular: [XY], radial: [XY]) {
        guard s.count > 2 else { return ([], []) }
        var ang: [XY] = [], rad: [XY] = []
        for i in 1..<(s.count - 1) {
            let a = s[i - 1], b = s[i + 1], m = s[i]
            guard m.r > 0 else { continue }
            ang.append(XY(id: i, x: m.r, y: m.beta / m.r, series: "κθ = β/R"))
            rad.append(XY(id: i, x: m.r, y: (b.beta - a.beta) / (b.r - a.r), series: "κR = β′"))
        }
        return (ang, rad)
    }
}

// MARK: - Lapse from the embedding (§2.5)

enum Lapse {
    /// Integrates N′/N = γ²(ββ′ + β²/R) inward from R = rOuter with N(rOuter) = 1, using
    /// only β(R) (here the exterior β² = r_s/R). Returns N at the requested radii.
    static func integrateVacuum(at radii: [Double], rOuter: Double = 1e6, beta2: (Double) -> Double = Embedding.beta2Exterior) -> [Double] {
        func rhs(_ r: Double) -> Double {
            let h = r * 1e-5
            let b = beta2(r).squareRoot()
            let bp = (beta2(r + h).squareRoot() - beta2(r - h).squareRoot()) / (2 * h)
            let g2 = 1 / (1 - beta2(r))
            return g2 * (b * bp + beta2(r) / r)
        }
        // Integrate d lnN / d s with s = ln r, from s_outer down.
        let targets = radii.sorted(by: >)
        var results: [Double: Double] = [:]
        var s = log(rOuter)
        var lnN = 0.0
        let ds = -0.004
        for target in targets {
            let sTarget = log(target)
            while s + ds > sTarget {
                lnN += rk4(s, ds, lnN, rhs)
                s += ds
            }
            let last = sTarget - s
            if abs(last) > 0 { lnN += rk4(s, last, lnN, rhs); s = sTarget }
            results[target] = exp(lnN)
        }
        return radii.map { results[$0] ?? .nan }
    }

    private static func rk4(_ s: Double, _ h: Double, _ y: Double, _ f: (Double) -> Double) -> Double {
        // dy/ds = r f(r) with r = e^s; independent of y.
        func g(_ s: Double) -> Double { let r = exp(s); return r * f(r) }
        let k1 = g(s), k2 = g(s + h / 2), k4 = g(s + h)
        return h / 6 * (k1 + 4 * k2 + k4)
    }

    /// Free fall from rest at R₀: γ_rel = N(R₀)/N(R), β_rel² = 1 − N(R)²/N(R₀)².
    static func releaseFromRest(r: Double, r0: Double) -> (gammaRel: Double, betaRel: Double) {
        let n = Embedding.lapseExterior(r)
        let n0 = r0.isInfinite ? 1 : Embedding.lapseExterior(r0)
        let g = n0 / max(n, 1e-12)
        let b2 = max(0, 1 - (n * n) / (n0 * n0))
        return (g, b2.squareRoot())
    }
}

/// Interior Schwarzschild solution in the embedding language (§2.5.1). Lengths in r_s.
struct UniformStar {
    let radius: Double

    var L2: Double { radius * radius * radius }
    func s(_ r: Double) -> Double { max(0, 1 - r * r / L2).squareRoot() }
    var sStar: Double { max(0, 1 - 1 / radius).squareRoot() }

    /// N(R) = (3s* − s(R))/2 inside, √(1 − r_s/R) outside.
    func lapse(_ r: Double) -> Double {
        r >= radius ? Embedding.lapseExterior(r) : (3 * sStar - s(r)) / 2
    }

    /// p/ρc² = (s − s*)/(3s* − s) inside, 0 outside.
    func pressure(_ r: Double) -> Double {
        guard r < radius else { return 0 }
        let den = 3 * sStar - s(r)
        return den > 0 ? (s(r) - sStar) / den : .infinity
    }

    var centralPressure: Double {
        let den = 3 * sStar - 1
        return den > 0 ? (1 - sStar) / den : .infinity
    }

    var centralLapse: Double { (3 * sStar - 1) / 2 }
    var surfaceGamma: Double { 1 / max(sStar, 1e-12) }
    var surfaceTiltDegrees: Double { acos(min(1, sStar)) * 180 / Double.pi }
    var isStable: Bool { radius > 9.0 / 8.0 }
}
