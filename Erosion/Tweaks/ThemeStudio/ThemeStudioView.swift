//
//  ThemeStudioView.swift
//  ErosionWQ
//
//  Visual Theme & Asset Modding Studio (100% MCM Container Scoped):
//  1. Apple Wallet / Passbook Card Skin Modder (com.apple.Passbook)
//  2. Lock Screen Poster & Clock Descriptor Inspector (com.apple.PosterBoard)
//  3. Safari Start Page & Experimental Flags Modder (com.apple.mobilesafari)
//  4. SystemGroup App Icon Cache Inspector (systemgroup.com.apple.lsd.iconscache)
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
                    Label("Custom Wallpapers (.tendies)", systemImage: "photo.on.rectangle.angled")
                }
                NavigationLink(destination: KeypadView()) {
                    Label("Dialer Keypad Studio (6 Built-in Themes)", systemImage: "circle.grid.3x3.fill")
                }
            } header: {
                HeaderLabel("Core Theme Engines", symbol: "paintpalette")
            }
            
            // MARK: - 2. Apple Wallet / Passbook Card Art Modder
            Section {
                if isScanning {
                    HStack {
                        ProgressView()
                        Text("Scanning MCM containers for themeable assets...")
                            .font(.caption)
                            .padding(.leading, 6)
                    }
                } else if walletAssets.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(passbookContainer.isEmpty ? "Passbook container not scanned yet." : "No cached .pkpass card images found in Passbook container.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 12) {
                            Button("Scan Containers") {
                                scanThemeContainers()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            
                            if !passbookContainer.isEmpty {
                                Button("Open Passbook Container") {
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
                            Button("Replace Art") {
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
                        Label("Browse Passbook Container", systemImage: "folder")
                    }
                }
            } header: {
                HeaderLabel("Wallet / Passbook Card Skins", symbol: "creditcard")
            } footer: {
                Text("Replaces cached card artwork inside com.apple.Passbook (/var/mobile/Containers/Data/Application/*). Original card images are backed up to Documents/Backups.")
            }
            
            // MARK: - 3. PosterBoard Lock Screen Providers
            Section {
                if posterProviders.isEmpty {
                    Button {
                        scanThemeContainers()
                    } label: {
                        Label("Scan Lock Screen Poster Providers", systemImage: "sparkles.rectangle.stack")
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
                HeaderLabel("PosterBoard Wallpaper Descriptors", symbol: "sparkles")
            } footer: {
                Text("Inspects PRBPosterExtensionDataStore inside com.apple.PosterBoard to customize Collections, Mercury, Photos, Weather, and Emoji lock screen posters.")
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
                        Label("Edit Safari Preferences & Flags (.plist)", systemImage: "safari")
                    }
                    
                    Button {
                        navigateToPath = URL(fileURLWithPath: safariContainer)
                    } label: {
                        Label("Browse Safari Data Container", systemImage: "folder.badge.gearshape")
                    }
                }
                
                HStack {
                    Label("System Icon Cache (lsd)", systemImage: "app.badge")
                    Spacer()
                    Text("\(iconCacheCount) files (\(wq_size_text(iconCacheBytes)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Button {
                    _ = wq_grant(lsdIconsCacheRoot)
                    navigateToPath = URL(fileURLWithPath: lsdIconsCacheRoot)
                } label: {
                    Label("Browse SystemGroup Icon Cache", systemImage: "square.grid.2x2")
                }
                
                Button(role: .destructive) {
                    purgeIconCache()
                } label: {
                    Label("Purge & Rebuild Icon Cache", systemImage: "arrow.counterclockwise")
                }
            } header: {
                HeaderLabel("Safari & SystemGroup Icon Cache", symbol: "cube.transparent")
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
            Button("OK", role: .cancel) {}
        } message: {
            Text(statusAlertBody)
        }
    }
    
    // MARK: - Container Scanner
    
    private func scanThemeContainers() {
        guard !isScanning else { return }
        isScanning = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            // 1. Check Icon Cache in SystemGroup
            _ = wq_grant(lsdIconsCacheRoot)
            let icBytes = wq_dir_size(lsdIconsCacheRoot)
            let subIconsDir = (lsdIconsCacheRoot as NSString).appendingPathComponent("com.apple.IconsCache")
            _ = wq_grant(subIconsDir)
            let icFiles = wq_list(subIconsDir, nil)?.count ?? (wq_list(lsdIconsCacheRoot, nil)?.count ?? 0)
            
            // 2. Discover Application Containers (PosterBoard, Passbook, MobileSafari)
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
            
            // 3. Scan PosterBoard Extension Providers
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
            
            // 4. Scan Passbook Card Art PNGs
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
            statusAlertTitle = "Invalid Image"
            statusAlertBody = "Could not convert selected image to PNG."
            showStatusAlert = true
            return
        }
        var err: NSString?
        if wq_write(asset.fullPath, pngData, &err) {
            Haptic.shared.play(.soft)
            statusAlertTitle = "Card Skin Applied!"
            statusAlertBody = "Overwrote \(asset.imageName) in \(asset.passFolderName). Original image was backed up to Documents/Backups."
            showStatusAlert = true
            scanThemeContainers()
        } else {
            statusAlertTitle = "Failed to Write Card Skin"
            statusAlertBody = (err as String?) ?? "Could not write to \(asset.fullPath)."
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
                self.statusAlertTitle = "Icon Cache Purged"
                self.statusAlertBody = "Cleared \(wq_size_text(freed)) from systemgroup.com.apple.lsd.iconscache. Respring from Home to rebuild icons."
                self.showStatusAlert = true
                self.scanThemeContainers()
            }
        }
    }
}
