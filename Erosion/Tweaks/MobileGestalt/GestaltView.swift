//
//  GestaltView.swift
//  ThaiBinh (ErosionWQ)
//
//  Bản quyền © 2026 ThaiBinh (hoanmaster321)
//

import SwiftUI
import UniformTypeIdentifiers

struct GestaltView: View {
    @EnvironmentObject private var mgr: ErosionManager
    @StateObject private var store = GestaltStore.shared
    @AppStorage("mgOverrideGates") private var mgOverrideGates = false
    @AppStorage("mgWriteAtomically") private var mgWriteAtomically = true
    @AppStorage("autoRespring") var autoRespring = false
    @AppStorage("hasShownSheet") private var hasShownSheet = false
    @Environment(\.dismiss) private var dismiss
    
    @State private var mgSubtype = 0
    @State private var mgOgSubtype = 0
    @State private var mgOgDeviceName = ""
    @State private var mgEnableDeviceName = false
    @AppStorage("mgDeviceName") private var mgDeviceName = ""
    @AppStorage("ogMachineName") private var ogMachineName = ""
    @AppStorage("showRegionTweak") private var showRegionTweak = false
    @AppStorage("showCustomKeys") private var showCustomKeys = false
    @AppStorage("mgCustKeyArray") var customKeys: [MGCustomKey] = []
    @State private var mgProductType = ""
    
