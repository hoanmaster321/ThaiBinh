//
//  ContentView.swift
//  ErosionWQ
//
//  Home & Dashboard View: Device Diagnostics, App Group Status, Fast Actions & Console
//

import SwiftUI

struct ContentView: View {
    @AppStorage("ogMachineName") var ogMachineName = ""
    @EnvironmentObject var mgr: ErosionManager
    @StateObject private var engine = WQEngine.shared
    @State private var showSettings = false
    @State private var alertMsg = ""
    @State private var showAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "iphone.gen3")
                                .font(.title)
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(engine.deviceLine)
                                    .font(.headline)
                                Text("worse_query sandbox escape active")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Label("App Group:", systemImage: "person.2.badge.gearshape")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(engine.activeAppGroup)
                                .font(.caption)
                                .fontWeight(.medium)
                                .monospaced()
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    HeaderLabel("Device & Exploit", symbol: "info.circle")
                }
                
                Section {
                    Button {
                        Haptic.shared.play(.heavy)
                        mgr.shouldRespring = true
                    } label: {
                        HStack {
                            Label("Respring SpringBoard", systemImage: "arrow.counterclockwise.circle.fill")
                                .foregroundStyle(.orange)
                            Spacer()
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                    
                    Button {
                        engine.cleanCrashLogs { freed in
                            alertMsg = "Purged \(wq_size_text(freed)) of crash reports."
                            showAlert = true
                        }
                    } label: {
                        HStack {
                            Label("Quick Clear Crash Reports", systemImage: "stethoscope")
                            Spacer()
                            Image(systemName: "trash")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button {
                        engine.scanApps()
                        engine.scanCaches()
                        alertMsg = "Started background rescan of applications and caches."
                        showAlert = true
                    } label: {
                        HStack {
                            Label("Rescan Apps & Containers", systemImage: "arrow.triangle.2.circlepath")
                            Spacer()
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    HeaderLabel("Quick Actions", symbol: "bolt")
                }
                
                Section {
                    LogView()
                        .modifier(TerminalPlatter())
                } header: {
                    HeaderLabel("Live Console Logs", symbol: "apple.terminal")
                }
            }
            .navigationTitle("ErosionWQ")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                            .labelStyle(.iconOnly)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .alert("Action Result", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMsg)
            }
            .onAppear {
                if ogMachineName.isEmpty {
                    ogMachineName = machineName()
                }
                engine.refreshActiveGroup()
            }
        }
    }
}

#Preview {
    ContentView()
}
