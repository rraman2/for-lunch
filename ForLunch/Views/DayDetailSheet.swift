//
//  DayDetailSheet.swift
//  ForLunch
//
//  Bottom sheet (50–70%): date header, events (same cards as Today), Lunch/Breakfast collapsed.
//

import SwiftUI

struct DayDetailSheet: View {
    let date: Date
    let events: [Event]
    let schools: [School]
    let menusBySchoolId: [String: DayMenu]
    let onDismiss: () -> Void

    @State private var mealsExpanded = false
    private let calendar = Calendar.current

    private static var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignTokens.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(Self.dateFormatter.string(from: date))
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(DesignTokens.title)
                            .padding(.bottom, 8)

                        EventsSectionView(events: events, date: date, isExpanded: !events.isEmpty)

                        mealsSection
                    }
                    .padding(16)
                    .padding(.bottom, 32)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignTokens.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { onDismiss() }
                        .foregroundStyle(DesignTokens.title)
                }
            }
        }
    }

    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                mealsExpanded.toggle()
            } label: {
                HStack {
                    Text("Lunch & Breakfast")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DesignTokens.title)
                    Spacer()
                    Image(systemName: mealsExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(DesignTokens.date)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            if mealsExpanded {
                ForEach(schools) { school in
                    if let menu = menusBySchoolId[school.id] {
                        VStack(alignment: .leading, spacing: DesignTokens.cardSpacing) {
                            Text(school.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(DesignTokens.schoolName)
                            compactMealRow(title: "Lunch", items: menu.lunchItems)
                            compactMealRow(title: "Breakfast", items: menu.breakfastItems)
                        }
                        .padding(.bottom, 12)
                    }
                }
            }
        }
    }

    private func compactMealRow(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(DesignTokens.mealHeaderSecondary)
            Text(items.prefix(5).joined(separator: " · "))
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(DesignTokens.secondaryItem)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}