    @State private var showInfoSheet = false
    @State private var idiotButtonTimerComplete = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Picker("Độ phân giải (Subtype)", selection: $mgSubtype) {
                            Text("Mặc định (\(mgOgSubtype))").tag(mgOgSubtype)
                            if isDynamIslandHD() && doubleSysVrs() < 19.0 {
                                Text("Tắt Dynamic Island").tag(2436)
                            }
                            Text("iPhone 14 Pro").tag(2436)
                            Text("iPhone 14 Pro Max").tag(2796)
                            Text("iPhone 15 Pro Max").tag(2976)
                            if doubleSysVrs() >= 18.0 {
                                Text("iPhone 16 Pro").tag(2622)
                                Text("iPhone 16 Pro Max").tag(2868)
                            }
                            if doubleSysVrs() >= 26.0 {
                                Text("iPhone Air").tag(2736)
                            }
                            if doubleSysVrs() >= 27.0 {
                                Text("iPhone 18 Pro Max").tag(2670)
                            }
                            if isHomeButtonHD() {
                                Text("Cử chỉ vuốt iPhone X").tag(2436)
                            }
                        }
                        Spacer()
                        Button {
                            Alertinator.shared.alert(title: "Thông tin Subtype", body: MGMsg.subtype)
                        } label: {
                            Image(systemName: "info.circle")
                                .frame(width: 24, height: 22)
                        }
                        .buttonStyle(.plain)
                    }
                    Toggle("Đổi tên mô tả thiết bị", isOn: $mgEnableDeviceName)
                    if mgEnableDeviceName {
                        TextField("Tên thiết bị tùy chỉnh", text: $mgDeviceName)
                    }
                } header: {
                    HeaderLabel("Hiển thị & Khung hình (Artwork)", symbol: "paintbrush.pointed")
                }
                
                if !isDynamIslandHD() || !isAODHD() || !isBootChimeHD() || !isChargeLimitHD() || mgOverrideGates {
                    Section {
                        if !isDynamIslandHD() || mgOverrideGates {
                            PlainToggle("Bật Dynamic Island", minVrs: 19.0, isOn: store.mgKeyBinding([MGKey.island]))
                        }
                        if !isAODHD() || mgOverrideGates {
                            PlainToggle("Bật Màn hình luôn sáng (AOD)", minVrs: 18.0, isOn: store.mgKeyBinding([MGKey.AOD, MGKey.AOTime]))
                            if store.isEnabled([MGKey.AOD]) {
                                PlainToggle("Hiệu ứng AOD Vibrancy", minVrs: 18.0, isOn: store.mgKeyBinding([MGKey.AODVibrancy]))
                            }
                        }
                        if !isBootChimeHD() || mgOverrideGates {
                            PlainToggle("Giới hạn sạc 80% (Charge Limit)", minVrs: 17.0, isOn: store.mgKeyBinding([MGKey.chargeLim]))
                        }
                        if !isChargeLimitHD() || mgOverrideGates {
                            PlainToggle("Âm thanh khởi động (Boot Chime)", isOn: store.mgKeyBinding([MGKey.bootChime]))
                        }
                    } header: {
                        HeaderLabel("Tính năng Phần cứng", symbol: "gearshape")
                    }
                }
                
                Section {
                    PlainToggle("Bật Internal Install", infoType: .info, infoMessage: MGMsg.intInstall, isOn: store.mgKeyBinding([MGKey.intInstall]))
                    PlainToggle("Bật Internal Build (Dung lượng ẩn)", infoType: .info, infoMessage: MGMsg.intBuild, isOn: store.mgKeyBinding([MGKey.intBuild]))
                } header: {
                    HeaderLabel("Tính năng Nội bộ (Internal)", symbol: "ant")
                }
                .disabled(store.isEnabled([MGKey.appIntell]))
                
                Section {
                    PlainToggle("Bật giao diện SRD UI", minVrs: 26.0, isOn: store.mgKeyBinding([MGKey.srd]))
                    if showRegionTweak || mgOverrideGates {
                        PlainToggle("Gỡ giới hạn vùng (Tắt âm chụp ảnh)", isOn: store.mgRegionRestrictionsBinding())
                    }
                    if !isAppleIntellHD() || mgOverrideGates {
                        PlainToggle("Mở khóa Apple Intelligence", minVrs: 18.1, isOn: store.mgKeyBinding([MGKey.appIntell]))
                            .onChange(of: store.mgKeyBinding([MGKey.appIntell]).wrappedValue) { (_, newVal) in
                                if newVal {
                                    store.mgPullKeys([MGKey.intBuild, MGKey.intInstall])
                                }
                            }
                    }
                    HStack(spacing: 10) {
                        Picker("Giả lập mã máy (Spoof)", selection: $mgProductType) {
                            Text("Mặc định").tag(ogMachineName)
                            if ogMachineName.contains("Pad") {
                                if doubleSysVrs() >= 17.4 {
                                    Text("iPad Pro 11-inch (M4)").tag("iPad16,3")
                                    Text("iPad Pro 11-inch (M4, Cellular)").tag("iPad16,4")
                                }
                                Text("iPad Pro 11-inch (4th Gen)").tag("iPad14,3")
                                Text("iPad Pro 11-inch (4th Gen, Cellular)").tag("iPad14,4")
                            } else {
                                Text("iPhone 15 Pro").tag("iPhone16,1")
                                Text("iPhone 15 Pro Max").tag("iPhone16,2")
                                if doubleSysVrs() >= 18.0 {
                                    Text("iPhone 16").tag("iPhone17,3")
                                    Text("iPhone 16 Plus").tag("iPhone17,4")
                                    Text("iPhone 16 Pro").tag("iPhone17,1")
                                    Text("iPhone 16 Pro Max").tag("iPhone17,2")
                                }
                                if doubleSysVrs() >= 19.0 {
                                    Text("iPhone 17").tag("iPhone18,3")
                                    Text("iPhone 17 Pro").tag("iPhone18,1")
                                    Text("iPhone 17 Pro Max").tag("iPhone18,2")
                                    Text("iPhone Air").tag("iPhone18,4")
                                }
                                if doubleSysVrs() >= 27.0 {
                                    Text("iPhone 18 Pro").tag("iPhone19,2")
                                    Text("iPhone 18 Pro Max").tag("iPhone19,3")
                                    Text("iPhone Duo").tag("iPhone19,4")
                                }
                            }
                        }
                        Button {
                            Alertinator.shared.alert(title: "Thông tin Giả lập", body: isAppleIntellHD() ? MGMsg.spoofUseless : MGMsg.spoofAI)
                        } label: {
                            Image(systemName: "info.circle")
                                .frame(width: 24, height: 22)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    HeaderLabel("Mở khóa Điều kiện (Eligibility)", symbol: "flag")
                }
                
                Section {
                    if !isCrashDectHD() || mgOverrideGates {
                        PlainToggle("Phát hiện va chạm (Crash Detection)", isOn: store.mgKeyBinding([MGKey.crashDet]))
                    }
                    if !isPWMHD() || mgOverrideGates {
                        PlainToggle("Điều chế độ rộng xung (PWM)", minVrs: 19.0, isOn: store.mgKeyBinding([MGKey.pwm]))
                    }
                    if ogMachineName.contains("iPhone") || mgOverrideGates {
                        PlainToggle("Hỗ trợ Apple Pencil", isOn: store.mgKeyBinding([MGKey.appPencil]))
                    }
                    if !isCamControlHD() || mgOverrideGates {
                        PlainToggle("Điều khiển Camera (Camera Control)", minVrs: 18.0, isOn: store.mgKeyBinding([MGKey.camButton, MGKey.grapPefr]))
                    }
                    if !isActionButtonHD() || mgOverrideGates {
                        PlainToggle("Nút Tác Vụ (Action Button)", minVrs: 17.0, isOn: store.mgKeyBinding([MGKey.actButton]))
                    }
                    if isHomeButtonHD() || mgOverrideGates {
                        PlainToggle("Chạm để bật màn hình (Tap to Wake)", isOn: store.mgKeyBinding([MGKey.tapToWake]))
                    }
                } header: {
                    HeaderLabel("Menu Cài đặt (Preference Bundles)", symbol: "gear")
                }
                
                Section {
                    if machineName().contains("iPad") || mgOverrideGates {
                        PlainToggle("Bật Quản lý Màn hình (Stage Manager)", isOn: store.mgKeyBinding([MGKey.stageMgr]))
                    }
                    if store.strVal(forKey: MGKey.deviceClass) == "iPhone" || mgOverrideGates {
                        PlainToggle("Bật giao diện iPadOS UI", infoType: .warning, infoMessage: MGMsg.ipadOS, isOn: store.mgTrollPadBinding())
                    }
                } header: {
                    HeaderLabel("Tính năng iPadOS", symbol: "ipad")
                }
            }
            .navigationTitle("MobileGestalt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            mgRevert()
                        } label: {
                            Label("Hoàn tác về mặc định", systemImage: "xmark")
                        }
                        
                        Button(role: .destructive) {
                            Alertinator.shared.alert(title: "Đặt lại MobileGestalt?", body: MGMsg.mgReset, actionLabel: "Xác nhận", action: {
                                do {
                                    try? fm.removeItem(at: MGURL.savedGestaltURL)
                                    var err: NSString?
                                    if !wq_delete(MGURL.fsGestaltURL.path, &err) {
                                        try fm.removeItem(at: MGURL.fsGestaltURL)
                                    }
                                    store.mgCurrentDict = NSMutableDictionary()
                                    Alertinator.shared.alert(title: "Đã đặt lại MobileGestalt!", body: MGMsg.mgResetComp, showCancel: false, actionLabel: "Thoát ứng dụng", action: { exitinator() })
                                } catch {
                                    print("(mg) failed to reset mobilegestalt: \(error.localizedDescription)")
                                    Alertinator.shared.alert(title: "Lỗi đặt lại MobileGestalt!", body: AppMsg.opFailed)
                                }
                            })
                        } label: {
                            Label("Xóa & Tạo lại Gestalt", systemImage: "trash")
                        }
                        
                        Divider()
                        
                        if showCustomKeys {
                            NavigationLink(destination: CustomKeyView()) {
                                Label("Khóa tùy chỉnh (Custom Keys)", systemImage: "pencil")
                            }
                        }
                        
                        NavigationLink {
                            List {
                                Section {
                                    Button("Xuất tệp Gestalt hiện tại") {
                                        if let temp = makeTemp(MGURL.fsGestaltURL) {
                                            presentShareSheet(with: temp)
                                        } else {
                                            presentShareSheet(with: MGURL.fsGestaltURL)
                                        }
                                    }
                                    Button("Xuất tệp Gestalt gốc đã lưu") {
                                        presentShareSheet(with: MGURL.savedGestaltURL)
                                    }
                                    Button("Cập nhật lại bản Gestalt gốc", role: .destructive) {
                                        Alertinator.shared.alert(title: "Cảnh báo!", body: MGMsg.mgResetSavWarn, action: {
                                            try? fm.removeItem(at: MGURL.savedGestaltURL)
                                            let _ = mgLoadData()
                                        })
                                    }
                                } header: {
                                    HeaderLabel("Dữ liệu sao lưu", symbol: "loupe")
                                }
                                
                                Section {
                                    PlainToggle("Hiển thị toàn bộ Tinh chỉnh ẩn", infoType: .warning, infoMessage: MGMsg.hidTweakWarn, isOn: $mgOverrideGates)
                                    Toggle("Bật mục Khóa tùy chỉnh", isOn: $showCustomKeys)
                                    Toggle("Ghi đè bền vững (Atomic Write)", isOn: $mgWriteAtomically)
                                } footer: {
                                    Text("Khi bật Atomic Write, các tinh chỉnh MobileGestalt sẽ giữ nguyên sau khi khởi động lại máy.")
                                }
                            }
                            .navigationTitle("Cài đặt Gestalt")
                        } label: {
                            Label("Cài đặt Gestalt", systemImage: "gear")
                        }
                    } label: {
                        Label("Menu", systemImage: "ellipsis")
                            .labelStyle(.iconOnly)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Áp dụng", role: .adaptiveConfirm) {
                        if !hasShownSheet {
                            showInfoSheet = true
                        } else {
                            mgApply()
                        }
                    }
                }
            }
            .sheet(isPresented: $showInfoSheet) {
                NavigationStack {
                    VStack {
                        InfoSheet(title: "Lưu ý trước khi áp dụng...") {
                            InfoSheetCell(title: "Cảnh báo quan trọng!", symbol: "exclamationmark.triangle.fill", context: MGMsg.support)
                                .modifier(SectionPlatter())
                            InfoSheetCell(title: "Apple Intelligence", symbol: "apple.intelligence", context: MGMsg.spoofAI)
                            InfoSheetCell(title: "Giao diện iPadOS UI", symbol: "ipad", context: MGMsg.ipadOS)
                            InfoSheetCell(title: "Gỡ giới hạn vùng", symbol: "map", context: MGMsg.region)
                        } button: {
                            Button("Áp dụng ngay") {
                                showInfoSheet = false
                                hasShownSheet = true
                                idiotButtonTimerComplete = false
                                mgApply(isFromSheet: true)
                            }
                            .buttonStyle(ConfirmButtonStyle())
                            .padding(.horizontal, 30)
                            .padding(.bottom, device.userInterfaceIdiom == .pad ? 25 : 0)
                            .disabled(!idiotButtonTimerComplete)
                        }
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            idiotButtonTimerComplete = true
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Hủy") {
                                showInfoSheet = false
                                idiotButtonTimerComplete = false
                            }
                        }
                    }
                }
            }
            .onAppear {
                _ = wq_grant(MGURL.fsGestaltURL.deletingLastPathComponent().path)
                store.mgCurrentDict = mgLoadData()
            }
        }
    }
    
    private func mgLoadData() -> NSMutableDictionary {
        _ = wq_grant(MGURL.fsGestaltURL.deletingLastPathComponent().path)
        do {
            guard let mgData = readDataWithWQ(MGURL.fsGestaltURL) else {
                throw "Không thể đọc tệp com.apple.MobileGestalt.plist"
            }
            if !fm.fileExists(atPath: MGURL.savedGestaltURL.path) {
                try mgData.write(to: MGURL.savedGestaltURL)
                if let locale = Locale.current.region?.identifier {
                    showRegionTweak = locale != "US"
                }
            }
            
            if let ogDict = NSDictionary(contentsOf: MGURL.savedGestaltURL),
               let ogCacheExtra = ogDict["CacheExtra"] as? NSDictionary,
               let ogArtwork = ogCacheExtra[MGKey.artwork] as? NSDictionary {
                mgOgSubtype = ogArtwork["ArtworkDeviceSubType"] as? Int ?? 0
                mgOgDeviceName = ogArtwork["ArtworkDeviceProductDescription"] as? String ?? ""
            }
            
            guard let currentDict = (try? PropertyListSerialization.propertyList(from: mgData, options: .mutableContainersAndLeaves, format: nil)) as? NSMutableDictionary else {
                throw "Không thể phân tích cấu trúc từ điển MobileGestalt"
            }
            
            if let cacheExtra = currentDict["CacheExtra"] as? NSDictionary,
               let artwork = cacheExtra[MGKey.artwork] as? NSDictionary {
                mgSubtype = artwork["ArtworkDeviceSubType"] as? Int ?? 0
                mgDeviceName = artwork["ArtworkDeviceProductDescription"] as? String ?? ""
                if mgDeviceName != mgOgDeviceName {
                    mgEnableDeviceName = true
                }
                mgProductType = cacheExtra[MGKey.prodType] as? String ?? machineName()
            }
            
            return currentDict
        } catch {
            print("(mg) Lỗi đọc MobileGestalt: \(error.localizedDescription)")
            Haptic.shared.play(.heavy)
            Alertinator.shared.alert(title: "Không thể đọc MobileGestalt!", body: "Hãy kiểm tra lại quyền App Group của ứng dụng.\nChi tiết: \(error.localizedDescription)")
        }
        
        return [:]
    }
    
    private func mgApply(isFromSheet: Bool = false) {
        do {
            let mgDictToApply = store.mgCurrentDict
            
            if let cacheExtra = mgDictToApply["CacheExtra"] as? NSMutableDictionary,
               let artwork = cacheExtra[MGKey.artwork] as? NSMutableDictionary {
                artwork["ArtworkDeviceSubType"] = mgSubtype
                if mgEnableDeviceName {
                    artwork["ArtworkDeviceProductDescription"] = mgDeviceName
                }
                cacheExtra[MGKey.prodType] = mgProductType
                for item in customKeys {
                    if item.isOn {
                        cacheExtra[item.key] = item.value
                    } else {
                        cacheExtra.removeObject(forKey: item.key)
                    }
                }
            } else {
                throw "Chưa nạp được từ điển CacheExtra của MobileGestalt!"
            }
            
            let data = try PropertyListSerialization.data(fromPropertyList: mgDictToApply, format: .binary, options: 0)
            let res = mgWrite(data)
            
            if res {
                print("[*] Đã ghi đè MobileGestalt thành công!")
                Haptic.shared.play(.soft)
                if autoRespring || isFromSheet {
                    mgr.shouldRespring = true
                } else {
                    Alertinator.shared.alert(title: "Đã áp dụng MobileGestalt!", body: AppMsg.applied + (store.isEnabled([MGKey.appIntell]) ? " Hãy khởi động lại máy nếu bạn bật Apple Intelligence." : ""), actionLabel: "Respring", action: { mgr.shouldRespring = true })
                }
            } else {
                throw "Ghi đè thất bại!"
            }
        } catch {
            print("(mg) Lỗi áp dụng MobileGestalt: \(error.localizedDescription)")
            Alertinator.shared.alert(title: "Lỗi áp dụng MobileGestalt!", body: "Chi tiết: \(error.localizedDescription)")
        }
    }
    
    private func mgRevert() {
        do {
            guard let mgDictToApply = NSMutableDictionary(contentsOf: MGURL.savedGestaltURL) else {
                throw "Không tìm thấy bản sao lưu Gestalt gốc!"
            }
            
            let data = try PropertyListSerialization.data(fromPropertyList: mgDictToApply, format: .binary, options: 0)
            let res = mgWrite(data)
            
            if res {
                print("[*] Đã khôi phục MobileGestalt gốc!")
                Haptic.shared.play(.soft)
                if let dict = NSMutableDictionary(contentsOf: MGURL.savedGestaltURL) {
                    store.mgCurrentDict = dict
                }
                Alertinator.shared.alert(title: "Đã hoàn tác MobileGestalt!", body: MGMsg.revertComp)
            } else {
                throw "Ghi đè thất bại!"
            }
        } catch {
            print("(mg) Lỗi hoàn tác MobileGestalt: \(error.localizedDescription)")
            Alertinator.shared.alert(title: "Không thể hoàn tác MobileGestalt!", body: AppMsg.opFailed)
        }
    }
}
