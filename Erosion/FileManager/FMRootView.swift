//
//  FMRootView.swift
//  ThaiBinh (ErosionWQ)
//
//  Trình duyệt Tệp MCM Container & Sao lưu an toàn
//  Bản quyền © 2026 ThaiBinh (hoanmaster321)
//

import SwiftUI

enum FSPaths {
    static let appContainers = "/var/mobile/Containers/Data/Application"
    static var appBundles = "/var/containers/Bundle/Application"
}

enum FSURL {
    static let appContainers = URL(fileURLWithPath: FSPaths.appContainers)
    static var sysGroup = URL(fileURLWithPath: "/var/containers/Shared/SystemGroup")
    static var configProfiles = FSURL.sysGroup.appendingPathComponent("systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles")
    static var internalDaemons = URL(fileURLWithPath: "/var/mobile/Containers/Data/InternalDaemon")
    static var appPlugins = URL(fileURLWithPath: "/var/mobile/Containers/Data/PluginKitPlugin")
    static var appGroup = URL(fileURLWithPath: "/var/mobile/Containers/Shared/AppGroup")
    static var systemData = URL(fileURLWithPath: "/var/containers/Data/System")
    static var appBackups = URL.documentsDirectory.appendingPathComponent("AppBackups")
    static var safeBackups = URL.documentsDirectory.appendingPathComponent("Backups")
}

struct FMRootView: View {
    @State private var showCustomPathAlert = false
    @State private var customPathInput = ""
    @State private var navigateToCustomURL: URL? = nil
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        FileBrowserView(path: FSURL.appContainers, isContainer: true)
                    } label: {
                        Label("Dữ liệu Ứng dụng (Data/Application)", systemImage: "square.grid.2x2")
                    }
                    
                    NavigationLink {
                        FileBrowserView(path: FSURL.appGroup, shouldGrant: true)
                    } label: {
                        Label("Nhóm Ứng dụng (Shared/AppGroup)", systemImage: "square.stack.3d.up")
                    }
                    
                    NavigationLink {
                        FileBrowserView(path: FSURL.appPlugins, isContainer: true)
                    } label: {
                        Label("Tiện ích mở rộng & Widget (PluginKitPlugin)", systemImage: "puzzlepiece.extension")
                    }
                } header: {
                    HeaderLabel("Nhánh Ứng dụng (MCM Application)", symbol: "app.badge")
                }
                
                Section {
                    NavigationLink {
                        FileBrowserView(path: FSURL.sysGroup, isContainer: true)
                    } label: {
                        Label("Nhóm Hệ thống (SystemGroup - Gestalt, Profiles)", systemImage: "slider.horizontal.3")
                    }
                    
                    NavigationLink {
                        FileBrowserView(path: FSURL.internalDaemons, isContainer: true)
                    } label: {
                        Label("Tiến trình Nội bộ (InternalDaemon)", systemImage: "gearshape.2")
                    }
                    
                    NavigationLink {
                        FileBrowserView(path: FSURL.systemData, shouldGrant: true)
                    } label: {
                        Label("Dữ liệu Hệ thống (Data/System)", systemImage: "cpu")
                    }
                    
                    NavigationLink {
                        FileBrowserView(path: URL(fileURLWithPath: "/"), shouldGrant: true)
                    } label: {
                        Label("Thư mục Gốc (/)", systemImage: "internaldrive")
                    }
                } header: {
                    HeaderLabel("Nhánh Hệ thống (MCM System)", symbol: "gear")
                }
                
                Section {
                    NavigationLink {
                        FileBrowserView(path: FSURL.appBackups, shouldGrant: false)
                    } label: {
                        Label("Kho Sao lưu Ứng dụng (AppBackups)", systemImage: "externaldrive.badge.timemachine")
                    }
                    
                    NavigationLink {
                        FileBrowserView(path: FSURL.safeBackups, shouldGrant: false)
                    } label: {
                        Label("Kho Sao lưu Tệp bị ghi đè (Backups)", systemImage: "arrow.counterclockwise.circle")
                    }
                } header: {
                    HeaderLabel("Kho Sao lưu An toàn", symbol: "shield.checkerboard")
                }
                
                Section {
                    Button {
                        showCustomPathAlert = true
                    } label: {
                        Label("Đi tới Đường dẫn bất kỳ…", systemImage: "arrow.right.circle")
                    }
                } header: {
                    HeaderLabel("Điều hướng nhanh", symbol: "magnifyingglass")
                }
            }
            .navigationTitle("Trình duyệt Tệp")
            .alert("Đi tới Đường dẫn", isPresented: $showCustomPathAlert) {
                TextField("/var/mobile/...", text: $customPathInput)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button("Mở") {
                    let cleaned = customPathInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !cleaned.isEmpty {
                        navigateToCustomURL = URL(fileURLWithPath: cleaned)
                    }
                }
                Button("Hủy", role: .cancel) {}
            } message: {
                Text("Nhập đường dẫn tuyệt đối trên hệ thống tệp iOS để mở.")
            }
            .background(
                Group {
                    if let target = navigateToCustomURL {
                        NavigationLink(
                            destination: FileBrowserView(path: target, shouldGrant: true),
                            isActive: Binding(
                                get: { navigateToCustomURL != nil },
                                set: { if !$0 { navigateToCustomURL = nil } }
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
