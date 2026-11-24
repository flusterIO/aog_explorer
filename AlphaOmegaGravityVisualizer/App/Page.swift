//
//  Page.swift
//  AlphaOmegaGravityVisualizer
//

import Foundation
import SwiftUI

enum PaperSection: String, CaseIterable, Identifiable {
    case overview, kinematics, geometry, dynamics, flow, galactic, appendix, explore

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: "Overview"
        case .kinematics: "Kinematics of y"
        case .geometry: "Embedding & Metric"
        case .dynamics: "Lapse & Dynamics"
        case .flow: "Flow & Cosmology"
        case .galactic: "Galactic Hypothesis"
        case .appendix: "Numerical Observations"
        case .explore: "Exploration"
        }
    }

    var color: Color {
        switch self {
        case .overview: .primary
        case .kinematics: Color(red: 0.55, green: 0.75, blue: 1.0)
        case .geometry: Theme.geometry
        case .dynamics: Theme.time
        case .flow: Theme.flow
        case .galactic: Theme.hypothesis
        case .appendix: Theme.observation
        case .explore: Color(red: 0.98, green: 0.45, blue: 0.70)
        }
    }
}

enum Page: String, CaseIterable, Identifiable, Hashable {
    case home
    case lighthouse, slope, interval
    case flamm, distributions, fifthMetric, fourPotential
    case lapse, buchdahl, orbits, frameDragging
    case river, cosmology
    case hypothesisM
    case velocities, fineStructure
    case starLab, rapidity, reference

    var id: String { rawValue }

    var section: PaperSection {
        switch self {
        case .home: .overview
        case .lighthouse, .slope, .interval: .kinematics
        case .flamm, .distributions, .fifthMetric, .fourPotential: .geometry
        case .lapse, .buchdahl, .orbits, .frameDragging: .dynamics
        case .river, .cosmology: .flow
        case .hypothesisM: .galactic
        case .velocities, .fineStructure: .appendix
        case .starLab, .rapidity, .reference: .explore
        }
    }

    var title: String {
        switch self {
        case .home: "Overview"
        case .lighthouse: "Lighthouse & Clock-Tower"
        case .slope: "γ as a Slope"
        case .interval: "Minkowski Interval"
        case .flamm: "Flamm Embedding"
        case .distributions: "Mass Distributions"
        case .fifthMetric: "The Component G₄₄"
        case .fourPotential: "The Four-Potential"
        case .lapse: "Lapse from the Embedding"
        case .buchdahl: "Interior & Buchdahl Bound"
        case .orbits: "Orbits & Precession"
        case .frameDragging: "Rotation & Frame Dragging"
        case .river: "Painlevé–Gullstrand Flow"
        case .cosmology: "Hubble Flow & Sciama"
        case .hypothesisM: "Hypothesis M"
        case .velocities: "Characteristic Velocities"
        case .fineStructure: "Fine-Structure Alignments"
        case .starLab: "Star Lab"
        case .rapidity: "Rapidity Composition"
        case .reference: "Dictionary & Status"
        }
    }

    var subtitle: String {
        switch self {
        case .home: "The Lorentz factor as the slope of an additional spatial coordinate."
        case .lighthouse: "A classical notion of simultaneity, with the extra separation carried by y."
        case .slope: "γ = √(1 + (∂ₓy)²): the Lorentz factor as the gradient of a fourth spatial coordinate."
        case .interval: "The instantaneous transformations preserve the Minkowski interval."
        case .flamm: "The static Schwarzschild slice as a hypersurface y(R) of flat ℝ⁴."
        case .distributions: "β² = 2Gm(R)/(c²R) for a point mass, a uniform ball, and the critical-density universe."
        case .fifthMetric: "Why G₄₄ = 1: the Schwarzschild radial metric, Cassini, and the scalar charge."
        case .fourPotential: "𝒜_μ = ∂_μ y: a pure-gauge Kaluza–Klein potential and its non-gradient extension."
        case .lapse: "In a static vacuum region, N = 1/γ follows from the Gauss equation of the embedding."
        case .buchdahl: "With pressure, the lapse is the TOV potential; for uniform density, R* > 9r_s/8."
        case .orbits: "Effective potential, ISCO and perihelion advance from A = γ² and N = 1/γ."
        case .frameDragging: "The non-gradient potential of a slowly rotating source is the gravitomagnetic field."
        case .river: "Space as a flat background flowing at βc — inward for a mass, outward for Hubble."
        case .cosmology: "Binding and expansion as one relation; the Sciama identity at the Hubble radius."
        case .hypothesisM: "Horizon-limited Machian inertia with g₀ = κ′cH₀, compared with the Milky Way."
        case .velocities: "v_cosmo, v_kinematic and the √2 between them; dependence on L_τ."
        case .fineStructure: "ω = δ^{1/3} ≈ α(2 − α) for Earth, and related alignments."
        case .starLab: "Explore static stars with non-uniform density: slice, lapse, pressure and compactness limit."
        case .rapidity: "Velocity composition as addition of rapidities: slopes sinh η compose hyperbolically."
        case .reference: "The paper's dictionary of standard counterparts and the meaning of each status badge."
        }
    }

    var systemImage: String {
        switch self {
        case .home: "sparkles.rectangle.stack"
        case .lighthouse: "light.beacon.max"
        case .slope: "triangle"
        case .interval: "angle"
        case .flamm: "circle.hexagongrid"
        case .distributions: "chart.xyaxis.line"
        case .fifthMetric: "square.grid.3x3.topleft.filled"
        case .fourPotential: "arrow.up.right.circle"
        case .lapse: "clock.arrow.circlepath"
        case .buchdahl: "sun.max.trianglebadge.exclamationmark"
        case .orbits: "circle.dotted.circle"
        case .frameDragging: "tornado"
        case .river: "water.waves"
        case .cosmology: "globe.americas"
        case .hypothesisM: "hurricane"
        case .velocities: "speedometer"
        case .fineStructure: "atom"
        case .starLab: "flask"
        case .rapidity: "arrow.triangle.merge"
        case .reference: "book.closed"
        }
    }

    /// Location in the manuscript.
    var paperReference: String {
        switch self {
        case .home: "Abstract"
        case .lighthouse: "§1.1"
        case .slope: "§2.2"
        case .interval: "§2.2.1"
        case .flamm: "§2.3, App. B"
        case .distributions: "§2.4.4"
        case .fifthMetric: "§2.3.3–2.3.6"
        case .fourPotential: "§2.4"
        case .lapse: "§2.5"
        case .buchdahl: "§2.5.1"
        case .orbits: "§2.7, App. B"
        case .frameDragging: "§2.6"
        case .river: "§2.9"
        case .cosmology: "§2.9.2, §3.2"
        case .hypothesisM: "§3, App. A.6"
        case .velocities: "App. A.2–A.5"
        case .fineStructure: "App. A.1, A.7"
        case .starLab: "Beyond §2.5.1"
        case .rapidity: "Beyond §1"
        case .reference: "Tables 1 & 3"
        }
    }

    static func pages(in section: PaperSection) -> [Page] {
        allCases.filter { $0.section == section }
    }
}
