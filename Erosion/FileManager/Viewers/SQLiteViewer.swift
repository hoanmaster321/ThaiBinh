//
//  SQLiteViewer.swift
//  ThaiBinh (ErosionWQ)
//
//  Trình xem Cơ sở dữ liệu SQLite (Chỉ đọc, Truy vấn SQL & Xuất CSV) - WQFiles v0.8
//  Bản quyền © 2026 ThaiBinh (hoanmaster321)
//

import SwiftUI
import SQLite3

struct SQLiteTableItem: Identifiable, Hashable {
    var id: String { "\(type):\(name)" }
    let name: String
    let type: String // "table" or "view"
    let rows: Int64
}

struct SQLiteResultPage {
    var title: String
    var sql: String
    var columns: [String]
    var rows: [[String]]
    var limit: Int
    var hasMore: Bool
}

private let SQLITE_TRANSIENT_DESTRUCTOR = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

struct SQLiteViewer: View {
    @Environment(\.dismiss) private var dismiss
    let fileURL: URL
    
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var tempDir: String? = nil
    @State private var localDBPath: String? = nil
    @State private var tables: [SQLiteTableItem] = []
    @State private var searchText = ""
    
    @State private var showSQLPrompt = false
    @State private var customSQL = "SELECT name, type FROM sqlite_master;"
    @State private var queryResultPage: SQLiteResultPage? = nil
    @State private var showQueryResultSheet = false
    @State private var sqlErrorText: String? = nil
    @State private var showSQLError = false
    
