//
//  ParameterStore.swift
//  AlphaOmegaGravityVisualizer
//
//  Global, user-adjustable constants shared by every page (shown in the inspector).
//

import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
final class ParameterStore {
    var c: Double = SI.c
    var G: Double = SI.G
    /// H₀ in km s⁻¹ Mpc⁻¹.
    var hubbleKmsMpc: Double = 70
    /// κ′ in g₀ = κ′ c H₀ (Hypothesis M). Candidate value 1/2π.
    var kappaPrime: Double = 1.0 / (2.0 * Double.pi)
    /// τ̂ in seconds; fixes the reference length L_τ = c τ̂.
    var tauHat: Double = 1.0

    var H0: Double { hubbleKmsMpc * 1_000 / SI.Mpc }
    var cH0: Double { c * H0 }
    var g0: Double { kappaPrime * cH0 }
    var lTau: Double { c * tauHat }
    var criticalDensity: Double { 3 * H0 * H0 / (8 * Double.pi * G) }
    var hubbleRadius: Double { c / H0 }

    func schwarzschildRadius(_ mass: Double) -> Double { 2 * G * mass / (c * c) }

    var isModified: Bool {
        c != SI.c || G != SI.G || hubbleKmsMpc != 70 || kappaPrime != 1.0 / (2.0 * Double.pi) || tauHat != 1.0
    }

    func reset() {
        c = SI.c
        G = SI.G
        hubbleKmsMpc = 70
        kappaPrime = 1.0 / (2.0 * Double.pi)
        tauHat = 1.0
    }
}

@MainActor
@Observable
final class NavigationModel {
    var page: Page? = .home

    func go(_ page: Page) {
        withAnimation(.snappy) { self.page = page }
    }
}
