//
//  SpringBoardTweaksView.swift
//  ThaiBinh (ErosionWQ)
//
//  SpringBoard, Lock Screen, PosterBoard & SystemGroup Studio
//  Bản quyền © 2026 ThaiBinh (hoanmaster321)
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
                    Text("Chữ hiển thị dưới đáy Màn hình khóa (Footnote)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Nhập dòng chữ tùy chỉnh...", text: $lockScreenFootnote)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Nhãn tài sản thiết bị (Asset Tag)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Ví dụ: Thiết bị của ThaiBinh...", text: $assetTagText)
                }
            } header: {
                HeaderLabel("Văn bản Màn hình khóa (SystemGroup)", symbol: "lock.iphone")
            } footer: {
                Text("Ghi trực tiếp vào /var/containers/Shared/SystemGroup/systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles/SharedDeviceConfiguration.plist.")
            }
            
            // MARK: - 2. SpringBoard & Camera Flags (SystemGroup mobilegestaltcache)
            Section {
                Toggle("Tắt âm chụp ảnh Camera (Máy Nhật/Hàn)", isOn: $disableShutterSound)
                PlainToggle("Kích hoạt Dynamic Island", minVrs: 19.0, isOn: store.mgKeyBinding([MGKey.island]))
                PlainToggle("Màn hình luôn bật (Always On Display)", minVrs: 18.0, isOn: store.mgKeyBinding([MGKey.AOD, MGKey.AOTime]))
                PlainToggle("Menu Nút Tác Vụ (Action Button UI)", minVrs: 17.0, isOn: store.mgKeyBinding([MGKey.actButton]))
                PlainToggle("Menu Điều khiển Camera (Camera Control)", minVrs: 18.0, isOn: store.mgKeyBinding([MGKey.camButton, MGKey.grapPefr]))
                PlainToggle("Chạm để bật màn hình (Tap to Wake - SE)", isOn: store.mgKeyBinding([MGKey.tapToWake]))
            } header: {
                HeaderLabel("Tính năng SpringBoard & Phần cứng", symbol: "sparkles.rectangle.stack")
            } footer: {
                Text("Can thiệp trực tiếp vào /var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist.")
            }
            
            // MARK: - 3. PosterBoard Lock Screen & Wallpaper Container
            Section {
                HStack {
                    Label("Container PosterBoard", systemImage: "photo.on.rectangle.angled")
                    Spacer()
                    Text(posterBoardContainer.isEmpty ? "Chưa quét" : "Đã kết nối")
                        .font(.caption)
                        .foregroundStyle(posterBoardContainer.isEmpty ? Color.secondary : Color.green)
                }
                
                if !posterBoardContainer.isEmpty {
                    Button {
                        backupPosterBoardData()
                    } label: {
                        Label("Sao lưu toàn bộ Màn hình khóa (Posters)", systemImage: "externaldrive.badge.timemachine")
                    }
                    
                    if hasPosterBackup {
                        Button {
                            restorePosterBoardData()
                        } label: {
                            Label("Khôi phục Màn hình khóa đã lưu", systemImage: "arrow.uturn.backward.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    
                    Button {
                        let prefsPath = (posterBoardContainer as NSString).appendingPathComponent("Library/Preferences/com.apple.PosterBoard.plist")
                        _ = wq_grant((posterBoardContainer as NSString).appendingPathComponent("Library/Preferences"))
                        inspectPlistURL = URL(fileURLWithPath: prefsPath)
                        showPlistSheet = true
                    } label: {
                        Label("Sửa tệp com.apple.PosterBoard.plist", systemImage: "tablecells")
                    }
                    
                    Button {
                        browseContainerURL = URL(fileURLWithPath: posterBoardContainer)
                    } label: {
                        Label("Duyệt thư mục PosterBoard", systemImage: "folder")
                    }
                } else {
                    Button {
                        locatePosterBoard()
                    } label: {
                        Label("Dò tìm Container com.apple.PosterBoard", systemImage: "magnifyingglass")
                    }
                }
            } header: {
                HeaderLabel("Dữ liệu Màn hình khóa (PosterBoard)", symbol: "wand.and.stars")
            } footer: {
                Text("Truy cập com.apple.PosterBoard trong /var/mobile/Containers/Data/Application/* để sao lưu, khôi phục hoặc chỉnh sửa hình nền khóa.")
            }
            
            // MARK: - 4. SystemGroup Icon Cache & SpringBoard Shared Settings
            Section {
                Button {
                    rebuildIconCache()
                } label: {
                    Label("Xóa & Làm mới Icon Cache (lsd.iconscache)", systemImage: "square.grid.2x2.fill")
                        .foregroundStyle(.orange)
                }
                
                Button {
                    _ = wq_grant(sbSharedSettingsDir)
                    browseContainerURL = URL(fileURLWithPath: sbSharedSettingsDir)
                } label: {
                    Label("Mở thư mục SpringBoard.sharedsettings", systemImage: "folder.badge.gearshape")
                }
                
                Button {
                    _ = wq_grant(configProfilesDir)
                    inspectPlistURL = URL(fileURLWithPath: sharedDevConfigPath)
                    showPlistSheet = true
                } label: {
                    Label("Sửa tệp SharedDeviceConfiguration.plist", systemImage: "doc.text")
                }
            } header: {
                HeaderLabel("Bảo trì SystemGroup", symbol: "wrench.and.screwdriver")
            } footer: {
                Text("Xóa bộ nhớ đệm trong /var/containers/Shared/SystemGroup/systemgroup.com.apple.lsd.iconscache/Library/Caches để SpringBoard tạo lại icon khi Respring.")
            }
        }
        .navigationTitle("SpringBoard Studio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Áp dụng", role: .adaptiveConfirm) {
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
            Button("Respring ngay") {
                mgr.shouldRespring = true
            }
            Button("Để sau", role: .cancel) {}
        } message: {
            Text(statusMessage)
        }
    }
    
    // MARK: - Logic
    
    private func loadCurrentSettings() {
        _ = wq_grant(MGURL.fsGestaltURL.deletingLastPathComponent().path)
        if let data = readDataWithWQ(MGURL.fsGestaltURL),
           let dict = (try? PropertyListSerialization.propertyList(from: data, options: .mutableContainersAndLeaves, format: nil)) as? NSMutableDictionary {
            store.mgCurrentDict = dict
        } else if let dict = NSMutableDictionary(contentsOf: MGURL.fsGestaltURL) {
            store.mgCurrentDict = dict
        }
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
                    Alertinator.shared.alert(title: "Đã sao lưu PosterBoard", body: "Đã lưu snapshot màn hình khóa vào AppBackups/com.apple.PosterBoard/\(stampDir?.lastPathComponent ?? "").")
                } else {
                    Alertinator.shared.alert(title: "Sao lưu thất bại", body: (err as String?) ?? "Không thể sao lưu PosterBoard.")
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
                    self.statusMessage = "Đã khôi phục cấu hình hình nền khóa PosterBoard! Hãy Respring ngay để áp dụng."
                    self.showStatusAlert = true
                } else {
                    Alertinator.shared.alert(title: "Khôi phục thất bại", body: (err as String?) ?? "Không thể khôi phục PosterBoard.")
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
                self.statusMessage = "Đã dọn \(wq_size_text(freed)) từ systemgroup.com.apple.lsd.iconscache. Hãy Respring để làm mới icon."
                self.showStatusAlert = true
            }
        }
    }
    
    private func applyAll() {
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
        
        if disableShutterSound {
            store.cacheExtra[shutterClickKey] = 0
            store.cacheExtra[MGKey.regionCode] = "LL"
            store.cacheExtra[MGKey.regionSysconfig] = "LL/A"
        } else {
            store.cacheExtra.removeObject(forKey: shutterClickKey)
        }
        store.mgCurrentDict["CacheExtra"] = store.cacheExtra
        if let mgData = try? PropertyListSerialization.data(fromPropertyList: store.mgCurrentDict, format: .binary, options: 0) {
            _ = mgWrite(mgData)
        }
        
        Haptic.shared.play(.soft)
        if autoRespring {
            mgr.shouldRespring = true
        } else {
            statusMessage = "Đã áp dụng tinh chỉnh SpringBoard & SystemGroup thành công! Hãy Respring để thấy thay đổi."
            showStatusAlert = true
        }
    }
}
