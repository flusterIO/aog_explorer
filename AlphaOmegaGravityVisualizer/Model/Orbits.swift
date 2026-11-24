//
//  Orbits.swift
//  AlphaOmegaGravityVisualizer
//
//  Geodesic motion in the static exterior metric with A = γ², N = 1/γ (§2.7, Appendix B).
//  Units: G = M = c = 1, so lengths are in GM/c² and r_s = 2.
//

import Foundation
import CoreGraphics

enum Schwarzschild {
    /// V_eff / c² = N²(1 + L²/R²)
    static func effectivePotential(r: Double, l: Double) -> Double {
        (1 - 2 / r) * (1 + l * l / (r * r))
    }

    /// L² = GMR²/(R − 3GM/c²) for a circular orbit.
    static func circularL2(r: Double) -> Double { r * r / (r - 3) }

    /// v_local²/c² = GM/(c²(R − r_s))
    static func localCircularSpeed2(r: Double) -> Double { 1 / (r - 2) }

    /// Extrema of V_eff for given L: r = (L² ± √(L⁴ − 12L²))/2.
    static func circularRadii(l: Double) -> (unstable: Double?, stable: Double?) {
        let l2 = l * l
        let disc = l2 * l2 - 12 * l2
        guard disc >= 0 else { return (nil, nil) }
        let root = disc.squareRoot()
        return ((l2 - root) / 2, (l2 + root) / 2)
    }

    /// V″_eff at a circular orbit: 2r_s(R − 3r_s)/(R³(2R − 3r_s)) (c = 1, r_s = 2).
    static func curvatureAtCircular(r: Double) -> Double {
        let rs = 2.0
        return 2 * rs * (r - 3 * rs) / (r * r * r * (2 * r - 3 * rs))
    }

    /// Leading-order perihelion advance per orbit, 6πGM/(pc²) (radians).
    static func advanceFormula(p: Double) -> Double { 6 * Double.pi / p }

    /// Δφ = 2π[1/(1 − 3GM/(pc²)) − 1]
    static func advanceFirstOrderExact(p: Double) -> Double { 2 * Double.pi * (1 / (1 - 3 / p) - 1) }

    struct Trace {
        var points: [CGPoint] = []
        var periapsisAngles: [Double] = []
        var plunged = false
        var escaped = false
        /// Mean measured advance per orbit (rad).
        var measuredAdvance: Double? {
            guard periapsisAngles.count >= 2 else { return nil }
            var sum = 0.0
            for i in 1..<periapsisAngles.count { sum += periapsisAngles[i] - periapsisAngles[i - 1] - 2 * Double.pi }
            return sum / Double(periapsisAngles.count - 1)
        }
    }

    /// Integrates u″ + u = 1/p + 3u² from periapsis u₀ = (1 + e)/p, u′ = 0.
    static func integrateOrbit(p: Double, e: Double, revolutions: Double, stepsPerRev: Int = 720) -> Trace {
        var trace = Trace()
        var u = (1 + e) / p
        var w = 0.0
        var phi = 0.0
        let h = 2 * Double.pi / Double(stepsPerRev)
        let total = Int(revolutions * Double(stepsPerRev))
        func acc(_ u: Double) -> Double { -u + 1 / p + 3 * u * u }
        trace.points.reserveCapacity(total + 1)
        trace.points.append(CGPoint(x: cos(phi) / u, y: sin(phi) / u))
        // The start is a turning point; it is a periapsis only if u is at a maximum there.
        if acc(u) < 0 { trace.periapsisAngles.append(0) }
        for _ in 0..<total {
            let k1u = w, k1w = acc(u)
            let k2u = w + h / 2 * k1w, k2w = acc(u + h / 2 * k1u)
            let k3u = w + h / 2 * k2w, k3w = acc(u + h / 2 * k2u)
            let k4u = w + h * k3w, k4w = acc(u + h * k3u)
            let wOld = w
            u += h / 6 * (k1u + 2 * k2u + 2 * k3u + k4u)
            w += h / 6 * (k1w + 2 * k2w + 2 * k3w + k4w)
            phi += h
            if u >= 0.5 { trace.plunged = true; break }
            if u <= 1e-6 { trace.escaped = true; break }
            // Periapsis: u′ goes from + to − (u maximum).
            if wOld > 0 && w <= 0 {
                let frac = wOld / (wOld - w)
                trace.periapsisAngles.append(phi - h + frac * h)
            }
            trace.points.append(CGPoint(x: cos(phi) / u, y: sin(phi) / u))
        }
        return trace
    }

    /// Mercury: semilatus rectum in units of GM☉/c².
    static func mercuryP(G: Double, c: Double) -> Double {
        let a = 5.7909e10, e = 0.2056
        return a * (1 - e * e) * c * c / (G * SI.solarMass)
    }

    /// Mercury advance in arcsec per century from 6πGM/(a(1 − e²)c²).
    static func mercuryArcsecPerCentury(G: Double, c: Double) -> Double {
        let period = 87.969 * 86_400.0
        let perOrbit = advanceFormula(p: mercuryP(G: G, c: c))
        return perOrbit * (100 * SI.julianYear / period) * SI.radToArcsec
    }
}

// MARK: - Frame dragging (§2.6)

enum FrameDragging {
    /// ω(R) = 2GJ/(c²R³)
    static func zamoAngularVelocity(J: Double, R: Double, G: Double, c: Double) -> Double {
        2 * G * J / (c * c * R * R * R)
    }

    /// Ω_LT = G/(c²R³)[3(J·r̂)r̂ − J] in the meridional (x, z) plane with J ∥ ẑ.
    static func precession(x: Double, z: Double, J: Double, G: Double, c: Double) -> (Double, Double) {
        let r2 = x * x + z * z
        let r = r2.squareRoot()
        guard r > 0 else { return (0, 0) }
        let k = G * J / (c * c * r * r2)
        let cosT = z / r
        return (k * 3 * cosT * (x / r), k * (3 * cosT * (z / r) - 1))
    }

    /// Average over a polar orbit of radius a: GJ/(2c²a³).
    static func polarOrbitAverage(J: Double, a: Double, G: Double, c: Double) -> Double {
        G * J / (2 * c * c * a * a * a)
    }

    static func toMasPerYear(_ radPerSecond: Double) -> Double {
        radPerSecond * SI.julianYear * SI.radToMas
    }
}

// MARK: - Cosmology (§2.8, §3)

enum Cosmology {
    /// Flat ΛCDM H(z).
    static func hubble(z: Double, H0: Double, omegaM: Double) -> Double {
        H0 * (omegaM * pow(1 + z, 3) + (1 - omegaM)).squareRoot()
    }

    /// β² in Schwarzschild–de Sitter PG form: β_N² + β_H².
    static func combinedBeta2(R: Double, mass: Double, H: Double, G: Double, c: Double) -> (local: Double, cosmic: Double) {
        (2 * G * mass / (c * c * R), H * H * R * R / (c * c))
    }

    /// Radius where β_N = β_H: R = (2GM/H²)^{1/3}.
    static func balanceRadius(mass: Double, H: Double, G: Double) -> Double {
        pow(2 * G * mass / (H * H), 1.0 / 3.0)
    }
}
