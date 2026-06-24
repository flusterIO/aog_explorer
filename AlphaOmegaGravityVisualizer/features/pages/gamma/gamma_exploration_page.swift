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
                OrbitalDtGammaPlot()
                    .frame(height: 400)
                MarkdownView(
                    markdown: """
                        Above is the γ (gamma) of the 'dt' found in the orbital 'dt' plot on the gravity page. This demontrates the nature of gravity,
                        where a body closer to the source of gravitation is indistinguishable from a body approaching the speed of light, because it is
                        space that is moving, not the observer.  
                        
                        As the observer approaches R=0, v approaches c, until a point where v=c at what we now call the event horizon.
                        """
                )
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
