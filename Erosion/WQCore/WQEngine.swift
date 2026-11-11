//
//  WQEngine.swift
//  ErosionWQ
//
//  Unified Swift Service for WQFiles App Manager, Cache Cleaner & Fast Inode Access
//

import SwiftUI
import Combine
import ZIPFoundation

struct AppInfoItem: Identifiable, Hashable {
    var id: String { containerPath }
    let containerPath: String
    let bundleID: String
    let name: String
    let bytes: UInt64
    let formattedBytes: String
    let hasBackup: Bool
    let latestBackupPath: String?
    let allBackupPaths: [String]
    
    var backupCount: Int {
        return allBackupPaths.count
    }
    
    var icon: UIImage? {
        return wq_app_icon(bundleID)
    }
}

class CacheScanItem: Identifiable, ObservableObject {
    var id: String { bundleID ?? name }
    let name: String
    let bundleID: String?
    let cacheBytes: UInt64
    let tempBytes: UInt64
    let totalBytes: UInt64
    let targets: [String]
    @Published var isSelected: Bool = false
    
    init(name: String, bundleID: String?, cacheBytes: UInt64, tempBytes: UInt64, targets: [String]) {
        self.name = name
        self.bundleID = bundleID
        self.cacheBytes = cacheBytes
        self.tempBytes = tempBytes
        self.totalBytes = cacheBytes + tempBytes
        self.targets = targets
        self.isSelected = false
    }
    
    var formattedSize: String {
        return wq_size_text(totalBytes)
    }
    
    var icon: UIImage? {
        if let bid = bundleID {
            return wq_app_icon(bid)
        }
        return UIImage(systemName: "stethoscope")
    }
}

final class WQEngine: ObservableObject {
    static let shared = WQEngine()
    
    @Published var apps: [AppInfoItem] = []
    @Published var isScanningApps = false
    @Published var scanAppProgress: String = ""
    @Published var totalAppDataBytes: UInt64 = 0
    
    @Published var cacheItems: [CacheScanItem] = []
    @Published var isScanningCaches = false
    @Published var isCleaningCaches = false
    @Published var cleanStatusMessage: String = ""
    @Published var cleanResultAlert: String? = nil
    
    @Published var activeAppGroup: String = ""
    @Published var deviceLine: String = ""
    @Published var pendingMovePaths: [String] = []
    
    private init() {
        self.deviceLine = wq_device_line()
        refreshActiveGroup()
    }
    
    func refreshActiveGroup() {
        if let g = wq_app_group() {
            self.activeAppGroup = g
        } else {
            self.activeAppGroup = "Chưa có App Group (Cần ký lại với quyền App Group)"
        }
    }
    
    // MARK: - App Manager
    
