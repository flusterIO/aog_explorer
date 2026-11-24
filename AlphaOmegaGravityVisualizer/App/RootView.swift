//
//  RootView.swift
//  AlphaOmegaGravityVisualizer
//

import Foundation
import SwiftUI

struct RootView: View {
    @Environment(NavigationModel.self) private var navigation
    @State private var showInspector = false

    var body: some View {
        @Bindable var navigation = navigation
        NavigationSplitView {
            Sidebar(selection: $navigation.page)
                .navigationSplitViewColumnWidth(min: 240, ideal: 270, max: 330)
        } detail: {
            PageHost(page: navigation.page ?? .home)
                .id(navigation.page ?? .home)
                .inspector(isPresented: $showInspector) {
                    ConstantsInspector()
                        .inspectorColumnWidth(min: 290, ideal: 320, max: 400)
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showInspector.toggle()
                        } label: {
                            Label("Constants", systemImage: "slider.horizontal.3")
                        }
                        .help("Universal constants (c, G, H₀, κ′, τ̂)")
                    }
                }
        }
    }
}

struct PageHost: View {
    let page: Page

    var body: some View {
        switch page {
        case .home: HomePage()
        case .lighthouse: LighthousePage()
        case .slope: SlopePage()
        case .interval: IntervalPage()
        case .flamm: FlammPage()
        case .distributions: DistributionsPage()
        case .fifthMetric: FifthMetricPage()
        case .fourPotential: FourPotentialPage()
        case .lapse: LapsePage()
        case .buchdahl: BuchdahlPage()
        case .orbits: OrbitsPage()
        case .frameDragging: FrameDraggingPage()
        case .river: RiverPage()
        case .cosmology: CosmologyPage()
        case .hypothesisM: HypothesisMPage()
        case .velocities: VelocitiesPage()
        case .fineStructure: FineStructurePage()
        case .starLab: StarLabPage()
        case .rapidity: RapidityPage()
        case .reference: ReferencePage()
        }
    }
}

// MARK: - Sidebar

struct Sidebar: View {
    @Binding var selection: Page?

    var body: some View {
        List(selection: $selection) {
            Section {
                NavigationLink(value: Page.home) {
                    Label(Page.home.title, systemImage: Page.home.systemImage)
                }
            } header: {
                SidebarBrand()
            }
            ForEach(PaperSection.allCases.filter { $0 != .overview }) { section in
                Section {
                    ForEach(Page.pages(in: section)) { page in
                        NavigationLink(value: page) {
                            Label {
                                Text(page.title)
                            } icon: {
                                Image(systemName: page.systemImage)
                                    .foregroundStyle(section.color)
                            }
                        }
                    }
                } header: {
                    Text(section.title)
                }
            }
        }
        .listStyle(.sidebar)
    }
}

private struct SidebarBrand: View {
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Theme.heroGradient)
                Text("γ")
                    .font(.system(size: 17, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
            }
            .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 0) {
                Text("Lorentz Slope")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("Interactive companion")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .textCase(nil)
        .padding(.vertical, 8)
    }
}

// MARK: - Inspector

struct ConstantsInspector: View {
    @Environment(ParameterStore.self) private var params

    var body: some View {
        @Bindable var params = params
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Universal constants").font(.title3.weight(.semibold))
                    Text("Shared by every page. Pages that work in units of r_s or GM/c² are unaffected.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ParameterSlider(title: "Speed of light", symbol: "c", value: $params.c, range: 1.0e8...6.0e8, unit: "m/s", format: { Fmt.sci($0, 5) })
                ParameterSlider(title: "Newton's constant", symbol: "G", value: $params.G, range: 1.0e-11...2.0e-10, scale: .log, unit: "m³/kg s²", format: { Fmt.sci($0, 5) })
                ParameterSlider(title: "Hubble constant", symbol: "H_0", value: $params.hubbleKmsMpc, range: 50...90, unit: "km/s/Mpc", format: { Fmt.fixed($0, 1) })
                ParameterSlider(title: "Acceleration-scale factor", symbol: "\\kappa'", value: $params.kappaPrime, range: 0.05...0.5, format: { Fmt.fixed($0, 4) })
                ParameterSlider(title: "Reference interval", symbol: "\\hat{\\tau}", value: $params.tauHat, range: 0.9...1.1, unit: "s", format: { Fmt.fixed($0, 4) })

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Derived").font(.headline)
                    InspectorRow(label: "cH₀", value: Fmt.sci(params.cH0, 3) + " m/s²")
                    InspectorRow(label: "g₀ = κ′cH₀", value: Fmt.sci(params.g0, 3) + " m/s²")
                    InspectorRow(label: "Hubble radius c/H₀", value: Fmt.sig(params.hubbleRadius / SI.Mpc, 4) + " Mpc")
                    InspectorRow(label: "Critical density ρ_c", value: Fmt.sci(params.criticalDensity, 3) + " kg/m³")
                    InspectorRow(label: "L_τ = cτ̂", value: Fmt.sig(params.lTau / SI.c, 4) + " light-seconds")
                    InspectorRow(label: "r_s of the Sun", value: Fmt.sig(params.schwarzschildRadius(SI.solarMass), 5) + " m")
                }

                Button {
                    withAnimation { params.reset() }
                } label: {
                    Label("Reset to measured values", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!params.isModified)
            }
            .padding(20)
        }
    }
}

private struct InspectorRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).monospacedDigit()
        }
        .font(.callout)
    }
}
