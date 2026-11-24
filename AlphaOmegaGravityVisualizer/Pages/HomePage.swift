//
//  HomePage.swift
//  AlphaOmegaGravityVisualizer
//

import Foundation
import SwiftUI

struct HomePage: View {
    @Environment(NavigationModel.self) private var navigation

    private let slice = Embedding.exteriorSlice(rMax: 14, count: 170)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 36) {
                hero
                coreRelations
                sectionMap
                statusLegend
            }
            .padding(Theme.pagePadding)
            .frame(maxWidth: Theme.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Overview")
    }

    // MARK: Hero

    private var hero: some View {
        HStack(alignment: .center, spacing: 32) {
            VStack(alignment: .leading, spacing: 18) {
                Text("INTERACTIVE COMPANION TO THE MANUSCRIPT")
                    .font(.caption.weight(.semibold))
                    .tracking(1.4)
                    .foregroundStyle(.secondary)
                Text("The Lorentz Factor as the Slope of an Additional Spatial Coordinate")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(Theme.heroGradient)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Embedding, Painlevé–Gullstrand Flow, and the Issue of Simultaneity")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Andrew Mueller · Independent Researcher")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                HStack(spacing: 4) {
                    Text("Read the full paper on")
                        .foregroundStyle(.secondary)
                    Link("Zenodo", destination: URL(string: "https://zenodo.org/records/24451649")!)
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.tint)
                }
                .font(.callout)

                Card {
                    VStack(alignment: .leading, spacing: 10) {
                        Equation("\\gamma = \\sqrt{1+(\\partial_x y)^2}", size: 30)
                        Text("A Kaluza–Klein-like construction in which the extra coordinate y is not compactified. Where it can be checked, it is equivalent to general relativity; one explicit hypothesis goes beyond it.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: 560)

                HStack(spacing: 10) {
                    Button {
                        navigation.go(.slope)
                    } label: {
                        Label("Start with γ as a slope", systemImage: "arrow.right.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    Button {
                        navigation.go(.flamm)
                    } label: {
                        Label("See the embedding", systemImage: "cube.transparent")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            SceneCard(spec: .from(slice, rings: [SurfaceRing(radius: 1.5, style: .marker), SurfaceRing(radius: 3, style: .accent)], flow: .inward), height: 520) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Flamm embedding of a static slice")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Equation("y(R) = 2\\sqrt{r_s(R-r_s)}", size: 16, color: .white)
                    Text("Tracers move at the river velocity βc = √(2GM/R)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .glassChip(cornerRadius: 14)
            }
            .frame(maxWidth: 620)
        }
    }

    // MARK: Core relations

    private var coreRelations: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(title: "Four relations", subtitle: "The spine of the paper, each tagged with its status.")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                EquationCard(
                    title: "Lorentz factor as a slope",
                    latex: "\\gamma=\\sqrt{1+(\\partial_x y)^2},\\quad \\partial_x y=\\beta\\gamma=\\sinh\\eta",
                    status: .identity,
                    note: "The right triangle of Fig. 1 is the hyperbolic identity cosh²η = 1 + sinh²η, used as the slope of an embedding.",
                    reference: "§2.2"
                )
                EquationCard(
                    title: "One relation for binding and expansion",
                    latex: "\\beta^2(R)=\\frac{2G\\,m(R)}{c^2R}",
                    status: .imported,
                    note: "The Hamiltonian constraint, written through the Hessian of y. Inward for a bound mass, outward for the Hubble flow.",
                    reference: "§2.4.4"
                )
                EquationCard(
                    title: "Lapse from the embedding",
                    latex: "N=\\frac{1}{\\gamma}=\\cos\\theta=\\sqrt{1-\\frac{r_s}{R}}",
                    status: .derived,
                    note: "In a static vacuum region the Gauss equation plus the second static field equation fix the lapse — the redshift is the foreshortening of the slice.",
                    reference: "§2.5"
                )
                EquationCard(
                    title: "Hypothesis M",
                    latex: "g_0=\\kappa' c H_0,\\qquad \\left(\\frac{v}{c}\\right)^4=\\frac{\\kappa'}{2}\\beta_N^2\\beta_H",
                    status: .hypothesis,
                    note: "Horizon-limited Machian inertia gives a flat rotation curve with v⁴ ∝ M, normalised by the expansion rate.",
                    reference: "§3"
                )
            }
        }
    }

    // MARK: Map

    private var sectionMap: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(title: "Explore the paper", subtitle: "Every page is live: drag a slider and every plot, surface and readout updates.")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280), spacing: 16)], spacing: 16) {
                ForEach(PaperSection.allCases.filter { $0 != .overview }) { section in
                    SectionTile(section: section) { navigation.go($0) }
                }
            }
        }
    }

    private var statusLegend: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(title: "Reading the badges", subtitle: "The paper separates identities, results recovered from GR, assumptions, hypotheses and numerical alignments. So does this app.")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 12)], alignment: .leading, spacing: 12) {
                ForEach(ClaimStatus.allCases) { status in
                    HStack(alignment: .top, spacing: 10) {
                        StatusBadge(status: status)
                        Text(status.blurb)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

private struct SectionTile: View {
    let section: PaperSection
    let open: (Page) -> Void
    @State private var hovering = false

    var body: some View {
        let pages = Page.pages(in: section)
        Button {
            if let first = pages.first { open(first) }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: pages.first?.systemImage ?? "circle")
                        .font(.title2)
                        .foregroundStyle(section.color)
                        .frame(width: 40, height: 40)
                        .background(section.color.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .foregroundStyle(.tertiary)
                }
                Text(section.title).font(.headline)
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(pages) { page in
                        Text("· " + page.title)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
            .background {
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .fill(.background.secondary)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .strokeBorder(section.color.opacity(hovering ? 0.6 : 0.1), lineWidth: 1)
            }
            .scaleEffect(hovering ? 1.01 : 1)
            .animation(.snappy(duration: 0.18), value: hovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
