//
//  File.swift
//  AlphaOmegaGravityVisualizer
//
//  Created by Andrew on 6/24/26.
//

import Foundation
import SwiftUI

struct NavigationSection: View {
    let items: [NavigationItem]
    var body: some View {
        Section {
            ForEach(items, id: \.id) { item in
                NavigationPanelItem(item: item)
            }
        }
    }
}

#Preview {
    NavigationSection(items: [])
}
