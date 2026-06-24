//
//  File.swift
//  AlphaOmegaGravityVisualizer
//
//  Created by Andrew on 6/22/26.
//

import Foundation
import SwiftUI
import AlphaOmegaGravity


struct NavigationPanelItem: View {
    let item: NavigationItem
    @ObservedObject private var appState: NavigationSingleton = .shared

    init(item: NavigationItem) {
        self.item = item
    }
    var body: some View {
        HStack {
            MathView(latex: item.latex, fontSize: 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .glassEffect()
        .onTapGesture {
            appState.navigateTo(to: item.page)
        }
    }
}
