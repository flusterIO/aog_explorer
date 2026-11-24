//
//  PhysicsModelTests.swift
//  AlphaOmegaGravityVisualizerTests
//
//  Checks the app's physics model against values quoted in the manuscript.
//

import Testing
import Foundation
@testable import AlphaOmegaGravityVisualizer

@MainActor
struct PhysicsModelTests {

    @Test func slopeIdentity() {
        for beta in stride(from: 0.0, through: 0.95, by: 0.05) {
            let g = Lorentz.gamma(beta: beta)
            #expect(abs(Lorentz.gammaFromSlope(Lorentz.slope(beta: beta)) - g) < 1e-12)
            // v(γ) ∂ₓy = ∂_τ y
            let lhs = Lorentz.beta(gamma: g) * SI.c * Lorentz.slope(beta: beta)
            #expect(abs(lhs - Lorentz.dyDtau(beta: beta, c: SI.c)) <= 1e-6 * max(1, lhs))
        }
    }

    @Test func numericalLapseMatchesClosedForm() {
        let radii = Sampling.log(1.05, 50, 30)
        let n = Lapse.integrateVacuum(at: radii)
        for (r, value) in zip(radii, n) {
            #expect(abs(value - Embedding.lapseExterior(r)) < 1e-4)
        }
    }

    @Test func gaussCurvatureOfUniformStar() {
        let star = Embedding.uniformStarSlice(starRadius: 3, rMax: 9, count: 400)
        let curvature = Embedding.scalarCurvature(star)
        let inside = curvature.filter { $0.x > 0.5 && $0.x < 2.5 }
        // ³R = 6/L² inside, L² = R*³
        for p in inside { #expect(abs(p.y - 6.0 / 27.0) < 1e-3) }
        let outside = curvature.filter { $0.x > 3.5 }
        for p in outside { #expect(abs(p.y) < 1e-3) }
    }

    @Test func buchdahlLimits() {
        #expect(abs(StarLab.criticalCompactness(exponent: 0) - 8.0 / 9.0) < 2e-3)
        #expect(abs(StarLab.criticalCompactness(exponent: 1) - 0.7724) < 3e-3)
        // Uniform-density central pressure, analytic vs integrated.
        let analytic = UniformStar(radius: 2).centralPressure
        let numeric = StarLab.solve(compactness: 0.5, exponent: 0).centralPressure
        #expect(abs(analytic - numeric) / analytic < 1e-3)
    }

    @Test func appendixVelocities() {
        let earth = BodyNumerics(body: .earth, G: SI.G, c: SI.c, tauHat: 1)
        #expect(abs(earth.vCosmo - 525_493.17) < 1)
        #expect(abs(earth.vKinematic - 371_580) < 1)
        #expect(abs(earth.omega / (SI.fineStructure * (2 - SI.fineStructure)) - 1 + 0.000253) < 2e-5)
        #expect(abs(FineStructureAlignments.vElectromagnetic(c: SI.c) - 371_721) < 1)
    }

    @Test func galacticFlowVelocityAtSun() {
        let model = BaryonModel(scale: 1)
        let r = SI.solarGalactocentricRadiusKpc
        let v = GalacticDynamics.flowVelocity(mass: model.enclosedMass(rKpc: r), r: r * SI.kpc, G: SI.G)
        #expect(abs(v - 216_874) < 5)
    }

    @Test func frameDraggingAndPrecession() {
        let lt = FrameDragging.toMasPerYear(FrameDragging.polarOrbitAverage(J: SI.earthAngularMomentum, a: SI.gpbOrbitRadius, G: SI.G, c: SI.c))
        #expect(abs(lt - 40.8) < 0.2)
        #expect(abs(Schwarzschild.mercuryArcsecPerCentury(G: SI.G, c: SI.c) - 42.98) < 0.05)
    }

    @Test func orbitIntegratorPrecession() throws {
        // Agreement with 6πGM/(pc²) improves as 1/p (higher-order terms); at p = 2000 it is ~0.4%.
        for e in [0.01, 0.3] {
            let trace = Schwarzschild.integrateOrbit(p: 2_000, e: e, revolutions: 4, stepsPerRev: 2_000)
            let measured = try #require(trace.measuredAdvance)
            #expect(abs(measured / Schwarzschild.advanceFormula(p: 2_000) - 1) < 0.01)
        }
    }

    @Test func sciamaIdentity() {
        let params = ParameterStore()
        let rH = params.hubbleRadius
        let mH = 4.0 / 3.0 * Double.pi * params.criticalDensity * pow(rH, 3)
        #expect(abs(params.G * mH / (params.c * params.c * rH) - 0.5) < 1e-12)
    }
}
