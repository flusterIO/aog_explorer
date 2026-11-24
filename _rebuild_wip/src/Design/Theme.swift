//
//  Theme.swift
//  AlphaOmegaGravityVisualizer
//

import SwiftUI
import Foundation

enum Theme {
    static let corner: CGFloat = 18
    static let pagePadding: CGFloat = 36
    static let maxContentWidth: CGFloat = 1320
    static let controlWidth: CGFloat = 330

    static let flow = Color(red: 0.36, green: 0.78, blue: 1.0)
    static let mass = Color(red: 1.0, green: 0.62, blue: 0.28)
    static let geometry = Color(red: 0.42, green: 0.86, blue: 0.72)
    static let time = Color(red: 0.98, green: 0.42, blue: 0.56)
    static let hypothesis = Color(red: 0.70, green: 0.52, blue: 1.0)
    static let observation = Color(red: 0.98, green: 0.80, blue: 0.30)
    static let neutral = Color.secondary

    static let heroGradient = LinearGradient(
        colors: [Color(red: 0.42, green: 0.86, blue: 0.95), Color(red: 0.55, green: 0.55, blue: 1.0), Color(red: 0.92, green: 0.50, blue: 0.85)],
        startPoint: .leading, endPoint: .trailing
    )
}

/// The epistemic status of a statement, mirroring the paper's "what is and is not established".
enum ClaimStatus: String, CaseIterable, Identifiable {
    case identity, derived, equivalentGR, imported, assumption, hypothesis, numerical, exploration

    var id: String { rawValue }

    var title: String {
        switch self {
        case .identity: "Identity"
        case .derived: "Derived here"
        case .equivalentGR: "Equivalent to GR"
        case .imported: "Imported from GR"
        case .assumption: "Assumption"
        case .hypothesis: "Hypothesis"
        case .numerical: "Numerical alignment"
        case .exploration: "Exploration"
        }
    }

    var symbol: String {
        switch self {
        case .identity: "equal.circle.fill"
        case .derived: "checkmark.seal.fill"
        case .equivalentGR: "link.circle.fill"
        case .imported: "arrow.down.circle.fill"
        case .assumption: "questionmark.diamond.fill"
        case .hypothesis: "lightbulb.max.fill"
        case .numerical: "number.circle.fill"
        case .exploration: "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .identity: Color(red: 0.55, green: 0.75, blue: 1.0)
        case .derived: Color(red: 0.35, green: 0.85, blue: 0.55)
        case .equivalentGR: Color(red: 0.36, green: 0.78, blue: 1.0)
        case .imported: Color(red: 0.62, green: 0.66, blue: 0.75)
        case .assumption: Color(red: 1.0, green: 0.62, blue: 0.28)
        case .hypothesis: Theme.hypothesis
        case .numerical: Theme.observation
        case .exploration: Color(red: 0.98, green: 0.45, blue: 0.70)
        }
    }

    var blurb: String {
        switch self {
        case .identity: "An algebraic or geometric identity — true by construction."
        case .derived: "Follows within the construction from the stated inputs."
        case .equivalentGR: "Reproduces a known general-relativistic result where it can be checked."
        case .imported: "Taken from general relativity as an input, not derived here."
        case .assumption: "A choice or postulate of the construction."
        case .hypothesis: "Goes beyond GR; testable, not derived from the embedding."
        case .numerical: "A numerical alignment the paper keeps only as a rough approximation."
        case .exploration: "An avenue suggested by the paper and explored numerically in this app."
        }
    }
}
