//
//  navigation_item.swift
//  AlphaOmegaGravityVisualizer
//
//  Created by Andrew on 6/22/26.
//

import Foundation

struct NavigationItem: Identifiable {
    var id: UUID = UUID()

    public let latex: String
    public let page: PageView
}
