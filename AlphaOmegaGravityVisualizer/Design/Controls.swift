//
//  Controls.swift
//  AlphaOmegaGravityVisualizer
//

import Foundation
import SwiftUI

/// A labelled slider with live value, optional LaTeX symbol, and linear or log scale.
struct ParameterSlider: View {
    enum Scale { case linear, log }

    let title: String
    var symbol: String? = nil
    @Binding var value: Double
    let range: ClosedRange<Double>
    var scale: Scale = .linear
    var unit: String? = nil
    var tint: Color = .accentColor
    var format: (Double) -> String = { Fmt.sig($0, 4) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                if let symbol {
                    Equation(symbol, size: 14)
                }
                Text(title)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                Spacer(minLength: 6)
                Text(format(value) + (unit.map { " " + $0 } ?? ""))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            Slider(value: sliderBinding, in: sliderRange)
                .tint(tint)
                .controlSize(.small)
        }
    }

    private var sliderRange: ClosedRange<Double> {
        switch scale {
        case .linear: range
        case .log: log10(range.lowerBound)...log10(range.upperBound)
        }
    }

    private var sliderBinding: Binding<Double> {
        switch scale {
        case .linear:
            return $value
        case .log:
            return Binding(
                get: { log10(max(value, range.lowerBound)) },
                set: { value = pow(10, $0) }
            )
        }
    }
}

/// Segmented picker with a title.
struct ChoicePicker<T: Hashable & Identifiable>: View {
    let title: String
    @Binding var selection: T
    let options: [T]
    let label: (T) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.callout.weight(.medium))
            Picker(title, selection: $selection) {
                ForEach(options) { option in
                    Text(label(option)).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }
}

/// Group of controls with a small header.
struct ControlPanel<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        Card(padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                Text(title.uppercased())
                    .font(.caption2.weight(.semibold))
                    .tracking(0.8)
                    .foregroundStyle(.secondary)
                content
            }
        }
    }
}
