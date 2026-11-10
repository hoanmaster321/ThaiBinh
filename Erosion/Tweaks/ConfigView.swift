//
//  ConfigView.swift
//  ThaiBinh (ErosionWQ)
//
//  Bản quyền © 2026 ThaiBinh (hoanmaster321)
//

import SwiftUI


enum CNURL {
    static var sharedDevConfig = FSURL.configProfiles.appendingPathComponent("SharedDeviceConfiguration.plist")
    static var cloudConfig = FSURL.configProfiles.appendingPathComponent("CloudConfigurationDetails.plist")
}

enum CNMsg {
    static var supWarning = "Nếu thiết bị của bạn đang được quản lý MDM doanh nghiệp, KHÔNG chạm vào nút này! Bạn có thể thấy màn hình thiết lập sau khi Respring."
    static var resetInfo = "Khi nhấn \"Xác nhận\", dòng chữ dưới màn hình khóa sẽ bị xóa và thiết bị sẽ tắt chế độ Giám sát (Supervision)."
}

struct ConfigView: View {
    @EnvironmentObject private var mgr: ErosionManager
    @AppStorage("autoRespring") var autoRespring = false
    @State private var ftCurrentDict = NSMutableDictionary()
    @State private var ccCurrentDict = NSMutableDictionary()
    @State private var footnoteText = ""
    @State private var supervised = false
    @State private var orgName = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 14) {
                        HStack {
                            Image(systemName: "flashlight.off.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 26)
                                .padding()
                                .modifier(QuickActionBackground())
                            Spacer()
                            Image(systemName: "camera.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 26)
                                .padding()
                                .modifier(QuickActionBackground())
                        }
                        .padding(.horizontal, 35)
                        
                        VStack {
                            Text(footnoteText)
                                .font(.system(size: 9))
                                .frame(height: 10)
                            Capsule()
                                .frame(width: 145, height: 4)
                        }
                    }
                    .padding(.top, 25)
                    .padding(.bottom, 10)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(
                        Group {
                            Image("solarium")
                                .resizable()
                                .scaledToFill()
                                .offset(y: 10)
                        }
                    )
                    
                    TextField("Nhập dòng chữ cuối Màn hình khóa (Footnote)", text: $footnoteText)
                }
                
                Section {
                    PlainToggle("Bật chế độ Giám sát (Supervision)", infoType: .warning, infoTitle: "Cảnh báo Supervision!", infoMessage: CNMsg.supWarning, isOn: $supervised)
                    if supervised {
                        TextField("Tên Tổ chức / Chủ sở hữu", text: $orgName)
                    }
                } header: {
                    HeaderLabel("Giám sát Thiết bị (Supervision)", symbol: "eye")
                }
            }
            .navigationTitle("Cấu hình & Giám sát")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Alertinator.shared.alert(title: "Khôi phục cài đặt gốc?", body: CNMsg.resetInfo, actionLabel: "Xác nhận", action: {
                            reset()
                        })
                    } label: {
                        Label("Đặt lại", systemImage: "gobackward")
                            .labelStyle(.iconOnly)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Áp dụng", role: .adaptiveConfirm) {
                        apply()
                    }
                }
            }
            .onAppear {
                doSetup()
            }
        }
    }
    
    private func doSetup() {
        _ = wq_grant(FSURL.configProfiles.path)
        if !fm.fileExists(atPath: CNURL.sharedDevConfig.path) {
            do {
                let dict = ["LockScreenFootnote" : ""]
                let data = try PropertyListSerialization.data(fromPropertyList: dict, format: .binary, options: 0)
                var err: NSString?
                if !wq_create_file(CNURL.sharedDevConfig.path, data, &err) {
                    try data.write(to: CNURL.sharedDevConfig)
                }
            } catch {
                print("(cn) failed to create footnote file: \(error.localizedDescription)")
            }
        }
        loadData()
    }
    
    private func loadData() {
        if let data = readDataWithWQ(CNURL.sharedDevConfig),
           let dict = (try? PropertyListSerialization.propertyList(from: data, options: .mutableContainersAndLeaves, format: nil)) as? NSMutableDictionary {
            ftCurrentDict = dict
            footnoteText = dict["LockScreenFootnote"] as? String ?? ""
        } else if let ftDict = NSMutableDictionary(contentsOf: CNURL.sharedDevConfig) {
            ftCurrentDict = ftDict
            footnoteText = ftDict["LockScreenFootnote"] as? String ?? ""
        }
        
        if let data = readDataWithWQ(CNURL.cloudConfig),
           let dict = (try? PropertyListSerialization.propertyList(from: data, options: .mutableContainersAndLeaves, format: nil)) as? NSMutableDictionary {
            ccCurrentDict = dict
            supervised = dict["IsSupervised"] as? Bool ?? false
            orgName = dict["OrganizationName"] as? String ?? ""
        } else if let ccDict = NSMutableDictionary(contentsOf: CNURL.cloudConfig) {
            ccCurrentDict = ccDict
            supervised = ccDict["IsSupervised"] as? Bool ?? false
            orgName = ccDict["OrganizationName"] as? String ?? ""
        }
    }
    
    private func apply() {
        _ = wq_grant(FSURL.configProfiles.path)
        let ftDict = ["LockScreenFootnote" : footnoteText]
        ccCurrentDict["IsSupervised"] = supervised
        ccCurrentDict["OrganizationName"] = orgName
        do {
            let ftData = try PropertyListSerialization.data(fromPropertyList: ftDict, format: .binary, options: 0)
            var err: NSString?
            if !wq_write(CNURL.sharedDevConfig.path, ftData, &err) && !wq_create_file(CNURL.sharedDevConfig.path, ftData, &err) {
                try ftData.write(to: CNURL.sharedDevConfig)
            }
            let ccData = try PropertyListSerialization.data(fromPropertyList: ccCurrentDict, format: .binary, options: 0)
            if !wq_write(CNURL.cloudConfig.path, ccData, &err) && !wq_create_file(CNURL.cloudConfig.path, ccData, &err) {
                try ccData.write(to: CNURL.cloudConfig)
            }
            print("(cn) Đã áp dụng cấu hình thành công!")
            Haptic.shared.play(.soft)
            if autoRespring {
                mgr.shouldRespring = true
            } else {
                Alertinator.shared.alert(title: "Đã áp dụng cấu hình!", body: AppMsg.applied, actionLabel: "Respring", action: { mgr.shouldRespring = true })
            }
        } catch {
            print("(cn) failed to write config files: \(error.localizedDescription)")
            Alertinator.shared.alert(title: "Lỗi áp dụng cấu hình!", body: AppMsg.opFailed)
        }
    }
    
    private func reset() {
        _ = wq_grant(FSURL.configProfiles.path)
        ccCurrentDict["IsSupervised"] = false
        ccCurrentDict.removeObject(forKey: "OrganizationName")
        do {
            var err: NSString?
            if !wq_delete(CNURL.sharedDevConfig.path, &err) {
                try? fm.removeItem(at: CNURL.sharedDevConfig)
            }
            let ccData = try PropertyListSerialization.data(fromPropertyList: ccCurrentDict, format: .binary, options: 0)
            if !wq_write(CNURL.cloudConfig.path, ccData, &err) {
                try ccData.write(to: CNURL.cloudConfig)
            }
            print("(cn) Đã đặt lại cấu hình!")
            Haptic.shared.play(.soft)
            loadData()
            footnoteText = ""
            Alertinator.shared.alert(title: "Đã đặt lại cấu hình!", body: AppMsg.applied, actionLabel: "Respring", action: { mgr.shouldRespring = true })
        } catch {
            print("(cn) failed to reset config files: \(error.localizedDescription)")
            Alertinator.shared.alert(title: "Không thể đặt lại cấu hình!", body: AppMsg.opFailed)
        }
    }
}

struct QuickActionBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.clear.interactive(), in: .circle)
        } else {
            content
                .background(.ultraThinMaterial, in: .circle)
        }
    }
}
