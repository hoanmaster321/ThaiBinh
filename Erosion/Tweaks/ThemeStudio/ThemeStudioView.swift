//
//  ThemeStudioView.swift
//  ThaiBinh (ErosionWQ)
//
//  Visual Theme & Asset Modding Studio (100% MCM Container Scoped)
//  Bản quyền © 2026 ThaiBinh (hoanmaster321)
//

import SwiftUI

struct WalletCardAsset: Identifiable {
    let id = UUID()
    let passFolderName: String
    let imageName: String
    let fullPath: String
    let sizeBytes: UInt64
}

struct PosterProviderItem: Identifiable {
    let id = UUID()
    let bundleID: String
    let displayName: String
    let descriptorsPath: String
    let descriptorCount: Int
}

struct ThemeStudioView: View {
    @EnvironmentObject private var mgr: ErosionManager
    
    @State private var isScanning = false
    @State private var passbookContainer: String = ""
    @State private var walletAssets: [WalletCardAsset] = []
    @State private var selectedWalletAsset: WalletCardAsset? = nil
    @State private var showPhotoPicker = false
    
    @State private var posterBoardContainer: String = ""
    @State private var posterProviders: [PosterProviderItem] = []
    
    @State private var safariContainer: String = ""
    @State private var iconCacheCount: Int = 0
    @State private var iconCacheBytes: UInt64 = 0
    
    @State private var navigateToPath: URL? = nil
    @State private var inspectPlistURL: URL? = nil
    @State private var showPlistSheet = false
    @State private var statusAlertTitle = ""
    @State private var statusAlertBody = ""
    @State private var showStatusAlert = false
    
    private let lsdIconsCacheRoot = "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.lsd.iconscache/Library/Caches"
    
