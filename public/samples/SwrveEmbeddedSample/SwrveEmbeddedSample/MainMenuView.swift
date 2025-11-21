import SwiftUI
import SwrveSDK

struct MainMenuView: View {
    @State private var path: [Route] = []
    @State private var showSetup = false

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 32) {
                    // Top Title
                    Text("Embedded Samples")
                        .font(.largeTitle).bold()
                        .padding(.top, 8)

                    // Primary buttons grouped
                    VStack(spacing: 16) {
                        SampleButton(title: "Carousel", color: .blue) {
                            path.append(.carousel)
                        }
                        SampleButton(title: "Offers", color: .green) {
                            path.append(.offers)
                        }
                        SampleButton(title: "Fixed Banner", color: .purple) {
                            path.append(.banner)
                        }
                        SampleButton(title: "Floating Banner", color: .orange) {
                            path.append(.floatingPromo)
                        }
                    }
                    .padding()
                    .background(.background)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)

                    Spacer()

                    // Lower emphasis row: only Setup button now
                    HStack(spacing: 12) {
                        Spacer(minLength: 8)
                        Button(action: { showSetup = true }) {
                            Text("Setup")
                                .font(.footnote.weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        .tint(.secondary)
                        .sheet(isPresented: $showSetup) { SetupView() }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .carousel: CarouselView()
                case .offers: OffersView()
                case .banner: FixedBannerView()
                case .floatingPromo: FloatingBannerView()
                }
            }
        }
    }

    private enum Route: Hashable { case carousel, offers, banner, floatingPromo }
}

// Reusable styled sample button.
private struct SampleButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(color.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .shadow(color: color.opacity(0.35), radius: 6, x: 0, y: 3)
    }
}
