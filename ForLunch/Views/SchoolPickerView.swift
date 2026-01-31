//
//  SchoolPickerView.swift
//  ForLunch
//

import SwiftUI

struct SchoolPickerView: View {
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private let searchService = SchoolSearchService()
    private var filteredSchools: [School] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return q.isEmpty ? [] : searchService.search(query: searchText)
    }

    let onSelect: (School) -> Void
    /// When non-nil, a Cancel button is shown (e.g. when presented as a sheet).
    var onCancel: (() -> Void)? = nil
    /// When true, show the short note above search (home / first-time).
    var showWelcomeNote: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showWelcomeNote {
                    Text("Selecting a school displays breakfast and lunch options for the day.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                }
                List {
                    ForEach(filteredSchools) { school in
                        Button {
                            onSelect(school)
                            if onCancel != nil { dismiss() }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(school.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("\(school.districtName) · \(school.state?.fullName ?? school.stateCode)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "School or district name")
            }
            .navigationTitle("Choose Your School")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let onCancel = onCancel {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", action: onCancel)
                    }
                }
            }
        }
    }
}
