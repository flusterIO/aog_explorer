//
//  Components.swift
//  AlphaOmegaGravityVisualizer
//
//  Reusable building blocks: cards, badges, readouts, callouts, equation cards.
//

import Foundation
import SwiftUI

// MARK: - Card

struct Card<Content: View>: View {
    var padding: CGFloat = 20
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(.background.secondary)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
            }
    }
}

/// A card with a title row and optional trailing accessory.
struct TitledCard<Content: View, Accessory: View>: View {
    let title: String
    var subtitle: String? = nil
    var systemImage: String? = nil
    @ViewBuilder var accessory: Accessory
    @ViewBuilder var content: Content

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    if let systemImage {
                        Image(systemName: systemImage).foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.headline)
                        if let subtitle {
                            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 8)
                    accessory
                }
                content
            }
        }
    }
}

extension TitledCard where Accessory == EmptyView {
    init(title: String, subtitle: String? = nil, systemImage: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.accessory = EmptyView()
        self.content = content()
    }
}

// MARK: - Status badge

struct StatusBadge: View {
    let status: ClaimStatus
    var compact = false

    var body: some View {
        Label {
            Text(status.title)
        } icon: {
            Image(systemName: status.symbol)
        }
        .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
        .foregroundStyle(status.color)
        .padding(.horizontal, compact ? 7 : 9)
        .padding(.vertical, compact ? 3 : 4)
        .background(status.color.opacity(0.14), in: Capsule())
        .help(status.blurb)
    }
}

// MARK: - Equation card

struct EquationCard: View {
    let title: String
    let latex: String
    var status: ClaimStatus? = nil
    var note: String? = nil
    var reference: String? = nil
    var size: CGFloat = 20

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) {
                    Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                    Spacer()
                    if let reference {
                        Text(reference).font(.caption.monospaced()).foregroundStyle(.tertiary)
                    }
                    if let status { StatusBadge(status: status, compact: true) }
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    Equation(latex, size: size)
                        .padding(.vertical, 4)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                if let note {
                    Text(LocalizedStringKey(note))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

// MARK: - Readouts

struct Readout: View {
    let title: String
    let value: String
    var unit: String? = nil
    var caption: String? = nil
    var tint: Color = .primary
    var latex: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let latex {
                    Equation(latex, size: 13, color: .gray)
                }
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .foregroundStyle(tint)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText())
                if let unit {
                    Text(unit).font(.callout).foregroundStyle(.secondary)
                }
            }
            if let caption {
                Text(caption).font(.caption).foregroundStyle(.tertiary).lineLimit(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct ReadoutGrid<Content: View>: View {
    var minimum: CGFloat = 170
    @ViewBuilder var content: Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimum), spacing: 12)], alignment: .leading, spacing: 12) {
            content
        }
    }
}

// MARK: - Callout

struct Callout: View {
    enum Kind {
        case note, caveat, insight, result

        var symbol: String {
            switch self {
            case .note: "info.circle.fill"
            case .caveat: "exclamationmark.triangle.fill"
            case .insight: "lightbulb.fill"
            case .result: "checkmark.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .note: Theme.flow
            case .caveat: Theme.mass
            case .insight: Theme.hypothesis
            case .result: Color(red: 0.35, green: 0.85, blue: 0.55)
            }
        }
    }

    let kind: Kind
    var title: String? = nil
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: kind.symbol)
                .font(.title3)
                .foregroundStyle(kind.color)
            VStack(alignment: .leading, spacing: 4) {
                if let title {
                    Text(title).font(.subheadline.weight(.semibold))
                }
                Text(LocalizedStringKey(text))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(kind.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(kind.color.opacity(0.25), lineWidth: 1)
        }
    }
}

// MARK: - Prose

struct Prose: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(LocalizedStringKey(text))
            .font(.body)
            .lineSpacing(3)
            .foregroundStyle(.primary.opacity(0.85))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: 820, alignment: .leading)
    }
}

struct SectionHeading: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title2.weight(.semibold))
            if let subtitle {
                Text(subtitle).font(.callout).foregroundStyle(.secondary)
            }
        }
        .padding(.top, 8)
    }
}

/// Legend chip used next to charts.
struct LegendChip: View {
    let label: String
    let color: Color
    var dashed = false

    var body: some View {
        HStack(spacing: 6) {
            Capsule()
                .stroke(color, style: StrokeStyle(lineWidth: 3, dash: dashed ? [4, 3] : []))
                .frame(width: 18, height: 3)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}

/// Horizontal layout of a visual with a control column.
struct VisualWithControls<Visual: View, Controls: View>: View {
    var controlWidth: CGFloat = Theme.controlWidth
    @ViewBuilder var visual: Visual
    @ViewBuilder var controls: Controls

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            visual.frame(maxWidth: .infinity)
            VStack(alignment: .leading, spacing: 16) { controls }
                .frame(width: controlWidth)
        }
    }
}
