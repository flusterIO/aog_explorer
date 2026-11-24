//
//  current_equivalent.swift
//  AlphaOmegaGravityVisualizer
//
//  Created by Andrew on 6/23/26.
//

import AlphaOmegaGravity
import Foundation
import SwiftUI

struct ElectromagnetismPage: View {
    @ObservedObject private var constants = Constants()
    var earthMass: Double {
        constants.earthMass()
    }
    var earthRadius: Double {
        constants.earthRadius()
    }
    var h: Double {
        constants.h()
    }
    var G: Double {
        constants.G()
    }
    var mu0: Double {
        constants.mu0()
    }
    var eps0: Double {
        constants.epsilon0()
    }
    var e: Double {
        constants.e()
    }
    var currentEarth: MassiveBody {
        MassiveBody(shape: Sphere(radius: earthRadius), vec: Vec3.zero(), mass: earthMass)
    }
    var magneticFieldDiv: Double {
        aog.magneticFieldDivergence(e: e, mu0: mu0, eps0: eps0, h: h)
    }
    var delta: Double {
        2 * G * earthMass / pow(earthRadius, 3)
    }
    let aog = AOG()
    var magneticDivergenceIntegral: Double {
        aog.magneticDivergenceIntegralOfR(earthRadius: earthRadius, e: e, mu0: mu0, eps0: eps0, h: h)
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                CurrentEquivalentPlot()
                    .frame(height: 400)
                MarkdownView(markdown: """
                    On Earth, there exists a Radius where this value is precisely the transcendental quantity Φ.
                    """)
                MathView(latex: """
                    $$
                    \\mathbf{J} = \\delta \\bar{v} = 2 \\frac{G M_{\\oplus}}{R_{\\oplus}^3} c \\sqrt{1 - \\frac{1}{\\left(1 + \\frac{g}{R}\\right)^2}} = \\Phi
                    $$
                    """, fontSize: 16)
                MagneticFieldDivergenceSurfacePlot()
                    .frame(height: 500)
                MarkdownView(markdown: """
                    Above is a plot of the function for magnetic divergence. It's not a 'diagram' of divergence, but rather a plot of the function found through the aog model that gives the _magnitude_ of divergence.
                    
                    All variables have been scaled to approximate 1 times the proportional input from your state changes to make the Apple renderer happy, because plotting numbers on the scale of _h_ or _e_ was proving to be impossible.
                    """)
                MathView(latex: """
                    $$
                    \\nabla \\cdot \\vec{B} = \\frac{
                    e^6 \\left(\\frac{\\mu_0}{\\epsilon_0}\\right)^{\\frac{3}{2}} \\left(2 - \\frac{1}{2}\\frac{e^2}{h} \\sqrt{\\frac{\\mu_0}{\\epsilon_0}}\\right)^3
                    }{8 h^3} = \\frac{d}{dR} g
                    $$
                    """, fontSize: 15)
                MarkdownView(markdown: """
                    If we plugin our current electromagnetic parameters, we find:
                    """)
                MathView(latex: """
                    $$
                    \\nabla \\cdot \\vec{B} = \\frac{
                    e^6 \\left(\\frac{\\mu_0}{\\epsilon_0}\\right)^{\\frac{3}{2}} \\left(2 - \\frac{1}{2}\\frac{e^2}{h} \\sqrt{\\frac{\\mu_0}{\\epsilon_0}}\\right)^3
                    }{8 h^3} = \(magneticFieldDiv)
                    $$
                    """, fontSize: 15)
                MarkdownView(markdown: """
                    Where as our gravitational parameters give:
                    """)
                MathView(latex: """
                    $$
                    \\frac{d}{dR}g = 2 G \\frac{M_\\oplus}{R_\\oplus^3} = \(delta)
                    $$
                    """, fontSize: 15)
                MarkdownView(markdown: """
                    That's a difference of \(Statistics.percentDiff(a: magneticFieldDiv, b: delta))%.
                    
                    And lastly on this page, we have the re-integration of the magnetic field divergence.
                    
                    If ∇⋅B is as represented above, then we should:
                    
                    1. Cube it
                    2. Slide _R_ over to the other side
                    3. Reintegrate R to bring this back up to the original dimensionality.
                    
                    This gives:
                    """)
                MathView(latex: """
                    $$
                    \\int_0^R \\left[\\nabla \\cdot \\vec{B} \\right] = R^{4} \\left(\\frac{e^{6} \\left(\\frac{\\mu_{0}}{\\epsilon_{0}}\\right)^{\\frac{3}{2}}}{4 h^{3}} + \\frac{3 \\mu_{0} e^{10} \\left(\\frac{\\mu_{0}}{\\epsilon_{0}}\\right)^{\\frac{3}{2}}}{64 \\epsilon_{0} h^{5}} - \\frac{3 \\mu_{0}^{2} e^{8}}{16 \\epsilon_{0}^{2} h^{4}} - \\frac{\\mu_{0}^{3} e^{12}}{256 \\epsilon_{0}^{3} h^{6}}\\right)
                    $$
                    """, fontSize: 16)
                MathView(latex: """
                    \\int_0^R \\left[\\nabla \\cdot \\vec{B} \\right] = \(magneticDivergenceIntegral)
                    """, fontSize: 16)
                 MagneticFieldDivergenceIntegral()
                    .frame(height: 400)
                MarkdownView(markdown: """
                    This value is oddly close (without state change) to
                    """)
                MathView(latex: """
                    $$
                    \\sqrt{\\Phi \\times 10^{42}} \\pm \(Statistics.percentDiff(a: magneticDivergenceIntegral, b: sqrt(GOLDEN_RATIO * pow(10, 42))))
                    $$
                    """, fontSize: 16)
                MarkdownView(markdown: """
                    Maybe not an anomalous finding on it's own, but in the context of _all_ of these 'dimensional coincidences' that just happen to fall directly out of a single, mathematically equivalent (in magnitude) modification to Einstein's model of relativity?
                    
                    """)

            }
            .padding()
        }
        .scrollIndicators(.never)
        .navigationTitle("Electromagnetism")
    }
}

#Preview {
    ElectromagnetismPage()
}
