//
//  gravity_exploratory_page.swift
//  AlphaOmegaGravityVisualizer
//
//  Created by Andrew on 6/24/26.
//

import Foundation
import SwiftUI
import AlphaOmegaGravity

struct GravityExploratoryPage: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                SinThetaTimesDrSurface()
                    .frame(height: 400)
            }
            .padding()
        }
        .scrollIndicators(.never)
        .navigationTitle("Gravity Exploratory")
    }
}

#Preview {
    GravityExploratoryPage()
}
