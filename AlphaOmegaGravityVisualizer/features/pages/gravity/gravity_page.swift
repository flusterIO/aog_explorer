//
//  gravity_page.swift
//  AlphaOmegaGravityVisualizer
//
//  Created by Andrew on 6/22/26.
//

import Foundation
import SwiftUI
import AlphaOmegaGravity

struct GravityExplorationPage: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                DerivedOrbitalVelocityDiagram()
                    .frame(height: 400)
                
                MarkdownView(markdown: """
                    Above, the primary line is the derived orbital velocity as described in the
                    plot heading. The faint line is the standard orbital velocity at R.
                    
                    This value _perfectly_ reproduces Earth's galactic radius from our orbital parameters,
                    **without** any unseed mass.
                    """)
                
                DerivedAlphaDiagram()
                    .frame(height: 400)
                
                MarkdownView(markdown: """
                    Above, α is given by this equation for bodies with an increased rotational energy per
                    mass density. This equation does **not** arise where Γ approximates 1/2 _inside_ of the cube root
                    as it does for very massive bodies like our Sun or even Jupyter.  
                    
                    The 'Solar' line represents the equation for massive, slowly rotating bodies as the 'spinor' approximation does not experience the spatial dilation as divergence, which in turn gives rise to the cube root, or the torsion which gives rise to α.
                    
                    I don't know how to derive α from first, **Newtonian** principles _yet_, but we're closer than we've ever been.
                    """)
                
                EarthRotationalVelocityDiagram()
                    .frame(height: 400)
                
                MarkdownView(markdown: """
                    The above equation and subsequent plot reproduce Earth's rotational velocity to within 1.18 inches per second, a painfully slow walking pace for an orbital velocity that takes into account the Earth's radius and a period as long as our day.
                    """)
                
                DThetaOverDRPlot()
                    .frame(height: 300)
                DThetaTimesDRPlot()
                    .frame(height: 300)
                DThetaPlusDRPlot()
                    .frame(height: 300)
                MarkdownView(markdown: """
                    The above 3 plots reresent the same 2 vectors dθ and dR, first as a ratio, then as a product, and lastly, as a sum.
                    
                    The formula used for these plots can be derived from the following equation, which is discussed in greater detail [here](https://www.flusterapp.com/blog/by_path/on_the_gravitational_nature_of_time).
                    """)
                
                MathView(latex: """
                    $$
                    \\nabla \\cdot \\vec{E} = c \\left(\\nabla \\cdot \\vec{B} \\right) = v_{\\text{rot}}\\left(2 - \\alpha \\right) = c \\delta = c \\frac{d}{dR}g
                    $$
                    """, fontSize: 16)
                
                AlphaDerivedFromAUPeriod()
                    .frame(height: 400)
                
                MarkdownView(markdown: """
                    Above, we can derive α from our orbital parameters and the relationship to Γ established
                    in the article published [here](https://www.flusterapp.com/blog/by_path/on_the_gravitational_nature_of_time), 
                    aligning with observation to within 0.1%.
                    """)
                
                GFromAlphaPlot()
                    .frame(height: 400)
                
                MarkdownView(markdown: """
                    Above, G is defined in terms of inverse mass-density and electromagnetic parameters, aligning with observation to a similar degree of accuracy.
                    """)
                
            }
            .padding()
            
        }
        .scrollIndicators(.never)
        .navigationTitle("Gravity")
    }
}

#Preview {
    GravityExplorationPage()
}