    var body: some View {
        List {
            // MARK: - 1. Quick Links to Built-in Themers
            Section {
                NavigationLink(destination: PosterBoardView()) {
                    Label("Cài Hình nền Động (.tendies)", systemImage: "photo.on.rectangle.angled")
                }
                NavigationLink(destination: KeypadView()) {
                    Label("Mod Bàn phím Gọi điện (6 Theme dựng sẵn)", systemImage: "circle.grid.3x3.fill")
                }
            } header: {
                HeaderLabel("Công cụ Theme Chính", symbol: "paintpalette")
            }
            
            // MARK: - 2. Apple Wallet / Passbook Card Art Modder
            Section {
                if isScanning {
                    HStack {
                        ProgressView()
                        Text("Đang quét các MCM container để tìm tài nguyên...")
                            .font(.caption)
                            .padding(.leading, 6)
                    }
                } else if walletAssets.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(passbookContainer.isEmpty ? "Chưa quét container Ví (Passbook)." : "Không tìm thấy ảnh thẻ .pkpass nào trong Ví Apple Wallet.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 12) {
                            Button("Quét Container") {
                                scanThemeContainers()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            
                            if !passbookContainer.isEmpty {
                                Button("Mở thư mục Passbook") {
                                    navigateToPath = URL(fileURLWithPath: passbookContainer)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } else {
                    ForEach(walletAssets) { asset in
                        HStack {
                            Image(systemName: "creditcard.fill")
                                .foregroundStyle(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(asset.imageName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("\(asset.passFolderName) · \(wq_size_text(asset.sizeBytes))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Button("Đổi ảnh thẻ") {
                                selectedWalletAsset = asset
                                showPhotoPicker = true
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                    
                    Button {
                        navigateToPath = URL(fileURLWithPath: passbookContainer)
                    } label: {
                        Label("Duyệt Container Passbook", systemImage: "folder")
                    }
                }
            } header: {
                HeaderLabel("Mod Skin Thẻ Apple Wallet / Passbook", symbol: "creditcard")
            } footer: {
                Text("Thay thế ảnh nền thẻ lưu trong com.apple.Passbook (/var/mobile/Containers/Data/Application/*). Ảnh gốc được tự động sao lưu vào Documents/Backups.")
            }
            
            // MARK: - 3. PosterBoard Lock Screen Providers
            Section {
                if posterProviders.isEmpty {
                    Button {
                        scanThemeContainers()
                    } label: {
                        Label("Quét Danh mục Hình nền PosterBoard", systemImage: "sparkles.rectangle.stack")
                    }
                } else {
                    ForEach(posterProviders) { provider in
                        Button {
                            navigateToPath = URL(fileURLWithPath: provider.descriptorsPath)
                        } label: {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                    .foregroundStyle(.purple)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(provider.displayName)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    Text("\(provider.descriptorCount) descriptors · \(provider.bundleID)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            } header: {
                HeaderLabel("Các bộ Hình nền Màn hình khóa (PosterBoard)", symbol: "sparkles")
            } footer: {
                Text("Truy cập trực tiếp PRBPosterExtensionDataStore bên trong com.apple.PosterBoard để tùy biến Collections, Mercury, Photos, Weather và Emoji.")
            }
            
            // MARK: - 4. Safari & SystemGroup Icon Cache
            Section {
                if !safariContainer.isEmpty {
                    Button {
                        let prefs = (safariContainer as NSString).appendingPathComponent("Library/Preferences/com.apple.mobilesafari.plist")
                        _ = wq_grant((safariContainer as NSString).appendingPathComponent("Library/Preferences"))
                        inspectPlistURL = URL(fileURLWithPath: prefs)
                        showPlistSheet = true
                    } label: {
                        Label("Sửa Cài đặt & Cờ ẩn Safari (.plist)", systemImage: "safari")
                    }
                    
                    Button {
                        navigateToPath = URL(fileURLWithPath: safariContainer)
                    } label: {
                        Label("Mở Container Dữ liệu Safari", systemImage: "folder.badge.gearshape")
                    }
                }
                
                HStack {
                    Label("Bộ nhớ đệm Icon (lsd)", systemImage: "app.badge")
                    Spacer()
                    Text("\(iconCacheCount) tệp (\(wq_size_text(iconCacheBytes)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Button {
                    _ = wq_grant(lsdIconsCacheRoot)
                    navigateToPath = URL(fileURLWithPath: lsdIconsCacheRoot)
                } label: {
                    Label("Duyệt Thư mục Icon Cache (SystemGroup)", systemImage: "square.grid.2x2")
                }
                
                Button(role: .destructive) {
                    purgeIconCache()
                } label: {
                    Label("Xóa & Làm mới Icon Cache Hệ thống", systemImage: "arrow.counterclockwise")
                }
            } header: {
                HeaderLabel("Safari & Bộ nhớ đệm Biểu tượng", symbol: "cube.transparent")
            }
        }
        .navigationTitle("Theme Studio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    scanThemeContainers()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .onAppear {
            if posterProviders.isEmpty && walletAssets.isEmpty {
                scanThemeContainers()
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            ImagePickerView { pickedData in
                if let asset = selectedWalletAsset {
                    applyWalletCardImage(pickedData, to: asset)
                }
            }
        }
        .sheet(isPresented: $showPlistSheet) {
            if let url = inspectPlistURL {
                PlistViewer(url)
            }
        }
        .background(
            Group {
                if let target = navigateToPath {
                    NavigationLink(
                        destination: FileBrowserView(path: target, isContainer: false, shouldGrant: true),
                        isActive: Binding(
                            get: { navigateToPath != nil },
                            set: { if !$0 { navigateToPath = nil } }
                        )
                    ) {
                        EmptyView()
                    }
                }
            }
        )
        .alert(statusAlertTitle, isPresented: $showStatusAlert) {
            Button("Đóng", role: .cancel) {}
        } message: {
            Text(statusAlertBody)
        }
    }
    
    // MARK: - Container Scanner
    
    private func scanThemeContainers() {
        guard !isScanning else { return }
        isScanning = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            _ = wq_grant(lsdIconsCacheRoot)
            let icBytes = wq_dir_size(lsdIconsCacheRoot)
            let subIconsDir = (lsdIconsCacheRoot as NSString).appendingPathComponent("com.apple.IconsCache")
            _ = wq_grant(subIconsDir)
            let icFiles = wq_list(subIconsDir, nil)?.count ?? (wq_list(lsdIconsCacheRoot, nil)?.count ?? 0)
            
            var foundPoster = ""
            var foundPassbook = ""
            var foundSafari = ""
            
            let cachedApps = WQEngine.shared.apps
            for app in cachedApps {
                if app.bundleID == "com.apple.PosterBoard" { foundPoster = app.containerPath }
                if app.bundleID == "com.apple.Passbook" { foundPassbook = app.containerPath }
                if app.bundleID == "com.apple.mobilesafari" { foundSafari = app.containerPath }
            }
            
            if foundPoster.isEmpty || foundPassbook.isEmpty || foundSafari.isEmpty {
                let appRoot = "/private/var/mobile/Containers/Data/Application"
                let containers = wq_enumerate(appRoot, 400000, nil) ?? []
                for c in containers {
                    guard let bid = wq_container_label(c) else { continue }
                    if bid == "com.apple.PosterBoard" { foundPoster = c }
                    else if bid == "com.apple.Passbook" { foundPassbook = c }
                    else if bid == "com.apple.mobilesafari" { foundSafari = c }
                }
            }
            
            var discoveredProviders: [PosterProviderItem] = []
            if !foundPoster.isEmpty {
                let storeRoot = (foundPoster as NSString).appendingPathComponent("Library/Application Support/PRBPosterExtensionDataStore")
                _ = wq_grant(storeRoot)
                if let versions = wq_list(storeRoot, nil) {
                    for ver in versions {
                        let extRoot = ((storeRoot as NSString).appendingPathComponent(ver) as NSString).appendingPathComponent("Extensions")
                        _ = wq_grant(extRoot)
                        if let extIDs = wq_list(extRoot, nil) {
                            for extID in extIDs {
                                let descrPath = ((extRoot as NSString).appendingPathComponent(extID) as NSString).appendingPathComponent("descriptors")
                                _ = wq_grant(descrPath)
                                let count = wq_list(descrPath, nil)?.count ?? 0
                                let shortName = wq_display_name(extID) ?? (extID as NSString).pathExtension
                                discoveredProviders.append(PosterProviderItem(
                                    bundleID: extID,
                                    displayName: shortName.isEmpty ? extID : shortName,
                                    descriptorsPath: descrPath,
                                    descriptorCount: count
                                ))
                            }
                        }
                    }
                }
            }
            
            var discoveredCards: [WalletCardAsset] = []
            if !foundPassbook.isEmpty {
                _ = wq_grant(foundPassbook)
                let candidateDirs = [
                    (foundPassbook as NSString).appendingPathComponent("Library/Passes/Cards"),
                    (foundPassbook as NSString).appendingPathComponent("Documents")
                ]
                for dir in candidateDirs {
                    _ = wq_grant(dir)
                    guard let entries = wq_list(dir, nil) else { continue }
                    for entry in entries where entry.hasSuffix(".pkpass") || entry.hasSuffix(".raw") {
                        let passDir = (dir as NSString).appendingPathComponent(entry)
                        _ = wq_grant(passDir)
                        guard let files = wq_list(passDir, nil) else { continue }
                        for f in files where f.lowercased().hasSuffix(".png") {
                            let full = (passDir as NSString).appendingPathComponent(f)
                            var st = stat()
                            let sz = wq_stat(full, &st) ? UInt64(st.st_size) : 0
                            discoveredCards.append(WalletCardAsset(
                                passFolderName: entry,
                                imageName: f,
                                fullPath: full,
                                sizeBytes: sz
                            ))
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.iconCacheCount = icFiles
                self.iconCacheBytes = icBytes
                self.posterBoardContainer = foundPoster
                self.passbookContainer = foundPassbook
                self.safariContainer = foundSafari
                self.posterProviders = discoveredProviders
                self.walletAssets = discoveredCards
                self.isScanning = false
            }
        }
    }
    
    private func applyWalletCardImage(_ imageData: Data, to asset: WalletCardAsset) {
        guard let uiImage = UIImage(data: imageData), let pngData = uiImage.pngData() else {
            statusAlertTitle = "Ảnh không hợp lệ"
            statusAlertBody = "Không thể chuyển đổi ảnh đã chọn sang định dạng PNG."
            showStatusAlert = true
            return
        }
        var err: NSString?
        if wq_write(asset.fullPath, pngData, &err) {
            Haptic.shared.play(.soft)
            statusAlertTitle = "Đã đổi Skin Thẻ!"
            statusAlertBody = "Đã ghi đè \(asset.imageName) trong \(asset.passFolderName). Ảnh gốc đã được sao lưu vào Documents/Backups."
            showStatusAlert = true
            scanThemeContainers()
        } else {
            statusAlertTitle = "Lỗi ghi ảnh thẻ"
            statusAlertBody = (err as String?) ?? "Không thể ghi vào \(asset.fullPath)."
            showStatusAlert = true
        }
    }
    
    private func purgeIconCache() {
        DispatchQueue.global(qos: .userInitiated).async {
            _ = wq_grant(lsdIconsCacheRoot)
            var freed: UInt64 = 0
            _ = wq_purge_contents(lsdIconsCacheRoot, &freed)
            DispatchQueue.main.async {
                Haptic.shared.play(.heavy)
                self.statusAlertTitle = "Đã xóa Icon Cache"
                self.statusAlertBody = "Đã giải phóng \(wq_size_text(freed)) từ systemgroup.com.apple.lsd.iconscache. Hãy Respring để làm mới biểu tượng."
                self.showStatusAlert = true
                self.scanThemeContainers()
            }
        }
    }
}
