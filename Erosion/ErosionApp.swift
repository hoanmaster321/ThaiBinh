//
//  ErosionApp.swift
//  ThaiBinh (ErosionWQ)
//
//  Developed & Customized by ThaiBinh (hoanmaster321)
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

let device = UIDevice.current
let fm = FileManager.default
var weOnADebugBuild = false
var pipe = Pipe()
var sema = DispatchSemaphore(value: 0)

@main
struct ErosionApp: App {
    @StateObject private var mgr = ErosionManager.shared
    @State private var currentTab = 0
    @State private var showMissingAppGroupAlert = false
    
    init() {
        setvbuf(stdout, nil, _IONBF, 0)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        
        // fix file picker
        let fixMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.fix_init(forOpeningContentTypes:asCopy:)))!
        let origMethod = class_getInstanceMethod(UIDocumentPickerViewController.self, #selector(UIDocumentPickerViewController.init(forOpeningContentTypes:asCopy:)))!
        method_exchangeImplementations(origMethod, fixMethod)
        
        #if DEBUG
        weOnADebugBuild = true
        #else
        weOnADebugBuild = false
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            TabView(selection: $currentTab) {
                ContentView()
                    .tabItem {
                        Label("Trang chủ", systemImage: "house")
                    }
                    .tag(0)
                TweaksView()
                    .tabItem {
                        Label("Tinh chỉnh", systemImage: "wrench.and.screwdriver")
                    }
                    .tag(1)
                AppsManagerView()
                    .tabItem {
                        Label("Ứng dụng", systemImage: "square.grid.2x2")
                    }
                    .tag(2)
                CacheCleanerView()
                    .tabItem {
                        Label("Dọn rác", systemImage: "sparkles")
                    }
                    .tag(3)
                FMRootView()
                    .tabItem {
                        Label("Tệp tin", systemImage: "folder")
                    }
                    .tag(4)
            }
            .environmentObject(mgr)
            .onAppear {
                pipe.fileHandleForReading.readabilityHandler = { fh in
                    let data = fh.availableData
                    
                    if data.isEmpty {
                        fh.readabilityHandler = nil
                        sema.signal()
                        return
                    }
                    
                    guard let text = String(data: data, encoding: .utf8) else {
                        return
                    }
                    
                    DispatchQueue.main.async {
                        mgr.logOutput.append(text)
                    }
                }
                print("")
                print("[*] ThaiBinh (ErosionWQ) v\(AppInfo.appVersion) (\(build))")
                print("[*] Bản quyền © 2026 ThaiBinh (hoanmaster321)")
                print("[*] Thiết bị: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion), \(machineName())")
                group = wq.getAppGroup()
                print("[*] App Group đang hoạt động: \(group)")
                if wq_app_group() == nil && !weOnADebugBuild {
                    showMissingAppGroupAlert = true
                }
            }
            .alert("Chưa có quyền App Group", isPresented: $showMissingAppGroupAlert) {
                Button("Đã hiểu", role: .cancel) {}
            } message: {
                Text("Bản cài đặt này được ký mà không có quyền App Group (com.apple.security.application-groups), nên ứng dụng không thể truy cập ngoài Sandbox.\n\nHãy cài đặt lại qua AltStore, SideStore, Sideloadly hoặc chứng chỉ có bật quyền App Group.")
            }
            .overlay {
                if mgr.shouldRespring {
                    RespringView()
                        .brightness(-1.0)
                        .ignoresSafeArea()
                }
            }
        }
    }
}

extension UIDocumentPickerViewController {
    @objc func fix_init(forOpeningContentTypes contentTypes: [UTType], asCopy: Bool) -> UIDocumentPickerViewController {
        return fix_init(forOpeningContentTypes: contentTypes, asCopy: true)
    }
}
