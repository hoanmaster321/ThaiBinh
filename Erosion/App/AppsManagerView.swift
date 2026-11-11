//
//  AppsManagerView.swift
//  ThaiBinh (ErosionWQ)
//
//  Quản lý Dữ liệu Ứng dụng: Sao lưu, Khôi phục, Đa Snapshot, Nhập/Xuất ZIP, Sửa Plist & Xóa dữ liệu
//  Bản quyền © 2026 ThaiBinh (hoanmaster321)
//

import SwiftUI
import UniformTypeIdentifiers

enum AppSortMode: String, CaseIterable {
    case size = "Dung lượng"
    case name = "Tên ứng dụng"
    case backedUp = "Đã sao lưu"
}

enum AppFilterMode: String, CaseIterable {
    case all = "Tất cả ứng dụng"
    case apple = "Ứng dụng Apple"
    case thirdParty = "Ứng dụng bên thứ 3"
    case backedUp = "Đã có Sao lưu"
}

struct AppsManagerView: View {
    @StateObject private var engine = WQEngine.shared
    @AppStorage("WQDeletingDisabled") private var deletingDisabled = false
    @State private var searchText = ""
    @State private var sortMode: AppSortMode = .size
    @State private var filterMode: AppFilterMode = .all
    @State private var selectedApp: AppInfoItem? = nil
    @State private var showActionSheet = false
    @State private var showConfirmClear = false
    @State private var showConfirmRestore = false
    @State private var showSnapshotsSheet = false
    @State private var showImportZip = false
    @State private var prefsPlistURL: URL? = nil
    @State private var showPrefsPlistSheet = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var navigateToContainerPath: String? = nil
    
