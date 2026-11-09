//
//  FMRootView.swift
//  ErosionWQ
//
//  File Browser Root View: Fast container bookmarks & custom path navigation
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
                        Label("App Data Containers", systemImage: "square.grid.2x2")
                    }
                    
                    NavigationLink {
                        FileBrowserView(path: FSURL.appGroup, shouldGrant: true)
                    } label: {
                        Label("App Groups", systemImage: "square.stack.3d.up")
                    }
                    
                    NavigationLink {
                        FileBrowserView(path: FSURL.appPlugins, isContainer: true)
                    } label: {
                        Label("Plugin Containers", systemImage: "puzzlepiece.extension")
                    }
                } header: {
                    HeaderLabel("Applications", symbol: "app.badge")
                }
                
                Section {
                    NavigationLink {
                        FileBrowserView(path: FSURL.internalDaemons, isContainer: true)
                    } label: {
                        Label("Internal Daemons", systemImage: "gearshape.2")
                    }
                    
                    NavigationLink {
                        FileBrowserView(path: FSURL.systemData, shouldGrant: true)
                    } label: {
                        Label("System Data", systemImage: "cpu")
                    }
                    
                    NavigationLink {
                        FileBrowserView(path: FSURL.sysGroup, isContainer: true)
                    } label: {
                        Label("System Groups (Gestalt & Profiles)", systemImage: "slider.horizontal.3")
                    }
                    
                    NavigationLink {
                        FileBrowserView(path: URL(fileURLWithPath: "/"), shouldGrant: true)
                    } label: {
                        Label("Root Filesystem (/)", systemImage: "internaldrive")
                    }
                } header: {
                    HeaderLabel("System Containers", symbol: "gear")
                }
                
                Section {
                    NavigationLink {
                        FileBrowserView(path: FSURL.appBackups, shouldGrant: false)
                    } label: {
                        Label("App Data Backups", systemImage: "externaldrive.badge.timemachine")
                    }
                    
                    NavigationLink {
                        FileBrowserView(path: FSURL.safeBackups, shouldGrant: false)
                    } label: {
                        Label("File Overwrite Backups", systemImage: "arrow.counterclockwise.circle")
                    }
                } header: {
                    HeaderLabel("Safety Backups", symbol: "shield.checkerboard")
                }
                
                Section {
                    Button {
                        showCustomPathAlert = true
                    } label: {
                        Label("Go to Path…", systemImage: "arrow.right.circle")
                    }
                } header: {
                    HeaderLabel("Navigation", symbol: "magnifyingglass")
                }
            }
            .navigationTitle("File Browser")
            .alert("Go to Path", isPresented: $showCustomPathAlert) {
                TextField("/var/mobile/...", text: $customPathInput)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button("Go") {
                    let cleaned = customPathInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !cleaned.isEmpty {
                        navigateToCustomURL = URL(fileURLWithPath: cleaned)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter an absolute iOS filesystem path to navigate to.")
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
