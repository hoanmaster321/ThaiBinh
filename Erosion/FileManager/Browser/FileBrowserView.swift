//
//  FileBrowserView.swift
//  AccessiblePlus
//
//  Created by lunginspector on 5/12/26.
//

import SwiftUI

import QuickLook
import Combine

enum FileSortMode: String, CaseIterable, Codable, Hashable {
    case system, name, date, created, type, size
    
    var id: String { label }
    
    var label: String {
        switch self {
        case .system: return "Mặc định"
        case .name: return "Tên"
        case .date: return "Ngày sửa"
        case .created: return "Ngày tạo"
        case .type: return "Loại"
        case .size: return "Kích thước"
        }
    }
}

struct FileBrowserView: View {
    @EnvironmentObject var mgr: ErosionManager
    var path: URL = URL(fileURLWithPath: "/")
    var isContainer = false
    var shouldGrant = false
    
    @State private var dirFiles: [FileItem] = []
    @State private var unfilteredFiles: [FileItem] = []
    @State private var searchText = ""
    @AppStorage("maxInode") var maxInode = 7500000
    @AppStorage("chosenSort") var chosenSort: FileSortMode = .system
    @AppStorage("filesAscend") var filesAscend = true
    @AppStorage("foldersFirst") var foldersFirst = true
    @AppStorage("listStyle") var listStyle = 1
    @AppStorage("hideDates") var hideDates = false
    @AppStorage("textViewerSize") var textViewerSize = 10
    @AppStorage("useMonospaced") var useMonospaced = true
    
    @State private var showFileImporter = false
    @State private var showFailure = false
    @State private var failMsg = ""
    @State private var isLoading = false
    @State private var hasLoaded = false
    
