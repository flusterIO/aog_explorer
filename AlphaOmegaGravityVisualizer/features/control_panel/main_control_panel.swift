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
                VStack(alignment: .leading) {
                    Text("Control Panel")
                        .font(.title)
                    Text("Control variables dynamically through this panel. Reset them with the button at the bottom, and remember, 'NaN' means 'not-a-number', usually because a square root can't be found because of a negative number.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading)
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
                Button(action: {
                    AppStorageKey.resetAll()
                }, label: {
                    Text("Reset All")
                })
            }
            .padding()
        }
        .scrollIndicators(.never)
    }
}

#Preview {
    MainControlPanel()
}
