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
            case .home:
                HomePage()
            case .gamma:
                GammaExplorationPage()
            case .gravityExploration:
                GravityExplorationPage()
            case .electromagnetism:
                ElectromagnetismPage()
            case .exploratory_li:
                ExporatoryLiObservationsPage()
            case .exploratory_gravity:
                GravityExploratoryPage()
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