    var filteredTables: [SQLiteTableItem] {
        if searchText.isEmpty { return tables }
        return tables.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Đang mở bản sao SQLite an toàn (Chỉ đọc)...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: " cylinder.split.1x2")
                            .font(.largeTitle)
                            .foregroundStyle(.red)
                        Text("Không thể mở cơ sở dữ liệu SQLite")
                            .font(.headline)
                        Text(err)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section {
                            HStack {
                                Image(systemName: "cylinder.split.1x2.fill")
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(fileURL.lastPathComponent)
                                        .font(.headline)
                                    Text("\(tables.count) bảng / khung nhìn · Chế độ Chỉ đọc (An toàn)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Button {
                                showSQLPrompt = true
                            } label: {
                                Label("Chạy truy vấn SQL (SELECT / PRAGMA)…", systemImage: "terminal")
                            }
                        }
                        
                        Section {
                            if filteredTables.isEmpty {
                                Text("Không tìm thấy bảng hoặc khung nhìn nào.")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(filteredTables) { item in
                                    if let dbPath = localDBPath {
                                        NavigationLink {
                                            SQLiteTableDetailView(
                                                dbPath: dbPath,
                                                tableName: item.name,
                                                tableType: item.type,
                                                totalRows: item.rows
                                            )
                                        } label: {
                                            HStack {
                                                Image(systemName: item.type == "view" ? "eye.square" : "tablecells")
                                                    .foregroundStyle(item.type == "view" ? .purple : .blue)
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(item.name)
                                                        .font(.body)
                                                        .fontWeight(.medium)
                                                    Text(item.type == "view" ? "View (Khung nhìn)" : "Table (Bảng)")
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                }
                                                Spacer()
                                                if item.rows >= 0 {
                                                    Text("\(item.rows) dòng")
                                                        .font(.subheadline)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        } header: {
                            Text("Danh sách Bảng & View (\(filteredTables.count))")
                        }
                    }
                    .searchable(text: $searchText, prompt: "Tìm tên bảng hoặc view")
                }
            }
            .navigationTitle("Trình xem SQLite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") {
                        cleanupTemp()
                        dismiss()
                    }
                }
                if localDBPath != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("SQL") {
                            showSQLPrompt = true
                        }
                    }
                }
            }
            .onAppear {
                if localDBPath == nil {
                    prepareAndLoadDatabase()
                }
            }
            .alert("Truy vấn SQL (Chỉ đọc)", isPresented: $showSQLPrompt) {
                TextField("SELECT * FROM ...", text: $customSQL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button("Chạy") {
                    runCustomQuery(customSQL)
                }
                Button("Hủy", role: .cancel) {}
            } message: {
                Text("Chỉ cho phép các câu lệnh đọc dữ liệu (SELECT, PRAGMA, EXPLAIN) trên bản sao tạm thời.")
            }
            .alert("Lỗi SQL", isPresented: $showSQLError) {
                Button("Đóng", role: .cancel) {}
            } message: {
                Text(sqlErrorText ?? "Truy vấn không hợp lệ")
            }
            .sheet(isPresented: $showQueryResultSheet) {
                if let page = queryResultPage, let dbPath = localDBPath {
                    NavigationStack {
                        SQLiteQueryRowsView(dbPath: dbPath, initialPage: page, isModal: true)
                    }
                }
            }
        }
    }
    
    private func prepareAndLoadDatabase() {
        isLoading = true
        let sourcePath = fileURL.path
        DispatchQueue.global(qos: .userInitiated).async {
            let dir = (NSTemporaryDirectory() as NSString).appendingPathComponent("WQSQLite-\(UUID().uuidString)")
            do {
                try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
                return
            }
            
            let local = (dir as NSString).appendingPathComponent("db.sqlite")
            var copyErr: NSString?
            if !wq_copy_to_local(sourcePath, local, &copyErr) {
                if let data = wq_read(sourcePath, 0, &copyErr) {
                    try? data.write(to: URL(fileURLWithPath: local))
                } else {
                    try? FileManager.default.removeItem(atPath: dir)
                    DispatchQueue.main.async {
                        self.errorMessage = (copyErr as String?) ?? "Không thể sao chép cơ sở dữ liệu"
                        self.isLoading = false
                    }
                    return
                }
            }
            
            // Copy -wal if present so recent uncommitted WAL pages are visible
            let walSource = sourcePath + "-wal"
            var st = stat()
            if wq_stat(walSource, &st) && (st.st_mode & S_IFMT) == S_IFREG && st.st_size > 0 && st.st_size < 64 * 1024 * 1024 {
                _ = wq_copy_to_local(walSource, local + "-wal", nil)
            }
            
            var db: OpaquePointer? = nil
            let rc = sqlite3_open_v2(local, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX, nil)
            guard rc == SQLITE_OK, let db = db else {
                let msg = db != nil ? String(cString: sqlite3_errmsg(db)) : "Không thể mở SQLite"
                if db != nil { sqlite3_close(db) }
                try? FileManager.default.removeItem(atPath: dir)
                DispatchQueue.main.async {
                    self.errorMessage = msg
                    self.isLoading = false
                }
                return
            }
            sqlite3_busy_timeout(db, 1500)
            sqlite3_exec(db, "PRAGMA query_only = ON;", nil, nil, nil)
            
            var loadedTables: [SQLiteTableItem] = []
            let sql = "SELECT name, type FROM sqlite_master WHERE type IN ('table', 'view') ORDER BY CASE WHEN name LIKE 'sqlite_%' THEN 1 ELSE 0 END, name COLLATE NOCASE"
            var stmt: OpaquePointer? = nil
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt = stmt {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    guard let cName = sqlite3_column_text(stmt, 0) else { continue }
                    let name = String(cString: cName)
                    let type = sqlite3_column_text(stmt, 1).map { String(cString: $0) } ?? "table"
                    loadedTables.append(SQLiteTableItem(name: name, type: type, rows: -1))
                }
                sqlite3_finalize(stmt)
            } else {
                let msg = String(cString: sqlite3_errmsg(db))
                sqlite3_close(db)
                try? FileManager.default.removeItem(atPath: dir)
                DispatchQueue.main.async {
                    self.errorMessage = msg
                    self.isLoading = false
                }
                return
            }
            
            var finalTables: [SQLiteTableItem] = []
            for item in loadedTables {
                var count: Int64 = -1
                if item.type == "table" {
                    let quoted = "\"" + item.name.replacingOccurrences(of: "\"", with: "\"\"") + "\""
                    let countSQL = "SELECT COUNT(*) FROM \(quoted)"
                    var cStmt: OpaquePointer? = nil
                    if sqlite3_prepare_v2(db, countSQL, -1, &cStmt, nil) == SQLITE_OK, let cStmt = cStmt {
                        if sqlite3_step(cStmt) == SQLITE_ROW {
                            count = sqlite3_column_int64(cStmt, 0)
                        }
                        sqlite3_finalize(cStmt)
                    }
                }
                finalTables.append(SQLiteTableItem(name: item.name, type: item.type, rows: count))
            }
            sqlite3_close(db)
            
            DispatchQueue.main.async {
                self.tempDir = dir
                self.localDBPath = local
                self.tables = finalTables
                self.isLoading = false
            }
        }
    }
    
    private func runCustomQuery(_ sqlInput: String) {
        let trimmed = sqlInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let dbPath = localDBPath else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            switch SQLiteQueryHelper.executeReadOnly(dbPath: dbPath, title: "Kết quả SQL", sql: trimmed, limit: 200) {
            case .success(let page):
                DispatchQueue.main.async {
                    self.queryResultPage = page
                    self.showQueryResultSheet = true
                }
            case .failure(let err):
                DispatchQueue.main.async {
                    self.sqlErrorText = err.localizedDescription
                    self.showSQLError = true
                }
            }
        }
    }
    
    private func cleanupTemp() {
        if let dir = tempDir {
            try? FileManager.default.removeItem(atPath: dir)
            tempDir = nil
        }
    }
}

