//
//  AlphaOmegaGravityVisualizerApp.swift
//  AlphaOmegaGravityVisualizer
//
//  Interactive companion to "The Lorentz Factor as the Slope of an Additional Spatial
//  Coordinate: Embedding, Painlevé–Gullstrand Flow, and the Issue of Simultaneity".
//

import Foundation
import SwiftUI

@main
struct AlphaOmegaGravityVisualizerApp: App {
    @State private var params = ParameterStore()
    @State private var navigation = NavigationModel()

    var body: some Scene {
        WindowGroup("Lorentz Slope Visualizer") {
            RootView()
                .environment(params)
                .environment(navigation)
                .frame(minWidth: 1180, minHeight: 760)
        }
        .defaultSize(width: 1520, height: 960)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(after: .sidebar) {
                Button("Reset Constants") { params.reset() }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
                Divider()
                Button("Overview") { navigation.go(.home) }
                    .keyboardShortcut("0", modifiers: [.command])
            }
        }
    }
}
