//
//  SchoolsListView.swift
//  ForLunch
//
//  Lists saved schools with swipe-to-delete; Add school opens the picker.
//

import SwiftUI

struct SchoolsListView: View {
    let schools: [School]
    let onRemove: (School) -> Void
    let onDismiss: () -> Void
    var onSchoolsChanged: (() -> Void)? = nil

    @State private var showAddPicker = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(schools) { school in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(school.name)
                            .font(.headline)
                        Text("\(school.districtName) · \(school.state?.fullName ?? school.stateCode)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: deleteSchools)
                Button {
                    showAddPicker = true
                } label: {
                    Label("Add school", systemImage: "plus.circle.fill")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Schools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
            .sheet(isPresented: $showAddPicker) {
                SchoolPickerView(
                    onSelect: { school in
                        SchoolStorage.addSchool(school)
                        showAddPicker = false
                        onSchoolsChanged?()
                    },
                    onCancel: { showAddPicker = false },
                    showWelcomeNote: false
                )
                .presentationDetents([.large])
            }
        }
    }

    private func deleteSchools(at offsets: IndexSet) {
        for index in offsets {
            guard index < schools.count else { continue }
            onRemove(schools[index])
        }
    }
}
