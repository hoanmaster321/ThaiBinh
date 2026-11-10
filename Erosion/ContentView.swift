//
//  ContentView.swift
//  ThaiBinh (ErosionWQ)
//
//  Trang chủ & Bảng điều khiển: Chẩn đoán thiết bị, App Group, Tác vụ nhanh & Nhật ký hệ thống
//

import SwiftUI

struct ContentView: View {
    @AppStorage("ogMachineName") var ogMachineName = ""
    @EnvironmentObject var mgr: ErosionManager
    @StateObject private var engine = WQEngine.shared
    @State private var showSettings = false
    @State private var alertMsg = ""
    @State private var showAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "iphone.gen3")
                                .font(.title)
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(engine.deviceLine)
                                    .font(.headline)
                                Text("worse_query MCM Sandbox Escape · Bản quyền © ThaiBinh")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Label("App Group:", systemImage: "person.2.badge.gearshape")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(engine.activeAppGroup)
                                .font(.caption)
                                .fontWeight(.medium)
                                .monospaced()
                                .lineLimit(1)
                        }
                        
                        HStack {
                            Label("Bộ nhớ máy:", systemImage: "internaldrive")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(engine.storageSummaryText)
                                .font(.caption)
                                .monospacedDigit()
                                .lineLimit(1)
                        }
                        
                        HStack {
                            Label("Sao lưu cục bộ:", systemImage: "externaldrive.badge.timemachine")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(engine.totalSafetyBackupsText)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    HeaderLabel("Thiết bị & Trạng thái Exploit", symbol: "info.circle")
                }
                
                Section {
                    Button {
                        Haptic.shared.play(.heavy)
                        mgr.shouldRespring = true
                    } label: {
                        HStack {
                            Label("Khởi động lại SpringBoard (Respring)", systemImage: "arrow.counterclockwise.circle.fill")
                                .foregroundStyle(.orange)
                            Spacer()
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                    
                    Button {
                        engine.cleanCrashLogs { freed in
                            alertMsg = "Đã dọn sạch \(wq_size_text(freed)) bộ nhớ đệm chẩn đoán & icon cache hệ thống."
                            showAlert = true
                        }
                    } label: {
                        HStack {
                            Label("Dọn nhanh Chẩn đoán & Icon Cache", systemImage: "stethoscope")
                            Spacer()
                            Image(systemName: "trash")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Button {
                        engine.scanApps()
                        engine.scanCaches()
                        alertMsg = "Đang tiến hành quét lại danh sách ứng dụng và bộ nhớ đệm trong nền."
                        showAlert = true
                    } label: {
                        HStack {
                            Label("Quét lại Ứng dụng & Container", systemImage: "arrow.triangle.2.circlepath")
                            Spacer()
                            Image(systemName: "arrow.clockwise")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    HeaderLabel("Tác vụ nhanh", symbol: "bolt")
                }
                
                Section {
                    LogView()
                        .modifier(TerminalPlatter())
                } header: {
                    HeaderLabel("Nhật ký hệ thống (Live Console)", symbol: "apple.terminal")
                } footer: {
                    Text("ThaiBinh (ErosionWQ) · Phát triển bởi hoanmaster321")
                }
            }
            .navigationTitle("ThaiBinh")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Label("Cài đặt", systemImage: "gear")
                            .labelStyle(.iconOnly)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .alert("Thông báo", isPresented: $showAlert) {
                Button("Đóng", role: .cancel) {}
            } message: {
                Text(alertMsg)
            }
            .onAppear {
                if ogMachineName.isEmpty {
                    ogMachineName = machineName()
                }
                engine.refreshActiveGroup()
            }
        }
    }
}

#Preview {
    ContentView()
}
