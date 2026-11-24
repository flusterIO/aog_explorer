//
//  PageScaffold.swift
//  AlphaOmegaGravityVisualizer
//

import Foundation
import SwiftUI

/// Standard page layout: eyebrow, title, subtitle, then content in a centred column.
struct PageScaffold<Content: View>: View {
    let page: Page
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                content
            }
            .padding(Theme.pagePadding)
            .frame(maxWidth: Theme.maxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.automatic)
        .navigationTitle(page.title)
        .navigationSubtitle(page.paperReference)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: page.systemImage)
                Text(page.section.title.uppercased())
                    .tracking(1.2)
                Text("·").foregroundStyle(.tertiary)
                Text(page.paperReference)
                    .foregroundStyle(.secondary)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(page.section.color)

            Text(page.title)
                .font(.system(size: 34, weight: .bold, design: .default))

            Text(page.subtitle)
                .font(.title3)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 4)
    }
}
