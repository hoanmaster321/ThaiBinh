//
//  SpringBoardTweaksView.swift
//  ErosionWQ
//
//  SpringBoard, Lock Screen, PosterBoard & SystemGroup Studio
//  Strictly uses MCM container paths supported by worse_query:
//  - /var/containers/Shared/SystemGroup/*
//  - /var/mobile/Containers/Data/Application/* (com.apple.PosterBoard, com.apple.mobilephone, etc.)
//  - /var/mobile/Containers/Data/PluginKitPlugin/*
//  - /var/mobile/Containers/Shared/AppGroup/*
//

import SwiftUI

struct SpringBoardTweaksView: View {
    @EnvironmentObject private var mgr: ErosionManager
    @StateObject private var store = GestaltStore.shared
    @AppStorage("autoRespring") var autoRespring = false
    
    // MCM SystemGroup paths (accessible via worse_query)
    private let configProfilesDir = "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles"
    private var sharedDevConfigPath: String {
        (configProfilesDir as NSString).appendingPathComponent("SharedDeviceConfiguration.plist")
    }
    private let sbSharedSettingsDir = "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.SpringBoard.sharedsettings"
    private let lsdIconsCacheDir = "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.lsd.iconscache/Library/Caches"
    
    // Lock Screen Footnote & Asset Tag (SystemGroup configurationprofiles)
    @State private var lockScreenFootnote = ""
    @State private var assetTagText = ""
    
    // MobileGestalt SpringBoard / Camera keys (SystemGroup mobilegestaltcache)
    private let shutterClickKey = "nFRqKto/RuQAV1P+0/qkBA" // RegionalBehaviorShutterClick
    @State private var disableShutterSound = false
    
    // PosterBoard Container (/var/mobile/Containers/Data/Application/*)
    @State private var posterBoardContainer: String = ""
    @State private var hasPosterBackup = false
    
    // Navigation & Sheets
    @State private var inspectPlistURL: URL? = nil
    @State private var showPlistSheet = false
    @State private var browseContainerURL: URL? = nil
    
    @State private var statusMessage = ""
    @State private var showStatusAlert = false
    
