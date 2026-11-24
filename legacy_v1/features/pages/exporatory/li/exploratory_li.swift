//
//  exploratory_li.swift
//  AlphaOmegaGravityVisualizer
//
//  Created by Andrew on 6/24/26.
//

import Foundation
import SwiftUI
import AlphaOmegaGravity


struct ExporatoryLiObservationsPage: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                LiGammaEquivalent()
                    .frame(height: 400)
                LiGammaVbarEquivalent()
                    .frame(height: 400)
            }
            .padding(.vertical, 32)
        }
        .scrollIndicators(.never)
        .padding()
        .navigationTitle("Li Observations")
    }
}

#Preview {
    ExporatoryLiObservationsPage()
}
