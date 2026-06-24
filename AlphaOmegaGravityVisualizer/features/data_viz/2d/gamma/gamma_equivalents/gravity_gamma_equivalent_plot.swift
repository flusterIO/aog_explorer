//
//  File.swift
//  AlphaOmegaGravityVisualizer
//
//  Created by Andrew on 6/22/26.
//

import Charts
import SwiftMath
import SwiftUI
import AlphaOmegaGravity


class GravityGammaData: Identifiable {
    var gravityGamma: Double
    var R_earth: Double
    var gravityTimeDepedentGamma: Double
    init(r: Double, dt: Double, constants: Constants) {
        self.R_earth = r
        let mb = constants.getEarthMassiveBody()
        self.gravityGamma = mb.gravityGamaEquivalent(G: constants.G(), R: r)
        self.gravityTimeDepedentGamma = mb.gravityGamaEquivalentTimeDependent(dt: dt, G: constants.G(), c: constants.c(), R: r)
    }
}

public struct GravityGammaPlot: View {
    @State private var ySelection: ClosedRange<Double>? = 0.99...1.01
    @AppStorage(AppStorageKey.variable_earthRadius.rawValue) private var earthRadius: Double = EARTH_RADIUS_EQUATORIAL
    @AppStorage(AppStorageKey.axis_points.rawValue) private var axisPoints: Double = 100
    let aog = AOG()
    let earth = MassiveBody.earth()
    let constants = Constants()
    var data: [GravityGammaData] {
        let d: AxisData = .fromLinSpace(0,  earthRadius, axisPoints)
        return d.data.map { r in
            GravityGammaData(
                r: r,
                dt: constants.timeDelta(),
                constants: constants
            )
        }
    }

    public init() {
    }
    
    public var body: some View {
            Chart {
                ForEach(data) { item in
                    LineMark(x: .value("Radius", item.R_earth), y: .value("Gravity", item.gravityGamma))
                        .foregroundStyle(by: .value("Gravity", "'Oven' frame"))
                    LineMark(x: .value("Radius", item.R_earth), y: .value("Gravity Time Dependent", item.gravityTimeDepedentGamma))
                        .foregroundStyle(by: .value("Gravity Time Dependent", "Time Dependent"))
                }
            }
            .chartYAxisLabel {
                MathView(latex: """
                $$
                \\gamma_g = 1 + \\frac{g}{R}
                $$
                """, fontSize: 12)
            }
            .chartXAxisLabel() {
                MathView(latex: """
                    $$
                    x=R
                    $$
                    """, fontSize: 12)
            }
        .padding()
    }
}

#Preview {
    GravityGammaPlot()
}