    var body: some View {
        List {
            if isLoading {
                Section {
                    VStack(alignment: .leading) {
                        HStack {
                            ProgressView()
                                .offset(y: 0.5)
                            Text("Đang tải danh sách tệp...")
                                .fontWeight(.medium)
                        }
                        if isContainer {
                            Text("Đang quét nhanh thư mục container...")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else if showFailure {
                CompactAlert(title: "Không thể tải tệp từ thư mục!", symbol: "folder.badge.questionmark", text: failMsg)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            } else {
                ForEach(dirFiles) { file in
                    if file.type == .folder {
                        FolderRow(file: file, shouldGrant: isContainer ? true : false, isContainer: isContainer)
                    } else {
                        FileRow(file: file)
                    }
                }
            }
        }
        .navigationTitle(path.lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .customListStyle(listStyle)
        .adaptiveListMargin()
        .searchable(text: $searchText)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(FileSortMode.allCases, id: \.self) { option in
                        Button {
                            chosenSort = option
                        } label: {
                            if chosenSort == option {
                                Label(option.label, systemImage: "checkmark")
                                    .tag(option)
                            } else {
                                Text(option.label)
                                    .tag(option)
                            }
                        }
                    }
                    Divider()
                    Button {
                        foldersFirst.toggle()
                    } label: {
                        if foldersFirst {
                            Label("Thư mục lên đầu", systemImage: "checkmark")
                        } else {
                            Text("Thư mục lên đầu")
                        }
                    }
                    Button {
                        filesAscend.toggle()
                    } label: {
                        if filesAscend {
                            Label("Tăng dần", systemImage: "chevron.up")
                        } else {
                            Label("Giảm dần", systemImage: "chevron.down")
                        }
                    }
                    .disabled(chosenSort == .system)
                } label: {
                    Label("Sắp xếp", systemImage: "line.3.horizontal.decrease")
                }
                .labelStyle(.iconOnly)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if !isContainer {
                        Menu {
                            Button {
                                Alertinator.shared.prompt(title: "Nhập tên cho tệp mới (kèm phần mở rộng):", placeholder: "new.txt", completion: { name in
                                    let name = name ?? ""
                                    if !name.isEmpty {
                                        let fileURL = path.appendingPathComponent(name)
                                        var err: NSString?
                                        if wq_create_file(fileURL.path, Data(), &err) {
                                            mgr.refreshFiles.toggle()
                                        } else {
                                            do {
                                                try Data().write(to: fileURL)
                                                mgr.refreshFiles.toggle()
                                            } catch {
                                                print("(fm) failed to create file: \(error.localizedDescription)")
                                                Alertinator.shared.alert(title: "Không thể tạo tệp!", body: (err as String?) ?? error.localizedDescription)
                                            }
                                        }
                                    }
                                })
                            } label: {
                                Label("Tệp tin", systemImage: "doc")
                            }
                            
                            Button {
                                Alertinator.shared.prompt(title: "Nhập tên cho tệp Property List mới:", placeholder: "Tên Plist", completion: { name in
                                    let name = name ?? ""
                                    if !name.isEmpty {
                                        do {
                                            let fileURL = path.appendingPathComponent(name + ".plist")
                                            let data = try PropertyListSerialization.data(fromPropertyList: NSMutableDictionary(), format: .xml, options: 0)
                                            var err: NSString?
                                            if wq_create_file(fileURL.path, data, &err) {
                                                mgr.refreshFiles.toggle()
                                            } else {
                                                try data.write(to: fileURL)
                                                mgr.refreshFiles.toggle()
                                            }
                                        } catch {
                                            print("(fm) failed to create plist: \(error.localizedDescription)")
                                            Alertinator.shared.alert(title: "Không thể tạo tệp Plist!", body: error.localizedDescription)
                                        }
                                    }
                                })
                            } label: {
                                Label("Tệp Plist", systemImage: "tablecells")
                            }
                            
                            Button {
                                Alertinator.shared.prompt(title: "Nhập tên cho thư mục mới:", placeholder: "Tên thư mục", completion: { name in
                                    let name = name ?? ""
                                    if !name.isEmpty {
                                        let folderURL = path.appendingPathComponent(name)
                                        var err: NSString?
                                        if wq_create_dir(folderURL.path, &err) {
                                            mgr.refreshFiles.toggle()
                                        } else {
                                            do {
                                                try fm.createDirectoryIfNeeded(at: folderURL)
                                                mgr.refreshFiles.toggle()
                                            } catch {
                                                print("(fm) failed to create folder: \(error.localizedDescription)")
                                                Alertinator.shared.alert(title: "Không thể tạo thư mục!", body: (err as String?) ?? error.localizedDescription)
                                            }
                                        }
                                    }
                                })
                            } label: {
                                Label("Thư mục", systemImage: "folder")
                            }
                            
                            Button {
                                Alertinator.shared.prompt(title: "Nhập đường dẫn đích cho liên kết tượng trưng (Symlink):", placeholder: "/path/to/dir", completion: { symPath in
                                    let symPath = symPath ?? ""
                                    if !symPath.isEmpty {
                                        do {
                                            try fm.createSymbolicLink(atPath: path.appendingPathComponent(URL(fileURLWithPath: symPath).lastPathComponent).path, withDestinationPath: symPath)
                                            mgr.refreshFiles.toggle()
                                        } catch {
                                            print("(fm) failed to create symlink: \(error.localizedDescription)")
                                            Alertinator.shared.alert(title: "Không thể tạo Symlink!", body: "\(error.localizedDescription)")
                                        }
                                    }
                                })
                            } label: {
                                Label("Liên kết (Symlink)", systemImage: "arrow.up.right.circle")
                            }
                        } label: {
                            Label("Tạo mới...", systemImage: "plus")
                        }
                        
                        Button {
                            showFileImporter.toggle()
                        } label: {
                            Label("Nhập tệp từ bên ngoài", systemImage: "arrow.down.doc")
                        }
                        Divider()
                    }
                    NavigationLink {
                        FileBrowserView(path: URL.documentsDirectory)
                    } label: {
                        Label("Mở thư mục Documents", systemImage: "folder")
                    }
                    NavigationLink {
                        List {
                            Section {
                                HStack {
                                    Text("Số Inode tối đa")
                                    TextField("7500000", value: $maxInode, format: .number)
                                        .multilineTextAlignment(.trailing)
                                }
                            } header: {
                                HeaderLabel("Quét Container", symbol: "externaldrive")
                            } footer: {
                                Text("Điều chỉnh tốc độ quét container. Giá trị thấp hơn = quét nhanh hơn nhưng có thể bỏ sót tệp mới.")
                            }
                            
                            Section {
                                Picker("Kiểu danh sách", selection: $listStyle) {
                                    Text("Mặc định").tag(1)
                                    Text("Đơn giản").tag(2)
                                    Text("Nhóm").tag(3)
                                }
                                Toggle("Ẩn ngày sửa đổi", isOn: $hideDates)
                            } header: {
                                HeaderLabel("Tùy chọn hiển thị", symbol: "eye")
                            }
                            
                            Section {
                                Stepper(value: $textViewerSize) {
                                    HStack {
                                        Text("Cỡ chữ")
                                        Spacer()
                                        Text(textViewerSize.description)
                                    }
                                }
                                Toggle("Phông chữ Monospaced", isOn: $useMonospaced)
                            } header: {
                                HeaderLabel("Trình xem văn bản", symbol: "doc.plaintext")
                            }
                        }
                        .navigationTitle("Cài đặt Trình duyệt tệp")
                    } label: {
                        Label("Cài đặt", systemImage: "gearshape")
                    }
                } label: {
                    Label("Tác vụ", systemImage: "ellipsis")
                }
                .labelStyle(.iconOnly)
            }
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.item]) { result in
            handleImport(result)
        }
        .refreshable {
            wq_enumerate_invalidate()
            wq_display_names_reset_miss()
            mgr.refreshFiles.toggle()
        }
        .onAppear {
            if !mgr.storedFiles.isEmpty && mgr.storedURL == path {
                dirFiles = sortFiles(files: mgr.storedFiles)
                unfilteredFiles = sortFiles(files: mgr.storedFiles)
            } else if isContainer && hasLoaded {
                // do nothing as it's already being stored in the variable
            } else {
                if shouldGrant {
                    let res = wq.grantAccess(path: path.path)
                    if res.0 {
                        loadFilesFromPath()
                    } else {
                        showFailure = true
                        failMsg = "You don't have permission to view this directory."
                    }
                } else {
                    loadFilesFromPath()
                }
            }
        }
        // I want to talk to the Apple Engineer who thought it would be cool to remove the one-parameter action closure from onChange.
        .onChange(of: searchText) { (newSearch, _) in
            dirFiles = unfilteredFiles.filter { $0.name.localizedCaseInsensitiveContains(newSearch) }
        }
        .modifier(KeyboardDismissObserver() {
            dirFiles = unfilteredFiles
        })
        .onChange(of: chosenSort) {
            loadFilesFromPath()
        }
        .onChange(of: filesAscend) {
            loadFilesFromPath()
        }
        .onChange(of: foldersFirst) {
            loadFilesFromPath()
        }
        .onChange(of: mgr.refreshFiles) {
            loadFilesFromPath()
        }
    }
    
