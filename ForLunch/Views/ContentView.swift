//
//  ContentView.swift
//  ForLunch
//

import SwiftUI

struct ContentView: View {
    @State private var schools: [School] = SchoolStorage.loadSchools()
    @State private var showSchoolPicker = false

    var body: some View {
        Group {
            if schools.isEmpty {
                SchoolPickerView(
                    onSelect: { school in
                        SchoolStorage.addSchool(school)
                        schools = SchoolStorage.loadSchools()
                    },
                    showWelcomeNote: true
                )
            } else {
                MenuView(
                    schools: schools,
                    onChangeSchool: { showSchoolPicker = true },
                    onRemoveSchool: { school in
                        SchoolStorage.removeSchool(id: school.id)
                        schools = SchoolStorage.loadSchools()
                    }
                )
                .sheet(isPresented: $showSchoolPicker) {
                    SchoolsListView(
                        schools: schools,
                        onRemove: { school in
                            SchoolStorage.removeSchool(id: school.id)
                            schools = SchoolStorage.loadSchools()
                            if schools.isEmpty { showSchoolPicker = false }
                        },
                        onDismiss: { showSchoolPicker = false },
                        onSchoolsChanged: { schools = SchoolStorage.loadSchools() }
                    )
                }
            }
        }
    }
}
