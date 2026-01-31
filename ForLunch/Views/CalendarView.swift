//
//  CalendarView.swift
//  ForLunch
//
//  Month grid, planning-oriented. Tap day → DayDetailBottomSheet.
//

import SwiftUI

struct CalendarView: View {
    let viewingDate: Date
    @Binding var surface: Surface
    @Binding var viewingDateBinding: Date
    let onSelectDate: (Date) -> Void
    let eventCountByDate: [String: Int] // "yyyy-MM-dd" → count (max 3 dots, then "+")

    private let calendar = Calendar.current
    private let weekdaySymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    private var monthStart: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: viewingDate)) ?? viewingDate
    }

    private var monthRange: (start: Date, count: Int) {
        guard let range = calendar.range(of: .day, in: .month, for: monthStart),
              let start = calendar.date(from: calendar.dateComponents([.year, .month], from: monthStart)) else {
            return (monthStart, 28)
        }
        let firstWeekday = calendar.component(.weekday, from: start) - 1
        let leadingEmpty = firstWeekday
        let totalCells = leadingEmpty + range.count
        let rows = (totalCells + 6) / 7
        return (start, rows * 7)
    }

    private func dateKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(monthYearString)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(DesignTokens.title)
                Spacer()
                Button {
                    surface = .today
                    viewingDateBinding = Date()
                } label: {
                    Text("Today")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(DesignTokens.date)
                }
            }
            .padding(.horizontal, 16)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 12) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(DesignTokens.date)
                }
                ForEach(0..<monthRange.count, id: \.self) { index in
                    let (start, _) = monthRange
                    let dayOffset = index - (calendar.component(.weekday, from: start) - 1)
                    if dayOffset >= 0,
                       let cellDate = calendar.date(byAdding: .day, value: dayOffset, to: start),
                       calendar.isDate(cellDate, equalTo: monthStart, toGranularity: .month) {
                        dayCell(date: cellDate)
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignTokens.background)
    }

    private var monthYearString: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: monthStart)
    }

    private func dayCell(date: Date) -> some View {
        let key = dateKey(date)
        let count = eventCountByDate[key] ?? 0
        let isSelected = calendar.isDate(date, inSameDayAs: viewingDate)
        let isToday = calendar.isDateInToday(date)

        return Button {
            onSelectDate(date)
        } label: {
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 15, weight: isToday ? .semibold : .regular))
                    .foregroundStyle(isSelected ? DesignTokens.background : DesignTokens.title)
                if count > 0 {
                    HStack(spacing: 2) {
                        ForEach(0..<min(count, 3), id: \.self) { _ in
                            Circle()
                                .fill(DesignTokens.EventAccent.academic)
                                .frame(width: 4, height: 4)
                        }
                        if count > 3 {
                            Text("+")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundStyle(DesignTokens.date)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(isSelected ? DesignTokens.mainItem : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