    // MARK: handle files
    private func loadFilesFromPath() {
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            var unsortedFiles: [FileItem] = []
            
            _ = wq_grant(path.path)
            
            var listErr: NSString?
            let listedNames = wq_list(path.path, &listErr)
            
            if let names = listedNames, !names.isEmpty {
                for name in names {
                    let fileURL = path.appendingPathComponent(name)
                    unsortedFiles.append(getFileItem(at: fileURL, isContainer: isContainer))
                }
            } else if isContainer || path.path.contains("/Containers/") || path.path.contains("/SystemGroup") {
                var discoveredSet = Set<String>()
                var orderedPaths: [String] = []
                let fastPaths = wq_enumerate(path.path, 0, nil) ?? wq_enumerate(path.path, 400000, nil) ?? []
                if !fastPaths.isEmpty {
                    for p in fastPaths where !discoveredSet.contains(p) {
                        discoveredSet.insert(p)
                        orderedPaths.append(p)
                    }
                } else {
                    let paths = fsHandlers.getDirPaths(path.path, maxInode: 400000)
                    for p in paths where !p.isEmpty && !discoveredSet.contains(p) {
                        discoveredSet.insert(p)
                        orderedPaths.append(p)
                    }
                }
                if path.path.hasSuffix("/SystemGroup") {
                    for kp in wq_known_system_groups() {
                        if !discoveredSet.contains(kp) {
                            discoveredSet.insert(kp)
                            orderedPaths.append(kp)
                        }
                    }
                }
                for p in orderedPaths {
                    unsortedFiles.append(getFileItem(at: URL(fileURLWithPath: p), isContainer: true))
                }
            } else if let pathFiles = try? fm.contentsOfDirectory(at: path, includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey, .contentModificationDateKey]) {
                unsortedFiles = pathFiles.map { fileURL in
                    getFileItem(at: fileURL, isContainer: isContainer)
                }
            }
            
