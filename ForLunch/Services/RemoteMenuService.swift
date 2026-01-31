//
//  RemoteMenuService.swift
//  ForLunch
//
//  Fetches menu from the usa-school-menu API (separate backend).
//

import Foundation

enum RemoteMenuServiceError: Error {
    case invalidURL
    case noData
    case decodeError
}

/// Response from GET /api/menu?schoolId=...&date=YYYY-MM-DD
struct RemoteMenuResponse: Decodable {
    let breakfast: [String]
    let lunch: [String]
}

/// Fetches breakfast/lunch for a school/date from the usa-school-menu API.
final class RemoteMenuService {
    private let session: URLSession
    private let baseURL: String

    init(session: URLSession = .shared, baseURL: String? = nil) {
        self.session = session
        self.baseURL = baseURL ?? Self.effectiveBaseURL
    }

    /// Simulator uses localhost; device uses USA_SCHOOL_MENU_BASE_URL (set to your Mac’s IP).
    private static var effectiveBaseURL: String {
        #if targetEnvironment(simulator)
        return "http://localhost:3000"
        #else
        let fromPlist = (Bundle.main.infoDictionary?["USA_SCHOOL_MENU_BASE_URL"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return fromPlist ?? "http://localhost:3000"
        #endif
    }

    /// Current base URL used for API requests (for debugging / device setup).
    static var currentBaseURL: String { effectiveBaseURL }

    /// GET /api/menu?schoolId=xxx&date=YYYY-MM-DD
    func fetchMenu(schoolId: String, date: Date) async throws -> DayMenu {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        let dateKey = formatter.string(from: date)
        var components = URLComponents(string: "\(baseURL)/api/menu")
        components?.queryItems = [
            URLQueryItem(name: "schoolId", value: schoolId),
            URLQueryItem(name: "date", value: dateKey),
        ]
        guard let url = components?.url else { throw RemoteMenuServiceError.invalidURL }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw RemoteMenuServiceError.noData
        }
        let decoder = JSONDecoder()
        do {
            let body = try decoder.decode(RemoteMenuResponse.self, from: data)
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            return DayMenu(
                date: startOfDay,
                breakfastItems: body.breakfast,
                lunchItems: body.lunch
            )
        } catch {
            throw RemoteMenuServiceError.decodeError
        }
    }
}
