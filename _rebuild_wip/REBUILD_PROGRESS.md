# Visualizer rebuild — progress notes

Goal: rebuild `AlphaOmegaGravityVisualizer` around the manuscript *"The Lorentz Factor as the Slope of an Additional Spatial Coordinate: Embedding, Painlevé–Gullstrand Flow, and the Issue of Simultaneity"* (`main.tex`, Nov 2026), with many pages, a clean macOS 26 UI, and screenshot-ready visuals.

## Where things are

- New sources (work in progress) are in **`_rebuild_wip/src/`** at the repo root. That's outside the synced target folder, so Xcode does **not** compile them yet.
- The old app is untouched and still builds.
- Project facts: synced folders (`PBXFileSystemSynchronizedRootGroup`), Swift 5 mode, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `MemberImportVisibility` on (import every module you use in each file), deployment target macOS 26, SwiftMath linked directly.
- The new code doesn't import the `AlphaOmegaGravity` package. LaTeX renders through `SwiftMath.MathImage`.

## Done (written, not yet compiled)

| Folder | Files |
|---|---|
| `App/` | `AlphaOmegaGravityVisualizerApp.swift`, `RootView.swift` (split view, sidebar, `PageHost`, constants inspector), `Page.swift` (20 pages in 8 sections, with paper refs) |
| `Model/` | `Units`, `ParameterStore` (global c, G, H₀, κ′, τ̂ + `NavigationModel`), `Relativity` (Lorentz slope, slices, Gauss curvature, numerical lapse integration, `UniformStar`), `Orbits` (V_eff, RK4 orbit + precession, frame dragging, cosmology), `Galaxy` (Eilers 2019 data, rescaled baryon model, RAR, χ², g₀ fit), `NumericalObservations` (Appendix A), `StarLab` (TOV for ρ ∝ (1−x²)ⁿ; checked in Python: n=0 → 8/9, n=1 → 0.772) |
| `Design/` | `Theme` (colours, `ClaimStatus` badges), `Equation` (SwiftMath + cache, `Fmt` formatting), `Components` (Card, TitledCard, StatusBadge, EquationCard, Readout, Callout, …), `Controls` (ParameterSlider lin/log, ChoicePicker, `ControlPanel`), `PageScaffold` |
| `Visuals/` | `EmbeddingSceneView` (SceneKit surface of revolution, rings, flow tracers timed by β), `Diagrams` (slope triangle, Minkowski hyperbola, lighthouse/clock-tower), `FlowViews` (river flow animation, orbit canvas, vector field) |
| `Pages/` | `Shared` (SceneCard, StageCard, ChartCard, `glassChip`, `standardChartStyle`, `sample`), `HomePage`, `KinematicsPages` (Lighthouse, Slope, Interval), `GeometryPages` (Flamm, Distributions, FifthMetric, FourPotential), `DynamicsPages` (Lapse + ForeshorteningDiagram, Buchdahl, Orbits, FrameDragging), `FlowPages` (River, Cosmology) |

## Left to do

1. **Write the remaining pages.** `PageHost` already references these, so the project won't build until they exist.
   - `HypothesisMPage`: rotation curve (Eilers points, v_orbit = √(2GM/R), Newtonian, Hypothesis M with `params.g0`, best fit via `GalacticDynamics.fitG0`); required mass v²R/2G vs the model; RAR plot; g₀(z) = κ′cH(z); BTFR readout; the Derived / Assumed / Not claimed / What would count against it callouts. Sliders: baryon scale s and fractional error f. Note in the UI that Eilers per-point errors aren't bundled, so χ² uses a uniform fractional error.
   - `VelocitiesPage`: body picker (`Body.all`), v_cosmo, v_kinematic, √2 ratio, CMB dipole (369.82 km/s), v_kinematic vs L_τ (τ̂). Tag everything `.numerical`.
   - `FineStructurePage`: ω = δ^{1/3} vs α(2−α); `FineStructureAlignments.gravityFits`; v(γ_em) = 371,721 m/s; ω vs density with the α … α(2−α) band; caveats from App. A.7.
   - `StarLabPage`: exponent n and compactness sliders, `StarLab.solve` charts (ρ, β², p, N, y), 3D embedding, critical-compactness readout (`criticalCompactness`).
   - `RapidityPage`: compose β₁ ⊕ β₂; slopes sinh(η₁ + η₂); stacked triangles.
   - `ReferencePage`: Table 1 and Table 3 dictionaries plus the `ClaimStatus` legend.
2. **Global fix-ups.** Replace `\tfrac` with `\frac` (SwiftMath may not support it), and `Text(.init(` with `Text(LocalizedStringKey(`.
3. **Install.**
   - Move the old `features/`, `ContentView.swift` and the old `AlphaOmegaGravityVisualizerApp.swift` out of the target folder into `legacy_v1/` at the repo root.
   - Copy `_rebuild_wip/src/*` into `AlphaOmegaGravityVisualizer/AlphaOmegaGravityVisualizer/`.
   - Leave the stray `.app` bundle alone.
4. **Build in Xcode and fix compile errors.** The code was written without a compiler. The APIs most likely to need fixes:
   - `.glassEffect(.regular, in: .rect(cornerRadius:))` (only in `Shared.swift`, `glassChip`)
   - `MathImage(latex:fontSize:textColor:).asImage()`
   - `RectangleMark` / `RuleMark` initialisers
   - `chartXScale(type: .log)`
   - `SCNVector3` with Double values
5. **Polish.** Update the README with new screenshots and the page list. Optionally use computer use to build, run and capture screenshots.

## Verified numbers (Python, to match the paper)

| Quantity | Value |
|---|---|
| v_cosmo (Earth, R = 6378.1 km) | 525,493 m/s |
| v_kinematic (Earth) | 371,580 m/s |
| ω⊕ | 0.014538 = α(2−α) − 0.025% |
| Sun: (½δ)^{1/3} | α + 0.47% |
| v(γ_em) | 371,721 m/s |
| v_orbit (8.12 kpc, 4.44 × 10¹⁰ M☉) | 216.87 km/s |
| Frame dragging, polar-orbit average (Gravity Probe B orbit) | 40.8 mas/yr |
| Mercury perihelion advance | 42.98″/century |
| cH₀ | 6.80 × 10⁻¹⁰ m/s² |
| Baryon model v_orbit | 233 → 143 km/s over 5.3–24.8 kpc |
| Best-fit g₀/cH₀ (5% error) | ≈ 0.28 / 0.17 / 0.12 for s = 1 / 1.31 / 1.6 |
