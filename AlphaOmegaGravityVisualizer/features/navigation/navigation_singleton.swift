//
//  navigation_singleton.swift
//  AlphaOmegaGravityVisualizer
//
//  Created by Andrew on 6/22/26.
//

import Foundation
import SwiftUI
import Combine


public class NavigationSingleton: ObservableObject {
    
    public static var shared: NavigationSingleton = .init()
    @Published public var activePage: PageView = .gamma
    
    private init() {
        
    }
    
    public func navigateTo(to activePage: PageView) {
        self.activePage = activePage
    }
    
}
