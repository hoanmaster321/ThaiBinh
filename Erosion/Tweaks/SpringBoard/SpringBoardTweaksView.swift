//
//  SpringBoardTweaksView.swift
//  ErosionWQ
//
//  SpringBoard, Status Bar, Control Center & Home Screen Layout Studio via worse_query
//

import SwiftUI

struct SpringBoardTweaksView: View {
    @EnvironmentObject private var mgr: ErosionManager
    @AppStorage("autoRespring") var autoRespring = false
    
    private let sbPlistPath = "/var/mobile/Library/Preferences/com.apple.springboard.plist"
    private let globalPlistPath = "/var/mobile/Library/Preferences/.GlobalPreferences.plist"
    private let ccPlistPath = "/var/mobile/Library/ControlCenter/ModuleConfiguration.plist"
    private let iconStatePath = "/var/mobile/Library/SpringBoard/IconState.plist"
    private let desiredIconStatePath = "/var/mobile/Library/SpringBoard/DesiredIconState.plist"
    
    @State private var sbDict: [String: Any] = [:]
    @State private var globalDict: [String: Any] = [:]
    
    // UIKit Speed
    @State private var animSpeed: Double = 1.0
    
    // Status Bar
    @State private var showNumericWiFi = false
    @State private var showNumericCellular = false
    @State private var disableBreadcrumb = false
    @State private var forceBatteryPercent = false
    @State private var enableCustomTime = false
    @State private var customTimeText = "9:41"
    
    // Lock Screen & SpringBoard Behavior
    @State private var disableLockCamera = false
    @State private var disableTodayView = false
    @State private var preventAutoLock = false
    @State private var enablePrototypeSettings = false
    @State private var hideDockBackground = false
    
    // Control Center Modules
    @State private var ccEnabledModules: Set<String> = []
    @State private var hasIconBackup = false
    
    // Plist Inspector Sheet
    @State private var inspectPlistURL: URL? = nil
    @State private var showPlistSheet = false
    
    @State private var statusMessage = ""
    @State private var showStatusAlert = false
    
    private let ccHiddenModules: [(id: String, title: String, icon: String)] = [
        ("com.apple.springboard.SilentModeControlCenterModule", "Silent Mode (Bell Toggle)", "bell.slash.fill"),
        ("com.apple.shazamkit.controlcenter.ShazamModule", "Music Recognition (Shazam)", "shazam.logo.fill"),
        ("com.apple.accessibility.controlcenter.guidedaccess", "Guided Access", "lock.rectangle.on.rectangle"),
        ("com.apple.accessibility.controlcenter.hearingdevices", "Hearing Devices & Background Sounds", "ear.fill"),
        ("com.apple.AccessibilityUIServer.LiveTranscriptionModule", "Live Captions", "captions.bubble.fill"),
        ("com.apple.control-center.LowPowerModule", "Low Power Mode", "battery.25")
    ]
    
    var body: some View {
        List {
            // MARK: - 1. UIKit Animation Speed
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("UI Animation Speed", systemImage: "gauge.with.dots.needle.67percent")
                            .fontWeight(.medium)
                        Spacer()
                        Text(speedLabel(animSpeed))
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                            .monospacedDigit()
                    }
                    
                    Picker("Animation Speed", selection: $animSpeed) {
                        Text("1.0x").tag(1.0)
                        Text("0.75x").tag(0.75)
                        Text("0.5x").tag(0.5)
                        Text("0.25x").tag(0.25)
                        Text("0.1x").tag(0.1)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 4)
            } header: {
                HeaderLabel("UIKit Animation Speed", symbol: "bolt.horizontal")
            } footer: {
                Text("Adjusts UIAnimationDragCoefficient in .GlobalPreferences.plist. Lower values speed up app launches, sheets, and system transitions.")
            }
            
