//
//  EventsSectionView.swift
//  ForLunch
//
//  Events module: collapsed when empty (discover on tap); expanded when events exist.
//

import SwiftUI

struct EventsSectionView: View {
    let events: [Event]
    let date: Date
    var isExpanded: Bool = false
    var onToggle: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.cardSpacing) {
            Button {
                onToggle?()
            } label: {
                HStack {
                    Text("Events")
                        .font(.system(size: DesignTokens.eventsSectionHeaderSize, weight: .semibold))
                        .foregroundStyle(DesignTokens.mealHeader)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(DesignTokens.date)
                }
                .padding(DesignTokens.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignTokens.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
            if isExpanded {
                if events.isEmpty {
                    Text("No events scheduled today.")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(DesignTokens.secondaryItem)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                } else {
                    ForEach(events) { event in
                        EventCardView(event: event)
                    }
                }
            }
        }
    }
}
