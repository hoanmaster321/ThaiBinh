//
//  OperationsView.swift
//  ThaiBinh (ErosionWQ)
//
//  Bản quyền © 2026 ThaiBinh (hoanmaster321)
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
                    Label("Chọn Đường dẫn MCM Mẫu (Presets)...", systemImage: "bookmark.fill")
                }
                
                TextField("Thư mục đích (Directory)", text: $directory)
                    .disabled(isAcc)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                TextField("Tên tệp (File Name)", text: $fileName)
                    .disabled(isAcc)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                HStack {
                    Button("Xin quyền Truy cập (Grant Access)") {
                        let fullPath = "\(directory)/\(fileName)"
                        if wq_grant(directory) || wq_grant(fullPath) {
                            isAcc = true
                        } else {
                            let res = wq.grantAccess(path: fullPath)
                            if !res.0 {
                                Alertinator.shared.alert(title: "Không thể xin quyền truy cập!", body: "\(res.1): \(res.2)")
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
                            Text("Đã cấp quyền")
                        }
                        .foregroundStyle(.green)
                    }
                }
                if isAcc {
                    Button("Đổi đường dẫn khác", role: .destructive) {
                        isAcc = false
                        imprtName = ""
                        imprtData = Data()
                    }
                    
                    Button("Xuất / Chia sẻ tệp đích hiện tại") {
                        let fileDir = "\(directory)/\(fileName)"
                        if let temp = makeTemp(URL(fileURLWithPath: fileDir)) {
                            presentShareSheet(with: temp)
                        } else {
                            presentShareSheet(with: URL(fileURLWithPath: fileDir))
                        }
                    }
                }
            } header: {
                HeaderLabel("Mục tiêu (Target MCM)", symbol: "dot.scope")
            }
            
            Section {
                HStack {
                    Button("Chọn tệp thay thế từ máy") {
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
                
                Button("Ghi đè tệp đích (Tự động Sao lưu)") {
                    let targetURL = URL(fileURLWithPath: "\(directory)/\(fileName)")
                    var err: NSString?
                    if wq_write(targetURL.path, imprtData, &err) {
                        print("(ov) Đã ghi đè tệp qua wq_write: \(targetURL.path) (\(imprtData.count) bytes)")
                        Haptic.shared.play(.soft)
                        Alertinator.shared.alert(title: "Ghi đè thành công", body: "Tệp gốc đã được sao lưu vào Documents/Backups trước khi ghi đè.")
                    } else {
                        do {
                            try imprtData.write(to: targetURL)
                            Haptic.shared.play(.soft)
                        } catch {
                            Alertinator.shared.alert(title: "Ghi đè thất bại!", body: (err as String?) ?? error.localizedDescription)
                        }
                    }
                }
                .disabled(imprtData.isEmpty || directory.isEmpty || fileName.isEmpty)
                
                Button("Tạo thành tệp mới trong thư mục") {
                    let targetURL = URL(fileURLWithPath: directory).appendingPathComponent(imprtName)
                    var err: NSString?
                    if wq_create_file(targetURL.path, imprtData, &err) {
                        Haptic.shared.play(.soft)
                        Alertinator.shared.alert(title: "Tạo tệp thành công", body: "Đã tạo \(targetURL.path)")
                    } else {
                        do {
                            try imprtData.write(to: targetURL)
                            Haptic.shared.play(.soft)
                        } catch {
                            Alertinator.shared.alert(title: "Không thể tạo tệp!", body: (err as String?) ?? error.localizedDescription)
                        }
                    }
                }
                .disabled(imprtData.isEmpty || directory.isEmpty)
                
                Button("Xóa tệp đích (Tự động Sao lưu)", role: .destructive) {
                    let targetURL = URL(fileURLWithPath: "\(directory)/\(fileName)")
                    var err: NSString?
                    if wq_delete(targetURL.path, &err) {
                        Haptic.shared.play(.heavy)
                        Alertinator.shared.alert(title: "Đã xóa tệp", body: "Tệp đã được sao lưu vào Documents/Backups trước khi xóa.")
                    } else {
                        do {
                            try fm.removeItem(at: targetURL)
                            Haptic.shared.play(.heavy)
                        } catch {
                            Alertinator.shared.alert(title: "Không thể xóa tệp!", body: (err as String?) ?? error.localizedDescription)
                        }
                    }
                }
                .disabled(directory.isEmpty || fileName.isEmpty)
            } header: {
                HeaderLabel("Thao tác Tệp", symbol: "wrench.and.screwdriver")
            }
        }
        .navigationTitle("Thao tác Tệp MCM")
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
                Alertinator.shared.alert(title: "Lỗi nhập tệp!", body: "Không thể đọc tệp đã chọn: \(error.localizedDescription)")
            }
        case .failure(let error):
            Alertinator.shared.alert(title: "Lỗi nhập tệp!", body: error.localizedDescription)
        }
    }
}
