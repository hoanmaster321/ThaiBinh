//
//  SettingsView.swift
//  ThaiBinh (ErosionWQ)
//
//  Bản quyền © 2026 ThaiBinh (hoanmaster321)
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("autoRespring") var autoRespring = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("Tự động Respring sau khi áp dụng", isOn: $autoRespring)
                } header: {
                    HeaderLabel("Cài đặt chung", symbol: "gearshape")
                } footer: {
                    Text("Tự động khởi động lại SpringBoard ngay sau khi áp dụng các tinh chỉnh hệ thống.")
                }
                
                Section {
                    AppInfoCell(build: build)
                } header: {
                    HeaderLabel("Thông tin & Bản quyền", symbol: "info.circle")
                } footer: {
                    Text("Bản quyền © 2026 **ThaiBinh (hoanmaster321)**. Phát triển và Việt hóa dựa trên nền tảng mở [ThaiBinh GitHub](https://github.com/hoanmaster321/ThaiBinh).")
                }
                
                Section {
                    LinkCreditCell(image: Image(systemName: "crown.fill"), name: "ThaiBinh (hoanmaster321)", description: "Chủ sở hữu dự án, phát triển tích hợp, nâng cấp tính năng & Việt hóa toàn diện.", url: "https://github.com/hoanmaster321/ThaiBinh")
                    LinkCreditCell(image: Image("lunginspector"), name: "lunginspector", description: "Tác giả nền tảng Erosion gốc.", url: "https://github.com/lunginspector")
                    LinkCreditCell(image: Image(systemName: "externaldrive.fill.badge.checkmark"), name: "kolbicz", description: "Tác giả nhân xử lý WQFiles & LaunchServices.", url: "https://github.com/kolbicz/WQFiles")
                    LinkCreditCell(image: Image("forcequit"), name: "forcequit (Taj C)", description: "Kỹ thuật vượt sandbox worse_query.", url: "https://github.com/forcequitOS")
                    LinkCreditCell(image: Image("0xjohnny"), name: "0xjohnny", description: "Kỹ thuật vượt sandbox worse_query / bad_query.", url: "https://github.com/0xjohnnydev")
                    LinkCreditCell(image: Image("skadz108"), name: "Skadz", description: "Triển khai exploit và các hàm hệ thống.", url: "https://github.com/skadz108")
                    LinkCreditCell(image: Image("neonmodder123"), name: "neonmodder123", description: "Phương thức Respring qua WebView.", url: "https://github.com/neonmodder123")
                } header: {
                    HeaderLabel("Đóng góp & Tác giả", symbol: "star.fill")
                }
            }
            .navigationTitle("Cài đặt")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        ToolbarLabel("Đóng", symbol: "xmark")
                    }
                }
            }
        }
    }
}
