//
//  Event.swift
//  ForLunch
//
//  Time-bound school info: same mental model as lunch. Color classifies, does not prioritize.
//

import Foundation

/// Event type drives left-accent color only. Do not rank importance.
enum EventType: String, Codable, CaseIterable {
    case academic
    case sports
    case arts
    case admin
    case district
}

struct Event: Identifiable {
    let id: String
    let title: String
    let schoolName: String
    let startTime: Date?
    let endTime: Date?
    let isAllDay: Bool
    let type: EventType
    let location: String?
    let audience: String?

    /// Metadata line: "8:30–9:15 AM · School Name" or "All day · School Name"
    func metadataLine(timeFormatter: DateFormatter) -> String {
        if isAllDay || (startTime == nil && endTime == nil) {
            return "All day · \(schoolName)"
        }
        guard let start = startTime else { return schoolName }
        if let end = endTime {
            return "\(timeFormatter.string(from: start))–\(timeFormatter.string(from: end)) · \(schoolName)"
        }
        return "\(timeFormatter.string(from: start)) · \(schoolName)"
    }

    /// Optional secondary: "Location · Audience"
    var secondaryLine: String? {
        let parts = [location, audience].compactMap { $0 }.filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
