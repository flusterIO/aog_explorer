//
//  EmbeddingSceneView.swift
//  AlphaOmegaGravityVisualizer
//
//  A SceneKit surface of revolution y(R) with vertex colouring, grid lines, marker rings
//  and tracers that move along the slice at the local flow speed β c.
//

import SwiftUI
import SceneKit
import AppKit
import QuartzCore

struct SurfaceRing: Equatable {
    enum Style: Equatable { case horizon, surface, marker, accent }
    var radius: Double
    var style: Style
}

enum TracerFlow: Equatable { case none, inward, outward }

enum SurfaceHue: Equatable { case flow, star, cosmos }

struct SurfaceSpec: Equatable {
    /// Radii (any unit; normalised internally).
    var radii: [Double]
    /// Embedding heights at each radius (same unit as radii).
    var heights: [Double]
    /// Colour ramp parameter in 0...1 at each radius.
    var tints: [Double]
    var rings: [SurfaceRing] = []
    var flow: TracerFlow = .none
    /// Flow speed β at each radius (times the tracers).
    var speeds: [Double] = []
    var verticalScale: Double = 1
    var hue: SurfaceHue = .flow
}

struct EmbeddingSceneView: NSViewRepresentable {
    var spec: SurfaceSpec
    var autoRotate: Bool = true

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        view.wantsLayer = true
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling4X
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = false
        view.preferredFramesPerSecond = 60
        view.scene = context.coordinator.scene
        view.pointOfView = context.coordinator.cameraNode
        context.coordinator.update(spec: spec, autoRotate: autoRotate)
        view.isPlaying = true
        return view
    }

    func updateNSView(_ view: SCNView, context: Context) {
        context.coordinator.update(spec: spec, autoRotate: autoRotate)
    }

    final class Coordinator {
        let scene = SCNScene()
        let cameraNode = SCNNode()
        let pivot = SCNNode()
        private var surfaceNode = SCNNode()
        private var lastSpec: SurfaceSpec?
        private var lastRotate: Bool?

        init() {
            scene.background.contents = NSColor.clear
            scene.rootNode.addChildNode(pivot)

            let camera = SCNCamera()
            camera.fieldOfView = 36
            camera.zNear = 0.1
            camera.zFar = 400
            camera.wantsHDR = true
            camera.bloomIntensity = 0.9
            camera.bloomThreshold = 0.75
            camera.bloomBlurRadius = 10
            cameraNode.camera = camera
            cameraNode.position = SCNVector3(0, 10.5, 19)
            cameraNode.look(at: SCNVector3(0, 0, 0))
            scene.rootNode.addChildNode(cameraNode)

            let ambient = SCNNode()
            ambient.light = SCNLight()
            ambient.light?.type = .ambient
            ambient.light?.intensity = 420
            scene.rootNode.addChildNode(ambient)

            let key = SCNNode()
            key.light = SCNLight()
            key.light?.type = .directional
            key.light?.intensity = 950
            key.eulerAngles = SCNVector3(-1.0, 0.6, 0)
            scene.rootNode.addChildNode(key)

            let rim = SCNNode()
            rim.light = SCNLight()
            rim.light?.type = .directional
            rim.light?.intensity = 380
            rim.light?.color = NSColor(calibratedRed: 0.6, green: 0.7, blue: 1, alpha: 1)
            rim.eulerAngles = SCNVector3(0.5, Double.pi, 0)
            scene.rootNode.addChildNode(rim)
        }

        func update(spec: SurfaceSpec, autoRotate: Bool) {
            if spec != lastSpec {
                lastSpec = spec
                surfaceNode.removeFromParentNode()
                surfaceNode = Self.buildSurface(spec)
                pivot.addChildNode(surfaceNode)
            }
            if autoRotate != lastRotate {
                lastRotate = autoRotate
                pivot.removeAllActions()
                if autoRotate {
                    pivot.runAction(.repeatForever(.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 90)))
                }
            }
        }

        // MARK: Geometry

        private static func ramp(_ t: Double, hue: SurfaceHue) -> SIMD4<Float> {
            let stops: [SIMD3<Float>]
            switch hue {
            case .flow:
                stops = [SIMD3(0.06, 0.09, 0.26), SIMD3(0.24, 0.24, 0.78), SIMD3(0.28, 0.78, 1.0), SIMD3(0.96, 0.98, 1.0)]
            case .star:
                stops = [SIMD3(0.10, 0.08, 0.30), SIMD3(0.60, 0.22, 0.62), SIMD3(1.0, 0.55, 0.25), SIMD3(1.0, 0.92, 0.70)]
            case .cosmos:
                stops = [SIMD3(0.05, 0.12, 0.20), SIMD3(0.10, 0.45, 0.55), SIMD3(0.42, 0.86, 0.72), SIMD3(0.92, 1.0, 0.90)]
            }
            let x = Float(min(max(t, 0), 1)) * Float(stops.count - 1)
            let i = min(Int(x), stops.count - 2)
            let f = x - Float(i)
            let c = stops[i] * (1 - f) + stops[i + 1] * f
            return SIMD4(c.x, c.y, c.z, 1)
        }

        private static func buildSurface(_ spec: SurfaceSpec) -> SCNNode {
            let node = SCNNode()
            let n = spec.radii.count
            guard n > 2, spec.heights.count == n else { return node }
            let rMax = max(spec.radii.max() ?? 1, 1e-9)
            let scale = 10.0 / rMax
            let vScale = scale * spec.verticalScale
            let hMin = spec.heights.min() ?? 0, hMax = spec.heights.max() ?? 0
            let yOffset = -(hMin + hMax) / 2 * vScale
            let m = 128

            func height(_ i: Int) -> Double { spec.heights[i] * vScale + yOffset }

            var vertices: [SCNVector3] = []
            var normals: [SCNVector3] = []
            var colors: [Float] = []
            vertices.reserveCapacity(n * m)
            normals.reserveCapacity(n * m)
            colors.reserveCapacity(n * m * 4)

            for i in 0..<n {
                let r = spec.radii[i] * scale
                let h = height(i)
                let i0 = max(0, i - 1), i1 = min(n - 1, i + 1)
                let dr = (spec.radii[i1] - spec.radii[i0]) * scale
                let slope = dr > 0 ? (height(i1) - height(i0)) / dr : 0
                let norm = (1 + slope * slope).squareRoot()
                let tint = i < spec.tints.count ? spec.tints[i] : 0.5
                let col = ramp(tint, hue: spec.hue)
                for j in 0..<m {
                    let phi = Double(j) / Double(m) * 2 * Double.pi
                    let c = cos(phi), s = sin(phi)
                    vertices.append(SCNVector3(r * c, h, r * s))
                    normals.append(SCNVector3(-slope * c / norm, 1 / norm, -slope * s / norm))
                    colors.append(contentsOf: [col.x, col.y, col.z, col.w])
                }
            }

            var indices: [UInt32] = []
            indices.reserveCapacity((n - 1) * m * 6)
            for i in 0..<(n - 1) {
                for j in 0..<m {
                    let a = UInt32(i * m + j)
                    let b = UInt32(i * m + (j + 1) % m)
                    let c = UInt32((i + 1) * m + j)
                    let d = UInt32((i + 1) * m + (j + 1) % m)
                    indices.append(contentsOf: [a, c, b, b, c, d])
                }
            }

            let colorData = colors.withUnsafeBufferPointer { Data(buffer: $0) }
            let colorSource = SCNGeometrySource(
                data: colorData, semantic: .color, vectorCount: n * m,
                usesFloatComponents: true, componentsPerVector: 4,
                bytesPerComponent: MemoryLayout<Float>.size, dataOffset: 0,
                dataStride: MemoryLayout<Float>.size * 4
            )
            let geometry = SCNGeometry(
                sources: [SCNGeometrySource(vertices: vertices), SCNGeometrySource(normals: normals), colorSource],
                elements: [SCNGeometryElement(indices: indices, primitiveType: .triangles)]
            )
            let material = SCNMaterial()
            material.diffuse.contents = NSColor.white
            material.specular.contents = NSColor(white: 0.35, alpha: 1)
            material.shininess = 0.35
            material.lightingModel = .blinn
            material.isDoubleSided = true
            material.transparency = 0.96
            geometry.materials = [material]
            node.addChildNode(SCNNode(geometry: geometry))

            node.addChildNode(gridLines(spec: spec, scale: scale, height: height))

            for ring in spec.rings {
                guard let h = interpolatedHeight(ring.radius, spec: spec, vScale: vScale, yOffset: yOffset) else { continue }
                let torus = SCNTorus(ringRadius: ring.radius * scale, pipeRadius: ring.style == .horizon ? 0.06 : 0.04)
                let mat = SCNMaterial()
                let color: NSColor
                switch ring.style {
                case .horizon: color = NSColor(calibratedRed: 1, green: 0.35, blue: 0.45, alpha: 1)
                case .surface: color = NSColor(calibratedRed: 1, green: 0.75, blue: 0.35, alpha: 1)
                case .marker: color = NSColor(calibratedRed: 0.45, green: 0.95, blue: 0.75, alpha: 1)
                case .accent: color = NSColor(calibratedRed: 0.95, green: 0.95, blue: 1, alpha: 1)
                }
                mat.diffuse.contents = color
                mat.emission.contents = color
                mat.lightingModel = .constant
                torus.materials = [mat]
                let ringNode = SCNNode(geometry: torus)
                ringNode.position = SCNVector3(0, h + 0.03, 0)
                node.addChildNode(ringNode)
            }

            if spec.flow != .none {
                addTracers(to: node, spec: spec, scale: scale, height: height)
            }
            return node
        }

        private static func interpolatedHeight(_ r: Double, spec: SurfaceSpec, vScale: Double, yOffset: Double) -> Double? {
            guard let k = spec.radii.firstIndex(where: { $0 >= r }) else { return nil }
            if k == 0 { return spec.heights[0] * vScale + yOffset }
            let r0 = spec.radii[k - 1], r1 = spec.radii[k]
            let t = r1 > r0 ? (r - r0) / (r1 - r0) : 0
            let h = spec.heights[k - 1] * (1 - t) + spec.heights[k] * t
            return h * vScale + yOffset
        }

        private static func gridLines(spec: SurfaceSpec, scale: Double, height: (Int) -> Double) -> SCNNode {
            var points: [SCNVector3] = []
            var idx: [UInt32] = []
            let n = spec.radii.count
            let lift = 0.012
            // Radial meridians.
            let meridians = 24
            for j in 0..<meridians {
                let phi = Double(j) / Double(meridians) * 2 * Double.pi
                let base = UInt32(points.count)
                for i in 0..<n {
                    let r = spec.radii[i] * scale
                    points.append(SCNVector3(r * cos(phi), height(i) + lift, r * sin(phi)))
                    if i > 0 { idx.append(contentsOf: [base + UInt32(i - 1), base + UInt32(i)]) }
                }
            }
            // Parallels at evenly spaced radii.
            let parallels = 12
            let rMin = spec.radii.first ?? 0, rMax = spec.radii.last ?? 1
            for p in 1...parallels {
                let target = rMin + (rMax - rMin) * Double(p) / Double(parallels)
                guard let i = spec.radii.firstIndex(where: { $0 >= target }) else { continue }
                let r = spec.radii[i] * scale
                let h = height(i) + lift
                let base = UInt32(points.count)
                let seg = 96
                for k in 0..<seg {
                    let phi = Double(k) / Double(seg) * 2 * Double.pi
                    points.append(SCNVector3(r * cos(phi), h, r * sin(phi)))
                    idx.append(contentsOf: [base + UInt32(k), base + UInt32((k + 1) % seg)])
                }
            }
            let geometry = SCNGeometry(
                sources: [SCNGeometrySource(vertices: points)],
                elements: [SCNGeometryElement(indices: idx, primitiveType: .line)]
            )
            let mat = SCNMaterial()
            mat.diffuse.contents = NSColor(white: 1, alpha: 0.22)
            mat.lightingModel = .constant
            mat.blendMode = .add
            geometry.materials = [mat]
            return SCNNode(geometry: geometry)
        }

        private static func addTracers(to node: SCNNode, spec: SurfaceSpec, scale: Double, height: (Int) -> Double) {
            let n = spec.radii.count
            // Time along the path from dt = dR / β (coordinate flow speed), clamped.
            var times: [Double] = [0]
            for i in 1..<n {
                let dr = abs(spec.radii[i] - spec.radii[i - 1])
                let b = i < spec.speeds.count ? max(spec.speeds[i], 0.04) : 0.5
                times.append(times[i - 1] + dr / b)
            }
            let total = max(times.last ?? 1, 1e-9)
            let count = 36
            let sphere = SCNSphere(radius: 0.085)
            let mat = SCNMaterial()
            mat.diffuse.contents = NSColor.white
            mat.emission.contents = NSColor(calibratedRed: 0.75, green: 0.95, blue: 1, alpha: 1)
            mat.lightingModel = .constant
            sphere.materials = [mat]
            let duration = 7.0
            for k in 0..<count {
                let phi = Double(k) / Double(count) * 2 * Double.pi + Double(k % 3) * 0.07
                var values: [NSValue] = []
                var keyTimes: [NSNumber] = []
                let order: [Int] = spec.flow == .inward ? Array((0..<n).reversed()) : Array(0..<n)
                let stride = max(1, n / 60)
                for (q, i) in order.enumerated() where q % stride == 0 || q == order.count - 1 {
                    let r = spec.radii[i] * scale
                    values.append(NSValue(scnVector3: SCNVector3(r * cos(phi), height(i) + 0.09, r * sin(phi))))
                    let t = spec.flow == .inward ? (total - times[i]) / total : times[i] / total
                    keyTimes.append(NSNumber(value: t))
                }
                let anim = CAKeyframeAnimation(keyPath: "position")
                anim.values = values
                anim.keyTimes = keyTimes
                anim.duration = duration
                anim.repeatCount = .infinity
                anim.timeOffset = duration * Double(k) / Double(count) * 3.7
                anim.calculationMode = .linear
                let tracer = SCNNode(geometry: sphere)
                tracer.addAnimation(anim, forKey: "flow")
                node.addChildNode(tracer)
            }
        }
    }
}