            // MARK: - 2. Status Bar & Time
            Section {
                Toggle("Numeric Wi-Fi Signal (dBm)", isOn: $showNumericWiFi)
                Toggle("Numeric Cellular Signal (dBm)", isOn: $showNumericCellular)
                Toggle("Hide 'Back to App' Breadcrumb", isOn: $disableBreadcrumb)
                Toggle("Force Battery Percentage", isOn: $forceBatteryPercent)
                Toggle("Custom Status Bar Time Override", isOn: $enableCustomTime)
                if enableCustomTime {
                    HStack {
                        Text("Time String")
                        Spacer()
                        TextField("9:41", text: $customTimeText)
                            .multilineTextAlignment(.trailing)
                    }
                }
            } header: {
                HeaderLabel("Status Bar & Time", symbol: "wifi")
            } footer: {
                Text("Configures SBShowRSSI, SBShowGSMRSSI, SBDisableBreadcrumb, SBShowBatteryPercentage, and SBFakeTimeString in com.apple.springboard.plist.")
            }
            
            // MARK: - 3. Lock Screen & SpringBoard Behavior
            Section {
                Toggle("Disable Lock Screen Camera Swipe", isOn: $disableLockCamera)
                Toggle("Disable Lock Screen Today View", isOn: $disableTodayView)
                Toggle("Keep Screen Awake on Home Screen", isOn: $preventAutoLock)
                Toggle("Suppress Dock Blur Platter", isOn: $hideDockBackground)
                Toggle("Enable Internal Prototype Settings", isOn: $enablePrototypeSettings)
            } header: {
                HeaderLabel("Lock Screen & SpringBoard", symbol: "lock.iphone")
            }
            
            // MARK: - 4. Control Center Hidden Modules
            Section {
                ForEach(ccHiddenModules, id: \.id) { mod in
                    Toggle(isOn: Binding(
                        get: { ccEnabledModules.contains(mod.id) },
                        set: { enabled in
                            toggleControlCenterModule(mod.id, enabled: enabled)
                        }
                    )) {
                        Label(mod.title, systemImage: mod.icon)
                    }
                }
                
                Button {
                    _ = wq_grant("/var/mobile/Library/ControlCenter")
                    inspectPlistURL = URL(fileURLWithPath: ccPlistPath)
                    showPlistSheet = true
                } label: {
                    Label("Open ModuleConfiguration.plist in Editor", systemImage: "tablecells")
                }
            } header: {
                HeaderLabel("Control Center Modules", symbol: "switch.2")
            } footer: {
                Text("Directly adds or removes modules in /var/mobile/Library/ControlCenter/ModuleConfiguration.plist. Respring after toggling.")
            }
            
