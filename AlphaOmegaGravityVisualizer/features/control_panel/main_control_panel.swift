//
//  File.swift
//  AlphaOmegaGravityVisualizer
//
//  Created by Andrew on 6/22/26.
//

import AlphaOmegaGravity
import Foundation
import SwiftUI

struct MainControlPanel: View {

    @AppStorage(AppStorageKey.axis_points.rawValue) private var dataPoints:
        Int = 100

    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                IntegerSlider(
                    value: $dataPoints,
                    range: 10...1000,
                    label: "Data Points",
                    minText: "10",
                    maxText: "1000",
                    resetTo: 100,
                    unitText: "Points"
                )
                VariableDashboard()
            }
            .padding()
        }
    }
}

#Preview {
    MainControlPanel()
}
