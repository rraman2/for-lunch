//
//  DesignTokens.swift
//  ForLunch
//
//  Design spec: grok-first, ≤3 seconds. Dark mode #121212.
//

import SwiftUI

enum DesignTokens {
    // Background
    static let background = Color(hex: 0x121212)
    static let cardBackground = Color(hex: 0x1C1C1E)

    // Text
    static let title = Color(hex: 0xFFFFFF)
    static let date = Color(hex: 0xA1A1A1)
    /// School name: clearer neutral contrast (#C7C7CC). Neutral = calm; no brand/green/white (no action or priority).
    static let schoolName = Color(hex: 0xC7C7CC)
    static let mealHeader = Color(hex: 0xFFFFFF)
    static let mealHeaderSecondary = Color(hex: 0xEDEDED)
    static let mainItem = Color(hex: 0xFFFFFF)
    static let secondaryItem = Color(hex: 0xB3B3B3)

    // Chips (descriptive only)
    enum Chip {
        static let vegetarianText = Color(hex: 0x2ECC71)
        static let vegetarianBg = Color(hex: 0x1F3A2B)
        static let dailyOptionText = Color(hex: 0xFFD166)
        static let dailyOptionBg = Color(hex: 0x3A2F12)
    }

    // Events (left-accent only; color classifies, does not prioritize)
    static let eventsSectionHeaderSize: CGFloat = 18
    static let eventCardAccentWidth: CGFloat = 4
    static let eventCardPadding: CGFloat = 16
    enum EventAccent {
        static let academic = Color(hex: 0x6B7B8C)   // blue-gray
        static let sports = Color(hex: 0x2ECC71)    // green
        static let arts = Color(hex: 0x9B59B6)      // purple
        static let admin = Color(hex: 0x8E8E93)     // neutral gray
        static let district = Color(hex: 0xE67E22)   // orange
    }

    // Header (Figma: date-first, no divider)
    static let headerPrimarySize: CGFloat = 22
    static let headerSecondarySize: CGFloat = 13
    static let headerPrimaryToSecondary: CGFloat = 4

    // Layout (header height must fit: primary 22pt + spacing + secondary 13pt + nav row 44pt)
    static let headerHeight: CGFloat = 96
    static let cardCornerRadius: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 12
    static let mealHeaderToItems: CGFloat = 12
    static let itemRowSpacing: CGFloat = 10
    /// School name as section label: breathing room so role is clear.
    static let schoolNameTopMargin: CGFloat = 14   // from header (12–16)
    static let schoolNameBottomMargin: CGFloat = 18 // before first card (16–20)
}

extension Color {
    init(hex: Int) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
