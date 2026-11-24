//
//  NumericalObservations.swift
//  AlphaOmegaGravityVisualizer
//
//  Appendix A: numerical alignments that the paper keeps as rough approximations
//  "that a dynamical theory would have to explain or discard". None are predictions.
//

import Foundation

struct BodyNumerics {
    let body: CelestialBody
    let G: Double
    let c: Double
    /// τ̂ in seconds (L_τ = c τ̂).
    let tauHat: Double

    /// δ(M, R) = 2GM/R³ (radial tidal eigenvalue).
    var delta: Double { 2 * G * body.mass / pow(body.radius, 3) }
    /// ω = δ^{1/3}
    var omega: Double { pow(delta * tauHat * tauHat, 1.0 / 3.0) }
    /// φ = 1 + GM/R³ τ̂²
    var varphi: Double { 1 + G * body.mass / pow(body.radius, 3) * tauHat * tauHat }
    /// v_cosmo = c √(1 − 1/φ²)
    var vCosmo: Double { c * (1 - 1 / (varphi * varphi)).squareRoot() }
    /// v_kinematic = c √(1 − 1/(1 + ½GM/R³ τ̂²)²)
    var vKinematic: Double {
        let g = 1 + 0.5 * G * body.mass / pow(body.radius, 3) * tauHat * tauHat
        return c * (1 - 1 / (g * g)).squareRoot()
    }
    /// Length-only form v/c = √(GM/c²) L_τ / R^{3/2}, the leading-order kinematic-type velocity.
    var lengthOnlyRatio: Double {
        (G * body.mass / (c * c)).squareRoot() * (c * tauHat) / pow(body.radius, 1.5)
    }
    var surfaceGravity: Double { G * body.mass / (body.radius * body.radius) }
    /// Flow (escape) velocity √(2GM/R).
    var flowVelocity: Double { (2 * G * body.mass / body.radius).squareRoot() }
}

enum FineStructureAlignments {
    static var alpha: Double { SI.fineStructure }
    static var alphaTwoMinusAlpha: Double { alpha * (2 - alpha) }

    /// The four-term electromagnetic expression of Appendix A.1 (radius-independent part).
    static func electromagneticSeries(e: Double = SI.elementaryCharge, h: Double = SI.planck, mu0: Double = SI.mu0, eps0: Double = SI.epsilon0) -> Double {
        let z = (mu0 / eps0).squareRoot()
        let t1 = pow(e, 6) * pow(z, 3) / (4 * pow(h, 3))
        let t2 = 3 * mu0 * pow(e, 10) * pow(z, 3) / (64 * eps0 * pow(h, 5))
        let t3 = 3 * mu0 * mu0 * pow(e, 8) / (16 * eps0 * eps0 * pow(h, 4))
        let t4 = pow(mu0, 3) * pow(e, 12) / (256 * pow(eps0, 3) * pow(h, 6))
        return t1 + t2 - t3 - t4
    }

    /// v(γ_em) with γ_em = 1 + series.
    static func vElectromagnetic(c: Double) -> Double {
        let g = 1 + electromagneticSeries()
        return c * (1 - 1 / (g * g)).squareRoot()
    }

    struct GravityFit: Identifiable {
        let id: String
        let body: CelestialBody
        let latex: String
        let predicted: Double
        let observed: Double
        var relativeError: Double { predicted / observed - 1 }
    }

    /// g⊕ = R⊕ α³(2−α)³/2, g☉ = R☉ α³, g_Sat = ½ R_Sat α³ (τ = 1).
    static func gravityFits(G: Double) -> [GravityFit] {
        let a = alpha
        func g(_ b: CelestialBody) -> Double { G * b.mass / (b.radius * b.radius) }
        return [
            GravityFit(id: "earth", body: .earth, latex: "g_\\oplus = R_\\oplus\\,\\frac{\\alpha^3(2-\\alpha)^3}{2}", predicted: CelestialBody.earth.radius * pow(a * (2 - a), 3) / 2, observed: g(.earth)),
            GravityFit(id: "sun", body: .sun, latex: "g_\\odot = R_\\odot\\,\\alpha^3", predicted: CelestialBody.sun.radius * pow(a, 3), observed: g(.sun)),
            GravityFit(id: "saturn", body: .saturn, latex: "g_{\\mathrm{Sat}} = \\frac{1}{2}R_{\\mathrm{Sat}}\\,\\alpha^3", predicted: 0.5 * CelestialBody.saturn.radius * pow(a, 3), observed: g(.saturn)),
        ]
    }

    /// ω for a body of the given mean density: ω = (2·(4π/3)Gρ)^{1/3} (τ̂ = 1 s).
    static func omega(density: Double, G: Double) -> Double {
        pow(2 * 4.0 / 3.0 * Double.pi * G * density, 1.0 / 3.0)
    }
}
