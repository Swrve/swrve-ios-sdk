import Foundation
import SwiftUI

let EMBEDDED_SCHEMA_VERSION = 1

/// Title / body text block (text + color).
struct EmbeddedTextBlock: Codable {
    let text: String?
    let color: String?

    enum CodingKeys: String, CodingKey { case text, color }
}

/// Call-to-action metadata (button / tappable chip styling + destination).
struct EmbeddedDataCTA: Codable {
    let text: String?
    let url: String?
    let color: String?
    let backgroundColor: String?
    enum CodingKeys: String, CodingKey {
        case text, url, color
        case backgroundColor = "background_color"
    }
}

/// Model decoded from Swrve embedded campaign `data` JSON for carousel, offer, and banner.
struct EmbeddedData: Codable {
    let version: Int?  // defaults to 1 when absent
    /// Payload type (carousel, offer, banner, floating_banner, etc.)
    let type: String?
    /// Optional title block (text + color).
    let title: EmbeddedTextBlock?
    /// Optional body/secondary text block.
    let body: EmbeddedTextBlock?
    /// Primary image asset URL.
    let image: String?
    /// Background fill color for card/banner surface.
    let backgroundColor: String?
    /// Layout dispatch token (e.g. tall_card, image_only_card, compact_card, left_aligned_banner, centered_banner, right_aligned_banner).
    let layout: String?
    /// Optional call to action metadata.
    let cta: EmbeddedDataCTA?
    /// Display ordering / priority (lower numbers appear first).
    let displayOrder: Int?

    enum CodingKeys: String, CodingKey {
        case version, type, title, body, image, layout, cta
        case backgroundColor = "background_color"
        case displayOrder = "display_order"
    }
}

struct EmbeddedDataFloatingBanner: Codable {
    let version: Int?  // defaults to 1 when absent
    /// Payload type should be "floating_banner".
    let type: String?
    /// Collapsed (minimized) presentation.
    let collapsed: CollapsedBanner?
    /// Expanded (full) presentation.
    let expanded: ExpandedBanner?
    /// Placement hint (e.g. top / bottom).
    let location: String?
    /// Background surface color.
    let backgroundColor: String?
    /// Primary image asset URL.
    let image: String?
    /// Display ordering / priority (lower numbers appear first / higher priority).
    let displayOrder: Int?

    enum CodingKeys: String, CodingKey {
        case version, type, collapsed, expanded, location, image
        case backgroundColor = "background_color"
        case displayOrder = "display_order"
    }

    /// Collapsed banner.
    struct CollapsedBanner: Codable {
        let title: EmbeddedTextBlock?
        let body: EmbeddedTextBlock?
        enum CodingKeys: String, CodingKey { case title, body }
    }

    /// Expanded banner.
    struct ExpandedBanner: Codable {
        let title: EmbeddedTextBlock?
        let body: EmbeddedTextBlock?
        let helperText: EmbeddedTextBlock?
        let cta: EmbeddedDataCTA?
        enum CodingKeys: String, CodingKey {
            case title, body, cta
            case helperText = "helper_text"
        }
    }
}
