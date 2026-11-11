//
//  FolderRow.swift
//  Thái Bình (ErosionWQ)
//
//  Dòng hiển thị Thư mục tích hợp WQFiles v0.9:
//  Hiển thị Bundle ID dưới tên ứng dụng (#27), Đếm số lượng mục con trong nền (#35),
//  Khôi phục trực tiếp từ thư mục AppBackups, Di chuyển liên ứng dụng & Nén ZIP.
//

import SwiftUI
import QuickLook
import ZIPFoundation

struct FolderRow: View {
    @EnvironmentObject var mgr: ErosionManager
    @AppStorage("WQDeletingDisabled") var deletingDisabled = false
    @AppStorage("WQShowItemCounts") var showItemCounts = false
    var file: FileItem
    var shouldGrant: Bool
    var isContainer: Bool = false

    @State private var previewURL: URL?
    @State private var folderType: FolderType = .normal
    @State private var showInfo = false
    @State private var appIcon: UIImage? = nil
    @State private var displayName: String? = nil
    @State private var bundleID: String? = nil
    @State private var itemCount: Int? = nil

    private var restoreBundleIDFromAppBackups: String? {
        let p = file.fileURL.path
        let backupsRoot = wq_app_backups_root_dir()
        let parent = (p as NSString).deletingLastPathComponent
        if parent == backupsRoot {
            return file.name
        }
        let grandParent = (parent as NSString).deletingLastPathComponent
        if grandParent == backupsRoot {
            return (parent as NSString).lastPathComponent
        }
        return nil
    }