enum SQLiteQueryHelper {
    static func formatCell(_ stmt: OpaquePointer, index: Int32) -> String {
        let colType = sqlite3_column_type(stmt, index)
        switch colType {
        case SQLITE_NULL:
            return "NULL"
        case SQLITE_BLOB:
            let bytes = sqlite3_column_bytes(stmt, index)
            guard let raw = sqlite3_column_blob(stmt, index), bytes > 0 else {
                return "<0 bytes>"
            }
            let ptr = raw.assumingMemoryBound(to: UInt8.self)
            let show = Int(min(bytes, 16))
            var hex = "<\(bytes) bytes:"
            for i in 0..<show {
                hex += String(format: " %02x", ptr[i])
            }
            if bytes > 16 { hex += " …" }
            hex += ">"
            return hex
        default:
            if let cText = sqlite3_column_text(stmt, index) {
                let s = String(cString: cText)
                if s.count > 2000 {
                    return String(s.prefix(2000)) + "…"
                }
                return s
            }
            return ""
        }
    }
    
    static func executeReadOnly(dbPath: String, title: String, sql: String, limit: Int) -> Result<SQLiteResultPage, NSError> {
        var db: OpaquePointer? = nil
        guard sqlite3_open_v2(dbPath, &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX, nil) == SQLITE_OK, let db = db else {
            let msg = db != nil ? String(cString: sqlite3_errmsg(db)) : "Không thể mở SQLite"
            if db != nil { sqlite3_close(db) }
            return .failure(NSError(domain: "WQSQLite", code: 1, userInfo: [NSLocalizedDescriptionKey: msg]))
        }
        defer { sqlite3_close(db) }
        sqlite3_busy_timeout(db, 1500)
        sqlite3_exec(db, "PRAGMA query_only = ON;", nil, nil, nil)
        
        var stmt: OpaquePointer? = nil
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt = stmt else {
            let msg = String(cString: sqlite3_errmsg(db))
            return .failure(NSError(domain: "WQSQLite", code: 2, userInfo: [NSLocalizedDescriptionKey: msg]))
        }
        defer { sqlite3_finalize(stmt) }
        
        if sqlite3_stmt_readonly(stmt) == 0 {
            return .failure(NSError(domain: "WQSQLite", code: 3, userInfo: [NSLocalizedDescriptionKey: "Chỉ cho phép các truy vấn đọc dữ liệu (SELECT, PRAGMA, EXPLAIN)."]))
        }
        
        let colCount = sqlite3_column_count(stmt)
        var cols: [String] = []
        for c in 0..<colCount {
            if let cname = sqlite3_column_name(stmt, c) {
                cols.append(String(cString: cname))
            } else {
                cols.append("col_\(c)")
            }
        }
        
        var rows: [[String]] = []
        var hasMore = false
        while sqlite3_step(stmt) == SQLITE_ROW {
            if rows.count >= limit {
                hasMore = true
                break
            }
            var row: [String] = []
            for c in 0..<colCount {
                row.append(formatCell(stmt, index: c))
            }
            rows.append(row)
        }
        
        return .success(SQLiteResultPage(
            title: title,
            sql: sql,
            columns: cols,
            rows: rows,
            limit: limit,
            hasMore: hasMore
        ))
    }
    
    static func exportCSV(page: SQLiteResultPage) -> URL? {
        func csvField(_ s: String) -> String {
            if s.contains(",") || s.contains("\"") || s.contains("\n") || s.contains("\r") {
                return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
            }
            return s
        }
        var lines: [String] = []
        lines.append(page.columns.map(csvField).joined(separator: ","))
        for row in page.rows {
            lines.append(row.map(csvField).joined(separator: ","))
        }
        let csvString = lines.joined(separator: "\r\n") + "\r\n"
        let safeTitle = page.title.replacingOccurrences(of: "/", with: "-")
        let outURL = URL.temporaryDirectory.appendingPathComponent("\(safeTitle).csv")
        try? FileManager.default.removeItem(at: outURL)
        do {
            try csvString.data(using: .utf8)?.write(to: outURL)
            return outURL
        } catch {
            return nil
        }
    }
}

struct SQLiteTableDetailView: View {
    let dbPath: String
    let tableName: String
    let tableType: String
    let totalRows: Int64
    
