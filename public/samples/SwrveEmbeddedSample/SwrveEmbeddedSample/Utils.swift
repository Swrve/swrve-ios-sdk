import SwiftUI

// Shared utilities for the embedded samples. Put small, commonly reused helpers here
// (color parsing, simple remote image view, and string color fallbacks).

extension Color {
    /// Initialize a Color from a hex string like "#RRGGBB", "#AARRGGBB", "RRGGBB", "AARRGGBB", or "RGB"
    init(hex: String) {
        var string = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if string.hasPrefix("#") { string.removeFirst() }

        var int: UInt64 = 0
        Scanner(string: string).scanHexInt64(&int)

        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64

        switch string.count {
        case 3:  // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  // RRGGBB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  // AARRGGBB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0)
    }

    /// Failable initializer that returns nil for invalid hex strings. Use when caller wants to
    /// detect malformed inputs and handle fallbacks explicitly.
    init?(hexIfValid hex: String) {
        var string = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if string.hasPrefix("#") { string.removeFirst() }
        guard string.count == 3 || string.count == 6 || string.count == 8 else { return nil }
        var int: UInt64 = 0
        guard Scanner(string: string).scanHexInt64(&int) else { return nil }

        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64

        switch string.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0)
    }
}

// Convenience helpers used across the sample views
extension Optional where Wrapped == String {
    func colorOr(_ fallback: Color) -> Color {
        guard let hex = self else { return fallback }
        return Color(hex: hex)
    }
}

extension String {
    func colorOr(_ fallback: Color) -> Color {
        // Use the non-failable initializer; if the string is malformed the initializer will
        // produce a sensible fallback color (black) — callers can still use the failable
        // `Color(hexIfValid:)` if they wish to detect malformed input.
        Color(hex: self)
    }
}

// Small shared remote image view used by Banner and Carousel samples
struct RemoteImage: View {
    let urlString: String
    var body: some View {
        if let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.08)
                        ProgressView()
                    }
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    ZStack {
                        Color.gray.opacity(0.1)
                        Image(systemName: "photo").foregroundColor(.secondary)
                    }
                @unknown default:
                    Color.gray.opacity(0.1)
                }
            }
        } else {
            ZStack {
                Color.gray.opacity(0.1)
                Image(systemName: "photo").foregroundColor(.secondary)
            }
        }
    }
}
