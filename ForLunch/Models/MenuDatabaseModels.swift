//
//  MenuDatabaseModels.swift
//  ForLunch
//
//  Schema for PDF-sourced (or manually entered) menu data.
//  menus.json: schoolId -> date (YYYY-MM-DD) -> { "breakfast": [...], "lunch": [...] }
//

import Foundation

/// One day's menu in the database (breakfast and lunch item names).
struct DayMenuData: Decodable {
    let breakfast: [String]
    let lunch: [String]
}

/// Top-level menu database: school id -> date string -> DayMenuData.
/// Decoded from menus.json. Add entries when you add schools from PDFs.
typealias MenuDatabase = [String: [String: DayMenuData]]
