//
//  SchoolStorage.swift
//  ForLunch
//

import Foundation

/// Persists the user's list of schools (UserDefaults).
enum SchoolStorage {
    private static let key = "forlunch.schools"
    private static let legacyKey = "forlunch.selectedSchool"

    static func loadSchools() -> [School] {
        if let data = UserDefaults.standard.data(forKey: key),
           let schools = try? JSONDecoder().decode([School].self, from: data),
           !schools.isEmpty {
            return schools
        }
        if let data = UserDefaults.standard.data(forKey: legacyKey),
           let school = try? JSONDecoder().decode(School.self, from: data) {
            saveSchools([school])
            UserDefaults.standard.removeObject(forKey: legacyKey)
            return [school]
        }
        return []
    }

    static func saveSchools(_ schools: [School]) {
        guard let data = try? JSONEncoder().encode(schools) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    /// Adds a school to the list if not already present (by id).
    static func addSchool(_ school: School) {
        var list = loadSchools()
        if !list.contains(where: { $0.id == school.id }) {
            list.append(school)
            saveSchools(list)
        }
    }

    /// Removes a school from the list by id.
    static func removeSchool(id: String) {
        var list = loadSchools()
        list.removeAll { $0.id == id }
        saveSchools(list)
    }
}
