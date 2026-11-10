//
//  FolderRow.swift
//  AccessiblePlus
//
//  Created by lunginspector on 5/20/26.
//

import SwiftUI

import QuickLook
import ZIPFoundation

struct FolderRow: View {
    @EnvironmentObject var mgr: ErosionManager
    var file: FileItem
    var shouldGrant: Bool
    var isContainer: Bool = false
    
    @State private var previewURL: URL?
    @State private var folderType: FolderType = .normal
    @State private var showInfo = false
    @State private var appIcon: UIImage? = nil
    @State private var displayName: String? = nil
    
    var body: some View {
        NavigationLink(destination: FileBrowserView(path: file.destURL, shouldGrant: shouldGrant)) {
            HStack(spacing: isSolariumUI() ? 12 : 10) {
                if let icon = appIcon {
                    Image(uiImage: icon)
                        .resizable()
                        .frame(width: 26, height: 26)
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
                    if displayName != nil {
                        Text(file.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
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
            if isContainer || file.fileURL.path.contains("/Containers/") || file.fileURL.path.contains("/SystemGroup") {
                DispatchQueue.global(qos: .utility).async {
                    if let bid = wq_container_label(file.fileURL.path) {
                        let name = wq_display_name(bid)
                        let icon = wq_app_icon(bid)
                        DispatchQueue.main.async {
                            self.displayName = name
                            self.appIcon = icon
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showInfo) {
            InfoViewer(file)
        }
        .quickLookPreview($previewURL)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if !isContainer {
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
            if !isContainer {
                Button {
                    previewURL = file.fileURL
                } label: {
                    Label("Xem nhanh (Quick Look)", systemImage: "eye")
                }
                
                Divider()
                
                Button {
                    showInfo.toggle()
                } label: {
                    Label("Xem thông tin", systemImage: "info.circle")
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
                    let res = zipFile(file.fileURL)
                    if res {
                        mgr.refreshFiles.toggle()
                    } else {
                        Alertinator.shared.alert(title: "Không thể nén thư mục!", body: Errors.checkLogs)
                    }
                } label: {
                    Label("Nén ZIP", systemImage: "archivebox")
                }
                
                Button {
                    if let rootVC = UIApplication.shared.connectedScenes
                        .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first {
                        wq_share_folder(rootVC, file.fileURL.path, file.name, nil)
                    }
                } label: {
                    Label("Chia sẻ dạng ZIP (AirDrop…)", systemImage: "square.and.arrow.up")
                }
                
                Divider()
                
                Button {
                    if let url = makeTemp(file.fileURL) {
                        presentShareSheet(with: url)
                    }
                } label: {
                    Label("Chia sẻ", systemImage: "square.and.arrow.up")
                }
                
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
