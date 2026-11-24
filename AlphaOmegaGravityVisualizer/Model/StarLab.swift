//
//  StarLab.swift
//  AlphaOmegaGravityVisualizer
//
//  Exploration: static stars with non-uniform density ρ = ρ_c(1 − x²)ⁿ, x = R/R*.
//  The slice follows from β² = 2Gm(R)/(c²R) (§2.4.4); the lapse and pressure follow from
//  the interior lapse equation (§2.5.1) with hydrostatic equilibrium, integrated inward
//  from the surface. n = 0 is the interior Schwarzschild solution, n = 1 is Tolman VII.
//

import Foundation

struct StarProfile: Identifiable {
    let id: Int
    /// x = R/R*
    let x: Double
    /// ρ/ρ_c
    let density: Double
    /// β²
    let beta2: Double
    /// p/(ρ_c c²)
    let pressure: Double
    /// Lapse N
    let lapse: Double
    /// Embedding height (units of R*)
    var y: Double
    var gamma: Double { 1 / max(1e-12, 1 - beta2).squareRoot() }
    var slopeLapse: Double { 1 / gamma }
}

struct StarSolution {
    let compactness: Double
    let exponent: Double
    var samples: [StarProfile]
    var diverged: Bool
    var centralPressure: Double { samples.first?.pressure ?? .nan }
    var centralLapse: Double { samples.first?.lapse ?? .nan }
}

enum StarLab {
    static func density(_ x: Double, n: Double) -> Double { pow(max(0, 1 - x * x), n) }

    /// Solves the slice, lapse and pressure. `outerRadius` (in R*) extends the exterior.
    static func solve(compactness C: Double, exponent n: Double, steps: Int = 2_400, outerRadius: Double = 3) -> StarSolution {
        // Cumulative ∫ f x² dx on a fine grid.
        let m = 2_000
        var cumulative = [Double](repeating: 0, count: m + 1)
        for i in 1...m {
            let a = Double(i - 1) / Double(m), b = Double(i) / Double(m)
            cumulative[i] = cumulative[i - 1] + 0.5 * (density(a, n: n) * a * a + density(b, n: n) * b * b) * (b - a)
        }
        let k = C / cumulative[m]
        func mu(_ x: Double) -> Double {
            let xf = min(max(x, 0), 1) * Double(m)
            let j = min(m - 1, Int(xf))
            let t = xf - Double(j)
            return k * (cumulative[j] * (1 - t) + cumulative[j + 1] * t)
        }
        func dLnN(_ x: Double, _ p: Double) -> Double {
            let mm = mu(x)
            let den = x * x * (1 - mm / x)
            return (mm / 2 + k * x * x * x * p / 2) / den
        }
        func dP(_ x: Double, _ p: Double) -> Double { -(density(x, n: n) + p) * dLnN(x, p) }

        // Inward integration from the surface.
        var x = 1.0
        var p = 0.0
        var lnN = 0.5 * log(1 - C)
        let xEnd = 1e-4
        let h = -(1 - xEnd) / Double(steps)
        var interior: [(x: Double, p: Double, lnN: Double)] = [(x, p, lnN)]
        var diverged = false
        for _ in 0..<steps {
            let k1 = dP(x, p), l1 = dLnN(x, p)
            let k2 = dP(x + h / 2, p + h / 2 * k1), l2 = dLnN(x + h / 2, p + h / 2 * k1)
            let k3 = dP(x + h / 2, p + h / 2 * k2), l3 = dLnN(x + h / 2, p + h / 2 * k2)
            let k4 = dP(x + h, p + h * k3), l4 = dLnN(x + h, p + h * k3)
            p += h / 6 * (k1 + 2 * k2 + 2 * k3 + k4)
            lnN += h / 6 * (l1 + 2 * l2 + 2 * l3 + l4)
            x += h
            if !p.isFinite || p > 1e6 || !lnN.isFinite { diverged = true; break }
            interior.append((x, p, lnN))
        }
        interior.reverse()

        // Assemble samples (subsampled) and integrate the embedding outward, dy/dx = βγ.
        var samples: [StarProfile] = []
        let stride = max(1, interior.count / 240)
        var id = 0
        for i in Swift.stride(from: 0, to: interior.count, by: stride) {
            let s = interior[i]
            let b2 = s.x > 0 ? mu(s.x) / s.x : 0
            samples.append(StarProfile(id: id, x: s.x, density: density(s.x, n: n), beta2: b2, pressure: s.p, lapse: exp(s.lnN), y: 0))
            id += 1
        }
        if !diverged {
            for xo in Sampling.linear(1, outerRadius, 120).dropFirst() {
                samples.append(StarProfile(id: id, x: xo, density: 0, beta2: C / xo, pressure: 0, lapse: (1 - C / xo).squareRoot(), y: 0))
                id += 1
            }
        }
        // Embedding by trapezoid on βγ.
        var y = 0.0
        for i in samples.indices {
            if i > 0 {
                let a = samples[i - 1], b = samples[i]
                let sa = a.beta2.squareRoot() * a.gamma, sb = b.beta2.squareRoot() * b.gamma
                y += 0.5 * (sa + sb) * (b.x - a.x)
            }
            samples[i].y = y
        }
        return StarSolution(compactness: C, exponent: n, samples: samples, diverged: diverged)
    }

    /// Largest compactness r_s/R* with finite central pressure (bisection).
    static func criticalCompactness(exponent n: Double) -> Double {
        var lo = 0.01, hi = 0.99
        for _ in 0..<26 {
            let mid = (lo + hi) / 2
            if solve(compactness: mid, exponent: n, steps: 1_200, outerRadius: 1.01).diverged { hi = mid } else { lo = mid }
        }
        return lo
    }
}
