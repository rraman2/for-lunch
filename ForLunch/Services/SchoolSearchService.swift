//
//  SchoolSearchService.swift
//  ForLunch
//

import Foundation

/// Loads and filters schools from bundled JSON (only supported states).
final class SchoolSearchService {
    private var allSchools: [School] = []
    private let supportedStateCodes: Set<String>

    init() {
        self.supportedStateCodes = Set(SupportedState.allCases.map(\.rawValue))
        loadBundledSchools()
    }

    private func loadBundledSchools() {
        guard let url = Bundle.main.url(forResource: "schools", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([School].self, from: data) else {
            allSchools = []
            return
        }
        allSchools = decoded.filter { supportedStateCodes.contains($0.stateCode) }
    }

    /// Search by school or district name (case-insensitive), only in launch states.
    func search(query: String) -> [School] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return allSchools }
        return allSchools.filter {
            $0.name.lowercased().contains(q) ||
            $0.districtName.lowercased().contains(q) ||
            $0.stateCode.lowercased() == q ||
            ($0.state?.fullName.lowercased().contains(q) == true)
        }
    }

    /// All schools in supported states (for pull-down / list).
    func allSchoolsInLaunchStates() -> [School] {
        allSchools
    }

    func schools(byState state: SupportedState) -> [School] {
        allSchools.filter { $0.stateCode == state.rawValue }
    }
}