    @State private var page: SQLiteResultPage? = nil
    @State private var errorText: String? = nil
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Đang tải dữ liệu bảng \(tableName)...")
            } else if let err = errorText {
                Text(err)
                    .foregroundStyle(.red)
                    .padding()
            } else if let page = page {
                SQLiteQueryRowsView(dbPath: dbPath, initialPage: page, isModal: false)
            }
        }
        .navigationTitle(tableName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if page == nil {
                loadTable(limit: 200)
            }
        }
    }
    
    private func loadTable(limit: Int) {
        isLoading = true
        let quoted = "\"" + tableName.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        let sql = "SELECT * FROM \(quoted)"
        DispatchQueue.global(qos: .userInitiated).async {
            switch SQLiteQueryHelper.executeReadOnly(dbPath: dbPath, title: tableName, sql: sql, limit: limit) {
            case .success(let result):
                DispatchQueue.main.async {
                    self.page = result
                    self.isLoading = false
                }
            case .failure(let err):
                DispatchQueue.main.async {
                    self.errorText = err.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

struct SQLiteQueryRowsView: View {
    @Environment(\.dismiss) private var dismiss
    let dbPath: String
    @State var initialPage: SQLiteResultPage
    let isModal: Bool
    
    @State private var searchText = ""
    @State private var selectedRowIndex: Int? = nil
    @State private var showRowDetail = false
    
    var filteredRows: [(Int, [String])] {
        let indexed = initialPage.rows.enumerated().map { ($0.offset, $0.element) }
        if searchText.isEmpty { return indexed }
        return indexed.filter { (_, row) in
            row.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        List {
            Section {
                Text(initialPage.columns.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospaced()
            } header: {
                Text("\(filteredRows.count) dòng hiển thị · \(initialPage.columns.count) cột")
            }
            
            Section {
                ForEach(filteredRows, id: \.0) { (idx, row) in
                    Button {
                        selectedRowIndex = idx
                        showRowDetail = true
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.first ?? "")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            
                            if row.count > 1 {
                                var parts: [String] {
                                    var p: [String] = []
                                    let maxCols = min(row.count, initialPage.columns.count, 5)
                                    for c in 1..<maxCols {
                                        p.append("\(initialPage.columns[c]): \(row[c])")
                                    }
                                    return p
                                }
                                Text(parts.joined(separator: " · "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                
                if initialPage.hasMore && initialPage.limit < 5000 {
                    Button {
                        loadMore()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Tải thêm 200 dòng...", systemImage: "arrow.down.circle")
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle(initialPage.title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Lọc các dòng đã tải")
        .toolbar {
            if isModal {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Đóng") { dismiss() }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Xuất CSV") {
                    if let url = SQLiteQueryHelper.exportCSV(page: initialPage) {
                        presentShareSheet(with: url)
                    }
                }
            }
        }
        .sheet(isPresented: $showRowDetail) {
            if let rIdx = selectedRowIndex, rIdx < initialPage.rows.count {
                SQLiteSingleRowSheet(
                    rowNumber: rIdx + 1,
                    columns: initialPage.columns,
                    values: initialPage.rows[rIdx]
                )
            }
        }
    }
    
    private func loadMore() {
        let nextLimit = initialPage.limit + 200
        let sql = initialPage.sql
        let title = initialPage.title
        DispatchQueue.global(qos: .userInitiated).async {
            if case .success(let updated) = SQLiteQueryHelper.executeReadOnly(dbPath: dbPath, title: title, sql: sql, limit: nextLimit) {
                DispatchQueue.main.async {
                    self.initialPage = updated
                }
            }
        }
    }
}

struct SQLiteSingleRowSheet: View {
    @Environment(\.dismiss) private var dismiss
    let rowNumber: Int
    let columns: [String]
    let values: [String]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<min(columns.count, values.count), id: \.self) { idx in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(columns[idx])
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Text(values[idx])
                            .font(.system(.footnote, design: .monospaced))
                            .textSelection(.enabled)
                    }
                    .padding(.vertical, 2)
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = values[idx]
                        } label: {
                            Label("Sao chép giá trị", systemImage: "doc.on.doc")
                        }
                        Button {
                            UIPasteboard.general.string = "\(columns[idx]): \(values[idx])"
                        } label: {
                            Label("Sao chép tên cột & giá trị", systemImage: "doc.on.clipboard")
                        }
                    }
                }
            }
            .navigationTitle("Dòng \(rowNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Sao chép tất cả") {
                        var lines: [String] = []
                        for i in 0..<min(columns.count, values.count) {
                            lines.append("\(columns[i]): \(values[i])")
                        }
                        UIPasteboard.general.string = lines.joined(separator: "\n")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Xong") { dismiss() }
                }
            }
        }
    }
}
