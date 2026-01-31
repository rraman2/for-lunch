//
//  MenuModels.swift
//  ForLunch
//

import Foundation

/// Response from Nutrislice menu week API.
struct NutrisliceMenuWeek: Decodable {
    let startDate: String?
    let published: Bool?
    let days: [NutrisliceMenuDay]?

    enum CodingKeys: String, CodingKey {
        case startDate = "start_date"
        case published
        case days
    }
}

struct NutrisliceMenuDay: Decodable {
    let date: String?
    let menuItems: [NutrisliceMenuItem]?

    enum CodingKeys: String, CodingKey {
        case date
        case menuItems = "menu_items"
    }
}

struct NutrisliceMenuItem: Decodable {
    let name: String?
    let description: String?
    let id: Int?

    var displayName: String {
        name ?? "Item"
    }
}

/// App-level model for a day's menu (breakfast + lunch).
struct DayMenu {
    let date: Date
    let breakfastItems: [String]
    let lunchItems: [String]

    static var empty: DayMenu {
        DayMenu(date: Date(), breakfastItems: [], lunchItems: [])
    }
}

// MARK: - Display item (main + optional secondary + optional chip)

enum MenuItemModifier: String {
    case vegetarian = "Vegetarian"
    case dailyOption = "Daily Option"
}

struct ParsedMenuItem {
    let main: String
    let secondary: String?
    let modifier: MenuItemModifier?

    /// Parses a raw menu string, e.g. "Turkey & Cheese Sandwich + Goldfish Crackers" or "Veggie Tenders (Vegetarian)" or "Cereal (daily option)".
    static func parse(_ raw: String) -> ParsedMenuItem {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        var modifier: MenuItemModifier? = nil
        for (pattern, mod) in [
            (" (Vegetarian)", MenuItemModifier.vegetarian),
            (" (vegetarian)", MenuItemModifier.vegetarian),
            (" (daily option)", MenuItemModifier.dailyOption),
            (" (Daily option)", MenuItemModifier.dailyOption),
            (" (Daily Option)", MenuItemModifier.dailyOption),
        ] {
            if text.hasSuffix(pattern) {
                text = String(text.dropLast(pattern.count)).trimmingCharacters(in: .whitespaces)
                modifier = mod
                break
            }
        }
        let parts = text.split(separator: "+", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        let main = parts.first ?? text
        let secondary = parts.count > 1 ? parts[1] : nil
        return ParsedMenuItem(main: main, secondary: secondary, modifier: modifier)
    }
}