            DispatchQueue.main.async {
                self.dirFiles = self.sortFiles(files: unsortedFiles)
                self.unfilteredFiles = self.sortFiles(files: unsortedFiles)
                if self.isContainer {
                    self.mgr.storedFiles = unsortedFiles
                    self.mgr.storedURL = self.path
                }
                self.hasLoaded = true
                self.isLoading = false
            }
        }
    }
    
    private func sortFiles(files: [FileItem]) -> [FileItem] {
        var sortedFiles: [FileItem]
        
        switch chosenSort {
        case .system:
            sortedFiles = files
        case .name:
            sortedFiles = files.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .date:
            sortedFiles = files.sorted { $0.modifiedDate > $1.modifiedDate }
        case .created:
            sortedFiles = files.sorted { $0.creationDate > $1.creationDate }
        case .type:
            sortedFiles = files.sorted { $0.type.sortOrder < $1.type.sortOrder }
        case .size:
            sortedFiles = files.sorted { $0.size < $1.size }
        }

        if chosenSort != .system && !filesAscend {
            sortedFiles = sortedFiles.reversed()
        }
        if foldersFirst {
            sortedFiles = sortedFiles.sorted { a, b in
                (a.type == .folder) && (b.type != .folder)
            }
        }
        return sortedFiles
    }
    
    // MARK: handle import
    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let fileURL):
            do {
                let stopAccess = fileURL.startAccessingSecurityScopedResource()
                defer {
                    if stopAccess {
                        fileURL.stopAccessingSecurityScopedResource()
                    }
                }
                let data = try Data(contentsOf: fileURL)
                let newURL = path.appendingPathComponent(fileURL.lastPathComponent)
                var err: NSString?
                if wq_create_file(newURL.path, data, &err) {
                    mgr.refreshFiles.toggle()
                } else {
                    try? fm.removeItem(at: newURL)
                    try data.write(to: newURL)
                    mgr.refreshFiles.toggle()
                }
            } catch {
                print("(fm) failed to import file: \(error.localizedDescription)")
                Alertinator.shared.alert(title: "Failed to import file!", body: "\(error.localizedDescription)")
            }
        case .failure(let error):
            print("(fm) failed to import file: \(error.localizedDescription)")
            Alertinator.shared.alert(title: "Failed to import file!", body: "\(error.localizedDescription)")
        }
    }
}

// MARK: user interface
extension View {
    @ViewBuilder
    func customListStyle(_ selection: Int) -> some View {
        switch selection {
        case 2: self.listStyle(.inset)
        case 3: self.listStyle(.grouped)
        default: self.listStyle(.insetGrouped)
        }
    }
    
    @ViewBuilder
    func adaptiveListMargin() -> some View {
        if #available(iOS 26.0, *) {
            self.contentMargins(.top, 1)
        }
    }
}

struct KeyboardDismissObserver: ViewModifier {
    var action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onReceive(Publishers.keyboardDismissed) { _ in
                action()
            }
    }
}

extension Publishers {
    static var keyboardDismissed: AnyPublisher<Void, Never> {
        NotificationCenter.default
            .publisher(for: UIResponder.keyboardDidHideNotification)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