    func scanApps(forceRefresh: Bool = false) {
        guard !isScanningApps else { return }
        isScanningApps = true
        scanAppProgress = "Đang đọc cơ sở dữ liệu ứng dụng (LaunchServices v0.9)..."
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            if forceRefresh {
                wq_enumerate_invalidate()
                wq_display_names_reset_miss()
            }
            
            let root = "/private/var/mobile/Containers/Data/Application"
            // WQFiles v0.8: maxInode = 0 uses MCM / LaunchServices DB fast path + persistent incremental scan
            var containers = wq_enumerate(root, 0) { done, total, found in
                DispatchQueue.main.async {
                    let pct = total > 0 ? (done * 100 / total) : 0
                    self.scanAppProgress = "Đang tìm container... \(pct)% (Đã thấy \(found))"
                }
            } ?? []
            if containers.isEmpty {
                containers = wq_enumerate(root, 400000, nil) ?? []
            }
            
            var discovered: [AppInfoItem] = []
            var totalBytes: UInt64 = 0
            let myHome = (NSHomeDirectory() as NSString).resolvingSymlinksInPath
            
            for (idx, container) in containers.enumerated() {
                let resolved = (container as NSString).resolvingSymlinksInPath
                if resolved == myHome { continue }
                
                DispatchQueue.main.async {
                    self.scanAppProgress = "Đang phân tích ứng dụng \(idx + 1)/\(containers.count)..."
                }
                
                guard let bundleID = wq_container_label(container), !bundleID.isEmpty else {
                    continue
                }
                
                let displayName = wq_display_name(bundleID) ?? (bundleID as NSString).lastPathComponent
                
                var appSize: UInt64 = 0
                for part in ["Documents", "Library", "tmp"] {
                    let sub = (container as NSString).appendingPathComponent(part)
                    appSize += wq_dir_size(sub)
                }
                
                totalBytes += appSize
                let latestBackup = wq_latest_app_backup(bundleID)
                let allBackups = wq_all_app_backups(bundleID)
                
                discovered.append(AppInfoItem(
                    containerPath: container,
                    bundleID: bundleID,
                    name: displayName,
                    bytes: appSize,
                    formattedBytes: wq_size_text(appSize),
                    hasBackup: latestBackup != nil,
                    latestBackupPath: latestBackup,
                    allBackupPaths: allBackups
                ))
            }
            
            discovered.sort { $0.bytes > $1.bytes }
            
            DispatchQueue.main.async {
                self.apps = discovered
                self.totalAppDataBytes = totalBytes
                self.isScanningApps = false
                self.scanAppProgress = ""
            }
        }
    }
    
    func backupApp(_ app: AppInfoItem, completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var stampDir: NSString?
            var error: NSString?
            let ok = wq_backup_app_data(app.containerPath, app.bundleID, &stampDir, &error)
            
            DispatchQueue.main.async {
                if ok {
                    self.scanApps()
                    let msg = "Đã lưu bản sao lưu tại: AppBackups/\(app.bundleID)/\(stampDir?.lastPathComponent ?? "")"
                    completion(true, msg)
                } else {
                    completion(false, (error as String?) ?? "Sao lưu thất bại")
                }
            }
        }
    }
    
    func restoreApp(_ app: AppInfoItem, from backupPath: String, completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSString?
            let ok = wq_restore_app_data(backupPath, app.containerPath, &error)
            
            DispatchQueue.main.async {
                if ok {
                    self.scanApps()
                    completion(true, "Đã khôi phục dữ liệu thành công cho \(app.name). Vui lòng mở lại ứng dụng.")
                } else {
                    completion(false, (error as String?) ?? "Khôi phục thất bại")
                }
            }
        }
    }
    
    func clearAppData(_ app: AppInfoItem, completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var freed: UInt64 = 0
            let ok = wq_clear_app_data(app.containerPath, &freed)
            
            DispatchQueue.main.async {
                self.scanApps()
                let freedStr = wq_size_text(freed)
                completion(ok, "Đã giải phóng \(freedStr). Container ứng dụng đã được làm mới.")
            }
        }
    }
    
    func shareBackup(_ app: AppInfoItem, backupPath: String? = nil, from viewController: UIViewController, sourceView: UIView?) {
        guard let target = backupPath ?? app.latestBackupPath else { return }
        let zipTitle = "\(app.name) \(URL(fileURLWithPath: target).lastPathComponent)"
        wq_share_folder(viewController, target, zipTitle, sourceView)
    }
    
    func deleteBackupSnapshot(_ snapshotPath: String) -> Bool {
        let ok = wq_delete_app_backup(snapshotPath)
        if ok {
            scanApps()
        }
        return ok
    }
    
    func importBackupZip(for app: AppInfoItem, from zipURL: URL, completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let stopAccess = zipURL.startAccessingSecurityScopedResource()
            defer {
                if stopAccess {
                    zipURL.stopAccessingSecurityScopedResource()
                }
            }
            
            let fmt = DateFormatter()
            fmt.locale = Locale(identifier: "en_US_POSIX")
            fmt.dateFormat = "yyyy-MM-dd HH.mm.ss"
            let stamp = "Imported-" + fmt.string(from: Date())
            
            let rootDir = URL(fileURLWithPath: wq_app_backup_root(app.bundleID))
            let destDir = rootDir.appendingPathComponent(stamp)
            let tmpExtract = URL.temporaryDirectory.appendingPathComponent("WQImport-\(UUID().uuidString)")
            
            do {
                try? FileManager.default.removeItem(at: tmpExtract)
                try FileManager.default.createDirectory(at: tmpExtract, withIntermediateDirectories: true)
                try FileManager.default.unzipItem(at: zipURL, to: tmpExtract)
                
                // Determine if the zip had a top-level wrapper folder or directly contained Documents/Library
                var sourceRoot = tmpExtract
                let children = (try? FileManager.default.contentsOfDirectory(at: tmpExtract, includingPropertiesForKeys: nil)) ?? []
                if children.count == 1,
                   let first = children.first,
                   (try? first.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true,
                   first.lastPathComponent != "Documents" && first.lastPathComponent != "Library" {
                    sourceRoot = first
                }
                
                try FileManager.default.createDirectory(at: destDir.deletingLastPathComponent(), withIntermediateDirectories: true)
                try FileManager.default.moveItem(at: sourceRoot, to: destDir)
                try? FileManager.default.removeItem(at: tmpExtract)
                
                DispatchQueue.main.async {
                    self.scanApps()
                    completion(true, "Đã nhập bản sao lưu: \(stamp)")
                }
            } catch {
                try? FileManager.default.removeItem(at: tmpExtract)
                DispatchQueue.main.async {
                    completion(false, "Nhập thất bại: \(error.localizedDescription)")
                }
            }
        }
    }
    
    var storageSummaryText: String {
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let free = attrs[.systemFreeSize] as? UInt64,
           let total = attrs[.systemSize] as? UInt64 {
            let used = total > free ? (total - free) : 0
            return "Đã dùng \(wq_size_text(used)) / Trống \(wq_size_text(free)) (Tổng \(wq_size_text(total)))"
        }
        return "Không có thông tin bộ nhớ"
    }
    
    var totalSafetyBackupsText: String {
        let safeBytes = wq_dir_size(wq_backup_root())
        let docs = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
        let appBackupsBytes = wq_dir_size((docs as NSString).appendingPathComponent("AppBackups"))
        return "Sao lưu App: \(wq_size_text(appBackupsBytes)) · Sao lưu Tệp: \(wq_size_text(safeBytes))"
    }
    
    // MARK: - Cache Cleaner
    
    func scanCaches(forceRefresh: Bool = false) {
        guard !isScanningCaches else { return }
        isScanningCaches = true
        cleanStatusMessage = "Đang quét bộ nhớ đệm ứng dụng..."
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            if forceRefresh {
                wq_enumerate_invalidate()
                wq_display_names_reset_miss()
            }
            
            var items: [CacheScanItem] = []
            let roots = [
                "/private/var/mobile/Containers/Data/Application",
                "/private/var/mobile/Containers/Data/PluginKitPlugin",
                "/private/var/mobile/Containers/Data/InternalDaemon",
                "/private/var/mobile/Containers/Shared/AppGroup"
            ]
            
            for root in roots {
                let containers = wq_enumerate(root, 0, nil) ?? wq_enumerate(root, 400000, nil) ?? []
                for container in containers {
                    guard let bundleID = wq_container_label(container) else { continue }
                    let cachesPath = (container as NSString).appendingPathComponent("Library/Caches")
                    let tmpPath = (container as NSString).appendingPathComponent("tmp")
                    
                    let cacheBytes = wq_dir_size(cachesPath)
                    let tmpBytes = wq_dir_size(tmpPath)
                    
                    if (cacheBytes + tmpBytes) > 1024 * 1024 { // larger than 1MB
                        let name = wq_display_name(bundleID) ?? (bundleID as NSString).lastPathComponent
                        let item = CacheScanItem(
                            name: name,
                            bundleID: bundleID,
                            cacheBytes: cacheBytes,
                            tempBytes: tmpBytes,
                            targets: [cachesPath, tmpPath]
                        )
                        items.append(item)
                    }
                }
            }
            
            // SystemGroup Icon & Analytics Caches (MCM-accessible)
            let lsdCacheDir = "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.lsd.iconscache/Library/Caches"
            _ = wq_grant(lsdCacheDir)
            let lsdBytes = wq_dir_size(lsdCacheDir)
            if lsdBytes > 0 {
                items.append(CacheScanItem(
                    name: "LaunchServices Icon Cache (SystemGroup)",
                    bundleID: nil,
                    cacheBytes: lsdBytes,
                    tempBytes: 0,
                    targets: [lsdCacheDir]
                ))
            }
            
            let diagDir = "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.osanalyticsdiagnostics"
            _ = wq_grant(diagDir)
            let diagBytes = wq_dir_size(diagDir)
            if diagBytes > 0 {
                items.append(CacheScanItem(
                    name: "OSAnalytics Diagnostics (SystemGroup)",
                    bundleID: nil,
                    cacheBytes: diagBytes,
                    tempBytes: 0,
                    targets: [diagDir]
                ))
            }
            
            items.sort { $0.totalBytes > $1.totalBytes }
            
            DispatchQueue.main.async {
                self.cacheItems = items
                self.isScanningCaches = false
                self.cleanStatusMessage = ""
            }
        }
    }
    
    func selectCacheWhere(_ condition: (CacheScanItem) -> Bool) {
        for item in cacheItems {
            item.isSelected = condition(item)
        }
        objectWillChange.send()
    }
    
    func cleanSelectedCaches(completion: @escaping (UInt64, Bool) -> Void) {
        guard !isCleaningCaches else { return }
        let selected = cacheItems.filter { $0.isSelected }
        guard !selected.isEmpty else { return }
        
        isCleaningCaches = true
        cleanStatusMessage = "Đang dọn dẹp các bộ nhớ đệm đã chọn..."
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            var totalFreed: UInt64 = 0
            var allOk = true
            
            for (idx, item) in selected.enumerated() {
                DispatchQueue.main.async {
                    self.cleanStatusMessage = "Đang dọn \(idx + 1)/\(selected.count): \(item.name)"
                }
                for dir in item.targets {
                    var freed: UInt64 = 0
                    if !wq_purge_contents(dir, &freed) {
                        allOk = false
                    }
                    totalFreed += freed
                }
            }
            
            DispatchQueue.main.async {
                self.isCleaningCaches = false
                self.cleanStatusMessage = ""
                self.scanCaches()
                completion(totalFreed, allOk)
            }
        }
    }
    
    func cleanCrashLogs(completion: @escaping (UInt64) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var totalFreed: UInt64 = 0
            let targets = [
                "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.osanalyticsdiagnostics",
                "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.lsd.iconscache/Library/Caches"
            ]
            for dir in targets {
                _ = wq_grant(dir)
                var freed: UInt64 = 0
                _ = wq_purge_contents(dir, &freed)
                totalFreed += freed
            }
            DispatchQueue.main.async {
                completion(totalFreed)
            }
        }
    }
    
    // MARK: - WQFiles v0.9 Move, Compress, Extract & Free Name Helpers
    
    func startMove(_ paths: [String]) {
        pendingMovePaths = paths
    }
    
    func cancelMove() {
        pendingMovePaths = []
    }
    
    func canMove(to destDir: String) -> Bool {
        guard !pendingMovePaths.isEmpty else { return false }
        for path in pendingMovePaths {
            let parent = (path as NSString).deletingLastPathComponent
            if parent == destDir { return false }
            if destDir == path || destDir.hasPrefix(path + "/") { return false }
        }
        return true
    }
    
    func movePendingItems(to destDir: String, completion: @escaping (Bool, String) -> Void) {
        let paths = pendingMovePaths
        guard !paths.isEmpty else { return }
        pendingMovePaths = []
        
        DispatchQueue.global(qos: .userInitiated).async {
            var failed = 0
            var firstErr: String? = nil
            for p in paths {
                var err: NSString?
                if !wq_move(p, destDir, &err) {
                    failed += 1
                    if firstErr == nil {
                        firstErr = "\((p as NSString).lastPathComponent): \((err as String?) ?? "Thất bại")"
                    }
                }
            }
            DispatchQueue.main.async {
                if failed == 0 {
                    completion(true, "Đã di chuyển \(paths.count) mục vào thư mục hiện tại.")
                } else {
                    let msg = paths.count == 1 ? (firstErr ?? "Không thể di chuyển")
                        : "Không thể di chuyển \(failed)/\(paths.count) mục.\n\n\(firstErr ?? "")"
                    completion(false, msg)
                }
            }
        }
    }
    
    func unusedName(in dirPath: String, base: String, ext: String?) -> String {
        let existing = Set((wq_list(dirPath, nil) ?? []).map { $0.lowercased() })
        for n in 1..<10000 {
            let stem = n == 1 ? base : "\(base) \(n)"
            let candidate: String
            if let e = ext, !e.isEmpty {
                candidate = (stem as NSString).appendingPathExtension(e) ?? "\(stem).\(e)"
            } else {
                candidate = stem
            }
            if !existing.contains(candidate.lowercased()) {
                return candidate
            }
        }
        return "\(base) \(UUID().uuidString)"
    }
    
    func compressItems(_ paths: [String], in dirPath: String, completion: @escaping (Bool, String) -> Void) {
        guard !paths.isEmpty else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let base = paths.count == 1 ? ((paths[0] as NSString).lastPathComponent) : "Archive"
            let zipName = self.unusedName(in: dirPath, base: base, ext: "zip")
            let destZip = (dirPath as NSString).appendingPathComponent(zipName)
            var skipped: UInt = 0
            var err: NSString?
            let ok = wq_compress_items(paths, destZip, &skipped, &err)
            DispatchQueue.main.async {
                if ok {
                    let note = skipped > 0
                        ? "Đã tạo \(zipName). Đã bỏ qua \(skipped) liên kết tượng trưng hoặc tệp đặc biệt."
                        : "Đã nén thành công \(paths.count) mục thành \(zipName)."
                    completion(true, note)
                } else {
                    completion(false, (err as String?) ?? "Không thể tạo tệp ZIP.")
                }
            }
        }
    }
    
    func extractZip(_ zipPath: String, in dirPath: String, completion: @escaping (Bool, String) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let rawBase = ((zipPath as NSString).lastPathComponent as NSString).deletingPathExtension
            let base = rawBase.isEmpty ? "Archive" : rawBase
            let folderName = self.unusedName(in: dirPath, base: base, ext: nil)
            let destFolder = (dirPath as NSString).appendingPathComponent(folderName)
            var files: UInt = 0
            var skipped: UInt = 0
            var err: NSString?
            let ok = wq_extract_zip(zipPath, destFolder, &files, &skipped, &err)
            DispatchQueue.main.async {
                if ok {
                    let note = skipped > 0
                        ? "Đã giải nén \(files) tệp vào thư mục \(folderName) (bỏ qua \(skipped) symlink)."
                        : "Đã giải nén \(files) tệp vào thư mục \(folderName)."
                    completion(true, note)
                } else {
                    completion(false, (err as String?) ?? "Không thể giải nén tệp ZIP.")
                }
            }
        }
    }
}
