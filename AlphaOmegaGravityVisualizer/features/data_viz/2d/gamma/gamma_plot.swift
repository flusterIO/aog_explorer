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


class GammaData: Identifiable {
    var v: Double
    var gamma: Double
    var gravityGamma: Double
    var c: Double
    var M_earth: Double
    var R_earth: Double
    var G: Double
    init(v: Double, c: Double, G: Double, M_earth: Double, R_earth: Double) {
        self.v = v
        self.c = c
        self.G = G
        self.M_earth = M_earth
        self.R_earth = R_earth
        self.gamma = 1 / sqrt(1 - pow(v / self.c, 2))
        self.gravityGamma = 1 + self.G * self.M_earth / pow((self.R_earth * self.gamma), 3)
    }
}

public struct GammaPlot: View {
    var image: NSImage?
    @State private var ySelection: ClosedRange<Double>? = 0.99...1.01
    @AppStorage(AppStorageKey.variable_G.rawValue) private var G: Double = STANDARD_NEWTONS_CONSTANT
    @AppStorage(AppStorageKey.variable_c.rawValue) private var c: Double = STANDARD_SPEED_OF_LIGHT
    @AppStorage(AppStorageKey.variable_earthRadius.rawValue) private var earthRadius: Double = EARTH_RADIUS_EQUATORIAL
    @AppStorage(AppStorageKey.variable_earthMass.rawValue) private var earthMass: Double = EARTH_MASS
    @AppStorage(AppStorageKey.axis_points.rawValue) private var axisPoints: Double = 100
    var axisData: [GammaData] {
        AxisData.fromLinSpace(0, c, axisPoints).data.map { v in
            GammaData(v: v, c: c, G: G, M_earth: earthMass, R_earth: earthRadius)
        }
    }
    public init() {
        var r = SwiftMath.MathImage(
            latex: """
                $$
                \\gamma = \\frac{1}{\\sqrt{1 - \\frac{v^2}{c^2}}}, \\quad \\gamma_g = 1 + \\frac{g_\\oplus}{R_\\oplus}
                $$
                """,
            fontSize: 16,
            textColor: .white
        )
        let (_, img, _) = r.asImage()
        if img != nil {
            self.image = img!
        }
    }
    
    public var body: some View {
            Chart {
                ForEach(axisData) {gamma in
                    LineMark(x: .value("Velocity", gamma.v), y: .value("γ", gamma.gamma))
                        .foregroundStyle(by: .value("Gamma", "γ"))
                }
            }
            .chartYSelection(range: $ySelection)
            .chartYAxisLabel() {
                MathView(latex: """
                    $$
                    \\frac{1}{1 - \\frac{v^2}{c^2}}
                    $$
                    """, fontSize: 12)
            }
            .chartXAxisLabel() {
                MathView(latex: """
                    $$
                    x=v=c\\sqrt{1 - \\frac{1}{\\gamma^2}}
                    $$
                    """, fontSize: 12)
            }
        .padding()
    }
}

#Preview {
    GammaPlot()
}
