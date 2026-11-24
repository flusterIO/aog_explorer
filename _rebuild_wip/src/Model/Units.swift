//
//  Units.swift
//  AlphaOmegaGravityVisualizer
//
//  SI constants and reference bodies. Values match those used in the manuscript
//  "The Lorentz Factor as the Slope of an Additional Spatial Coordinate".
//

import Foundation

enum SI {
    static let c = 299_792_458.0
    static let G = 6.6743e-11
    static let fineStructure = 0.0072973525643
    static let elementaryCharge = 1.602176634e-19
    static let planck = 6.62607015e-34
    static let mu0 = 1.25663706127e-6
    static let epsilon0 = 8.8541878188e-12

    static let parsec = 3.085677581491367e16
    static let kpc = 3.085677581491367e19
    static let Mpc = 3.085677581491367e22
    static let julianYear = 365.25 * 86_400.0
    static let solarMass = 1.988409870698051e30

    static let radToMas = 180.0 / Double.pi * 3_600_000.0
    static let radToArcsec = 180.0 / Double.pi * 3_600.0

    /// Planck 2018 CMB dipole speed, 369.82 ± 0.11 km/s.
    static let cmbDipole = 369_820.0
    static let cmbDipoleSigma = 110.0

    /// Cassini radio-link bound, γ_PPN − 1 = (2.1 ± 2.3) × 10⁻⁵ (Bertotti et al. 2003).
    static let cassiniMean = 2.1e-5
    static let cassiniSigma = 2.3e-5

    /// Gravity Probe B frame-dragging measurement, 37.2 ± 7.2 mas/yr.
    static let gpbFrameDragging = 37.2
    static let gpbSigma = 7.2

    /// Earth's spin angular momentum as used in the manuscript.
    static let earthAngularMomentum = 5.86e33
    /// Gravity Probe B orbital radius.
    static let gpbOrbitRadius = 7_027_000.0

    /// Galactocentric radius of the Sun and the enclosed baryonic mass adopted in the paper.
    static let solarGalactocentricRadiusKpc = 8.12
    static let enclosedBaryonicMassSolar = 4.44e10
}

struct Body: Identifiable, Hashable {
    let id: String
    let name: String
    let latex: String
    let mass: Double
    let radius: Double

    var density: Double { mass / (4.0 / 3.0 * Double.pi * radius * radius * radius) }

    static let earth = Body(id: "earth", name: "Earth", latex: "\\oplus", mass: 5.972167867791379e24, radius: 6_378_100)
    static let moon = Body(id: "moon", name: "Moon", latex: "\\mathrm{Moon}", mass: 7.342e22, radius: 1_737_400)
    static let mars = Body(id: "mars", name: "Mars", latex: "\\mathrm{Mars}", mass: 6.4171e23, radius: 3_389_500)
    static let jupiter = Body(id: "jupiter", name: "Jupiter", latex: "\\mathrm{Jup}", mass: 1.89813e27, radius: 69_911_000)
    static let saturn = Body(id: "saturn", name: "Saturn", latex: "\\mathrm{Sat}", mass: 5.6834e26, radius: 58_232_000)
    static let sun = Body(id: "sun", name: "Sun", latex: "\\odot", mass: 1.988409870698051e30, radius: 695_700_000)

    static let all: [Body] = [.earth, .moon, .mars, .jupiter, .saturn, .sun]
}

/// Lightweight plottable sample.
struct XY: Identifiable {
    let id: Int
    let x: Double
    let y: Double
    var series: String = ""
}

/// Uniform and log-spaced grids.
enum Grid {
    static func linear(_ a: Double, _ b: Double, _ n: Int) -> [Double] {
        guard n > 1 else { return [a] }
        return (0..<n).map { a + (b - a) * Double($0) / Double(n - 1) }
    }

    static func log(_ a: Double, _ b: Double, _ n: Int) -> [Double] {
        guard n > 1, a > 0, b > 0 else { return [a] }
        let la = log10(a), lb = log10(b)
        return (0..<n).map { pow(10, la + (lb - la) * Double($0) / Double(n - 1)) }
    }
}
