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

    ]
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                NavigationPanelItem(item: NavigationItem(latex: """
            $$
            \\text{Home}
            $$
            """, page: .home))
                NavigationPanelItem(item: NavigationItem(latex: """
            $$
            \\gamma = \\frac{1}{1 - \\frac{v^2}{c^2}}
            $$
            """, page: .gamma))
                NavigationPanelItem(item: NavigationItem(latex: """
                $$
                \\gamma_g = 1 + \\frac{g}{R}
                $$
                """, page: .gravityExploration))
                NavigationPanelItem(item: NavigationItem(latex: """
                $$
                \\alpha = \\Gamma \\omega
                $$
                """, page: .electromagnetism))
                NavigationPanelItem(item: NavigationItem(latex: """
                    $$
                    \\text{Legal}
                    $$
                    """, page: .grossLegalShit))
                #if DEBUG
                NavigationSection(items: [
                    NavigationItem(latex: """
                    $$
                    \\text{Exporatory}
                    $$
                    """, page: .exploratory_li),
                    NavigationItem(latex: """
                    $$
                    \\text{Exporatory}_{\\text{gravity}}
                    $$
                    """, page: .exploratory_gravity)
                ])
                #endif
            }
        }
        }
}

#Preview {
    NavigationPanel()
}
