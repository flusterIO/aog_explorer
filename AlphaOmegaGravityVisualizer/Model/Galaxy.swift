//
//  Galaxy.swift
//  AlphaOmegaGravityVisualizer
//
//  Milky Way rotation curve (Eilers et al. 2019), an approximate baryonic model, the
//  flow velocity v_orbit = √(2GM/R) and Hypothesis M (§3, Appendix A.6).
//

import Foundation

struct RotationPoint: Identifiable {
    let id: Int
    /// Galactocentric radius (kpc).
    let rKpc: Double
    /// Observed circular speed (km/s).
    let vKms: Double
}

enum Eilers2019 {
    /// Circular velocities (km/s) at 38 radii between 5.3 and 24.8 kpc, as used in the paper.
    static let velocities: [Double] = [
        226.83, 230.8, 231.2, 229.88, 229.61, 229.91, 228.86, 226.5, 226.2, 225.94,
        225.68, 224.73, 224.02, 223.86, 222.23, 220.77, 220.92, 217.47, 217.31, 217.6,
        217.07, 217.38, 216.14, 212.52, 216.41, 213.7, 207.89, 209.6, 206.45, 201.91,
        199.84, 198.14, 195.3, 213.67, 176.97, 193.11, 176.63, 198.42,
    ]

    /// Radii in metres.
    static let radiiMeters: [Double] = [
        1.62615209e20, 1.77117893e20, 1.92237713e20, 2.07666101e20, 2.22785921e20,
        2.41299987e20, 2.52716994e20, 2.70922492e20, 2.86042312e20, 3.01162132e20,
        3.16590520e20, 3.31710340e20, 3.47138728e20, 3.62567116e20, 3.77995504e20,
        3.93115324e20, 4.08235144e20, 4.23972100e20, 4.39400488e20, 4.54828876e20,
        4.69640128e20, 4.85685651e20, 5.01114039e20, 5.16542427e20, 5.32279383e20,
        5.47707771e20, 5.62827591e20, 5.78255979e20, 5.93067231e20, 6.08187051e20,
        6.25466846e20, 6.41203801e20, 6.55397918e20, 6.72677713e20, 6.83169017e20,
        7.01374514e20, 7.30071316e20, 7.65865176e20,
    ]

    static let points: [RotationPoint] = zip(radiiMeters, velocities).enumerated().map { i, pair in
        RotationPoint(id: i, rKpc: pair.0 / SI.kpc, vKms: pair.1)
    }
}

/// Approximate baryonic model: Hernquist bulge plus exponential stellar and gas discs, with
/// flattened components treated as spherical shells, rescaled so that
/// M_b(< 8.12 kpc) = 4.44 × 10¹⁰ M☉ (the value adopted in the paper).
struct BaryonModel {
    enum Kind { case hernquist, exponential }
    struct Component: Identifiable {
        let id: String
        let kind: Kind
        /// Mass in M☉.
        let mass: Double
        /// Scale length (kpc).
        let scale: Double

        func enclosed(_ rKpc: Double) -> Double {
            switch kind {
            case .hernquist:
                return mass * rKpc * rKpc / ((rKpc + scale) * (rKpc + scale))
            case .exponential:
                let x = rKpc / scale
                return mass * (1 - (1 + x) * exp(-x))
            }
        }
    }

    static let components: [Component] = [
        Component(id: "Bulge", kind: .hernquist, mass: 0.92e10, scale: 0.6),
        Component(id: "Thin disc", kind: .exponential, mass: 3.52e10, scale: 2.5),
        Component(id: "Thick disc", kind: .exponential, mass: 1.05e10, scale: 3.02),
        Component(id: "Gas disc", kind: .exponential, mass: 1.2e10, scale: 7.0),
    ]

    /// Overall normalisation s (s = 1 reproduces 4.44 × 10¹⁰ M☉ inside 8.12 kpc).
    var scale: Double = 1

