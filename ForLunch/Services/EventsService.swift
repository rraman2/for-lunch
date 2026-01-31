//
//  EventsService.swift
//  ForLunch
//
//  Events for date-based surface. Returns empty until backend/source exists.
//

import Foundation

/// Events for a given date (all schools). Placeholder: returns [] until real source.
final class EventsService {
    func events(for date: Date, schoolIds: [String]) async -> [Event] {
        // No backend yet; return empty so UI (Events section, calendar dots) is in place.
        return []
    }
}