    var body: some View {
        List {
            // MARK: - 1. Lock Screen Banner & Asset Tag (SystemGroup configurationprofiles)
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Lock Screen Bottom Footnote")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Custom Lock Screen Text...", text: $lockScreenFootnote)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Lock Screen Asset Tag (Device Info)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g. Property of ThaiBinh...", text: $assetTagText)
                }
            } header: {
                HeaderLabel("Lock Screen Text (SystemGroup)", symbol: "lock.iphone")
            } footer: {
                Text("Writes to /var/containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles/SharedDeviceConfiguration.plist.")
            }
            
            // MARK: - 2. SpringBoard & Camera Flags (SystemGroup mobilegestaltcache)
            Section {
                Toggle("Mute Camera Shutter Sound (JP/KR)", isOn: $disableShutterSound)
                PlainToggle("Dynamic Island UI", minVrs: 19.0, isOn: store.mgKeyBinding([MGKey.island]))
                PlainToggle("Always On Display (AOD)", minVrs: 18.0, isOn: store.mgKeyBinding([MGKey.AOD, MGKey.AOTime]))
                PlainToggle("Action Button UI in Settings", minVrs: 17.0, isOn: store.mgKeyBinding([MGKey.actButton]))
                PlainToggle("Camera Control Button UI", minVrs: 18.0, isOn: store.mgKeyBinding([MGKey.camButton, MGKey.grapPefr]))
                PlainToggle("Tap to Wake (SE / Home Button)", isOn: store.mgKeyBinding([MGKey.tapToWake]))
            } header: {
                HeaderLabel("SpringBoard Hardware Capabilities", symbol: "sparkles.rectangle.stack")
            } footer: {
                Text("Writes to /var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist.")
            }
            
            // MARK: - 3. PosterBoard Lock Screen & Wallpaper Container (/var/mobile/Containers/Data/Application)
            Section {
                HStack {
                    Label("PosterBoard Container", systemImage: "photo.on.rectangle.angled")
                    Spacer()
                    Text(posterBoardContainer.isEmpty ? "Not Scanned" : "Found")
                        .font(.caption)
                        .foregroundStyle(posterBoardContainer.isEmpty ? .secondary : .green)
                }
                
                if !posterBoardContainer.isEmpty {
                    Button {
                        backupPosterBoardData()
                    } label: {
                        Label("Back Up All Lock Screen Posters", systemImage: "externaldrive.badge.timemachine")
                    }
                    
                    if hasPosterBackup {
                        Button {
                            restorePosterBoardData()
                        } label: {
                            Label("Restore Saved Lock Screen Posters", systemImage: "arrow.uturn.backward.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    
                    Button {
                        let prefsPath = (posterBoardContainer as NSString).appendingPathComponent("Library/Preferences/com.apple.PosterBoard.plist")
                        _ = wq_grant((posterBoardContainer as NSString).appendingPathComponent("Library/Preferences"))
                        inspectPlistURL = URL(fileURLWithPath: prefsPath)
                        showPlistSheet = true
                    } label: {
                        Label("Edit com.apple.PosterBoard.plist", systemImage: "tablecells")
                    }
                    
                    Button {
                        browseContainerURL = URL(fileURLWithPath: posterBoardContainer)
                    } label: {
                        Label("Browse PosterBoard Container", systemImage: "folder")
                    }
                } else {
                    Button {
                        locatePosterBoard()
                    } label: {
                        Label("Locate com.apple.PosterBoard Container", systemImage: "magnifyingglass")
                    }
                }
            } header: {
                HeaderLabel("PosterBoard Lock Screen Data", symbol: "wand.and.stars")
            } footer: {
                Text("Accesses com.apple.PosterBoard inside /var/mobile/Containers/Data/Application/* to back up, restore, or edit Lock Screen wallpaper descriptors.")
            }
            
            // MARK: - 4. SystemGroup Icon Cache & SpringBoard Shared Settings
            Section {
                Button {
                    rebuildIconCache()
                } label: {
                    Label("Purge & Rebuild Icon Cache (lsd.iconscache)", systemImage: "square.grid.2x2.fill")
                        .foregroundStyle(.orange)
                }
                
                Button {
                    _ = wq_grant(sbSharedSettingsDir)
                    browseContainerURL = URL(fileURLWithPath: sbSharedSettingsDir)
                } label: {
                    Label("Browse SpringBoard.sharedsettings", systemImage: "folder.badge.gearshape")
                }
                
                Button {
                    _ = wq_grant(configProfilesDir)
                    inspectPlistURL = URL(fileURLWithPath: sharedDevConfigPath)
                    showPlistSheet = true
                } label: {
                    Label("Edit SharedDeviceConfiguration.plist", systemImage: "doc.text")
                }
            } header: {
                HeaderLabel("SystemGroup Maintenance", symbol: "wrench.and.screwdriver")
            } footer: {
                Text("Purges /var/containers/Shared/SystemGroup/systemgroup.com.apple.lsd.iconscache/Library/Caches so SpringBoard rebuilds app icons on next respring.")
            }
        }
        .navigationTitle("SpringBoard Studio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Apply", role: .adaptiveConfirm) {
                    applyAll()
                }
            }
        }
        .onAppear {
            loadCurrentSettings()
            locatePosterBoard()
        }
        .sheet(isPresented: $showPlistSheet) {
            if let url = inspectPlistURL {
                PlistViewer(url)
            }
        }
        .background(
            Group {
                if let target = browseContainerURL {
                    NavigationLink(
                        destination: FileBrowserView(path: target, isContainer: false, shouldGrant: true),
                        isActive: Binding(
                            get: { browseContainerURL != nil },
                            set: { if !$0 { browseContainerURL = nil } }
                        )
                    ) {
                        EmptyView()
                    }
                }
            }
        )
        .alert("SpringBoard Studio", isPresented: $showStatusAlert) {
            Button("Respring Now") {
                mgr.shouldRespring = true
            }
            Button("Later", role: .cancel) {}
        } message: {
            Text(statusMessage)
        }
    }
    
    // MARK: - Logic
    
    private func loadCurrentSettings() {
        _ = mgLoadData()
        if let val = store.cacheExtra[shutterClickKey] as? Int, val == 0 {
            disableShutterSound = true
        } else {
            disableShutterSound = false
        }
        
        _ = wq_grant(configProfilesDir)
        if let data = wq_read(sharedDevConfigPath, 0, nil),
           let dict = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? [String: Any] {
            lockScreenFootnote = dict["LockScreenFootnote"] as? String ?? ""
            assetTagText = dict["AssetTagInformation"] as? String ?? ""
        }
    }
    
    private func locatePosterBoard() {
        // First check if WQEngine already scanned it
        if let match = WQEngine.shared.apps.first(where: { $0.bundleID == "com.apple.PosterBoard" }) {
            posterBoardContainer = match.containerPath
            checkPosterBackup()
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let found = fsHandlers.getContainerPath(forMatch: "com.apple.PosterBoard")
            DispatchQueue.main.async {
                if !found.isEmpty {
                    self.posterBoardContainer = found
                    self.checkPosterBackup()
                }
            }
        }
    }
    
    private func checkPosterBackup() {
        let latest = wq_latest_app_backup("com.apple.PosterBoard")
        hasPosterBackup = (latest != nil)
    }
    
    private func backupPosterBoardData() {
        guard !posterBoardContainer.isEmpty else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            var stampDir: NSString?
            var err: NSString?
            let ok = wq_backup_app_data(posterBoardContainer, "com.apple.PosterBoard", &stampDir, &err)
            DispatchQueue.main.async {
                self.checkPosterBackup()
                if ok {
                    Haptic.shared.play(.soft)
                    Alertinator.shared.alert(title: "PosterBoard Backed Up", body: "Saved Lock Screen posters snapshot to AppBackups/com.apple.PosterBoard/\(stampDir?.lastPathComponent ?? "").")
                } else {
                    Alertinator.shared.alert(title: "Backup Failed", body: (err as String?) ?? "Could not back up PosterBoard.")
                }
            }
        }
    }
    
    private func restorePosterBoardData() {
        guard !posterBoardContainer.isEmpty, let latest = wq_latest_app_backup("com.apple.PosterBoard") else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            var err: NSString?
            let ok = wq_restore_app_data(latest, posterBoardContainer, &err)
            DispatchQueue.main.async {
                if ok {
                    Haptic.shared.play(.soft)
                    self.statusMessage = "Restored PosterBoard Lock Screen wallpapers! Respring now to reload Lock Screen."
                    self.showStatusAlert = true
                } else {
                    Alertinator.shared.alert(title: "Restore Failed", body: (err as String?) ?? "Could not restore PosterBoard.")
                }
            }
        }
    }
    
    private func rebuildIconCache() {
        DispatchQueue.global(qos: .userInitiated).async {
            _ = wq_grant(lsdIconsCacheDir)
            var freed: UInt64 = 0
            let _ = wq_purge_contents(lsdIconsCacheDir, &freed)
            DispatchQueue.main.async {
                Haptic.shared.play(.heavy)
                self.statusMessage = "Purged \(wq_size_text(freed)) from systemgroup.com.apple.lsd.iconscache. Respring now to rebuild SpringBoard icons."
                self.showStatusAlert = true
            }
        }
    }
    
    private func applyAll() {
        // 1. Update SharedDeviceConfiguration.plist in systemgroup.com.apple.configurationprofiles
        _ = wq_grant(configProfilesDir)
        var configDict: [String: Any] = [:]
        if let existing = wq_read(sharedDevConfigPath, 0, nil),
           let parsed = (try? PropertyListSerialization.propertyList(from: existing, options: [], format: nil)) as? [String: Any] {
            configDict = parsed
        }
        configDict["LockScreenFootnote"] = lockScreenFootnote
        if assetTagText.isEmpty {
            configDict.removeValue(forKey: "AssetTagInformation")
        } else {
            configDict["AssetTagInformation"] = assetTagText
        }
        var errText: NSString?
        if let cfgData = try? PropertyListSerialization.data(fromPropertyList: configDict, format: .binary, options: 0) {
            if !wq_write(sharedDevConfigPath, cfgData, &errText) {
                _ = wq_create_file(sharedDevConfigPath, cfgData, &errText)
            }
        }
        
        // 2. Update MobileGestalt in systemgroup.com.apple.mobilegestaltcache
        if disableShutterSound {
            store.cacheExtra[shutterClickKey] = 0
            store.cacheExtra[MGKey.regionCode] = "LL"
            store.cacheExtra[MGKey.regionSysconfig] = "LL/A"
        } else {
            store.cacheExtra.removeObject(forKey: shutterClickKey)
        }
        store.mgCurrentDict["CacheExtra"] = store.cacheExtra
        if let mgData = try? PropertyListSerialization.data(fromPropertyList: store.mgCurrentDict, format: .xml, options: 0) {
            _ = mgWrite(mgData)
        }
        
        Haptic.shared.play(.soft)
        if autoRespring {
            mgr.shouldRespring = true
        } else {
            statusMessage = "Applied SpringBoard & SystemGroup tweaks successfully! Respring to see changes."
            showStatusAlert = true
        }
    }
}
