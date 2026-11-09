//
//  OperationsView.swift
//  Erosion
//
//  Created by lunginspector on 8/17/26.
//

import SwiftUI
import UniformTypeIdentifiers


struct OperationsView: View {
    @State private var directory = ""
    @State private var fileName = ""
    @State private var isAcc = false
    @State private var showImporter = false
    
    @State private var imprtName = ""
    @State private var imprtData = Data()
    
    private let presets: [(String, String, String)] = [
        ("MobileGestalt Cache (SystemGroup)", "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches", "com.apple.MobileGestalt.plist"),
        ("LockScreen Footnote (SystemGroup)", "/var/containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles", "SharedDeviceConfiguration.plist"),
        ("Cloud Supervision Config (SystemGroup)", "/var/containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles", "CloudConfigurationDetails.plist"),
        ("Effective User Settings (SystemGroup)", "/var/containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles/PublicInfo", "PublicEffectiveUserSettings.plist"),
        ("Find My SearchParty Settings (SystemGroup)", "/var/containers/Shared/SystemGroup/systemgroup.com.apple.icloud.searchpartyd.sharedsettings/Library/Preferences", "com.apple.icloud.searchpartyd.sharedsettings.plist")
    ]
    
    var body: some View {
        List {
            Section {
                Menu {
                    ForEach(presets, id: \.0) { preset in
                        Button(preset.0) {
                            directory = preset.1
                            fileName = preset.2
                            isAcc = false
                        }
                    }
                } label: {
                    Label("Load System Target Preset...", systemImage: "bookmark.fill")
                }
                
                TextField("Directory", text: $directory)
                    .disabled(isAcc)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                TextField("File Name", text: $fileName)
                    .disabled(isAcc)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                HStack {
                    Button("Grant Access") {
                        let fullPath = "\(directory)/\(fileName)"
                        if wq_grant(directory) || wq_grant(fullPath) {
                            isAcc = true
                        } else {
                            let res = wq.grantAccess(path: fullPath)
                            if !res.0 {
                                Alertinator.shared.alert(title: "Failed to get access to target file!", body: "\(res.1): \(res.2)")
                            } else {
                                isAcc = true
                            }
                        }
                    }
                    .disabled(isAcc || directory.isEmpty)
                    if isAcc {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                            Text("Access Granted")
                        }
                        .foregroundStyle(.green)
                    }
                }
                if isAcc {
                    Button("Change Path", role: .destructive) {
                        isAcc = false
                        imprtName = ""
                        imprtData = Data()
                    }
                    
                    Button("Export Current Target File") {
                        let fileDir = "\(directory)/\(fileName)"
                        if let temp = makeTemp(URL(fileURLWithPath: fileDir)) {
                            presentShareSheet(with: temp)
                        } else {
                            presentShareSheet(with: URL(fileURLWithPath: fileDir))
                        }
                    }
                }
            } header: {
                HeaderLabel("Target", symbol: "dot.scope")
            }
            
            Section {
                HStack {
                    Button("Import Replacement File") {
                        showImporter = true
                    }
                    if !imprtName.isEmpty {
                        Spacer()
                        Text("\(imprtName) (\(wq_size_text(UInt64(imprtData.count))))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                
                Button("Overwrite Target File (Safe Backup)") {
                    let targetURL = URL(fileURLWithPath: "\(directory)/\(fileName)")
                    var err: NSString?
                    if wq_write(targetURL.path, imprtData, &err) {
                        print("(ov) successfully overwrote file via wq_write: \(targetURL.path) (\(imprtData.count) bytes)")
                        Haptic.shared.play(.soft)
                        Alertinator.shared.alert(title: "Overwrite Complete", body: "Target file was backed up to Documents/Backups and overwritten in place.")
                    } else {
                        do {
                            try imprtData.write(to: targetURL)
                            print("(ov) successfully overwrote file: \(targetURL.path) (\(imprtData.count))")
                            Haptic.shared.play(.soft)
                        } catch {
                            print("(ov) failed to overwrite: \(error.localizedDescription)")
                            Alertinator.shared.alert(title: "Failed to overwrite file!", body: (err as String?) ?? error.localizedDescription)
                        }
                    }
                }
                .disabled(imprtData.isEmpty || directory.isEmpty || fileName.isEmpty)
                
                Button("Write as New File in Directory") {
                    let targetURL = URL(fileURLWithPath: directory).appendingPathComponent(imprtName)
                    var err: NSString?
                    if wq_create_file(targetURL.path, imprtData, &err) {
                        print("(ov) successfully created file: \(imprtName) -> \(targetURL.path)")
                        Haptic.shared.play(.soft)
                    } else {
                        do {
                            try imprtData.write(to: targetURL)
                            print("(ov) successfully moved file: \(imprtName) -> \(targetURL.path)")
                            Haptic.shared.play(.soft)
                        } catch {
                            print("(ov) failed to move: \(error.localizedDescription)")
                            Alertinator.shared.alert(title: "Failed to write file!", body: (err as String?) ?? error.localizedDescription)
                        }
                    }
                }
                .disabled(imprtData.isEmpty || directory.isEmpty)
                
                Button("Delete Target File (Safe Backup)", role: .destructive) {
                    let targetURL = URL(fileURLWithPath: "\(directory)/\(fileName)")
                    var err: NSString?
                    if wq_delete(targetURL.path, &err) {
                        print("(ov) successfully deleted file via wq_delete: \(targetURL.path)")
                        Haptic.shared.play(.heavy)
                    } else {
                        do {
                            try fm.removeItem(at: targetURL)
                            print("(ov) successfully deleted file: \(targetURL.path)")
                            Haptic.shared.play(.heavy)
                        } catch {
                            print("(ov) failed to delete: \(error.localizedDescription)")
                            Alertinator.shared.alert(title: "Failed to delete file!", body: (err as String?) ?? error.localizedDescription)
                        }
                    }
                }
                .disabled(directory.isEmpty || fileName.isEmpty)
            } header: {
                HeaderLabel("Operations", symbol: "wrench.and.screwdriver")
            }
        }
        .navigationTitle("File Operations")
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.item]) { result in
            handleImport(result)
        }
    }
    
    func handleImport(_ res: Result<URL, Error>) {
        switch res {
        case .success(let recURL):
            do {
                let stopAccess = recURL.startAccessingSecurityScopedResource()
                defer {
                    if stopAccess {
                        recURL.stopAccessingSecurityScopedResource()
                    }
                }
                
                imprtData = try Data(contentsOf: recURL)
                imprtName = recURL.lastPathComponent
            } catch {
                print("(ov) failed to import file: \(error.localizedDescription)")
                Alertinator.shared.alert(title: "Failed to import file!", body: "This file is likely invalid, corrupted, or inaccessible. Please try a different overwrite file.")
            }
        case .failure(let error):
            print("(ov) failed to import file: \(error.localizedDescription)")
            Alertinator.shared.alert(title: "Failed to import file!", body: "This file is likely invalid, corrupted, or inaccessible. Please try a different overwrite file.")
        }
    }
}
