//
//  legal_and_shameless_plug.swift
//  AlphaOmegaGravityVisualizer
//
//  Created by Andrew on 6/25/26.
//

import Foundation
import SwiftUI
import AlphaOmegaGravity


struct LegalAndShamelessPlug: View {
    var body: some View {
        ScrollView{
            VStack {
                MarkdownView(markdown: """
                    ## Shameless Plug
                    
                    Along with this sort of 'toy' application meant only to be an exploratory tool, there's a more robust note taking framework that I built to draw attention to this model available at [flusterapp.com](https://flusterapp.com).
                    
                    I am still borderline homeless, so any help supporting this application would be a huge step towards getting out of this situation, but more importantly, it would help bring this model into the physics debate... the entire reason I'm homeless in the first place.
                    
                    ## Disclaimer
                    
                    This app is meant to be an exploratory tool for various equations that fall out of Einstein's model of relativity. The equations are accurate to the best of my ability, but for legal purposes, there are no guarantees of any kind associated with the use of this application.
                    
                    The modified model of relativity discussed throughout this application is the sole work of Andrew Charles Mueller of Milwaukee, WI. Feel free to share, modify, fork or clone this application in anyway that you like, but you must give credit for the model to the original author.
                    
                    """)
            }
        }
        .scrollIndicators(.never)
        .padding()
    }
}

#Preview {
    LegalAndShamelessPlug()
}
