//
//  FileRow.swift
//  Thái Bình (ErosionWQ)
//
//  Dòng hiển thị Tệp tin tích hợp WQFiles v0.9:
//  SQLiteViewer, MediaPlayerView, WQArchive (Nén/Giải nén ZIP), Di chuyển liên ứng dụng & Bảo vệ Xóa.
//

import SwiftUI
import QuickLook
import ZIPFoundation

struct FileRow: View {
    @EnvironmentObject var mgr: ErosionManager
    @AppStorage("hideDates") var hideDates = false
    @AppStorage("WQDeletingDisabled") var deletingDisabled = false
    var file: FileItem

    @State private var conformsText = false
    @State private var conformsPlist = false
    @State private var conformsZip = false
    @State private var conformsSQLite = false
    @State private var conformsMedia = false
    @State private var backupOriginalPath: String? = nil

    @State private var showInfo = false
    @State private var showPlistViewer = false
    @State private var showTextViewer = false
    @State private var showHexViewer = false
    @State private var showSQLiteViewer = false
    @State private var showMediaPlayer = false
    @State private var previewURL: URL?

    var body: some View {
        Group {
            if file.type == .file {
                Button {
                    if conformsZip {
                        let parentDir = file.fileURL.deletingLastPathComponent().path
                        WQEngine.shared.extractZip(file.fileURL.path, in: parentDir) { ok, msg in
                            if ok {
                                Haptic.shared.play(.soft)
                                mgr.refreshFiles.toggle()
                            } else if unzipFile(file.fileURL) {
                                mgr.refreshFiles.toggle()
                            } else {
                                Haptic.shared.play(.heavy)
                                Alertinator.shared.alert(title: "Giải nén thất bại!", body: msg)
                            }
                        }
                    } else if conformsMedia {
                        showMediaPlayer = true
                    } else if conformsSQLite {
                        showSQLiteViewer = true
                    } else if conformsPlist {
                        showPlistViewer.toggle()
                    } else if conformsText {
                        showTextViewer.toggle()
                    } else {
                        previewURL = file.fileURL
                    }
                } label: {
                    HStack(spacing: isSolariumUI() ? 12 : 10) {
                        Image(systemName: fileIconName)
                            .frame(width: 20, alignment: .center)
                            .foregroundStyle(fileIconColor)

                        VStack(alignment: .leading) {
                            Text(file.name)
                                .foregroundStyle(file.hidden ? .secondary : .primary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            if !hideDates && !file.modifiedDateStr.isEmpty && file.type == .file {
                                Text(file.modifiedDateStr)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            if let orig = backupOriginalPath {
                                Text("Sao lưu từ: \(orig)")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                                    .lineLimit(1)
                                    .truncationMode(.head)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if file.type == .file {
                            Text("\(ByteCountFormatter.string(fromByteCount: Int64(file.size), countStyle: .file))")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        Button {
                            showInfo.toggle()
                        } label: {
                            Image(systemName: "info.circle")
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, !hideDates && !file.modifiedDateStr.isEmpty && file.type == .file && !isSolariumUI() ? 1 : 0)
                }
            } else {
                NavigationLink(destination: FileBrowserView(path: file.destURL)) {
                    HStack(spacing: isSolariumUI() ? 12 : 10) {
                        Image(systemName: "arrow.up.right.circle")
                            .frame(width: 20, alignment: .center)
                            .foregroundStyle(file.hidden ? .secondary : .primary)

                        Text(file.name)
                            .foregroundStyle(file.hidden ? .secondary : .primary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button {
                            showInfo.toggle()
                        } label: {
                            Image(systemName: "info.circle")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .foregroundStyle(Color(.label))
        .onAppear {
            conformsText = conformsToTextViewer(file.fileURL)
            conformsPlist = conformsToPlistViewer(file.fileURL)
            conformsMedia = MediaPlayerView.isMediaFile(file.fileURL)
            if file.uttype.conforms(to: .zip) || file.fileURL.pathExtension.lowercased() == "zip" {
                conformsZip = true
            }
            let ext = file.fileURL.pathExtension.lowercased()
            if ext == "sqlite" || ext == "sqlite3" || ext == "sqlitedb" || ext == "db" {
                conformsSQLite = true
            } else if file.type == .file && file.size >= 16 && !conformsMedia {
                DispatchQueue.global(qos: .utility).async {
                    let isSQL = wq_is_sqlite_file(file.fileURL.path)
                    if isSQL {
                        DispatchQueue.main.async {
                            self.conformsSQLite = true
                        }
                    }
                }
            }
            backupOriginalPath = wq_backup_original_path(file.fileURL.path)
        }
        .sheet(isPresented: $showInfo) {
            InfoViewer(file)
        }
        .sheet(isPresented: $showPlistViewer) {
            PlistViewer(file.fileURL)
        }
        .sheet(isPresented: $showTextViewer) {
            TextViewer(file.fileURL)
        }
        .sheet(isPresented: $showHexViewer) {
            NavigationView {
                HexViewer(url: file.fileURL)
            }
        }
        .sheet(isPresented: $showSQLiteViewer) {
            SQLiteViewer(fileURL: file.fileURL)
        }
        .sheet(isPresented: $showMediaPlayer) {
            MediaPlayerView(fileURL: file.fileURL)
        }
        .quickLookPreview($previewURL)
        // WQFiles v0.9: Vuốt sang trái (trailing) để Xóa khi Allow Deleting đang bật
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if !deletingDisabled {
                Button(role: .destructive) {
                    var error: NSString?
                    if wq_delete(file.fileURL.path, &error) {
                        mgr.refreshFiles.toggle()
                    } else {
                        do {
                            try fm.removeItem(at: file.fileURL)
                            mgr.refreshFiles.toggle()
                        } catch {
                            Alertinator.shared.alert(title: "Không thể xóa tệp!", body: (error as String?) ?? error.localizedDescription)
                        }
                    }
                } label: {
                    Label("Xóa", systemImage: "trash")
                }
            }

            if file.type == .file {
                Button {
                    Alertinator.shared.prompt(title: "Nhập tên mới cho tệp này:", placeholder: file.name) { result in
                        if let name = result, !name.isEmpty {
                            if renameFile(file.fileURL, to: name) {
                                mgr.refreshFiles.toggle()
                            } else {
                                Alertinator.shared.alert(title: "Không thể đổi tên tệp!", body: Errors.checkLogs)
                            }
                        }
                    }
                } label: {
                    Label("Đổi tên", systemImage: "pencil")
                }
                .tint(.orange)
            }
        }
        // MARK: cell actions
        .contextMenu {
            if let origPath = backupOriginalPath {
                Button {
                    if let data = readDataWithWQ(file.fileURL) {
                        var err: NSString?
                        if wq_write(origPath, data, &err) {
                            Haptic.shared.play(.soft)
                            Alertinator.shared.alert(title: "Khôi phục thành công", body: "Đã khôi phục tệp về đường dẫn gốc:\n\(origPath)")
                        } else {
                            Alertinator.shared.alert(title: "Khôi phục thất bại", body: (err as String?) ?? "Không thể ghi vào đường dẫn gốc.")
                        }
                    }
                } label: {
                    Label("Khôi phục về đường dẫn gốc", systemImage: "arrow.uturn.backward.circle.fill")
                }
                Divider()
            }

            if conformsMedia {
                Button {
                    showMediaPlayer = true
                } label: {
                    Label("Phát Đa phương tiện (Media Player)", systemImage: "play.rectangle.fill")
                }
            }

            if conformsSQLite {
                Button {
                    showSQLiteViewer = true
                } label: {
                    Label("Trình xem SQLite (Chỉ đọc)", systemImage: "cylinder.split.1x2")
                }
            }

            Menu {
                Button {
                    previewURL = file.fileURL
                } label: {
                    Label("Xem nhanh (Quick Look)", systemImage: "eye")
                }

                Button {
                    showTextViewer = true
                } label: {
                    Label("Trình sửa Văn bản & Tô màu Cú pháp", systemImage: "doc.plaintext")
                }

                Button {
                    showPlistViewer = true
                } label: {
                    Label("Trình sửa Plist", systemImage: "tablecells")
                }

                Button {
                    showHexViewer = true
                } label: {
                    Label("Trình soi mã Hex", systemImage: "curlybraces")
                }

                Button {
                    showSQLiteViewer = true
                } label: {
                    Label("Trình xem Cơ sở dữ liệu SQLite", systemImage: "cylinder.split.1x2")
                }

                Button {
                    showMediaPlayer = true
                } label: {
                    Label("Trình phát Đa phương tiện", systemImage: "play.rectangle")
                }
            } label: {
                Label("Mở bằng...", systemImage: "doc.text.magnifyingglass")
            }

            Divider()

            Button {
                showInfo.toggle()
            } label: {
                Label("Xem thông tin", systemImage: "info.circle")
            }

            Button {
                UIPasteboard.general.string = file.fileURL.path
                Haptic.shared.play(.light)
            } label: {
                Label("Sao chép Đường dẫn", systemImage: "link")
            }

            if file.type == .file {
                Button {
                    WQEngine.shared.startMove([file.fileURL.path])
                    Haptic.shared.play(.light)
                } label: {
                    Label("Di chuyển sang thư mục khác…", systemImage: "folder")
                }

                Button {
                    Alertinator.shared.prompt(title: "Nhập tên mới cho tệp này:", placeholder: file.name, completion: { result in
                        if let name = result {
                            let res = renameFile(file.fileURL, to: name)
                            if res {
                                mgr.refreshFiles.toggle()
                            } else {
                                Alertinator.shared.alert(title: "Không thể đổi tên tệp!", body: Errors.checkLogs)
                            }
                        }
                    })
                } label: {
                    Label("Đổi tên", systemImage: "pencil")
                }
            }

            if file.type == .file {
                if conformsZip {
                    Button {
                        let parentDir = file.fileURL.deletingLastPathComponent().path
                        WQEngine.shared.extractZip(file.fileURL.path, in: parentDir) { ok, msg in
                            if ok {
                                mgr.refreshFiles.toggle()
                                Alertinator.shared.alert(title: "Đã giải nén", body: msg)
                            } else if unzipFile(file.fileURL) {
                                mgr.refreshFiles.toggle()
                            } else {
                                Alertinator.shared.alert(title: "Giải nén thất bại!", body: msg)
                            }
                        }
                    } label: {
                        Label("Giải nén ZIP", systemImage: "archivebox")
                    }
                } else {
                    Button {
                        let parentDir = file.fileURL.deletingLastPathComponent().path
                        WQEngine.shared.compressItems([file.fileURL.path], in: parentDir) { ok, msg in
                            if ok {
                                mgr.refreshFiles.toggle()
                            } else if zipFile(file.fileURL) {
                                mgr.refreshFiles.toggle()
                            } else {
                                Alertinator.shared.alert(title: "Nén tệp thất bại!", body: msg)
                            }
                        }
                    } label: {
                        Label("Nén ZIP", systemImage: "doc.zipper")
                    }
                }
            }

            if file.type == .file {
                Button {
                    let res = duplicateFile(file.fileURL)
                    if res {
                        mgr.refreshFiles.toggle()
                    } else {
                        Alertinator.shared.alert(title: "Không thể nhân bản tệp!", body: Errors.checkLogs)
                    }
                } label: {
                    Label("Nhân bản", systemImage: "plus.square.on.square")
                }
            }

            Divider()

            Button {
                let res = copyFileToClipboard(file.fileURL)
                if !res {
                    Alertinator.shared.alert(title: "Không thể sao chép tệp!", body: Errors.checkLogs)
                }
            } label: {
                Label("Sao chép", systemImage: "doc.on.doc")
            }

            Button {
                if let url = makeTemp(file.fileURL) {
                    presentShareSheet(with: url)
                }
            } label: {
                Label("Chia sẻ", systemImage: "square.and.arrow.up")
            }

            if !deletingDisabled {
                Divider()

                Button(role: .destructive) {
                    var error: NSString?
                    if wq_delete(file.fileURL.path, &error) {
                        mgr.refreshFiles.toggle()
                    } else {
                        do {
                            try fm.removeItem(at: file.fileURL)
                            mgr.refreshFiles.toggle()
                        } catch {
                            Alertinator.shared.alert(title: "Không thể xóa tệp!", body: (error as String?) ?? error.localizedDescription)
                        }
                    }
                } label: {
                    Label("Xóa (Tự động Sao lưu)", systemImage: "trash")
                }
            }
        }
    }

    private var fileIconName: String {
        if conformsMedia { return "play.rectangle.fill" }
        if conformsSQLite { return "cylinder.split.1x2" }
        if conformsZip { return "doc.zipper" }
        if conformsPlist { return "tablecells" }
        return "doc"
    }

    private var fileIconColor: Color {
        if conformsMedia { return .purple }
        if conformsSQLite { return .blue }
        if conformsZip { return .orange }
        return file.hidden ? .secondary : .primary
    }
}
