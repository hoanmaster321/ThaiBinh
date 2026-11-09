//
//  AppsManagerView.swift
//  ErosionWQ
//
//  App Data Manager: Backup, Restore, Clear & Browse App Containers
//

import SwiftUI

struct AppsManagerView: View {
    @StateObject private var engine = WQEngine.shared
    @State private var searchText = ""
    @State private var selectedApp: AppInfoItem? = nil
    @State private var showActionSheet = false
    @State private var showConfirmClear = false
    @State private var showConfirmRestore = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var navigateToContainerPath: String? = nil
    
    var filteredApps: [AppInfoItem] {
        if searchText.isEmpty {
            return engine.apps
        }
        return engine.apps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.bundleID.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(engine.deviceLine)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospaced()
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(engine.apps.count) Applications")
                                    .font(.headline)
                                Text("\(wq_size_text(engine.totalAppDataBytes)) Total App Data")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if engine.isScanningApps {
                                ProgressView()
                            } else {
                                Button {
                                    engine.scanApps()
                                } label: {
                                    Image(systemName: "arrow.clockwise.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        
                        if !engine.scanAppProgress.isEmpty {
                            Text(engine.scanAppProgress)
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section {
                    if engine.apps.isEmpty && engine.isScanningApps {
                        HStack {
                            ProgressView()
                            Text("Enumerating containers...")
                                .padding(.leading, 8)
                        }
                    } else if filteredApps.isEmpty {
                        Text(searchText.isEmpty ? "No apps discovered yet. Pull down to scan." : "No apps matching '\(searchText)'")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(filteredApps) { app in
                            Button {
                                selectedApp = app
                                showActionSheet = true
                            } label: {
                                HStack(spacing: 12) {
                                    if let icon = app.icon {
                                        Image(uiImage: icon)
                                            .resizable()
                                            .frame(width: 40, height: 40)
                                            .cornerRadius(9)
                                    } else {
                                        RoundedRectangle(cornerRadius: 9)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 40, height: 40)
                                            .overlay(Image(systemName: "app.fill").foregroundStyle(.secondary))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(app.name)
                                                .font(.body)
                                                .fontWeight(.medium)
                                                .foregroundStyle(.primary)
                                            
                                            if app.hasBackup {
                                                Text("BACKED UP")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .padding(.horizontal, 5)
                                                    .padding(.vertical, 2)
                                                    .background(Color.green.opacity(0.2))
                                                    .foregroundStyle(.green)
                                                    .cornerRadius(4)
                                            }
                                        }
                                        
                                        Text("\(app.formattedBytes) · \(app.bundleID)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "ellipsis")
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Installed Apps (\(filteredApps.count))")
                }
            }
            .navigationTitle("App Manager")
            .searchable(text: $searchText, prompt: "Search by name or bundle id")
            .refreshable {
                engine.scanApps()
            }
            .onAppear {
                if engine.apps.isEmpty {
                    engine.scanApps()
                }
            }
            .confirmationDialog(selectedApp?.name ?? "App Actions", isPresented: $showActionSheet, presenting: selectedApp) { app in
                Button("Back Up App Data") {
                    engine.backupApp(app) { success, msg in
                        alertTitle = success ? "Backup Complete" : "Backup Failed"
                        alertMessage = msg
                        showAlert = true
                    }
                }
                
                if let latest = app.latestBackupPath {
                    let stamp = URL(fileURLWithPath: latest).lastPathComponent
                    Button("Restore Backup (\(stamp))") {
                        showConfirmRestore = true
                    }
                    
                    Button("Share Latest Backup (ZIP)") {
                        if let rootVC = UIApplication.shared.connectedScenes
                            .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first {
                            engine.shareBackup(app, from: rootVC, sourceView: nil)
                        }
                    }
                }
                
                Button("Clear App Data", role: .destructive) {
                    showConfirmClear = true
                }
                
                Button("Open Container in File Browser") {
                    navigateToContainerPath = app.containerPath
                }
                
                Button("Cancel", role: .cancel) {}
            } message: { app in
                Text("\(app.bundleID)\n\(app.formattedBytes) of data")
            }
            .alert("Clear \(selectedApp?.name ?? "App")?", isPresented: $showConfirmClear) {
                Button("Back Up First, Then Clear", role: .destructive) {
                    if let app = selectedApp {
                        engine.backupApp(app) { ok, _ in
                            if ok {
                                engine.clearAppData(app) { _, msg in
                                    alertTitle = "Cleared"
                                    alertMessage = msg
                                    showAlert = true
                                }
                            }
                        }
                    }
                }
                Button("Clear Without Backup", role: .destructive) {
                    if let app = selectedApp {
                        engine.clearAppData(app) { _, msg in
                            alertTitle = "Cleared"
                            alertMessage = msg
                            showAlert = true
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Deletes Documents, Library, and tmp folders. Logins, offline cache, and settings will be removed. Make sure the app is closed.")
            }
            .alert("Restore \(selectedApp?.name ?? "App")?", isPresented: $showConfirmRestore) {
                Button("Restore", role: .destructive) {
                    if let app = selectedApp, let path = app.latestBackupPath {
                        engine.restoreApp(app, from: path) { success, msg in
                            alertTitle = success ? "Restored" : "Restore Failed"
                            alertMessage = msg
                            showAlert = true
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Overwrites current Documents and Library with the backup snapshot. Make sure the app is closed.")
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .background(
                Group {
                    if let navPath = navigateToContainerPath {
                        NavigationLink(
                            destination: FileBrowserView(path: URL(fileURLWithPath: navPath), isContainer: false, shouldGrant: true),
                            isActive: Binding(
                                get: { navigateToContainerPath != nil },
                                set: { if !$0 { navigateToContainerPath = nil } }
                            )
                        ) {
                            EmptyView()
                        }
                    }
                }
            )
        }
    }
}
