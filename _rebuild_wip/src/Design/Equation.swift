//
//  Equation.swift
//  AlphaOmegaGravityVisualizer
//
//  LaTeX rendered with SwiftMath, cached per (latex, size, color).
//

import SwiftUI
import AppKit
import SwiftMath

@MainActor
private enum EquationCache {
    static var images: [String: NSImage] = [:]
    static var failures: Set<String> = []

    static func image(latex: String, size: CGFloat, color: NSColor, colorKey: String) -> NSImage? {
        let key = "\(colorKey)|\(size)|\(latex)"
        if let hit = images[key] { return hit }
        if failures.contains(key) { return nil }
        var renderer = MathImage(latex: latex, fontSize: size, textColor: color)
        let (_, image, _) = renderer.asImage()
        if let image {
            images[key] = image
        } else {
            failures.insert(key)
        }
        return image
    }
}

/// Renders a LaTeX expression (no `$` delimiters).
struct Equation: View {
    let latex: String
    var size: CGFloat = 18
    var color: Color? = nil

    @Environment(\.colorScheme) private var scheme

    init(_ latex: String, size: CGFloat = 18, color: Color? = nil) {
        self.latex = latex
        self.size = size
        self.color = color
    }

    var body: some View {
        let (ns, key) = resolvedColor
        if let image = EquationCache.image(latex: latex, size: size, color: ns, colorKey: key) {
            Image(nsImage: image)
                .interpolation(.high)
                .accessibilityLabel(Text(latex))
        } else {
            Text(latex)
                .font(.system(size: size * 0.75, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }

    private var resolvedColor: (NSColor, String) {
        if let color {
            let ns = NSColor(color)
            if let rgb = ns.usingColorSpace(.sRGB) {
                let key = String(format: "%.3f-%.3f-%.3f-%.3f", rgb.redComponent, rgb.greenComponent, rgb.blueComponent, rgb.alphaComponent)
                return (rgb, key + (scheme == .dark ? "d" : "l"))
            }
            return (ns, "\(color.description)-\(scheme == .dark)")
        }
        return scheme == .dark
            ? (NSColor(white: 0.95, alpha: 1), "dark")
            : (NSColor(white: 0.10, alpha: 1), "light")
    }
}

// MARK: - Number formatting

enum Fmt {
    private static let superscripts: [Character: Character] = [
        "0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹", "-": "⁻",
    ]

    /// Significant-figure formatting, switching to scientific notation for very large or small values.
    static func sig(_ x: Double, _ digits: Int = 4) -> String {
        guard x.isFinite else { return x.isNaN ? "—" : (x > 0 ? "∞" : "−∞") }
        if x == 0 { return "0" }
        let a = abs(x)
        if a >= 1e-3 && a < 1e7 {
            let magnitude = Int(floor(log10(a)))
            let decimals = max(0, digits - 1 - magnitude)
            return fixed(x, decimals)
        }
        return sci(x, digits)
    }

    static func sci(_ x: Double, _ digits: Int = 3) -> String {
        guard x.isFinite else { return x.isNaN ? "—" : (x > 0 ? "∞" : "−∞") }
        if x == 0 { return "0" }
        var exponent = Int(floor(log10(abs(x))))
        var mantissa = x / pow(10, Double(exponent))
        let rounded = (mantissa * pow(10, Double(digits - 1))).rounded() / pow(10, Double(digits - 1))
        if abs(rounded) >= 10 { mantissa = rounded / 10; exponent += 1 } else { mantissa = rounded }
        let m = String(format: "%.\(max(0, digits - 1))f", mantissa).replacingOccurrences(of: "-", with: "−")
        let e = String(String(exponent).map { superscripts[$0] ?? $0 })
        return "\(m) × 10\(e)"
    }

    static func fixed(_ x: Double, _ decimals: Int) -> String {
        guard x.isFinite else { return x.isNaN ? "—" : (x > 0 ? "∞" : "−∞") }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = decimals
        f.maximumFractionDigits = decimals
        f.usesGroupingSeparator = true
        let s = f.string(from: NSNumber(value: x)) ?? String(format: "%.\(decimals)f", x)
        return s.replacingOccurrences(of: "-", with: "−")
    }

    /// Fraction → percent string.
    static func percent(_ fraction: Double, _ decimals: Int = 2) -> String {
        fixed(fraction * 100, decimals) + "%"
    }

    static func signedPercent(_ fraction: Double, _ decimals: Int = 2) -> String {
        (fraction >= 0 ? "+" : "") + percent(fraction, decimals)
    }

    static func kms(_ metersPerSecond: Double, _ decimals: Int = 1) -> String {
        fixed(metersPerSecond / 1_000, decimals) + " km/s"
    }
}
