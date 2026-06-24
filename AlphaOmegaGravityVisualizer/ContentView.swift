//
//  ContentView.swift
//  AlphaOmegaGravityVisualizer
//
//  Created by Andrew on 6/22/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var appState: NavigationSingleton = NavigationSingleton.shared


    var body: some View {
        NavigationSplitView {
            NavigationPanel()
        } content: {
            switch appState.activePage {
            case .gamma:
                GammaExplorationPage()
            case .gravityExploration:
                GravityExplorationPage()
            case .electromagnetism:
                ElectromagnetismPage()
            }
        }
        detail: {
            MainControlPanel()
        }
    }

}

#Preview {
    ContentView()
}
