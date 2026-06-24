//
//  File.swift
//  AlphaOmegaGravityVisualizer
//
//  Created by Andrew on 6/22/26.
//

import Foundation
import SwiftUI


struct NavigationPanel: View {
    public let items: [NavigationItem] = [
        NavigationItem(latex: """
        $$
        \\gamma = \\frac{1}{1 - \\frac{v^2}{c^2}}
        $$
        """, page: .gamma),
        NavigationItem(latex: """
            $$
            \\gamma_g = 1 + \\frac{g}{R}
            $$
            """, page: .gravityExploration),
        NavigationItem(latex: """
            $$
            \\alpha = \\Gamma \\omega
            $$
            """, page: .electromagnetism),

    ]
    var body: some View {
            List(items) { item in
                NavigationPanelItem(item: item)
            }
        }
}

#Preview {
    NavigationPanel()
}
