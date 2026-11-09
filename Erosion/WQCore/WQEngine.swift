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
    
    private init() {
        self.deviceLine = wq_device_line()
        refreshActiveGroup()
    }
    
    func refreshActiveGroup() {
        if let g = wq_app_group() {
            self.activeAppGroup = g
        } else {
            self.activeAppGroup = "No App Group (Re-sign with group entitlement)"
        }
    }
    
    // MARK: - App Manager
    
    func scanApps() {
        guard !isScanningApps else { return }
        isScanningApps = true
        scanAppProgress = "Enumerating app containers..."
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let root = "/private/var/mobile/Containers/Data/Application"
            // Fast inode scan with 400,000 bounds
            let containers = wq_enumerate(root, 400000) { done, total, found in
                DispatchQueue.main.async {
                    let pct = total > 0 ? (done * 100 / total) : 0
                    self.scanAppProgress = "Scanning containers... \(pct)% (\(found) found)"
                }
            } ?? []
            
            var discovered: [AppInfoItem] = []
            var totalBytes: UInt64 = 0
            let myHome = (NSHomeDirectory() as NSString).resolvingSymlinksInPath
            
            for (idx, container) in containers.enumerated() {
                let resolved = (container as NSString).resolvingSymlinksInPath
                if resolved == myHome { continue }
                
                DispatchQueue.main.async {
                    self.scanAppProgress = "Analyzing app \(idx + 1) of \(containers.count)..."
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
                    let msg = "Backup saved to: AppBackups/\(app.bundleID)/\(stampDir?.lastPathComponent ?? "")"
                    completion(true, msg)
                } else {
                    completion(false, (error as String?) ?? "Backup failed")
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
                    completion(true, "Data successfully restored for \(app.name). Please relaunch the app.")
                } else {
                    completion(false, (error as String?) ?? "Restore failed")
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
                completion(ok, "Freed \(freedStr). App container is reset.")
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
                    completion(true, "Imported backup snapshot: \(stamp)")
                }
            } catch {
                try? FileManager.default.removeItem(at: tmpExtract)
                DispatchQueue.main.async {
                    completion(false, "Import failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    var storageSummaryText: String {
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let free = attrs[.systemFreeSize] as? UInt64,
           let total = attrs[.systemSize] as? UInt64 {
            let used = total > free ? (total - free) : 0
            return "\(wq_size_text(used)) used / \(wq_size_text(free)) free (of \(wq_size_text(total)))"
        }
        return "Storage stats unavailable"
    }
    
    var totalSafetyBackupsText: String {
        let safeBytes = wq_dir_size(wq_backup_root())
        let docs = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
        let appBackupsBytes = wq_dir_size((docs as NSString).appendingPathComponent("AppBackups"))
        return "App Snapshots: \(wq_size_text(appBackupsBytes)) · File Backups: \(wq_size_text(safeBytes))"
    }
    
    // MARK: - Cache Cleaner
    
    func scanCaches() {
        guard !isScanningCaches else { return }
        isScanningCaches = true
        cleanStatusMessage = "Scanning application caches..."
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var items: [CacheScanItem] = []
            let roots = [
                "/private/var/mobile/Containers/Data/Application",
                "/private/var/mobile/Containers/Data/PluginKitPlugin"
            ]
            
            for root in roots {
                let containers = wq_enumerate(root, 400000, nil) ?? []
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
            
            // CrashReporter logs
            let crashDir = "/private/var/mobile/Library/Logs/CrashReporter"
            let crashBytes = wq_dir_size(crashDir)
            if crashBytes > 0 {
                items.append(CacheScanItem(
                    name: "iOS Crash Reports",
                    bundleID: nil,
                    cacheBytes: crashBytes,
                    tempBytes: 0,
                    targets: [crashDir]
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
        cleanStatusMessage = "Purging selected caches..."
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            var totalFreed: UInt64 = 0
            var allOk = true
            
            for (idx, item) in selected.enumerated() {
                DispatchQueue.main.async {
                    self.cleanStatusMessage = "Cleaning \(idx + 1) of \(selected.count): \(item.name)"
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
            let crashDir = "/private/var/mobile/Library/Logs/CrashReporter"
            var freed: UInt64 = 0
            _ = wq_purge_contents(crashDir, &freed)
            DispatchQueue.main.async {
                completion(freed)
            }
        }
    }
}
