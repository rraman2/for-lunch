//
//  School.swift
//  ForLunch
//

import Foundation

struct School: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let districtName: String
    let stateCode: String
    /// Nutrislice API district subdomain (optional; omit for PDF/database-only schools)
    let nutrisliceDistrictSlug: String?
    /// Nutrislice API school path segment (optional; omit for PDF/database-only schools)
    let nutrisliceSchoolSlug: String?

    /// True if this school has Nutrislice slugs to try for live API.
    var hasNutrislice: Bool {
        guard let d = nutrisliceDistrictSlug, let s = nutrisliceSchoolSlug else { return false }
        return !d.isEmpty && !s.isEmpty
    }

    var state: SupportedState? {
        SupportedState.from(rawValue: stateCode)
    }

    var displayTitle: String {
        "\(name), \(districtName)"
    }
}
