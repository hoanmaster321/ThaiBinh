//
//  FileRow.swift
//  AccessiblePlus
//
//  Created by lunginspector on 5/20/26.
//

import SwiftUI

import QuickLook
import ZIPFoundation

struct FileRow: View {
    @EnvironmentObject var mgr: ErosionManager
    @AppStorage("hideDates") var hideDates = false
    var file: FileItem
    
    @State private var conformsText = false
    @State private var conformsPlist = false
    @State private var conformsZip = false
    @State private var backupOriginalPath: String? = nil
    
    @State private var showInfo = false
    @State private var showPlistViewer = false
    @State private var showTextViewer = false
    @State private var showHexViewer = false
    @State private var previewURL: URL?
    
    var body: some View {
        Group {
            if file.type == .file {
                Button {
                    if conformsZip {
                        let res = unzipFile(file.fileURL)
                        if res {
                            mgr.refreshFiles.toggle()
                        } else {
                            Haptic.shared.play(.heavy)
                        }
                    } else {
                        if conformsPlist {
                            showPlistViewer.toggle()
                        } else if conformsText {
                            showTextViewer.toggle()
                        } else {
                            previewURL = file.fileURL
                        }
                    }
                } label: {
                    HStack(spacing: isSolariumUI() ? 12 : 10) {
                        Image(systemName: "doc")
                            .frame(width: 20, alignment: .center)
                            .foregroundStyle(file.hidden ? .secondary : .primary)
                        
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
            if file.uttype.conforms(to: .zip) {
                conformsZip = true
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
        .quickLookPreview($previewURL)
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
            
            Button {
                showHexViewer = true
            } label: {
                Label("Xem mã Hex", systemImage: "curlybraces")
            }
            
            if conformsText || conformsPlist {
                Menu {
                    Button {
                        previewURL = file.fileURL
                    } label: {
                        Label("Xem nhanh (Quick Look)", systemImage: "eye")
                    }
                    
                    if conformsPlist {
                        Button {
                            showPlistViewer.toggle()
                        } label: {
                            Label("Trình sửa Plist", systemImage: "tablecells")
                        }
                    }
                    
                    if conformsText {
                        Button {
                            showTextViewer.toggle()
                        } label: {
                            Label("Trình sửa Văn bản", systemImage: "doc.plaintext")
                        }
                    }
                } label: {
                    Label("Mở bằng...", systemImage: "doc.text.magnifyingglass")
                }
            } else {
                Button {
                    previewURL = file.fileURL
                } label: {
                    Label("Xem nhanh (Quick Look)", systemImage: "eye")
                }
            }
            
            Divider()
            
            Button {
                showInfo.toggle()
            } label: {
                Label("Xem thông tin", systemImage: "info.circle")
            }
            
            if file.type == .file {
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
                        let res = unzipFile(file.fileURL)
                        if res {
                            mgr.refreshFiles.toggle()
                        } else {
                            Alertinator.shared.alert(title: "Giải nén thất bại!", body: Errors.checkLogs)
                        }
                    } label: {
                        Label("Giải nén", systemImage: "archivebox")
                    }
                } else {
                    Button {
                        let res = zipFile(file.fileURL)
                        if res {
                            mgr.refreshFiles.toggle()
                        } else {
                            Alertinator.shared.alert(title: "Nén tệp thất bại!", body: Errors.checkLogs)
                        }
                    } label: {
                        Label("Nén ZIP", systemImage: "archivebox")
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
                        print("(fm) failed to delete file: \(error.localizedDescription)")
                        Alertinator.shared.alert(title: "Không thể xóa tệp!", body: error.localizedDescription)
                    }
                }
            } label: {
                Label("Xóa (Tự động Sao lưu)", systemImage: "trash")
            }
        }
    }
}
