//
//  SupportedState.swift
//  ForLunch
//

import Foundation

/// States where the app is launched (9-state rollout).
enum SupportedState: String, CaseIterable, Identifiable {
    case california = "CA"
    case colorado = "CO"
    case maine = "ME"
    case massachusetts = "MA"
    case michigan = "MI"
    case minnesota = "MN"
    case newMexico = "NM"
    case vermont = "VT"

    var id: String { rawValue }

    var fullName: String {
        switch self {
        case .california: return "California"
        case .colorado: return "Colorado"
        case .maine: return "Maine"
        case .massachusetts: return "Massachusetts"
        case .michigan: return "Michigan"
        case .minnesota: return "Minnesota"
        case .newMexico: return "New Mexico"
        case .vermont: return "Vermont"
        }
    }

    static func from(rawValue value: String) -> SupportedState? {
        SupportedState(rawValue: value.uppercased())
    }
}