    var filteredApps: [AppInfoItem] {
        var base = engine.apps
        switch filterMode {
        case .all:
            break
        case .apple:
            base = base.filter { $0.bundleID.hasPrefix("com.apple.") }
        case .thirdParty:
            base = base.filter { !$0.bundleID.hasPrefix("com.apple.") }
        case .backedUp:
            base = base.filter { $0.hasBackup }
        }
        if !searchText.isEmpty {
            base = base.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.bundleID.localizedCaseInsensitiveContains(searchText)
            }
        }
        switch sortMode {
        case .size:
            return base.sorted { $0.bytes > $1.bytes }
        case .name:
            return base.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .backedUp:
            return base.sorted {
                if $0.hasBackup != $1.hasBackup {
                    return $0.hasBackup && !$1.hasBackup
                }
                return $0.bytes > $1.bytes
            }
        }
    }
    
    var alphabetSections: [(String, [AppInfoItem])] {
        var groups: [String: [AppInfoItem]] = [:]
        for app in filteredApps {
            let firstChar = app.name.trimmingCharacters(in: .whitespacesAndNewlines).first.map { String($0).uppercased() } ?? "#"
            let key = (firstChar >= "A" && firstChar <= "Z") ? firstChar : "#"
            groups[key, default: []].append(app)
        }
        return groups.keys.sorted { a, b in
            if a == "#" { return false }
            if b == "#" { return true }
            return a < b
        }.map { ($0, groups[$0] ?? []) }
    }
    
    @ViewBuilder
    private func appRow(_ app: AppInfoItem) -> some View {
        Button {
            selectedApp = app
            showActionSheet = true
        } label: {
            HStack(spacing: 12) {
                if let icon = app.icon {
                    Image(uiImage: icon)
                        .resizable()
                        .frame(width: 40, height: 40)
                        .cornerRadius(9)
                } else {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .overlay(Image(systemName: "app.fill").foregroundStyle(.secondary))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(app.name)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        if app.hasBackup {
                            Text(app.backupCount > 1 ? "ĐÃ LƯU (\(app.backupCount))" : "ĐÃ LƯU")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundStyle(.green)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text("\(app.formattedBytes) · \(app.bundleID)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "ellipsis")
                    .foregroundStyle(.tertiary)
            }
        }
        .contextMenu {
            Button {
                UIPasteboard.general.string = app.bundleID
                Haptic.shared.play(.light)
            } label: {
                Label("Sao chép Bundle ID", systemImage: "tag")
            }

            Button {
                UIPasteboard.general.string = app.containerPath
                Haptic.shared.play(.light)
            } label: {
                Label("Sao chép Đường dẫn Container", systemImage: "doc.on.doc")
            }

            Button {
                navigateToContainerPath = app.containerPath
            } label: {
                Label("Mở thư mục Dữ liệu (Container)", systemImage: "folder")
            }

            Divider()

            Button {
                engine.backupApp(app) { success, msg in
                    alertTitle = success ? "Sao lưu hoàn tất" : "Sao lưu thất bại"
                    alertMessage = msg
                    showAlert = true
                }
            } label: {
                Label("Sao lưu Dữ liệu ngay", systemImage: "externaldrive.badge.plus")
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                ZStack(alignment: .trailing) {
                    List {
                        Section {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(engine.deviceLine)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .monospaced()
                                
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text("\(engine.apps.count) Ứng dụng")
                                            .font(.headline)
                                        Text("Tổng dữ liệu: \(wq_size_text(engine.totalAppDataBytes))")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if engine.isScanningApps {
                                        ProgressView()
                                    } else {
                                        Button {
                                            engine.scanApps(forceRefresh: true)
                                        } label: {
                                            Image(systemName: "arrow.clockwise.circle.fill")
                                                .font(.title2)
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                }
                                
                                if !engine.scanAppProgress.isEmpty {
                                    Text(engine.scanAppProgress)
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        if engine.apps.isEmpty && engine.isScanningApps {
                            Section {
                                HStack {
                                    ProgressView()
                                    Text("Đang quét danh sách container ứng dụng...")
                                        .padding(.leading, 8)
                                }
                            }
                        } else if filteredApps.isEmpty {
                            Section {
                                Text(searchText.isEmpty ? "Chưa tìm thấy ứng dụng nào. Kéo xuống để quét lại." : "Không tìm thấy ứng dụng khớp '\(searchText)'")
                                    .foregroundStyle(.secondary)
                            }
                        } else if sortMode == .name {
                            ForEach(alphabetSections, id: \.0) { (letter, sectionApps) in
                                Section {
                                    ForEach(sectionApps) { app in
                                        appRow(app)
                                    }
                                } header: {
                                    Text(letter)
                                        .id("ALPHA_\(letter)")
                                }
                            }
                        } else {
                            Section {
                                ForEach(filteredApps) { app in
                                    appRow(app)
                                }
                            } header: {
                                Text("Danh sách Ứng dụng (\(filteredApps.count))")
                            }
                        }
                    }
                    
                    if sortMode == .name && alphabetSections.count > 1 {
                        VStack(spacing: 2) {
                            ForEach(alphabetSections, id: \.0) { (letter, _) in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        scrollProxy.scrollTo("ALPHA_\(letter)", anchor: .top)
                                    }
                                } label: {
                                    Text(letter)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.blue)
                                        .frame(width: 18, height: 14)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 2)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.trailing, 4)
                    }
                }
            }
            .navigationTitle("Quản lý Ứng dụng")
            .searchable(text: $searchText, prompt: "Tìm theo tên hoặc Bundle ID")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sắp xếp theo", selection: $sortMode) {
                            ForEach(AppSortMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        Divider()
                        Picker("Hiển thị", selection: $filterMode) {
                            ForEach(AppFilterMode.allCases, id: \.self) { fMode in
                                Text(fMode.rawValue).tag(fMode)
                            }
                        }
                    } label: {
                        Label("Sắp xếp & Lọc", systemImage: filterMode == .all ? "arrow.up.arrow.down.circle" : "line.3.horizontal.decrease.circle.fill")
                    }
                }
            }
            .refreshable {
                engine.scanApps(forceRefresh: true)
            }
            .onAppear {
                if engine.apps.isEmpty {
                    engine.scanApps()
                }
            }
            .confirmationDialog(selectedApp?.name ?? "Tác vụ Ứng dụng", isPresented: $showActionSheet, presenting: selectedApp) { app in
                Button("Sao lưu Dữ liệu (Tạo Snapshot mới)") {
                    engine.backupApp(app) { success, msg in
                        alertTitle = success ? "Sao lưu hoàn tất" : "Sao lưu thất bại"
                        alertMessage = msg
                        showAlert = true
                    }
                }
                
                if let latest = app.latestBackupPath {
                    let stamp = URL(fileURLWithPath: latest).lastPathComponent
                    Button("Khôi phục bản mới nhất (\(stamp))") {
                        showConfirmRestore = true
                    }
                    
                    Button("Quản lý các bản Sao lưu (\(app.backupCount))") {
                        showSnapshotsSheet = true
                    }
                    
                    Button("Chia sẻ bản Sao lưu (ZIP)") {
                        if let rootVC = UIApplication.shared.connectedScenes
                            .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first {
                            engine.shareBackup(app, from: rootVC, sourceView: nil)
                        }
                    }
                }
                
                Button("Nhập bản Sao lưu từ tệp (.zip)") {
                    showImportZip = true
                }
                
                Button("Sửa Cài đặt Ứng dụng (.plist)") {
                    openAppPreferences(for: app)
                }
                
                Button("Mở thư mục Documents của App") {
                    navigateToContainerPath = (app.containerPath as NSString).appendingPathComponent("Documents")
                }
                
                Button("Mở Container trong Trình duyệt Tệp") {
                    navigateToContainerPath = app.containerPath
                }

                Button("Sao chép Bundle ID") {
                    UIPasteboard.general.string = app.bundleID
                    Haptic.shared.play(.light)
                }
                
                if !deletingDisabled {
                    Button("Xóa sạch Dữ liệu Ứng dụng", role: .destructive) {
                        showConfirmClear = true
                    }
                }
                
                Button("Hủy", role: .cancel) {}
            } message: { app in
                Text("\(app.bundleID)\nDung lượng dữ liệu: \(app.formattedBytes)")
            }
            .sheet(isPresented: $showSnapshotsSheet) {
                if let app = selectedApp {
                    AppBackupSnapshotsSheet(app: app)
                }
            }
            .sheet(isPresented: $showPrefsPlistSheet) {
                if let plistURL = prefsPlistURL {
                    PlistViewer(plistURL)
                }
            }
            .fileImporter(isPresented: $showImportZip, allowedContentTypes: [.zip, .archive]) { result in
                if let app = selectedApp {
                    switch result {
                    case .success(let zipURL):
                        engine.importBackupZip(for: app, from: zipURL) { ok, msg in
                            alertTitle = ok ? "Đã nhập bản Sao lưu" : "Nhập thất bại"
                            alertMessage = msg
                            showAlert = true
                        }
                    case .failure(let err):
                        alertTitle = "Nhập thất bại"
                        alertMessage = err.localizedDescription
                        showAlert = true
                    }
                }
            }
            .alert("Xóa dữ liệu \(selectedApp?.name ?? "Ứng dụng")?", isPresented: $showConfirmClear) {
                Button("Sao lưu trước, sau đó Xóa", role: .destructive) {
                    if let app = selectedApp {
                        engine.backupApp(app) { ok, _ in
                            if ok {
                                engine.clearAppData(app) { _, msg in
                                    alertTitle = "Đã xóa dữ liệu"
                                    alertMessage = msg
                                    showAlert = true
                                }
                            }
                        }
                    }
                }
                Button("Xóa ngay (Không sao lưu)", role: .destructive) {
                    if let app = selectedApp {
                        engine.clearAppData(app) { _, msg in
                            alertTitle = "Đã xóa dữ liệu"
                            alertMessage = msg
                            showAlert = true
                        }
                    }
                }
                Button("Hủy", role: .cancel) {}
            } message: {
                Text("Thao tác này sẽ xóa toàn bộ thư mục Documents, Library và tmp của ứng dụng. Hãy đóng ứng dụng trước khi thực hiện.")
            }
            .alert("Khôi phục \(selectedApp?.name ?? "Ứng dụng")?", isPresented: $showConfirmRestore) {
                Button("Khôi phục ngay", role: .destructive) {
                    if let app = selectedApp, let path = app.latestBackupPath {
                        engine.restoreApp(app, from: path) { success, msg in
                            alertTitle = success ? "Đã khôi phục" : "Khôi phục thất bại"
                            alertMessage = msg
                            showAlert = true
                        }
                    }
                }
                Button("Hủy", role: .cancel) {}
            } message: {
                Text("Ghi đè thư mục Documents và Library hiện tại bằng bản sao lưu đã chọn. Hãy đóng ứng dụng trước khi khôi phục.")
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("Đóng", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .background(
                Group {
                    if let navPath = navigateToContainerPath {
                        NavigationLink(
                            destination: FileBrowserView(path: URL(fileURLWithPath: navPath), isContainer: false, shouldGrant: true),
                            isActive: Binding(
                                get: { navigateToContainerPath != nil },
                                set: { if !$0 { navigateToContainerPath = nil } }
                            )
                        ) {
                            EmptyView()
                        }
                    }
                }
            )
        }
    }
    
    private func openAppPreferences(for app: AppInfoItem) {
        let prefsDir = (app.containerPath as NSString).appendingPathComponent("Library/Preferences")
        _ = wq_grant(prefsDir)
        let targetPlist = (prefsDir as NSString).appendingPathComponent("\(app.bundleID).plist")
        var st = stat()
        if !wq_stat(targetPlist, &st) {
            if let emptyData = try? PropertyListSerialization.data(fromPropertyList: [String: Any](), format: .binary, options: 0) {
                var err: NSString?
                _ = wq_create_file(targetPlist, emptyData, &err)
            }
        }
        prefsPlistURL = URL(fileURLWithPath: targetPlist)
        showPrefsPlistSheet = true
    }
}

struct AppBackupSnapshotsSheet: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var engine = WQEngine.shared
    let app: AppInfoItem
    
    @State private var snapshots: [String] = []
    @State private var targetRestorePath: String? = nil
    @State private var showConfirmRestore = false
    @State private var statusTitle = ""
    @State private var statusMessage = ""
    @State private var showStatus = false
    
    var body: some View {
        NavigationView {
            List {
                if snapshots.isEmpty {
                    Text("Chưa có bản sao lưu nào cho \(app.name).")
                        .foregroundStyle(.secondary)
                } else {
                    Section {
                        ForEach(snapshots, id: \.self) { snapPath in
                            let stamp = URL(fileURLWithPath: snapPath).lastPathComponent
                            let snapSize = wq_size_text(wq_dir_size(snapPath))
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(stamp)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    Text(snapSize)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Button {
                                    if let rootVC = UIApplication.shared.connectedScenes
                                        .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first {
                                        engine.shareBackup(app, backupPath: snapPath, from: rootVC, sourceView: nil)
                                    }
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                        .padding(.horizontal, 6)
                                }
                                .buttonStyle(.borderless)
                                
                                Button("Khôi phục") {
                                    targetRestorePath = snapPath
                                    showConfirmRestore = true
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                            .padding(.vertical, 2)
                        }
                        .onDelete { offsets in
                            for idx in offsets {
                                let p = snapshots[idx]
                                _ = engine.deleteBackupSnapshot(p)
                            }
                            reloadSnapshots()
                        }
                    } header: {
                        Text("Các mốc Sao lưu của \(app.name) (\(snapshots.count))")
                    } footer: {
                        Text("Vuốt sang trái vào bất kỳ bản sao lưu nào để xóa.")
                    }
                }
            }
            .navigationTitle("Quản lý Snapshot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        engine.backupApp(app) { ok, msg in
                            reloadSnapshots()
                            statusTitle = ok ? "Đã tạo Snapshot" : "Lỗi sao lưu"
                            statusMessage = msg
                            showStatus = true
                        }
                    } label: {
                        Label("Tạo mới", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Xong") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                reloadSnapshots()
            }
            .alert("Khôi phục Snapshot này?", isPresented: $showConfirmRestore) {
                Button("Khôi phục", role: .destructive) {
                    if let path = targetRestorePath {
                        engine.restoreApp(app, from: path) { ok, msg in
                            statusTitle = ok ? "Đã khôi phục" : "Khôi phục thất bại"
                            statusMessage = msg
                            showStatus = true
                        }
                    }
                }
                Button("Hủy", role: .cancel) {}
            } message: {
                if let p = targetRestorePath {
                    Text("Ghi đè dữ liệu \(app.name) bằng bản sao lưu \(URL(fileURLWithPath: p).lastPathComponent)? Hãy đóng ứng dụng trước khi thực hiện.")
                }
            }
            .alert(statusTitle, isPresented: $showStatus) {
                Button("Đóng", role: .cancel) {}
            } message: {
                Text(statusMessage)
            }
        }
    }
    
    private func reloadSnapshots() {
        snapshots = wq_all_app_backups(app.bundleID)
    }
}
