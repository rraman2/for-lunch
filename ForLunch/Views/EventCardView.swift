//
//  EventCardView.swift
//  ForLunch
//
//  Same card style as Lunch/Breakfast. Left accent by event type only; no icons.
//

import SwiftUI

struct EventCardView: View {
    let event: Event

    private static var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }

    private var accentColor: Color {
        switch event.type {
        case .academic: return DesignTokens.EventAccent.academic
        case .sports: return DesignTokens.EventAccent.sports
        case .arts: return DesignTokens.EventAccent.arts
        case .admin: return DesignTokens.EventAccent.admin
        case .district: return DesignTokens.EventAccent.district
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(accentColor)
                .frame(width: DesignTokens.eventCardAccentWidth)
                .frame(maxHeight: .infinity)
                .padding(.vertical, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DesignTokens.mainItem)
                    .lineLimit(2)
                Text(event.metadataLine(timeFormatter: Self.timeFormatter))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(DesignTokens.date)
                if let sec = event.secondaryLine {
                    Text(sec)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(DesignTokens.secondaryItem)
                }
            }
            .padding(.leading, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DesignTokens.eventCardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius, style: .continuous))
    }
}
