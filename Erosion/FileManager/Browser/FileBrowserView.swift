//
//  FileBrowserView.swift
//  Thái Bình (ErosionWQ)
//
//  Trình duyệt Tệp tích hợp WQFiles v0.9:
//  Chọn nhiều mục (Select), Di chuyển liên ứng dụng (Move Here), Nén/Giải nén ZIP (WQArchive),
//  Nhập nhiều tệp & Nhập cả thư mục (Import Files / Import Folder), Cho phép Xóa & Đếm mục con.
//

import SwiftUI
import QuickLook
import Combine
import UniformTypeIdentifiers

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
    @ObservedObject private var engine = WQEngine.shared
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
    @AppStorage("textViewerSize") var textViewerSize = 12
    @AppStorage("useMonospaced") var useMonospaced = true
    @AppStorage("WQDeletingDisabled") var deletingDisabled = false
    @AppStorage("WQShowItemCounts") var showItemCounts = false

    @State private var showFileImporter = false
    @State private var importingFolders = false
    @State private var showFailure = false
    @State private var failMsg = ""
    @State private var isLoading = false
    @State private var hasLoaded = false

    // WQFiles v0.9: Chế độ chọn nhiều mục (Select, Move, Compress, Delete)
    @State private var isSelecting = false
    @State private var selectedPaths: Set<String> = []
    @State private var showDeleteSelectedAlert = false
    @State private var isBusyArchive = false
    @State private var busyArchiveTitle = ""

    var body: some View {
        List {
            if isLoading || isBusyArchive {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text(isBusyArchive ? busyArchiveTitle : "Đang tải danh sách tệp...")
                                .fontWeight(.medium)
                        }
                        if isContainer && !isBusyArchive {
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
                    if isSelecting {
                        Button {
                            toggleSelection(for: file.fileURL.path)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedPaths.contains(file.fileURL.path) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(selectedPaths.contains(file.fileURL.path) ? .blue : .secondary)

                                Image(systemName: file.type == .folder ? "folder.fill" : "doc")
                                    .frame(width: 20)
                                    .foregroundStyle(file.type == .folder ? Color.accentColor : .primary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(file.name)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    if file.type == .file {
                                        Text(ByteCountFormatter.string(fromByteCount: Int64(file.size), countStyle: .file))
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    } else if file.type == .folder {
                        FolderRow(file: file, shouldGrant: isContainer ? true : false, isContainer: isContainer)
                    } else {
                        FileRow(file: file)
                    }
                }
            }
        }
        .navigationTitle(isSelecting ? (selectedPaths.isEmpty ? "Chọn mục" : "Đã chọn \(selectedPaths.count) mục") : path.lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .customListStyle(listStyle)
        .adaptiveListMargin()
        .searchable(text: $searchText)
        .safeAreaInset(edge: .bottom) {
            if isSelecting {
                HStack(spacing: 12) {
                    Button {
                        let paths = Array(selectedPaths)
                        isSelecting = false
                        selectedPaths.removeAll()
                        engine.startMove(paths)
                    } label: {
                        Label("Di chuyển", systemImage: "folder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(selectedPaths.isEmpty)

                    Button {
                        let paths = Array(selectedPaths)
                        isSelecting = false
                        selectedPaths.removeAll()
                        busyArchiveTitle = "Đang nén \(paths.count) mục thành ZIP..."
                        isBusyArchive = true
                        engine.compressItems(paths, in: path.path) { ok, msg in
                            isBusyArchive = false
                            mgr.refreshFiles.toggle()
                            if !ok {
                                Alertinator.shared.alert(title: "Không thể nén ZIP", body: msg)
                            }
                        }
                    } label: {
                        Label("Nén ZIP", systemImage: "doc.zipper")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedPaths.isEmpty)

                    if !deletingDisabled {
                        Button(role: .destructive) {
                            showDeleteSelectedAlert = true
                        } label: {
                            Label("Xóa", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .disabled(selectedPaths.isEmpty)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            } else if !engine.pendingMovePaths.isEmpty && !isContainer {
                HStack(spacing: 12) {
                    Button("Hủy") {
                        engine.cancelMove()
                    }
                    .buttonStyle(.bordered)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(engine.pendingMovePaths.count == 1
                             ? "Đang di chuyển “\((engine.pendingMovePaths[0] as NSString).lastPathComponent)”"
                             : "Đang di chuyển \(engine.pendingMovePaths.count) mục")
                            .font(.caption.bold())
                            .lineLimit(1)
                        Text("Mở thư mục đích bất kỳ rồi nhấn Di chuyển vào đây")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()

                    Button("Di chuyển vào đây") {
                        engine.movePendingItems(to: path.path) { ok, msg in
                            mgr.refreshFiles.toggle()
                            if !ok {
                                Alertinator.shared.alert(title: "Không thể di chuyển", body: msg)
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!engine.canMove(to: path.path))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
        }
        .toolbar {
            if isSelecting {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if selectedPaths.count < dirFiles.count {
                            selectedPaths = Set(dirFiles.map { $0.fileURL.path })
                        } else {
                            selectedPaths.removeAll()
                        }
                    } label: {
                        Image(systemName: "checkmark.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Xong") {
                        isSelecting = false
                        selectedPaths.removeAll()
                    }
                    .fontWeight(.semibold)
                }
            } else {
                if !isContainer && !dirFiles.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Chọn") {
                            selectedPaths.removeAll()
                            isSelecting = true
                        }
                    }
                }

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
                                importingFolders = false
                                showFileImporter = true
                            } label: {
                                Label("Nhập tệp (Chọn nhiều tệp)", systemImage: "square.and.arrow.down")
                            }

                            Button {
                                importingFolders = true
                                showFileImporter = true
                            } label: {
                                Label("Nhập cả thư mục", systemImage: "folder.badge.plus")
                            }

                            Divider()
                        }

                        Button {
                            UIPasteboard.general.string = path.path
                            Haptic.shared.play(.light)
                        } label: {
                            Label("Sao chép Đường dẫn hiện tại", systemImage: "doc.on.doc")
                        }

                        NavigationLink {
                            FileBrowserView(path: URL.documentsDirectory)
                        } label: {
                            Label("Mở thư mục Documents", systemImage: "folder")
                        }

                        NavigationLink {
                            List {
                                Section {
                                    Toggle(isOn: Binding(
                                        get: { !deletingDisabled },
                                        set: { deletingDisabled = !$0 }
                                    )) {
                                        Label("Cho phép Xóa dữ liệu", systemImage: "trash")
                                    }

                                    Toggle(isOn: $showItemCounts) {
                                        Label("Hiển thị số lượng mục trong thư mục", systemImage: "number")
                                    }
                                } header: {
                                    HeaderLabel("An toàn & Hiển thị (WQFiles v0.9)", symbol: "shield.lefthalf.filled")
                                } footer: {
                                    Text("Khi tắt Cho phép Xóa dữ liệu, mọi thao tác Xóa tệp, Vuốt để xóa, Xóa dữ liệu ứng dụng và Dọn rác đều bị khóa.")
                                }

                                Section {
                                    HStack {
                                        Text("Số Inode tối đa")
                                        TextField("7500000", value: $maxInode, format: .number)
                                            .multilineTextAlignment(.trailing)
                                    }
                                } header: {
                                    HeaderLabel("Quét Container", symbol: "externaldrive")
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
                                    HeaderLabel("Trình xem văn bản & Cú pháp", symbol: "doc.plaintext")
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
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: importingFolders ? [.folder] : [.item],
            allowsMultipleSelection: true
        ) { result in
            handleMultiImport(result, isFolder: importingFolders)
        }
        .alert("Xóa \(selectedPaths.count) mục đã chọn?", isPresented: $showDeleteSelectedAlert) {
            Button("Xóa", role: .destructive) {
                deleteSelectedItems()
            }
            Button("Hủy", role: .cancel) {}
        } message: {
            Text("Các tệp sẽ được tự động sao lưu trước khi xóa. Thư mục chỉ được xóa khi trống hoặc được dọn sạch.")
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
                        failMsg = "Bạn không có quyền truy cập thư mục này."
                    }
                } else {
                    loadFilesFromPath()
                }
            }
        }
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

    private func toggleSelection(for itemPath: String) {
        Haptic.shared.play(.light)
        if selectedPaths.contains(itemPath) {
            selectedPaths.remove(itemPath)
        } else {
            selectedPaths.insert(itemPath)
        }
    }

    private func deleteSelectedItems() {
        let targets = Array(selectedPaths)
        isSelecting = false
        selectedPaths.removeAll()
        DispatchQueue.global(qos: .userInitiated).async {
            var failed = 0
            var firstErr: String? = nil
            for p in targets {
                var err: NSString?
                if !wq_delete(p, &err) {
                    failed += 1
                    if firstErr == nil {
                        firstErr = "\((p as NSString).lastPathComponent): \((err as String?) ?? "Không thể xóa")"
                    }
                }
            }
            DispatchQueue.main.async {
                self.mgr.refreshFiles.toggle()
                if failed > 0 {
                    Alertinator.shared.alert(
                        title: "Không thể xóa \(failed)/\(targets.count) mục",
                        body: firstErr ?? ""
                    )
                }
            }
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
                } else if wq_app_group() != nil {
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

    // MARK: WQFiles v0.9 Multi-File & Whole-Folder Import (#23)
    private func handleMultiImport(_ result: Result<[URL], Error>, isFolder: Bool) {
        switch result {
        case .success(let urls):
            guard !urls.isEmpty else { return }
            let targetDir = path.path
            busyArchiveTitle = isFolder ? "Đang nhập thư mục..." : "Đang nhập \(urls.count) tệp..."
            isBusyArchive = true

            DispatchQueue.global(qos: .userInitiated).async {
                var importedCount = 0
                var firstError: String? = nil

                for url in urls {
                    let scoped = url.startAccessingSecurityScopedResource()
                    defer {
                        if scoped { url.stopAccessingSecurityScopedResource() }
                    }
                    let origName = url.lastPathComponent
                    let ext = (origName as NSString).pathExtension
                    let stem = (origName as NSString).deletingPathExtension
                    let safeName = self.engine.unusedName(
                        in: targetDir,
                        base: stem.isEmpty ? origName : stem,
                        ext: isFolder ? nil : (ext.isEmpty ? nil : ext)
                    )
                    let destPath = (targetDir as NSString).appendingPathComponent(safeName)

                    if isFolder {
                        var coordErr: NSError?
                        var copyOk = false
                        var copyErr: NSString?
                        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordErr) { readableURL in
                            if wq_create_dir(destPath, &copyErr) && wq_copy_contents(readableURL.path, destPath, &copyErr) {
                                copyOk = true
                            }
                        }
                        if copyOk {
                            importedCount += 1
                        } else if firstError == nil {
                            firstError = "\(origName): \((copyErr as String?) ?? coordErr?.localizedDescription ?? "Không thể sao chép thư mục")"
                        }
                    } else {
                        var err: NSString?
                        if wq_create_file_from(destPath, url.path, &err) {
                            importedCount += 1
                        } else if let data = try? Data(contentsOf: url), wq_create_file(destPath, data, &err) {
                            importedCount += 1
                        } else if firstError == nil {
                            firstError = "\(origName): \((err as String?) ?? "Không thể nhập tệp")"
                        }
                    }
                }

                DispatchQueue.main.async {
                    self.isBusyArchive = false
                    self.mgr.refreshFiles.toggle()
                    if importedCount < urls.count {
                        Alertinator.shared.alert(
                            title: "Đã nhập \(importedCount)/\(urls.count) mục",
                            body: firstError ?? "Một số mục không thể nhập."
                        )
                    }
                }
            }
        case .failure(let error):
            Alertinator.shared.alert(title: "Nhập thất bại!", body: error.localizedDescription)
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