            // MARK: - 5. Home Screen Icon Layout Backup & Editor
            Section {
                Button {
                    backupIconLayout()
                } label: {
                    Label("Back Up Home Screen Icon Layout", systemImage: "square.and.arrow.down.on.square")
                }
                
                if hasIconBackup {
                    Button {
                        restoreIconLayout()
                    } label: {
                        Label("Restore Saved Icon Layout", systemImage: "arrow.uturn.backward.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                
                Button {
                    _ = wq_grant("/var/mobile/Library/SpringBoard")
                    inspectPlistURL = URL(fileURLWithPath: iconStatePath)
                    showPlistSheet = true
                } label: {
                    Label("Edit IconState.plist (Dock & Folders)", systemImage: "square.grid.3x3.topleft.filled")
                }
                
                Button {
                    _ = wq_grant("/var/mobile/Library/Preferences")
                    inspectPlistURL = URL(fileURLWithPath: sbPlistPath)
                    showPlistSheet = true
                } label: {
                    Label("Edit com.apple.springboard.plist Directly", systemImage: "doc.badge.gearshape")
                }
            } header: {
                HeaderLabel("Home Screen Layout (IconState)", symbol: "apps.iphone")
            } footer: {
                Text("Back up your Home Screen icon & folder layout before changing Dynamic Island or Screen Subtype in MobileGestalt so you can restore it in 1 tap.")
            }
        }
        .navigationTitle("SpringBoard Studio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    resetToDefaults()
                } label: {
                    Label("Reset", systemImage: "gobackward")
                        .labelStyle(.iconOnly)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Apply", role: .adaptiveConfirm) {
                    applyChanges()
                }
            }
        }
        .onAppear {
            loadPreferences()
            loadControlCenterModules()
            checkIconBackup()
        }
        .sheet(isPresented: $showPlistSheet) {
            if let url = inspectPlistURL {
                PlistViewer(url)
            }
        }
        .alert("SpringBoard Studio", isPresented: $showStatusAlert) {
            Button("Respring Now") {
                mgr.shouldRespring = true
            }
            Button("Later", role: .cancel) {}
        } message: {
            Text(statusMessage)
        }
    }
    
    private func speedLabel(_ val: Double) -> String {
        switch val {
        case 0.1: return "0.1x Instant"
        case 0.25: return "0.25x Ultra Fast"
        case 0.5: return "0.5x Fast"
        case 0.75: return "0.75x Snappy"
        default: return "1.0x Normal"
        }
    }
    
    private func loadPreferences() {
        _ = wq_grant("/var/mobile/Library/Preferences")
        if let data = wq_read(sbPlistPath, 0, nil),
           let dict = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? [String: Any] {
            sbDict = dict
            showNumericWiFi = dict["SBShowRSSI"] as? Bool ?? false
            showNumericCellular = dict["SBShowGSMRSSI"] as? Bool ?? false
            disableBreadcrumb = dict["SBDisableBreadcrumb"] as? Bool ?? false
            forceBatteryPercent = dict["SBShowBatteryPercentage"] as? Bool ?? false
            enableCustomTime = dict["SBFakeTime"] as? Bool ?? false
            customTimeText = dict["SBFakeTimeString"] as? String ?? "9:41"
            
            disableLockCamera = dict["SBDisableLockScreenCamera"] as? Bool ?? false
            disableTodayView = dict["SBDisableLockScreenTodayView"] as? Bool ?? false
            preventAutoLock = dict["SBDontLockEver"] as? Bool ?? false
            enablePrototypeSettings = dict["SBPrototypeSettingsEnabled"] as? Bool ?? false
            hideDockBackground = dict["SBHideDockBackground"] as? Bool ?? false
        }
        
        if let gData = wq_read(globalPlistPath, 0, nil),
           let gDict = (try? PropertyListSerialization.propertyList(from: gData, options: [], format: nil)) as? [String: Any] {
            globalDict = gDict
            if let num = gDict["UIAnimationDragCoefficient"] as? NSNumber {
                animSpeed = num.doubleValue
            } else {
                animSpeed = 1.0
            }
        }
    }
    
    private func loadControlCenterModules() {
        _ = wq_grant("/var/mobile/Library/ControlCenter")
        guard let data = wq_read(ccPlistPath, 0, nil),
              let dict = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? [String: Any],
              let list = dict["module-identifiers"] as? [String] else {
            return
        }
        ccEnabledModules = Set(list)
    }
    
    private func toggleControlCenterModule(_ moduleID: String, enabled: Bool) {
        _ = wq_grant("/var/mobile/Library/ControlCenter")
        var dict: [String: Any] = [:]
        if let data = wq_read(ccPlistPath, 0, nil),
           let loaded = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? [String: Any] {
            dict = loaded
        }
        var modules = (dict["module-identifiers"] as? [String]) ?? []
        var disabled = (dict["disabled-module-identifiers"] as? [String]) ?? []
        
        if enabled {
            if !modules.contains(moduleID) {
                modules.append(moduleID)
            }
            disabled.removeAll { $0 == moduleID }
            ccEnabledModules.insert(moduleID)
        } else {
            modules.removeAll { $0 == moduleID }
            ccEnabledModules.remove(moduleID)
        }
        
        dict["module-identifiers"] = modules
        dict["disabled-module-identifiers"] = disabled
        
        if let outData = try? PropertyListSerialization.data(fromPropertyList: dict, format: .binary, options: 0) {
            var err: NSString?
            if wq_write(ccPlistPath, outData, &err) || wq_create_file(ccPlistPath, outData, &err) {
                Haptic.shared.play(.soft)
            }
        }
    }
    
    private var iconBackupDir: URL {
        URL.documentsDirectory.appendingPathComponent("IconLayoutBackup")
    }
    
    private func checkIconBackup() {
        let saved = iconBackupDir.appendingPathComponent("IconState.plist")
        hasIconBackup = FileManager.default.fileExists(atPath: saved.path)
    }
    
    private func backupIconLayout() {
        _ = wq_grant("/var/mobile/Library/SpringBoard")
        try? FileManager.default.createDirectory(at: iconBackupDir, withIntermediateDirectories: true)
        var ok = false
        if let data = wq_read(iconStatePath, 0, nil) {
            try? data.write(to: iconBackupDir.appendingPathComponent("IconState.plist"))
            ok = true
        }
        if let dData = wq_read(desiredIconStatePath, 0, nil) {
            try? dData.write(to: iconBackupDir.appendingPathComponent("DesiredIconState.plist"))
        }
        checkIconBackup()
        if ok {
            Haptic.shared.play(.soft)
            Alertinator.shared.alert(title: "Icon Layout Backed Up", body: "Saved IconState.plist and DesiredIconState.plist to Documents/IconLayoutBackup.")
        } else {
            Alertinator.shared.alert(title: "Backup Failed", body: "Could not read /var/mobile/Library/SpringBoard/IconState.plist.")
        }
    }
    
    private func restoreIconLayout() {
        _ = wq_grant("/var/mobile/Library/SpringBoard")
        var err: NSString?
        var ok = false
        let savedIcon = iconBackupDir.appendingPathComponent("IconState.plist")
        let savedDesired = iconBackupDir.appendingPathComponent("DesiredIconState.plist")
        
        if let data = try? Data(contentsOf: savedIcon) {
            if wq_write(iconStatePath, data, &err) {
                ok = true
            }
        }
        if let dData = try? Data(contentsOf: savedDesired) {
            _ = wq_write(desiredIconStatePath, dData, &err)
        }
        if ok {
            Haptic.shared.play(.soft)
            statusMessage = "Restored Home Screen icon layout! Respring now to apply your saved layout."
            showStatusAlert = true
        } else {
            Alertinator.shared.alert(title: "Restore Failed", body: (err as String?) ?? "Could not write IconState.plist.")
        }
    }
    
    private func applyChanges() {
        _ = wq_grant("/var/mobile/Library/Preferences")
        
        var updatedSB = sbDict
        updatedSB["SBShowRSSI"] = showNumericWiFi
        updatedSB["SBShowGSMRSSI"] = showNumericCellular
        updatedSB["SBDisableBreadcrumb"] = disableBreadcrumb
        updatedSB["SBShowBatteryPercentage"] = forceBatteryPercent
        updatedSB["SBFakeTime"] = enableCustomTime
        if enableCustomTime {
            updatedSB["SBFakeTimeString"] = customTimeText
        } else {
            updatedSB.removeValue(forKey: "SBFakeTimeString")
        }
        
        updatedSB["SBDisableLockScreenCamera"] = disableLockCamera
        updatedSB["SBDisableLockScreenTodayView"] = disableTodayView
        updatedSB["SBDontLockEver"] = preventAutoLock
        updatedSB["SBPrototypeSettingsEnabled"] = enablePrototypeSettings
        updatedSB["SBHideDockBackground"] = hideDockBackground
        
        var updatedGlobal = globalDict
        if animSpeed == 1.0 {
            updatedGlobal.removeValue(forKey: "UIAnimationDragCoefficient")
        } else {
            updatedGlobal["UIAnimationDragCoefficient"] = animSpeed
        }
        
        var sbOk = false
        var globalOk = false
        var errText: NSString?
        
        if let sbData = try? PropertyListSerialization.data(fromPropertyList: updatedSB, format: .binary, options: 0) {
            if wq_write(sbPlistPath, sbData, &errText) || wq_create_file(sbPlistPath, sbData, &errText) {
                sbOk = true
            }
        }
        
        if let gData = try? PropertyListSerialization.data(fromPropertyList: updatedGlobal, format: .binary, options: 0) {
            if wq_write(globalPlistPath, gData, &errText) || wq_create_file(globalPlistPath, gData, &errText) {
                globalOk = true
            }
        }
        
        if sbOk || globalOk {
            Haptic.shared.play(.soft)
            if autoRespring {
                mgr.shouldRespring = true
            } else {
                statusMessage = "Successfully updated SpringBoard, Status Bar & UI preferences. Respring to apply changes."
                showStatusAlert = true
            }
        } else {
            Alertinator.shared.alert(title: "Failed to Apply", body: (errText as String?) ?? "Could not write to /var/mobile/Library/Preferences.")
        }
    }
    
    private func resetToDefaults() {
        showNumericWiFi = false
        showNumericCellular = false
        disableBreadcrumb = false
        forceBatteryPercent = false
        enableCustomTime = false
        customTimeText = "9:41"
        disableLockCamera = false
        disableTodayView = false
        preventAutoLock = false
        enablePrototypeSettings = false
        hideDockBackground = false
        animSpeed = 1.0
        applyChanges()
    }
}
