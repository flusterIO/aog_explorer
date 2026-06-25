//
//  landing_page.swift
//  AlphaOmegaGravityVisualizer
//
//  Created by Andrew on 6/24/26.
//

import Foundation
import SwiftUI
import AlphaOmegaGravity


struct HomePage: View {
    @ObservedObject private var constants: Constants = Constants()
    @AppStorage(AppStorageKey.alpha_method.rawValue) private var alphaMethod: AlphaMethod = .independentProperty
    let aog = AOG()
    var currentEarth: MassiveBody {
        return MassiveBody(shape: Sphere(radius: constants.earthRadius()), vec: Vec3.zero(), mass: constants.earthMass())
    }
    var G: Double {
        constants.G()
    }
    var c: Double {
        constants.c()
    }
    var earthRadius: Double {
        constants.earthRadius()
    }
    var earthMass: Double {
        constants.earthMass()
    }
    var alpha: Double {
        constants.alpha(alphaMethod: alphaMethod)
    }
    var currentSun: MassiveBody {
        return MassiveBody(shape: Sphere(radius: constants.solarRadius()), vec: Vec3.zero(), mass: constants.solarMass())
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 32) {
                LandingPageIntro()
                DerivationWalkthroughOne()
                DerivationTwo()
                DerivationThree()
            }
            .padding()
            .padding(.vertical, 64)
        }
        .scrollIndicators(.never)
        .navigationTitle("Home")
    }
}

#Preview {
    HomePage()
}
