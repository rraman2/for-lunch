//
//  MenuSheetView.swift
//  ForLunch
//
//  Hamburger menu: Schools (add/remove) and Other apps (placeholder).
//

import SwiftUI

struct MenuSheetView: View {
    let onOpenSchools: () -> Void
    let onDismiss: () -> Void

    private static var menuAPIBaseURL: String { RemoteMenuService.currentBaseURL }
    private static var isLocalhost: Bool { menuAPIBaseURL.contains("localhost") }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        onDismiss()
                        DispatchQueue.main.async {
                            onOpenSchools()
                        }
                    } label: {
                        Label("Schools", systemImage: "building.2")
                    }
                }
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Menu API: \(Self.menuAPIBaseURL)")
                            .font(.caption)
                            .textSelection(.enabled)
                        #if !targetEnvironment(simulator)
                        if Self.isLocalhost {
                            Text("On this device, menus load from your Mac. In Xcode: Build Settings → USA_SCHOOL_MENU_BASE_URL (Debug) = http://YOUR_MAC_IP:3000 (e.g. http://192.168.1.5:3000). Run the server in the usa-school-menu folder, then rebuild.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        #endif
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Device setup")
                }
                Section {
                    NavigationLink {
                        OtherAppsView()
                    } label: {
                        Label("Other apps", systemImage: "square.grid.2x2")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

struct OtherAppsView: View {
    var body: some View {
        List {
            Section {
                Text("Turn on or connect other apps here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Other apps")
            } footer: {
                Text("Connect integrations and enable other apps in a future update.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Other apps")
        .navigationBarTitleDisplayMode(.inline)
    }
}
