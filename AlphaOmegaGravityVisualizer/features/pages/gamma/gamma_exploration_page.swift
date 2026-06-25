//
//  File.swift
//  AlphaOmegaGravityVisualizer
//
//  Created by Andrew on 6/22/26.
//

import AlphaOmegaGravity
import Foundation
import SwiftUI

struct GammaExplorationPage: View {
    @ObservedObject private var constants = Constants()
    var earthRadius: Double {
        constants.earthRadius()
    }
    var earthMass: Double {
        constants.earthMass()
    }
    var G: Double {
        constants.G()
    }
    var c: Double {
        constants.c()
    }
    var currentEarth: MassiveBody {
        MassiveBody(shape: Sphere(radius: earthRadius), vec: Vec3.zero(), mass: earthMass)
    }
    var orbitalDt: Double {
    return -currentEarth.derivedOrbitalDtAtR(R: earthRadius, G: G)
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                GammaPlot()
                    .frame(height: 400)
                MarkdownView(
                    markdown: """
                        The above plot represents Einstein's traditional γ, as it appears in his famous 1905 paper.
                        """
                )
                OrbitalDtVofGammaPlot()
                    .frame(height: 400)
                MarkdownView(
                    markdown: """
                        Above is the 'v' of the 'γ' found by the triginometric solution to our orbital velocity, basically:
                        """
                )
                MathView(latex: """
                    $$
                    v = c \\sqrt{1 - \\frac{1}{\\gamma_{(dt)}^2}} = \(StandardCosmology.vFromGamma(gamma: -orbitalDt, c: c).bePretty(.decimal)) \\ \\text{m} \\ \\text{s}^{-1}
                    $$
                    """, fontSize: 16)
                Text("Where the following equation and plot represent the 'dt' necessary to induce the 'γ' found for the orbital velocity 'v'.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                MathView(latex: """
                    $$
                    dt = R_{\\oplus}^3 \\left(\\frac{1}{\\frac{1}{2}G M_{\\oplus} - R_{\\oplus}^3}\\right) = \(orbitalDt.bePretty(.decimal, accuracy: 8, maxDigits: 10)) \\ \\text{s}
                    $$
                    """, fontSize: 16)
                OrbitalDtPlot()
                    .frame(height: 400)
                Divider()
                GravityGammaPlot()
                    .frame(height: 400)
                MarkdownView(markdown: """
                    The above plot represents the the gravitational equivalent of γ as the integral of this equation
                    induces our gravitational acceleration secondarily to the divergence produced by ω.
                    """)
                VOfGravityGammaPlot()
                    .frame(height: 400)
                MarkdownView(markdown: """
                    The above plot is the velocity required to induce the γ magnitude of the plot prior in Einstein's model of relativity.
                    """)
            }
            .padding()
        }
        .scrollIndicators(.never)
        .navigationTitle("γ")
    }
}

#Preview {
    GammaExplorationPage()
}
