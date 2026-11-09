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
                                Text("Backup of \(orig)")
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
                            Alertinator.shared.alert(title: "Restored Successfully", body: "Restored file to:\n\(origPath)")
                        } else {
                            Alertinator.shared.alert(title: "Restore Failed", body: (err as String?) ?? "Could not write to original location.")
                        }
                    }
                } label: {
                    Label("Restore to Original Path", systemImage: "arrow.uturn.backward.circle.fill")
                }
                Divider()
            }
            
            Button {
                showHexViewer = true
            } label: {
                Label("Hex Viewer", systemImage: "curlybraces")
            }
            
            if conformsText || conformsPlist {
                Menu {
                    Button {
                        previewURL = file.fileURL
                    } label: {
                        Label("Quick Look", systemImage: "eye")
                    }
                    
                    if conformsPlist {
                        Button {
                            showPlistViewer.toggle()
                        } label: {
                            Label("Plist Viewer", systemImage: "tablecells")
                        }
                    }
                    
                    if conformsText {
                        Button {
                            showTextViewer.toggle()
                        } label: {
                            Label("Text Viewer", systemImage: "doc.plaintext")
                        }
                    }
                } label: {
                    Label("View In...", systemImage: "doc.text.magnifyingglass")
                }
            } else {
                Button {
                    previewURL = file.fileURL
                } label: {
                    Label("Quick Look", systemImage: "eye")
                }
            }
            
            Divider()
            
            Button {
                showInfo.toggle()
            } label: {
                Label("Get Info", systemImage: "info.circle")
            }
            
            if file.type == .file {
                Button {
                    Alertinator.shared.prompt(title: "What would you like to call this file?", placeholder: file.name, completion: { result in
                        if let name = result {
                            let res = renameFile(file.fileURL, to: name)
                            if res {
                                mgr.refreshFiles.toggle()
                            } else {
                                Alertinator.shared.alert(title: "Failed to rename file!", body: Errors.checkLogs)
                            }
                        }
                    })
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
            }
            
            if file.type == .file {
                if conformsZip {
                    Button {
                        let res = unzipFile(file.fileURL)
                        if res {
                            mgr.refreshFiles.toggle()
                        } else {
                            Alertinator.shared.alert(title: "Failed to uncompress file!", body: Errors.checkLogs)
                        }
                    } label: {
                        Label("Uncompress", systemImage: "archivebox")
                    }
                } else {
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
                }
            }
            
            if file.type == .file {
                Button {
                    let res = duplicateFile(file.fileURL)
                    if res {
                        mgr.refreshFiles.toggle()
                    } else {
                        Alertinator.shared.alert(title: "Failed to duplicate file!", body: Errors.checkLogs)
                    }
                } label: {
                    Label("Duplicate", systemImage: "plus.square.on.square")
                }
            }
            
            Divider()
            
            Button {
                let res = copyFileToClipboard(file.fileURL)
                if !res {
                    Alertinator.shared.alert(title: "Failed to copy file!", body: Errors.checkLogs)
                }
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            
            Button {
                if let url = makeTemp(file.fileURL) {
                    presentShareSheet(with: url)
                }
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
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
                        Alertinator.shared.alert(title: "Failed to delete file!", body: error.localizedDescription)
                    }
                }
            } label: {
                Label("Delete (Safe Backup)", systemImage: "trash")
            }
        }
    }
}
