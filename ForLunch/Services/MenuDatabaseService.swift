//
//  MenuDatabaseService.swift
//  ForLunch
//
//  Loads menu data from bundled menus.json (PDF-sourced or manually entered).
//  Use this as the primary source; Nutrislice can be a fallback for districts that expose it.
//

import Foundation

/// Returns menu for a school/date from the bundled menu database (e.g. from PDFs).
final class MenuDatabaseService {
    private var database: MenuDatabase = [:]

    init() {
        loadBundledMenus()
    }

    private func loadBundledMenus() {
        guard let url = Bundle.main.url(forResource: "menus", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(MenuDatabase.self, from: data) else {
            database = [:]
            return
        }
        database = decoded
    }

    /// Returns today's menu for the school from the database, or nil if not present.
    func menu(for schoolId: String, date: Date) -> DayMenu? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        let dateKey = formatter.string(from: date)
        guard let schoolDates = database[schoolId],
              let day = schoolDates[dateKey] else {
            return nil
        }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        return DayMenu(
            date: startOfDay,
            breakfastItems: day.breakfast,
            lunchItems: day.lunch
        )
    }

    /// Optional: find nearest date with data (e.g. same week) for a school. Not used by default.
    func nearestMenu(for schoolId: String, near date: Date) -> DayMenu? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        guard let schoolDates = database[schoolId], !schoolDates.isEmpty else { return nil }
        let dateKey = formatter.string(from: date)
        if let day = schoolDates[dateKey] {
            let calendar = Calendar.current
            return DayMenu(
                date: calendar.startOfDay(for: date),
                breakfastItems: day.breakfast,
                lunchItems: day.lunch
            )
        }
        // Same week: try a few days before/after
        let calendar = Calendar.current
        for offset in 1...3 {
            if let d = calendar.date(byAdding: .day, value: offset, to: date),
               let key = Optional(formatter.string(from: d)),
               let day = schoolDates[key] {
                return DayMenu(
                    date: calendar.startOfDay(for: d),
                    breakfastItems: day.breakfast,
                    lunchItems: day.lunch
                )
            }
            if let d = calendar.date(byAdding: .day, value: -offset, to: date),
               let key = Optional(formatter.string(from: d)),
               let day = schoolDates[key] {
                return DayMenu(
                    date: calendar.startOfDay(for: d),
                    breakfastItems: day.breakfast,
                    lunchItems: day.lunch
                )
            }
        }
        return nil
    }
}
