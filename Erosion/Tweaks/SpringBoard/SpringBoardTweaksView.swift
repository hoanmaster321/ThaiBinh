//
//  SpringBoardTweaksView.swift
//  ErosionWQ
//
//  SpringBoard & Global UI Preferences Customizer via worse_query
//

import SwiftUI

struct SpringBoardTweaksView: View {
    @EnvironmentObject private var mgr: ErosionManager
    @AppStorage("autoRespring") var autoRespring = false
    
    private let sbPlistPath = "/var/mobile/Library/Preferences/com.apple.springboard.plist"
    private let globalPlistPath = "/var/mobile/Library/Preferences/.GlobalPreferences.plist"
    
    @State private var sbDict: [String: Any] = [:]
    @State private var globalDict: [String: Any] = [:]
    
    @State private var showNumericWiFi = false
    @State private var showNumericCellular = false
    @State private var preventAutoLock = false
    @State private var enablePrototypeSettings = false
    @State private var hideDockBackground = false
    @State private var animSpeed: Double = 1.0
    
    @State private var statusMessage = ""
    @State private var showStatusAlert = false
    
    var body: some View {
        List {
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
                        Text("1.0x (Default)").tag(1.0)
                        Text("0.75x (Snappy)").tag(0.75)
                        Text("0.5x (Fast)").tag(0.5)
                        Text("0.25x (Ultra)").tag(0.25)
                        Text("0.1x (Instant)").tag(0.1)
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.vertical, 4)
            } header: {
                HeaderLabel("UIKit Animation Speed", symbol: "bolt.horizontal")
            } footer: {
                Text("Adjusts UIAnimationDragCoefficient in .GlobalPreferences.plist. Lower values make app launches, sheets, and transitions faster.")
            }
            
            Section {
                Toggle("Numeric Wi-Fi Signal (dBm)", isOn: $showNumericWiFi)
                Toggle("Numeric Cellular Signal (dBm)", isOn: $showNumericCellular)
            } header: {
                HeaderLabel("Status Bar Diagnostics", symbol: "wifi")
            } footer: {
                Text("Writes SBShowRSSI and SBShowGSMRSSI to com.apple.springboard.plist.")
            }
            
            Section {
                Toggle("Keep Screen Awake on Home Screen", isOn: $preventAutoLock)
                Toggle("Enable Internal Prototype Settings", isOn: $enablePrototypeSettings)
                Toggle("Suppress Dock Blur Platter Hint", isOn: $hideDockBackground)
            } header: {
                HeaderLabel("SpringBoard Flags", symbol: "sparkles.rectangle.stack")
            } footer: {
                Text("All modified preference files are automatically backed up to Documents/Backups before writing.")
            }
        }
        .navigationTitle("SpringBoard & UI")
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
        }
        .alert("SpringBoard Tweaks", isPresented: $showStatusAlert) {
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
    
    private func applyChanges() {
        _ = wq_grant("/var/mobile/Library/Preferences")
        
        var updatedSB = sbDict
        updatedSB["SBShowRSSI"] = showNumericWiFi
        updatedSB["SBShowGSMRSSI"] = showNumericCellular
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
                statusMessage = "Successfully updated SpringBoard & Global UI preferences. Respring to apply changes."
                showStatusAlert = true
            }
        } else {
            Alertinator.shared.alert(title: "Failed to Apply", body: (errText as String?) ?? "Could not write to /var/mobile/Library/Preferences.")
        }
    }
    
    private func resetToDefaults() {
        showNumericWiFi = false
        showNumericCellular = false
        preventAutoLock = false
        enablePrototypeSettings = false
        hideDockBackground = false
        animSpeed = 1.0
        applyChanges()
    }
}
