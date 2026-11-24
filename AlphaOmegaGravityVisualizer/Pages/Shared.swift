//
//  Shared.swift
//  AlphaOmegaGravityVisualizer
//
//  Helpers shared by pages: 3D scene cards, glass chips and chart styling.
//

import Foundation
import SwiftUI
import Charts

// MARK: - Liquid Glass chip

extension View {
    /// Floating chip on top of a visual, using Liquid Glass (macOS 26).
    func glassChip(cornerRadius: CGFloat = 12) -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
    }
}

// MARK: - Scene card

/// A dark stage for 3D embeddings with an overlay slot for chips and legends.
struct SceneCard<Overlay: View>: View {
    var spec: SurfaceSpec
    var height: CGFloat = 460
    var autoRotate = true
    @ViewBuilder var overlay: Overlay

    var body: some View {
        ZStack(alignment: .topLeading) {
            RadialGradient(
                colors: [Color(red: 0.11, green: 0.13, blue: 0.25), Color(red: 0.03, green: 0.03, blue: 0.08)],
                center: .center, startRadius: 10, endRadius: 700
            )
            EmbeddingSceneView(spec: spec, autoRotate: autoRotate)
            overlay
                .padding(16)
                .environment(\.colorScheme, .dark)
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        }
        .overlay(alignment: .bottomTrailing) {
            Label("Drag to orbit · scroll to zoom", systemImage: "rotate.3d")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.55))
                .padding(12)
        }
    }
}

extension SceneCard where Overlay == EmptyView {
    init(spec: SurfaceSpec, height: CGFloat = 460, autoRotate: Bool = true) {
        self.spec = spec
        self.height = height
        self.autoRotate = autoRotate
        self.overlay = EmptyView()
    }
}

extension SurfaceSpec {
    /// Surface from a radial slice; tint = β.
    static func from(_ slice: [SliceSample], rings: [SurfaceRing] = [], flow: TracerFlow = .none, hue: SurfaceHue = .flow, verticalScale: Double = 1) -> SurfaceSpec {
        SurfaceSpec(
            radii: slice.map(\.r),
            heights: slice.map(\.y),
            tints: slice.map { min(1, $0.beta) },
            rings: rings,
            flow: flow,
            speeds: slice.map(\.beta),
            verticalScale: verticalScale,
            hue: hue
        )
    }
}

// MARK: - Canvas card

/// A card hosting a 2D canvas on a subtle dark stage.
struct StageCard<Content: View>: View {
    var height: CGFloat = 420
    var dark = false
    @ViewBuilder var content: Content
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        content
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(dark
                          ? AnyShapeStyle(RadialGradient(colors: [Color(red: 0.10, green: 0.12, blue: 0.22), Color(red: 0.03, green: 0.03, blue: 0.07)], center: .center, startRadius: 10, endRadius: 600))
                          : AnyShapeStyle(BackgroundStyle().secondary))
            }
            .overlay {
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
            }
            .environment(\.colorScheme, dark ? .dark : scheme)
    }
}

// MARK: - Chart styling

struct ChartCard<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    var height: CGFloat = 300
    @ViewBuilder var content: Content

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    if let subtitle {
                        Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
                content
                    .frame(height: height)
            }
        }
    }
}

extension View {
    /// Consistent axis and legend styling for charts.
    func standardChartStyle() -> some View {
        self
            .chartLegend(position: .top, alignment: .leading, spacing: 10)
            .chartXAxis {
                AxisMarks { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Color.primary.opacity(0.08))
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5)).foregroundStyle(Color.primary.opacity(0.08))
                    AxisTick()
                    AxisValueLabel()
                }
            }
    }
}

/// Convenience to sample a function into chart points.
func sample(_ xs: [Double], series: String = "", _ f: (Double) -> Double) -> [XY] {
    xs.enumerated().compactMap { i, x in
        let y = f(x)
        return y.isFinite ? XY(id: i, x: x, y: y, series: series) : nil
    }
}
