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
            }
            .padding()
        }
        .navigationTitle("Electromagnetism")
    }
}

#Preview {
    ElectromagnetismPage()
}
