//
//  TextViewer.swift
//  Filos
//
//  Created by lunginspector on 5/20/26.
//

import SwiftUI


struct TextViewer: View {
    @EnvironmentObject var mgr: ErosionManager
    @Environment(\.dismiss) var dismiss
    
    @AppStorage("textViewerSize") var textViewerSize = 11
    @AppStorage("useMonospaced") var useMonospaced = true
    
    var fileURL: URL
    
    @State private var file = clearFileItem
    @State private var fileText = ""
    @State private var editText = ""
    @State private var isEditing = false
    @State private var wasBinaryPlist = false
    
    init(_ fileURL: URL) {
        self.fileURL = fileURL
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    if wasBinaryPlist {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left.arrow.right.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Binary Plist converted to XML for editing — saves back in binary format.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                        .padding(.horizontal, 6)
                        .padding(.top, 4)
                    }
                    
                    if isEditing {
                        TextEditor(text: $editText)
                            .font(.system(size: CGFloat(textViewerSize), design: useMonospaced ? .monospaced : .default))
                            .frame(minHeight: 450)
                    } else {
                        Text(fileText)
                            .font(.system(size: CGFloat(textViewerSize), design: useMonospaced ? .monospaced : .default))
                            .padding(5)
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(minHeight: 100, alignment: .topLeading)
            }
            .navigationTitle(fileURL.deletingPathExtension().lastPathComponent)
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.insetGrouped)
            .safeAreaInset(edge: .bottom) {
                if !file.writable {
                    HStack {
                        Spacer()
                        Button {
                            Alertinator.shared.alert(title: "View-Only File", body: "You can only read this file.")
                        } label: {
                            Image(systemName: "lock")
                                .padding(10)
                        }
                        .foregroundStyle(Color.accentColor)
                        .padding(.trailing)
                        .ignoresSafeArea()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isEditing {
                        Button {
                            isEditing = false
                            editText = fileText
                        } label: {
                            ToolbarLabel("Cancel", symbol: "xmark")
                        }
                    }
                    
                    Menu {
                        if file.writable && !isEditing {
                            Button {
                                isEditing = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                        }
                        
                        Button {
                            Haptic.shared.play(.soft)
                            UIPasteboard.general.string = fileText
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        
                        Button {
                            if let url = makeTemp(fileURL) {
                                presentShareSheet(with: url)
                            }
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Label("Menu", systemImage: "ellipsis")
                            .labelStyle(.iconOnly)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        Button(role: .adaptiveConfirm) {
                            let res = writeTextIntoFile(fileURL, string: editText)
                            if res {
                                isEditing = false
                                fileText = getFileText(fileURL)
                            }
                        } label: {
                            ToolbarLabel("Save", symbol: "checkmark")
                        }
                    } else {
                        Button {
                            dismiss()
                            mgr.refreshFiles.toggle()
                        } label: {
                            ToolbarLabel("Close", symbol: "xmark")
                        }
                    }
                }
            }
            .onAppear {
                file = getFileItem(at: fileURL)
                if let rawData = readDataWithWQ(fileURL, maxBytes: 16), isBinaryPlistData(rawData) {
                    wasBinaryPlist = true
                }
                let text = getFileText(fileURL)
                fileText = text
                editText = text
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func writeTextIntoFile(_ url: URL, string: String) -> Bool {
        var dataToWrite = Data(string.utf8)
        if wasBinaryPlist {
            do {
                let plist = try PropertyListSerialization.propertyList(from: dataToWrite, options: [], format: nil)
                dataToWrite = try PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0)
            } catch {
                Alertinator.shared.alert(title: "Invalid Plist XML", body: error.localizedDescription)
                return false
            }
        }
        var wqErr: NSString?
        let ok = wq_write(url.path, dataToWrite, &wqErr)
        if ok {
            Haptic.shared.play(.soft)
            return true
        } else {
            do {
                try dataToWrite.write(to: url)
                return true
            } catch {
                print("(fm) failed to write data: \(error.localizedDescription), wq: \(String(describing: wqErr))")
                Alertinator.shared.alert(title: "Save Failed", body: (wqErr as String?) ?? error.localizedDescription)
            }
        }
        return false
    }
}