    var body: some View {
        NavigationLink(destination: FileBrowserView(path: file.destURL, shouldGrant: shouldGrant)) {
            HStack(spacing: isSolariumUI() ? 12 : 10) {
                if let icon = appIcon {
                    Image(uiImage: icon)
                        .resizable()
                        .frame(width: 28, height: 28)
                        .cornerRadius(6)
                } else {
                    Image(systemName: "folder.fill")
                        .frame(width: 20, alignment: .center)
                        .foregroundStyle(file.hidden ? .secondary : Color.accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName ?? file.name)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(file.hidden ? .secondary : .primary)

                    // WQFiles v0.9 (#27): Hiển thị Bundle ID dưới tên ứng dụng thay vì UUID
                    if let bid = bundleID, !bid.isEmpty {
                        Text(bid)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else if displayName != nil {
                        Text(file.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else if showItemCounts, let count = itemCount {
                        Text("\(count) mục")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if showItemCounts, let count = itemCount, displayName == nil {
                    Text("\(count)")
                        .font(.caption2.monospacedDigit())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.12), in: Capsule())
                        .foregroundStyle(.secondary)
                }

                Button {
                    showInfo.toggle()
                } label: {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.plain)
                .foregroundStyle(file.hidden ? .secondary : .primary)
            }
        }
        .foregroundStyle(Color(.label))
        .onAppear {
            folderType = getFolderType(url: file.fileURL)
            let isContainerFolder = isContainer || file.fileURL.path.contains("/Containers/") || file.fileURL.path.contains("/SystemGroup")
            if isContainerFolder {
                DispatchQueue.global(qos: .utility).async {
                    if let bid = wq_container_label(file.fileURL.path) {
                        let name = wq_display_name(bid)
                        let icon = wq_app_icon(bid)
                        DispatchQueue.main.async {
                            self.bundleID = bid
                            self.displayName = name
                            self.appIcon = icon
                        }
                    }
                }
            } else if showItemCounts {
                loadSubfolderCount()
            }
        }
        .onChange(of: showItemCounts) { _, newValue in
            if newValue && !isContainer {
                loadSubfolderCount()
            } else {
                itemCount = nil
            }
        }
        .sheet(isPresented: $showInfo) {
            InfoViewer(file)
        }
        .quickLookPreview($previewURL)
        // WQFiles v0.9 (#36 & #32): Chỉ xóa khi vuốt sang trái (trailing) và khi Allow Deleting bật
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if !isContainer {
                if !deletingDisabled {
                    Button(role: .destructive) {
                        var err: NSString?
                        if !wq_delete(file.fileURL.path, &err) {
                            var freed: UInt64 = 0
                            _ = wq_purge_contents(file.fileURL.path, &freed)
                            if !wq_delete(file.fileURL.path, &err) {
                                try? fm.removeItem(at: file.fileURL)
                            }
                        }
                        mgr.refreshFiles.toggle()
                    } label: {
                        Label("Xóa", systemImage: "trash")
                    }
                }

                Button {
                    Alertinator.shared.prompt(title: "Đổi tên thư mục", placeholder: file.name) { result in
                        if let name = result, !name.isEmpty {
                            if renameFile(file.fileURL, to: name) {
                                mgr.refreshFiles.toggle()
                            } else {
                                Alertinator.shared.alert(title: "Không thể đổi tên thư mục!", body: Errors.checkLogs)
                            }
                        }
                    }
                } label: {
                    Label("Đổi tên", systemImage: "pencil")
                }
                .tint(.orange)
            }
        }
        .contextMenu {
            if let bid = bundleID {
                Button {
                    UIPasteboard.general.string = bid
                    Haptic.shared.play(.light)
                } label: {
                    Label("Sao chép Bundle ID (\(bid))", systemImage: "tag")
                }
            }

            Button {
                UIPasteboard.general.string = file.fileURL.path
                Haptic.shared.play(.light)
            } label: {
                Label("Sao chép Đường dẫn", systemImage: "doc.on.doc")
            }

            // WQFiles v0.9: Khôi phục trực tiếp từ thư mục AppBackups
            if let restoreBid = restoreBundleIDFromAppBackups {
                Button {
                    restoreBackupFromFolder(bundleID: restoreBid, folderPath: file.fileURL.path)
                } label: {
                    Label("Khôi phục bản Sao lưu này…", systemImage: "clock.arrow.circlepath")
                }
            }

            if !isContainer {
                Divider()

                Button {
                    showInfo.toggle()
                } label: {
                    Label("Xem thông tin", systemImage: "info.circle")
                }

                Button {
                    WQEngine.shared.startMove([file.fileURL.path])
                    Haptic.shared.play(.light)
                } label: {
                    Label("Di chuyển sang thư mục khác…", systemImage: "folder")
                }

                Button {
                    Alertinator.shared.prompt(title: "Đổi tên thư mục", placeholder: file.name) { result in
                        if let name = result, !name.isEmpty {
                            if renameFile(file.fileURL, to: name) {
                                mgr.refreshFiles.toggle()
                            } else {
                                Alertinator.shared.alert(title: "Không thể đổi tên thư mục!", body: Errors.checkLogs)
                            }
                        }
                    }
                } label: {
                    Label("Đổi tên", systemImage: "pencil")
                }

                Button {
                    let parentDir = file.fileURL.deletingLastPathComponent().path
                    WQEngine.shared.compressItems([file.fileURL.path], in: parentDir) { ok, msg in
                        if ok {
                            mgr.refreshFiles.toggle()
                        } else if zipFile(file.fileURL) {
                            mgr.refreshFiles.toggle()
                        } else {
                            Alertinator.shared.alert(title: "Không thể nén thư mục!", body: msg)
                        }
                    }
                } label: {
                    Label("Nén ZIP", systemImage: "doc.zipper")
                }

                Button {
                    if let rootVC = UIApplication.shared.connectedScenes
                        .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first {
                        wq_share_folder(rootVC, file.fileURL.path, file.name, nil)
                    }
                } label: {
                    Label("Chia sẻ dạng ZIP (AirDrop…)", systemImage: "square.and.arrow.up")
                }

                if !deletingDisabled {
                    Divider()

                    Button(role: .destructive) {
                        var err: NSString?
                        if !wq_delete(file.fileURL.path, &err) {
                            var freed: UInt64 = 0
                            _ = wq_purge_contents(file.fileURL.path, &freed)
                            if !wq_delete(file.fileURL.path, &err) {
                                try? fm.removeItem(at: file.fileURL)
                            }
                        }
                        mgr.refreshFiles.toggle()
                    } label: {
                        Label("Xóa thư mục", systemImage: "trash")
                    }
                }
            }
        }
    }

    private func loadSubfolderCount() {
        let targetPath = file.fileURL.path
        DispatchQueue.global(qos: .utility).async {
            if let names = wq_list(targetPath, nil) {
                DispatchQueue.main.async {
                    self.itemCount = names.count
                }
            }
        }
    }

    private func restoreBackupFromFolder(bundleID: String, folderPath: String) {
        let engine = WQEngine.shared
        guard let app = engine.apps.first(where: { $0.bundleID == bundleID }) else {
            Alertinator.shared.alert(
                title: "Chưa tìm thấy ứng dụng",
                body: "Ứng dụng \(bundleID) chưa được cài đặt hoặc chưa được quét trong tab Ứng dụng. Hãy mở tab Ứng dụng để quét trước khi khôi phục."
            )
            return
        }
        let targetBackup: String?
        if (folderPath as NSString).deletingLastPathComponent == wq_app_backups_root_dir() {
            targetBackup = wq_latest_app_backup(bundleID)
        } else {
            targetBackup = folderPath
        }
        guard let backupPath = targetBackup else {
            Alertinator.shared.alert(title: "Không có bản sao lưu", body: "Không tìm thấy bản sao lưu hợp lệ cho \(app.name).")
            return
        }
        engine.restoreApp(app, from: backupPath) { ok, msg in
            Alertinator.shared.alert(title: ok ? "Đã khôi phục" : "Khôi phục thất bại", body: msg)
        }
    }
}
