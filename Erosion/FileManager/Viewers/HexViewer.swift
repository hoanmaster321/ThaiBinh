//
//  HexViewer.swift
//  ErosionWQ
//
//  Hex dump viewer for arbitrary binary and system files
//

import SwiftUI

struct HexViewer: View {
    let url: URL
    @State private var hexContent: String = "Loading..."
    @State private var isLoading = true
    @State private var fileSizeStr: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(fileSizeStr)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    UIPasteboard.general.string = hexContent
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(UIColor.secondarySystemBackground))
            
            Divider()
            
            if isLoading {
                Spacer()
                ProgressView("Reading bytes...")
                Spacer()
            } else {
                ScrollView([.horizontal, .vertical]) {
                    Text(hexContent)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(UIColor.systemBackground))
            }
        }
        .navigationTitle(url.lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    presentShareSheet(with: url)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .onAppear {
            loadHex()
        }
    }
    
    private func loadHex() {
        DispatchQueue.global(qos: .userInitiated).async {
            var err: NSString?
            let data = wq_read(url.path, 128 * 1024, &err)
            
            DispatchQueue.main.async {
                if let d = data {
                    self.fileSizeStr = "\(wq_size_text(UInt64(d.count))) · read up to 128 KB"
                    self.hexContent = wq_hex_dump(d)
                } else {
                    self.hexContent = "Failed to read file: \((err as String?) ?? "Access Denied")"
                }
                self.isLoading = false
            }
        }
    }
}
