//
//  landing_page.swift
//  AlphaOmegaGravityVisualizer
//
//  Created by Andrew on 6/24/26.
//

import Foundation
import SwiftUI
import AlphaOmegaGravity


struct HomePage: View {
    @ObservedObject private var constants: Constants = Constants()
    @AppStorage(AppStorageKey.alpha_method.rawValue) private var alphaMethod: AlphaMethod = .independentProperty
    let aog = AOG()
    var currentEarth: MassiveBody {
        return MassiveBody(shape: Sphere(radius: constants.earthRadius()), vec: Vec3.zero(), mass: constants.earthMass())
    }
    var G: Double {
        constants.G()
    }
    var c: Double {
        constants.c()
    }
    var earthRadius: Double {
        constants.earthRadius()
    }
    var alpha: Double {
        constants.alpha(alphaMethod: alphaMethod)
    }
    var currentSun: MassiveBody {
        return MassiveBody(shape: Sphere(radius: constants.solarRadius()), vec: Vec3.zero(), mass: constants.solarMass())
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
               MarkdownView(markdown: """
                   # α ω Gravity
                   
                   Presented here is the _only_ alternative solution to the set of relativistic equations provided by Michelson and Morely that **does not** produce relativistic simultaneity while still allowing for Einstein's experimentally proven factor of γ.
                   
                   ### Included Derivations
                   
                   - Our Cosmological Velocity
                   - Our Kinematic Velocity, 3 times
                   - α, multiple times in seperately defined functions.
                   - G as a function of mass density and α
                   - A displacement current equivalent that approximates Φ.
                   
                   > The following table includes the % error, as well as the name of the function as it appears in the `alpha_omega_gravity` python package and associated notebook. All calculations were done with the latest CODATA/IAU values or data from semi-recent, well cited sources.
                   
                   | Derivation                                                | Function                         | % Error             |
                   |:----------------------------------------------------------|:---------------------------------|:--------------------|
                   | cosmological velocity from local gravitational parameters | `vbarCosmological`               | Difficult to assess |
                   | kinematic velocity from local gravitational parameters    | `vbarKinematic`                  | 0.442258391884371%   |
                   | Earth's rotational velocity via α                   | `rotationVelocityFromDivergence` | 0.00677756400547747% |
                   | Solar-Galactic Radius from visible mass                   | `galacticRadiusPolynomial`       | 0.0%                 |
                   | α (solar)                                          | `alphaSolar`                     | 0.00342749503676447% |
                   | α (Earth)                                          | `omega`, `alphaFactor`           | 0.0253043303850287%  |
                   | α (orbital velocity)                               | `solarMetricVelocity`, `vOrbit`  | 0.0544665494810030%  |
                   | α (from derived velocity)                          | `vbarAlphaEquivalence`           | 0.0761820393770567%  |
                   | J ≈ Φ                                          | `currentEquivalent`              | 0.213633171310522%   |
                   | h from α                                        | `omega`, `alpha`                 | 0.0253887188634106%  |
                   | h / (2 - α) from ω                          | `omega`, `alpha`                 | 0.00342749503676447% |
                   | Φ mass density approximation                         | `massDensityEquivalence`         | 0.863214423082925%   |
                   | G as a function of α and ρ                  | --                               | 0.07618221222642045% |
                   
                   
                   ### The following table will respond to state change
                   
                   
                   | Derivation                                                | % Error             |
                   |:----------------------------------------------------------|:--------------------|
                   | kinematic velocity from local gravitational parameters    | \(Statistics.percentDiff(a:currentEarth.vbarKinematic(G: G, c: c, xdot: nil), b: CMB_VELOCITY_RANGE[2]))%   |
                   | Earth's rotational velocity via α                   | \(Statistics.percentDiff(a: currentEarth.derivedRotationalVelocity(radius: earthRadius, alpha: alpha, G: G, c: c), b: (2 * Double.pi * EARTH_RADIUS_POLAR) / Double(TIME_DAY)))% |
                   | Solar-Galactic Radius from visible mass                   | 0.0%                 |
                   | α (solar)                                          | \(Statistics.percentDiff(a: currentSun.alphaSolar(G: G), b: ALPHA))% |
                   | α (Earth)                                          | \(Statistics.percentDiff(a: currentEarth.alphaApproximationAtR(G: G, R: earthRadius).1, b: ALPHA))%  |
                   | α (orbital velocity)                               | \(Statistics.percentDiff(a: currentEarth.electricFieldDivergenceEquivalentAtR(radius: earthRadius, G: G, aog: aog, c: c), b: (2 * Double.pi * EARTH_RADIUS_POLAR) / Double(TIME_DAY)))%  |
                   | α (from derived velocity)                          | \(Statistics.percentDiff(a: pow(currentEarth.vbarCosmological(G: G, c: c), 2) / pow(c, 2), b: pow((alpha * (2 - alpha)), 3)))%  |
                   | J ≈ Φ                                          | \(Statistics.percentDiff(a: currentEarth.displacementCurrentEquivalent(G: G, c: c), b: GOLDEN_RATIO))%   |
                   | h from α                                       | 0.0253887188634106%  |
                   | h / (2 - α) from ω                          | 0.00342749503676447% |
                   | Φ mass density approximation                         | \(Statistics.percentDiff(a: aog.massDensityApproximation(G: G, c: c, alpha: alpha), b: currentEarth.massDensity()))%   |
                   | G as a function of α and ρ                  | 0.07618221222642045% |

                   
                   ### Included Plots 
                   
                   Among the plots included here at the following, with derivations available [here](https://www.flusterapp.com/blog/by_path/on_the_gravitational_nature_of_time).
                   """)
               .frame(maxWidth: 1080, alignment: .center)
                MathView(latex: """
                    $$
                    \\alpha = \\frac{1}{2 - \\alpha} \\sqrt[3]{\\frac{d}{dR} g_{\\oplus}} \\pm 0.025\\%
                    $$
                    """, fontSize: 16)
                MathView(latex: """
                    $$
                    v_0 = c \\sqrt{1 - \\frac{1}{\\left(1 + \\frac{g}{R}\\right)^2}}
                    $$
                    """, fontSize: 16)
                MathView(latex: """
                    $$
                    v_0^\\prime = c \\sqrt{1 - \\frac{1}{\\left(1 + \\frac{1}{2} \\frac{g}{R}\\frac{\\left(\\tau \\bar{v}\\right)^2}{\\bar{v^2}}\\right)^2}}
                    $$
                    """, fontSize: 16)
            }
            .padding()
            .padding(.vertical, 64)
        }
        .scrollIndicators(.never)
        .navigationTitle("Home")
    }
}

#Preview {
    HomePage()
}
