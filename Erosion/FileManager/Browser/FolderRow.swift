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
        .contextMenu {
            if !isContainer {
                Button {
                    previewURL = file.fileURL
                } label: {
                    Label("Quick Look", systemImage: "eye")
                }
                
                Divider()
                
                Button {
                    showInfo.toggle()
                } label: {
                    Label("Get Info", systemImage: "info.circle")
                }
                
                Button {
                    let res = zipFile(file.fileURL)
                    if res {
                        mgr.refreshFiles.toggle()
                    } else {
                        Alertinator.shared.alert(title: "Failed to compress file!", body: Errors.checkLogs)
                    }
                } label: {
                    Label("Compress", systemImage: "archivebox")
                }
                
                Button {
                    if let rootVC = UIApplication.shared.connectedScenes
                        .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController }).first {
                        wq_share_folder(rootVC, file.fileURL.path, file.name, nil)
                    }
                } label: {
                    Label("Share as ZIP (AirDrop…)", systemImage: "square.and.arrow.up")
                }
                
                Divider()
                
                Button {
                    if let url = makeTemp(file.fileURL) {
                        presentShareSheet(with: url)
                    }
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                
                Divider()
                
                Button(role: .destructive) {
                    try? fm.removeItem(at: file.fileURL)
                    mgr.refreshFiles.toggle()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}
