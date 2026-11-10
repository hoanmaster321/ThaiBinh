//
//  PosterBoardView.swift
//  ThaiBinh (ErosionWQ)
//
//  Bản quyền © 2026 ThaiBinh (hoanmaster321)
//

import SwiftUI
import UniformTypeIdentifiers

let pbHandler = PBHandler()

enum PBMsg {
    static var noTendies = "Hãy nhập tệp hình nền .tendies để bắt đầu cài đặt hình nền động."
    static var tooManyTendies = "Bạn chỉ có thể chọn tối đa 15 hình nền cùng lúc. Hãy bỏ chọn bớt một gói khác!"
    static var limitWarning = "Bạn đang chọn nhiều hơn 5 hình nền. Một số hình nền có thể không hiển thị đầy đủ. Bạn vẫn muốn tiếp tục?"
    static var corruption = "Vui lòng kiểm tra lại tệp .tendies không bị lỗi và thử lại."
    static var finishApply = "Ứng dụng PosterBoard sẽ mở ra. Hãy vuốt đóng PosterBoard từ trình đa nhiệm. Nếu hình nền chưa hiện, hãy thử Đặt lại (Reset) các bộ sưu tập trong phần Cài đặt PosterBoard."
    static var applyInfo = "Nếu hình nền chưa xuất hiện trong PosterBoard, hãy vào Cài đặt ở góc trên và nhấn Đặt lại Collections rồi thử lại."
    static var imprtFailed = "Đảm bảo bạn đã chọn đúng tệp .tendies hợp lệ."
}

struct PosterBoardView: View {
    @AppStorage("pbContainerPath") private var pbContainerPath = ""
    @AppStorage("tendiesArray") private var tendiesArray: [TendiesObject] = []
    @AppStorage("hasShownFirstRunMsg") private var hasShownFirstRunMsg = false
    
    @State private var showImporter = false
    let columns = Array(repeating: GridItem(.flexible()), count: device.userInterfaceIdiom == .pad ? 4 : 2)
    
