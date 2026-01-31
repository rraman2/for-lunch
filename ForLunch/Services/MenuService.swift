//
//  MenuService.swift
//  ForLunch
//

import Foundation

enum MenuServiceError: Error {
    case invalidURL
    case noData
    case decodeError
}

/// Fetches breakfast and lunch menus from Nutrislice API for a given school and date.
final class MenuService {
    private let session: URLSession
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy/MM/dd"
        f.timeZone = TimeZone.current
        return f
    }()

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Builds Nutrislice menu week URL.
    /// Example: https://sterlingpublicschools.api.nutrislice.com/menu/api/weeks/school/washington-elementary-school/menu-type/lunch/2023/05/17
    private func menuURL(districtSlug: String, schoolSlug: String, menuType: String, date: Date) -> URL? {
        let ymd = dateFormatter.string(from: date).split(separator: "/")
        guard ymd.count == 3 else { return nil }
        let path = "https://\(districtSlug).api.nutrislice.com/menu/api/weeks/school/\(schoolSlug)/menu-type/\(menuType)/\(ymd[0])/\(ymd[1])/\(ymd[2])"
        return URL(string: path)
    }

    func fetchMenuWeek(districtSlug: String, schoolSlug: String, menuType: String, date: Date) async throws -> NutrisliceMenuWeek {
        guard let url = menuURL(districtSlug: districtSlug, schoolSlug: schoolSlug, menuType: menuType, date: date) else {
            throw MenuServiceError.invalidURL
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw MenuServiceError.noData
        }
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(NutrisliceMenuWeek.self, from: data)
        } catch {
            throw MenuServiceError.decodeError
        }
    }

    /// Fetches breakfast and lunch from Nutrislice for the given school and date. Requires school to have Nutrislice slugs.
    func fetchDayMenu(school: School, date: Date) async throws -> DayMenu {
        guard let districtSlug = school.nutrisliceDistrictSlug, let schoolSlug = school.nutrisliceSchoolSlug else {
            throw MenuServiceError.invalidURL
        }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let lunchWeek = try await fetchMenuWeek(
            districtSlug: districtSlug,
            schoolSlug: schoolSlug,
            menuType: "lunch",
            date: startOfDay
        )
        let breakfastWeek = try await fetchMenuWeek(
            districtSlug: districtSlug,
            schoolSlug: schoolSlug,
            menuType: "breakfast",
            date: startOfDay
        )

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        let targetDate = formatter.string(from: startOfDay)

        let lunchDay = lunchWeek.days?.first { $0.date == targetDate }
        let breakfastDay = breakfastWeek.days?.first { $0.date == targetDate }

        let lunchItems = lunchDay?.menuItems?.map { $0.displayName } ?? []
        let breakfastItems = breakfastDay?.menuItems?.map { $0.displayName } ?? []

        return DayMenu(
            date: startOfDay,
            breakfastItems: breakfastItems,
            lunchItems: lunchItems
        )
    }
}
