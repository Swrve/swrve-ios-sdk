import SwiftUI
import SwrveSDK

// Placeholder app shell used inside sample views.
struct DemoShellView: View {
    enum Tab { case home, offers, search, notifications, account }
    @State private var tab: Tab = .home
    private let floatingContent: AnyView?
    private let homeContent: AnyView?
    private let offersContent: AnyView?

    init(homeContent: AnyView? = nil, offersContent: AnyView? = nil, floatingContent: AnyView? = nil, selectedTab: Tab = .home) {
        self.homeContent = homeContent
        self.offersContent = offersContent
        self.floatingContent = floatingContent
        self._tab = State(initialValue: selectedTab)
    }

    var body: some View {
        TabView(selection: $tab) {
            TabHomeFeed(homeContent: homeContent, floatingContent: floatingContent)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(Tab.home)
            TabOffersView(offersContent: offersContent)
                .tabItem { Label("Offers", systemImage: "tag") }
                .tag(Tab.offers)
            TabSearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(Tab.search)
            TabNotificationsView()
                .tabItem { Label("Notifications", systemImage: "bell") }
                .tag(Tab.notifications)
            TabAccountView()
                .tabItem { Label("Account", systemImage: "person.crop.circle") }
                .tag(Tab.account)
        }
    }
}

// MARK: - Tabs
private struct TabHomeFeed: View {
    let homeContent: AnyView?
    let floatingContent: AnyView?

    var body: some View {
        // The home content is scrollable while `floatingContent` (if provided) is rendered as a fixed overlay at the top
        // so it remains visible while the user scrolls the feed.
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // If a homeContent is provided, render it at the top of the scrollable content so it scrolls with the feed.
                if let homeContent {
                    homeContent
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                }

                Text("Featured Products")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 6)
                HomeProductGrid()
                Divider().padding(.vertical, 16)
                Text("Recommended For You")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 6)
                HomeProductRow(count: 6)
            }
            .padding(.horizontal, 16)  // Keep a small top padding so content doesn't scroll under the navigation bar.
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        // Overlay the floating content so it stays fixed.
        .overlay(alignment: .top) {
            if let floatingContent {
                floatingContent
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(UIColor.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

private struct TabOffersView: View {
    let offersContent: AnyView?

    var body: some View {
        VStack {
            if let offersContent = offersContent {
                offersContent
            } else {
                Image(systemName: "tag")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)
                    .foregroundColor(.secondary)
                Text("No offers available")
                    .font(.title3.weight(.semibold))
                Text("Check back later for personalized offers.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(UIColor.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

private struct TabSearchView: View {
    @State private var query: String = ""
    var body: some View {
        VStack(spacing: 16) {
            TextField("Search products", text: $query)
                .textFieldStyle(.roundedBorder)
            if query.isEmpty {
                Text("Start typing to search the catalog.")
                    .foregroundColor(.secondary)
            } else {
                List(0..<5, id: \.self) { idx in
                    HStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 48, height: 48)
                            .overlay(Text(String(query.prefix(1))).font(.headline))
                        VStack(alignment: .leading) {
                            Text("Result #\(idx + 1) for \"\(query)\"")
                            Text("Short description...").font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
            }
            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(UIColor.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

private struct TabNotificationsView: View {
    var body: some View {
        List {
            Section("Today") {
                ForEach(0..<3, id: \.self) { i in
                    HStack(spacing: 12) {
                        Circle().fill(Color.orange.opacity(0.2)).frame(width: 34, height: 34)
                            .overlay(Image(systemName: "bell.fill").foregroundColor(.orange))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Price drop on item #\(i+1)").font(.subheadline.bold())
                            Text("Tap to view the updated offer.").font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }
            Section("Earlier") {
                ForEach(0..<5, id: \.self) { i in
                    HStack(spacing: 12) {
                        Circle().fill(Color.blue.opacity(0.2)).frame(width: 34, height: 34)
                            .overlay(Image(systemName: "tray.fill").foregroundColor(.blue))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Order update #\(1000 + i)").font(.subheadline.bold())
                            Text("We're processing your shipment.").font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(UIColor.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

private struct TabAccountView: View {
    var body: some View {
        Form {
            Section("Profile") {
                HStack {
                    Image(systemName: "person.crop.circle.fill").font(.system(size: 42))
                    VStack(alignment: .leading) {
                        Text("Jane Doe").font(.headline)
                        Text("jane@example.com").font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            Section("Settings") {
                Toggle(isOn: .constant(true)) { Text("Email Offers") }
                Toggle(isOn: .constant(false)) { Text("Push Promotions") }
                Toggle(isOn: .constant(true)) { Text("Dark Mode (Mock)") }
            }
            Section("About") {
                HStack {
                    Text("App Version")
                    Spacer()
                    Text("1.0.0").foregroundColor(.secondary)
                }
                HStack {
                    Text("Build")
                    Spacer()
                    Text("100").foregroundColor(.secondary)
                }
            }
            Section {
                Button(role: .destructive) {
                } label: {
                    Text("Sign Out")
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(UIColor.systemBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

// MARK: - Components
private struct HomeProductGrid: View {
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(0..<4, id: \.self) { idx in
                HomeProductCard(index: idx)
            }
        }
    }
}

private struct HomeProductRow: View {
    let count: Int
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(0..<count, id: \.self) { idx in
                    HomeProductMiniCard(index: idx)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

private struct HomeProductCard: View {
    let index: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(colors: [.blue.opacity(0.25), .purple.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(height: 120)
                Text("IMG \(index+1)").font(.caption.bold()).foregroundColor(.white.opacity(0.9))
            }
            Text("Product Title \(index+1)").font(.subheadline.bold())
            Text("$\(19 + index).99").font(.caption).foregroundColor(.secondary)
            Button(action: {
                _ = SwrveSDK.event("add_to_cart_product_\(index + 1)")
            }) {
                Text("Add to Cart").font(.caption.bold()).padding(.vertical, 6).frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(12)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

private struct HomeProductMiniCard: View {
    let index: Int
    var body: some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.orange.opacity(0.25))
                .frame(width: 90, height: 70)
                .overlay(Text("IMG").font(.caption.bold()).foregroundColor(.white))
            Text("Item \(index+1)").font(.caption)
            Text("$\(9 + index).99").font(.caption2).foregroundColor(.secondary)
        }
        .padding(8)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}
