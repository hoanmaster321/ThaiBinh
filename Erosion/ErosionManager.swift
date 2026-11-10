//
//  ErosionManager.swift
//  ThaiBinh (ErosionWQ)
//

import Foundation
import Combine

let build = "ThaiBinh-Edition"

enum Errors {
    static var checkLogs = "Vui lòng kiểm tra Nhật ký hệ thống (Console Logs) ở Trang chủ để xem chi tiết."
}

enum AppURL {
    static let pb = URL.documentsDirectory.appendingPathComponent("PosterBoard")
    static let pbFolders = AppURL.pb.appendingPathComponent("Wallpapers")
    static let ps = URL.documentsDirectory.appendingPathComponent("Passcode Themes")
}

enum AppMsg {
    static let opFailed = "Vui lòng khởi động lại ứng dụng và thử lại. Đảm bảo ứng dụng đã được ký kèm quyền App Group."
    static let applied = "Hãy khởi động lại SpringBoard (Respring) để các thay đổi có hiệu lực."
    static let unsupported = "Phiên bản iOS hiện tại không hỗ trợ phương thức này."
}

final class ErosionManager: ObservableObject {
    static let shared = ErosionManager()
    @Published var logOutput = ""
    @Published var shouldRespring = false
    @Published var refreshFiles = false
    
    @Published var storedFiles = [FileItem]()
    @Published var storedURL: URL = URL(fileURLWithPath: "/")
    
    init() {}
}
