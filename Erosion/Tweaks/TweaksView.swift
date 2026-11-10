//
//  TweaksView.swift
//  ThaiBinh (ErosionWQ)
//
//  Bản quyền © 2026 ThaiBinh (hoanmaster321)
//

import SwiftUI


struct TweaksView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: ThemeStudioView()) {
                        Label("Theme & Mod Giao diện (Wallet, Safari, Icon)", systemImage: "paintpalette.fill")
                    }
                    NavigationLink(destination: PosterBoardView()) {
                        Label("Hình nền Động (.tendies PosterBoard)", systemImage: "photo.on.rectangle.angled")
                    }
                    NavigationLink(destination: KeypadView()) {
                        Label("Theme Bàn phím Gọi điện (6 Theme dựng sẵn)", systemImage: "circle.grid.3x3.fill")
                    }
                    NavigationLink(destination: SpringBoardTweaksView()) {
                        Label("SpringBoard, Màn hình khóa & SystemGroup", systemImage: "sparkles.rectangle.stack")
                    }
                } header: {
                    HeaderLabel("Giao diện & Chủ đề (Theming)", symbol: "paintbrush")
                }
                
                Section {
                    NavigationLink(destination: GestaltView()) {
                        Label("MobileGestalt (Dynamic Island, AOD, Sạc 80%)", systemImage: "cpu")
                    }
                    NavigationLink(destination: ConfigView()) {
                        Label("Chữ Màn hình khóa & Giám sát (Supervision)", systemImage: "lock.rectangle.on.rectangle")
                    }
                    NavigationLink(destination: OperationsView()) {
                        Label("Ghi đè Tệp Hệ thống & Preset MCM", systemImage: "wrench.and.screwdriver")
                    }
                } header: {
                    HeaderLabel("Hệ thống & Mở khóa Tính năng", symbol: "gear")
                }
            }
            .navigationTitle("Tinh chỉnh")
        }
    }
}
