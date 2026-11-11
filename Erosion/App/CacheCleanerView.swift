//
//  CacheCleanerView.swift
//  ThaiBinh (ErosionWQ)
//
//  Dọn dẹp Bộ nhớ đệm & Tệp tạm trên toàn bộ nhánh MCM Container
//  Bản quyền © 2026 ThaiBinh (hoanmaster321)
//

import SwiftUI
import Combine

struct CacheCleanerView: View {
    @StateObject private var engine = WQEngine.shared
    @AppStorage("WQDeletingDisabled") private var deletingDisabled = false
    @State private var searchText = ""
    @State private var showConfirmClean = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var targetBrowserPath: String? = nil
    
    var filteredItems: [CacheScanItem] {
        if searchText.isEmpty {
            return engine.cacheItems
        }
        return engine.cacheItems.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.bundleID ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var totalSelectedBytes: UInt64 {
        engine.cacheItems.filter { $0.isSelected }.reduce(0) { $0 + $1.totalBytes }
    }
    
    var totalAllBytes: UInt64 {
        engine.cacheItems.reduce(0) { $0 + $1.totalBytes }
    }
    
    var selectedCount: Int {
        engine.cacheItems.filter { $0.isSelected }.count
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Tổng dung lượng Rác & Cache")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(wq_size_text(totalAllBytes))
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Đã chọn để dọn")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(wq_size_text(totalSelectedBytes))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.blue)
                            }
                        }
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 8)
                                
                                let ratio = totalAllBytes > 0 ? CGFloat(totalSelectedBytes) / CGFloat(totalAllBytes) : 0
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue)
                                    .frame(width: max(0, min(geo.size.width, geo.size.width * ratio)), height: 8)
                            }
                        }
                        .frame(height: 8)
                        
                        HStack {
                            Button("Chọn tất cả") {
                                engine.selectCacheWhere { _ in true }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Button("Lớn (>50MB)") {
                                engine.selectCacheWhere { $0.totalBytes >= 50 * 1024 * 1024 }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Button("Bỏ chọn") {
                                engine.selectCacheWhere { _ in false }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            
                            Spacer()
                            
                            if engine.isScanningCaches {
                                ProgressView()
                            } else {
                                Button {
                                    engine.scanCaches(forceRefresh: true)
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        
                        if !engine.cleanStatusMessage.isEmpty {
                            Text(engine.cleanStatusMessage)
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section {
                    Button(role: .destructive) {
                        if deletingDisabled {
                            alertTitle = "Đã khóa thao tác Xóa"
                            alertMessage = "Hãy bật 'Cho phép Xóa dữ liệu' trong Cài đặt để dọn dẹp bộ nhớ đệm."
                            showAlert = true
                            return
                        }
                        engine.cleanCrashLogs { freed in
                            alertTitle = "Đã dọn Chẩn đoán & Icon Cache"
                            alertMessage = "Đã giải phóng \(wq_size_text(freed)) dữ liệu chẩn đoán hệ thống."
                            showAlert = true
                            engine.scanCaches()
                        }
                    } label: {
                        HStack {
                            Label("Dọn nhanh Chẩn đoán & Icon Cache (SystemGroup)", systemImage: "stethoscope")
                            Spacer()
                            Image(systemName: deletingDisabled ? "lock.fill" : "trash")
                        }
                    }
                    .disabled(deletingDisabled)
                }
                
                Section {
                    if engine.cacheItems.isEmpty && engine.isScanningCaches {
                        HStack {
                            ProgressView()
                            Text("Đang quét bộ nhớ đệm ứng dụng...")
                                .padding(.leading, 8)
                        }
                    } else if filteredItems.isEmpty {
                        Text(searchText.isEmpty ? "Thiết bị đã sạch hoặc chưa tìm thấy bộ nhớ đệm." : "Không có mục nào khớp '\(searchText)'")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(filteredItems) { item in
                            HStack(spacing: 12) {
                                Button {
                                    item.isSelected.toggle()
                                    engine.objectWillChange.send()
                                } label: {
                                    Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(item.isSelected ? .blue : .secondary)
                                }
                                .buttonStyle(.plain)
                                
                                if let icon = item.icon {
                                    Image(uiImage: icon)
                                        .resizable()
                                        .frame(width: 36, height: 36)
                                        .cornerRadius(8)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    
                                    Text("cache \(wq_size_text(item.cacheBytes)) · tmp \(wq_size_text(item.tempBytes))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(item.formattedSize)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                item.isSelected.toggle()
                                engine.objectWillChange.send()
                            }
                            .contextMenu {
                                if let firstDir = item.targets.first {
                                    Button {
                                        targetBrowserPath = firstDir
                                    } label: {
                                        Label("Mở thư mục Caches trong Trình duyệt Tệp", systemImage: "folder")
                                    }
                                }
                                if item.targets.count > 1 {
                                    Button {
                                        targetBrowserPath = item.targets[1]
                                    } label: {
                                        Label("Mở thư mục tmp trong Trình duyệt Tệp", systemImage: "folder.badge.gearshape")
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text("Bộ nhớ đệm Ứng dụng (\(filteredItems.count))")
                }
            }
            .navigationTitle("Dọn rác & Cache")
            .searchable(text: $searchText, prompt: "Lọc theo tên ứng dụng")
            .refreshable {
                engine.scanCaches(forceRefresh: true)
            }
            .onAppear {
                if engine.cacheItems.isEmpty {
                    engine.scanCaches()
                }
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        showConfirmClean = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Dọn sạch \(selectedCount) mục (\(wq_size_text(totalSelectedBytes)))")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(totalSelectedBytes == 0 || engine.isCleaningCaches || deletingDisabled)
                }
            }
            .alert("Xác nhận dọn Bộ nhớ đệm?", isPresented: $showConfirmClean) {
                Button("Xóa Cache (\(wq_size_text(totalSelectedBytes)))", role: .destructive) {
                    engine.cleanSelectedCaches { freed, allOk in
                        alertTitle = allOk ? "Dọn rác hoàn tất" : "Đã dọn một phần"
                        alertMessage = "Đã giải phóng \(wq_size_text(freed)).\(allOk ? "" : " Một số tệp đang được hệ thống sử dụng nên được giữ lại.")"
                        showAlert = true
                    }
                }
                Button("Hủy", role: .cancel) {}
            } message: {
                Text("Chỉ xóa nội dung trong Library/Caches và tmp. Tài khoản đăng nhập và dữ liệu Documents của bạn hoàn toàn được giữ nguyên.")
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("Đóng", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
            .background(
                Group {
                    if let path = targetBrowserPath {
                        NavigationLink(
                            destination: FileBrowserView(path: URL(fileURLWithPath: path), isContainer: false, shouldGrant: true),
                            isActive: Binding(
                                get: { targetBrowserPath != nil },
                                set: { if !$0 { targetBrowserPath = nil } }
                            )
                        ) {
                            EmptyView()
                        }
                    }
                }
            )
        }
    }
}
