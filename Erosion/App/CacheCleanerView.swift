//
//  CacheCleanerView.swift
//  ErosionWQ
//
//  Cache & Temp Cleaner: Purge App Caches, Temporary Files & Crash Logs
//

import SwiftUI
import Combine

struct CacheCleanerView: View {
    @StateObject private var engine = WQEngine.shared
    @State private var searchText = ""
    @State private var showConfirmClean = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var targetBrowserPath: String? = nil
    
    var filteredItems: [CacheScanItem] {
        if searchText.isEmpty {
            return engine.cacheItems
        }
        return engine.cacheItems.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.bundleID ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var totalSelectedBytes: UInt64 {
        engine.cacheItems.filter { $0.isSelected }.reduce(0) { $0 + $1.totalBytes }
    }
    
    var totalAllBytes: UInt64 {
        engine.cacheItems.reduce(0) { $0 + $1.totalBytes }
    }
    
    var selectedCount: Int {
        engine.cacheItems.filter { $0.isSelected }.count
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Total Junk Space")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(wq_size_text(totalAllBytes))
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Selected to Clean")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(wq_size_text(totalSelectedBytes))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.blue)
                            }
                        }
                        
                        // Progress bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                
                                let ratio = totalAllBytes > 0 ? CGFloat(totalSelectedBytes) / CGFloat(totalAllBytes) : 0
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue)
                                    .frame(width: max(0, min(geo.size.width, geo.size.width * ratio)), height: 8)
                            }
                        }
                        .frame(height: 8)
                        
                        // Selection shortcuts
                        HStack {
                            Button("Select All") {
                                engine.selectCacheWhere { _ in true }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Button("Large (>50MB)") {
                                engine.selectCacheWhere { $0.totalBytes >= 50 * 1024 * 1024 }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Button("None") {
                                engine.selectCacheWhere { _ in false }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Spacer()
                            
                            if engine.isScanningCaches {
                                ProgressView()
                            } else {
                                Button {
                                    engine.scanCaches()
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        
                        if !engine.cleanStatusMessage.isEmpty {
                            Text(engine.cleanStatusMessage)
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section {
                    Button(role: .destructive) {
                        engine.cleanCrashLogs { freed in
                            alertTitle = "Crash Logs Cleared"
                            alertMessage = "Purged \(wq_size_text(freed)) of crash reports."
                            showAlert = true
                            engine.scanCaches()
                        }
                    } label: {
                        HStack {
                            Label("Purge iOS Crash Reports", systemImage: "stethoscope")
                            Spacer()
                            Image(systemName: "trash")
                        }
                    }
                }
                
                Section {
                    if engine.cacheItems.isEmpty && engine.isScanningCaches {
                        HStack {
                            ProgressView()
                            Text("Scanning cache directories...")
                                .padding(.leading, 8)
                        }
                    } else if filteredItems.isEmpty {
                        Text(searchText.isEmpty ? "No caches found or device already clean." : "No caches matching '\(searchText)'")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(filteredItems) { item in
                            HStack(spacing: 12) {
                                Button {
                                    item.isSelected.toggle()
                                    engine.objectWillChange.send()
                                } label: {
                                    Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(item.isSelected ? .blue : .secondary)
                                }
                                .buttonStyle(.plain)
                                
                                if let icon = item.icon {
                                    Image(uiImage: icon)
                                        .resizable()
                                        .frame(width: 36, height: 36)
                                        .cornerRadius(8)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    
                                    Text("cache \(wq_size_text(item.cacheBytes)) · temp \(wq_size_text(item.tempBytes))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(item.formattedSize)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                item.isSelected.toggle()
                                engine.objectWillChange.send()
                            }
                            .contextMenu {
                                if let firstDir = item.targets.first {
                                    Button {
                                        targetBrowserPath = firstDir
                                    } label: {
                                        Label("Open Caches in File Browser", systemImage: "folder")
                                    }
                                }
                                if item.targets.count > 1 {
                                    Button {
                                        targetBrowserPath = item.targets[1]
                                    } label: {
                                        Label("Open tmp in File Browser", systemImage: "folder.badge.gearshape")
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text("App Caches (\(filteredItems.count))")
                }
            }
            .navigationTitle("Cache Cleaner")
            .searchable(text: $searchText, prompt: "Filter apps")
            .refreshable {
                engine.scanCaches()
            }
            .onAppear {
                if engine.cacheItems.isEmpty {
                    engine.scanCaches()
                }
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        showConfirmClean = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Clean \(selectedCount) Items (\(wq_size_text(totalSelectedBytes)))")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(totalSelectedBytes == 0 || engine.isCleaningCaches)
                }
            }
            .alert("Purge Selected Caches?", isPresented: $showConfirmClean) {
                Button("Delete Caches (\(wq_size_text(totalSelectedBytes)))", role: .destructive) {
                    engine.cleanSelectedCaches { freed, allOk in
                        alertTitle = allOk ? "Cleaning Finished" : "Cleaning Partially Finished"
                        alertMessage = "Freed \(wq_size_text(freed)).\(allOk ? "" : " Some system files could not be deleted.")"
                        showAlert = true
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will delete temporary caches and files for the selected applications. Cached data will regenerate when apps run.")
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .background(
                Group {
                    if let navPath = targetBrowserPath {
                        NavigationLink(
                            destination: FileBrowserView(path: URL(fileURLWithPath: navPath), isContainer: false, shouldGrant: true),
                            isActive: Binding(
                                get: { targetBrowserPath != nil },
                                set: { if !$0 { targetBrowserPath = nil } }
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