    private static func raw(_ r: Double) -> Double { components.reduce(0) { $0 + $1.enclosed(r) } }
    private static let normalisation = SI.enclosedBaryonicMassSolar / raw(SI.solarGalactocentricRadiusKpc)

    /// Enclosed baryonic mass in kg.
    func enclosedMass(rKpc: Double) -> Double {
        scale * Self.normalisation * Self.raw(rKpc) * SI.solarMass
    }

    func componentMass(_ c: Component, rKpc: Double) -> Double {
        scale * Self.normalisation * c.enclosed(rKpc) * SI.solarMass
    }
}

enum GalacticDynamics {
    /// Flow velocity β c = √(2GM/R) (the "v_orbit" of Appendix A).
    static func flowVelocity(mass: Double, r: Double, G: Double) -> Double { (2 * G * mass / r).squareRoot() }

    /// Trigonometric orbital velocity √(GM(GM + 2R³))/R² (Appendix A.4).
    static func trigonometricOrbit(mass: Double, r: Double, G: Double) -> Double {
        (G * mass * (G * mass + 2 * r * r * r)).squareRoot() / (r * r)
    }

    static func newtonian(mass: Double, r: Double, G: Double) -> Double { (G * mass / r).squareRoot() }

    /// RAR interpolation g = g_N / (1 − e^{−√(g_N/g₀)}) (McGaugh et al. 2016).
    static func rar(gN: Double, g0: Double) -> Double {
        guard gN > 0, g0 > 0 else { return gN }
        return gN / (1 - exp(-(gN / g0).squareRoot()))
    }

    /// Hypothesis M circular speed (m/s).
    static func hypothesisM(mass: Double, r: Double, g0: Double, G: Double) -> Double {
        let gN = G * mass / (r * r)
        return (rar(gN: gN, g0: g0) * r).squareRoot()
    }

    /// χ² with a fractional error σ = f·v_obs.
    static func chiSquared(model: BaryonModel, g0: Double, G: Double, fractionalError f: Double, maxRadiusKpc: Double = .infinity) -> (chi2: Double, n: Int) {
        var chi = 0.0, n = 0
        for p in Eilers2019.points where p.rKpc <= maxRadiusKpc {
            let r = p.rKpc * SI.kpc
            let v = hypothesisM(mass: model.enclosedMass(rKpc: p.rKpc), r: r, g0: g0, G: G) / 1_000
            let sigma = f * p.vKms
            chi += pow((v - p.vKms) / sigma, 2)
            n += 1
        }
        return (chi, n)
    }

    static func chiSquaredFlow(model: BaryonModel, G: Double, fractionalError f: Double) -> Double {
        Eilers2019.points.reduce(0) { acc, p in
            let v = flowVelocity(mass: model.enclosedMass(rKpc: p.rKpc), r: p.rKpc * SI.kpc, G: G) / 1_000
            return acc + pow((v - p.vKms) / (f * p.vKms), 2)
        }
    }

    /// Best-fit g₀ (log-space golden-section search between 10⁻¹² and 10⁻⁸ m s⁻²).
    static func fitG0(model: BaryonModel, G: Double, fractionalError f: Double) -> (g0: Double, chi2: Double) {
        var a = -12.0, b = -8.0
        let phi = (5.0.squareRoot() - 1) / 2
        func cost(_ x: Double) -> Double { chiSquared(model: model, g0: pow(10, x), G: G, fractionalError: f).chi2 }
        var c = b - phi * (b - a), d = a + phi * (b - a)
        var fc = cost(c), fd = cost(d)
        for _ in 0..<60 {
            if fc < fd { b = d; d = c; fd = fc; c = b - phi * (b - a); fc = cost(c) }
            else { a = c; c = d; fc = fd; d = a + phi * (b - a); fd = cost(d) }
        }
        let x = (a + b) / 2
        return (pow(10, x), cost(x))
    }

    /// Enclosed mass needed to match the data with the flow velocity, v²R/2G (kg).
    static func requiredMassForFlow(v: Double, r: Double, G: Double) -> Double { v * v * r / (2 * G) }
}