    var body: some View {
        ScrollView {
            if tendiesArray.isEmpty {
                Button {
                    showImporter = true
                } label: {
                    VStack(alignment: .leading) {
                        CompactAlert(title: "Chưa có gói .tendies nào!", symbol: "exclamationmark.triangle.fill", text: PBMsg.noTendies)
                            .padding(.horizontal, 15)
                    }
                    .frame(alignment: .leading)
                    .multilineTextAlignment(.leading)
                }
            }
            LazyVGrid(columns: columns) {
                ForEach($tendiesArray) { $tendies in
                    Button {
                        if !tendies.isOn && tendiesArray.filter({ $0.isOn }).flatMap({ $0.descrNames }).count > 15 {
                            Alertinator.shared.alert(title: "Đã đạt giới hạn hình nền!", body: PBMsg.tooManyTendies)
                        } else {
                            tendies.isOn.toggle()
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: tendies.targetDescr == .photos ? "play.rectangle" : "photo")
                                .imageScale(.large)
                                .foregroundStyle(Color.accentColor)
                            VStack {
                                Text(tendies.name)
                                    .lineLimit(1)
                                    .fontWeight(.medium)
                                Text("\(tendies.descrNames.count) hình nền")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .padding(.vertical, 10)
                        .background {
                            if tendies.targetDescr == .mercury {
                                VStack {
                                    Text("M")
                                        .font(.footnote)
                                        .padding(6)
                                        .background(Color.accentColor)
                                        .clipShape(.circle)
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .frame(maxHeight: .infinity)
                                .padding(12)
                            }
                        }
                        .background {
                            RoundedRectangle(cornerRadius: 26)
                                .fill(Color(.secondarySystemBackground))
                                .overlay {
                                    if tendies.isOn {
                                        RoundedRectangle(cornerRadius: 26)
                                            .fill(Color.clear)
                                            .strokeBorder(lineWidth: 2)
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                        }
                        .contextMenu {
                            Button {
                                let url = AppURL.pbFolders.appendingPathComponent(tendies.folderName)
                                fsHandlers.openInFilesApp(url)
                            } label: {
                                Label("Mở thư mục dữ liệu", systemImage: "folder")
                            }
                            
                            Button(role: .destructive) {
                                withAnimation {
                                    let url = AppURL.pbFolders.appendingPathComponent(tendies.folderName)
                                    try? fm.removeItem(at: url)
                                    tendiesArray.removeAll { $0.id == tendies.id }
                                }
                            } label: {
                                Label("Xóa gói này", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 15)
            .foregroundStyle(Color(.label))
        }
        .navigationTitle("Hình nền Động")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            doSetupStuff()
        }
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button {
                    showImporter = true
                } label: {
                    ButtonLabel("Nhập tệp .tendies", symbol: "arrow.down.doc")
                }
            }
            .buttonStyle(ActionButtonStyle())
            .frame(maxWidth: .infinity)
            .padding(device.userInterfaceIdiom == .pad ? 0 : 15)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showImporter = true
                    } label: {
                        Label("Nhập .tendies", systemImage: "arrow.down.doc")
                    }
                    
                    Button {
                        openApp(withBID: SysBID.poster)
                    } label: {
                        Label("Mở PosterBoard", systemImage: "arrow.up.right.square")
                    }
                    
                    Divider()
                    
                    NavigationLink {
                        List {
                            Section {
                                TextField("Đường dẫn PosterBoard", text: $pbContainerPath, axis: .vertical)
                                Button("Dò tìm Đường dẫn") {
                                    DispatchQueue.global(qos: .userInitiated).async {
                                        let found = fsHandlers.getContainerPath(forMatch: "com.apple.PosterBoard")
                                        DispatchQueue.main.async {
                                            pbContainerPath = found
                                        }
                                    }
                                }
                            } header: {
                                HeaderLabel("PosterBoard Container", symbol: "photo")
                            }
                            
                            Section {
                                Button("Xóa tất cả gói đã nhập") {
                                    for object in tendiesArray {
                                        let url = AppURL.pbFolders.appendingPathComponent(object.folderName)
                                        try? fm.removeItem(at: url)
                                    }
                                    tendiesArray.removeAll()
                                }
                                Button("Đặt lại Collections", role: .destructive) {
                                    if resetWallpapers(for: PBPath.wpKit) {
                                        Haptic.shared.play(.soft)
                                    }
                                }
                                Button("Đặt lại MercuryPoster", role: .destructive) {
                                    if resetWallpapers(for: PBPath.mercury) {
                                        Haptic.shared.play(.soft)
                                    }
                                }
                                Button("Đặt lại Videos", role: .destructive) {
                                    if resetWallpapers(for: PBPath.photos) {
                                        Haptic.shared.play(.soft)
                                    }
                                }
                            } header: {
                                HeaderLabel("Quản lý Dữ liệu", symbol: "loupe")
                            } footer: {
                                Text("Nếu gặp lỗi khi áp dụng hình nền, hãy nhấn Đặt lại một trong ba mục trên.")
                            }
                        }
                        .navigationTitle("Cài đặt PosterBoard")
                    } label: {
                        Label("Cài đặt", systemImage: "gearshape")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button("Áp dụng", role: .adaptiveConfirm) {
                    if !hasShownFirstRunMsg {
                        Alertinator.shared.alert(title: "Lưu ý trước khi bắt đầu...", body: PBMsg.applyInfo, actionLabel: "Tiếp tục", action: {
                            hasShownFirstRunMsg = true
                            proceed()
                        })
                    } else if tendiesArray.filter({ $0.isOn }).flatMap({ $0.descrNames }).count > 5 {
                        Alertinator.shared.alert(title: "Cảnh báo số lượng...", body: PBMsg.limitWarning, actionLabel: "Xác nhận", action: {
                            proceed()
                        })
                    } else {
                        proceed()
                    }
                    
                    @MainActor
                    func proceed() {
                        let res = applyObjects(tendiesArray.filter { $0.isOn })
                        if !res.0 {
                            Alertinator.shared.alert(title: "Không thể áp dụng hình nền!", body: res.1.isEmpty ? PBMsg.corruption : res.1)
                        } else {
                            Haptic.shared.play(.soft)
                            Alertinator.shared.alert(title: "Đã áp dụng thành công!", body: PBMsg.finishApply, showCancel: false, actionLabel: "Mở PosterBoard", action: { openApp(withBID: SysBID.poster) })
                        }
                    }
                }
                .disabled(tendiesArray.filter({ $0.isOn }).isEmpty || pbContainerPath.isEmpty)
            }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.item]) { result in
            let res = handleImport(result)
            if !res {
                Alertinator.shared.alert(title: "Lỗi nhập .tendies!", body: PBMsg.imprtFailed)
            }
        }
    }
    
    private func doSetupStuff() {
        if !fm.fileExists(atPath: AppURL.pb.path) {
            try? fm.createDirIfNeeded(at: AppURL.pb)
            try? fm.createDirIfNeeded(at: AppURL.pbFolders)
        }
        if pbContainerPath.isEmpty {
            if let match = WQEngine.shared.apps.first(where: { $0.bundleID == "com.apple.PosterBoard" }) {
                pbContainerPath = match.containerPath
            } else {
                DispatchQueue.global(qos: .userInitiated).async {
                    let found = fsHandlers.getContainerPath(forMatch: "com.apple.PosterBoard")
                    DispatchQueue.main.async {
                        if !found.isEmpty {
                            self.pbContainerPath = found
                        }
                    }
                }
            }
        }
    }
    
    private func applyObjects(_ objects: [TendiesObject]) -> (Bool, String) {
        let descrTargets = Set(objects.map(\.targetDescr))
        for descrTarget in descrTargets {
            let target = "\(pbContainerPath)/\(descrTarget.path)"
            if !wq_grant(target) {
                let res = wq.grantAccess(path: target)
                if !res.0 {
                    return (false, res.2)
                }
            }
        }
        
        for object in objects {
            let container = "\(pbContainerPath)/\(object.targetDescr.path)"
            _ = wq_grant(container)
            for descr in object.descrNames {
                let descrURL = AppURL.pbFolders.appendingPathComponent(object.folderName).appendingPathComponent(descr)
                let target = object.targetDescr == .mercury
                    ? URL(fileURLWithPath: container).appendingPathComponent(descrURL.lastPathComponent)
                    : URL(fileURLWithPath: container).appendingPathComponent(UUID().uuidString)
                var err: NSString?
                if !wq_copy_contents(descrURL.path, target.path, &err) {
                    do {
                        try fm.copyItem(at: descrURL, to: target)
                    } catch {
                        return (false, (err as String?) ?? error.localizedDescription)
                    }
                }
            }
        }
        return (true, "")
    }
    
    private func resetWallpapers(for item: PBPath) -> Bool {
        let target = URL(fileURLWithPath: "\(pbContainerPath)/\(item.path)")
        _ = wq_grant(target.path)
        var freed: UInt64 = 0
        if wq_purge_contents(target.path, &freed) {
            return true
        }
        do {
            let contents = try fm.contentsOfDirectory(at: target, includingPropertiesForKeys: nil)
            for url in contents {
                try fm.removeItem(at: url)
            }
            return true
        } catch {
            print("(pb) failed to reset \(item.rawValue): \(error.localizedDescription)")
            return false
        }
    }
    
    private func handleImport(_ result: Result<URL, Error>) -> Bool {
        switch result {
        case .success(let fileURL):
            let stopAccess = fileURL.startAccessingSecurityScopedResource()
            defer {
                if stopAccess {
                    fileURL.stopAccessingSecurityScopedResource()
                }
            }
            if let tendies = pbHandler.makeObjectFromTendies(at: fileURL) {
                withAnimation {
                    tendiesArray.append(tendies)
                }
                return true
            }
            return false
        case .failure(let error):
            print("(pb) failed to import file: \(error.localizedDescription)")
            return false
        }
    }
}
