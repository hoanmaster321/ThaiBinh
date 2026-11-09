//
//  FileHelpers.swift
//  Filos
//
//  Created by lunginspector on 7/22/26.
//

import SwiftUI
import ZIPFoundation
import UniformTypeIdentifiers

extension FileManager {
    func createDirectoryIfNeeded(at url: URL) throws {
        if !self.fileExists(atPath: url.path) {
            try self.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
}

func readDataWithWQ(_ url: URL, maxBytes: UInt = 0) -> Data? {
    var err: NSString?
    if let data = wq_read(url.path, maxBytes, &err) {
        return data
    }
    return try? Data(contentsOf: url)
}

func getFileDict(_ url: URL) -> [String : Any]? {
    if let data = readDataWithWQ(url),
       let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String : Any] {
        return dict
    }
    return nil
}

func getFileDictWithFormat(_ url: URL) -> ([String : Any], PropertyListSerialization.PropertyListFormat)? {
    guard let data = readDataWithWQ(url) else { return nil }
    var fmt = PropertyListSerialization.PropertyListFormat.binary
    if let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: &fmt) as? [String : Any] {
        return (dict, fmt)
    }
    return nil
}

func isBinaryPlistData(_ data: Data) -> Bool {
    guard data.count >= 8 else { return false }
    let magic = String(decoding: data.prefix(6), as: UTF8.self)
    return magic == "bplist"
}

func getFileText(_ url: URL) -> String {
    guard let data = readDataWithWQ(url) else {
        return ""
    }
    if isBinaryPlistData(data) {
        var fmt = PropertyListSerialization.PropertyListFormat.binary
        if let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: &fmt),
           let xmlData = try? PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0),
           let xmlStr = String(data: xmlData, encoding: .utf8) {
            return xmlStr
        }
    }
    if let text = String(data: data, encoding: .utf8) {
        return text
    }
    return String(decoding: data, as: UTF8.self)
}

func makeTemp(_ fileURL: URL) -> URL? {
    let neededAccess = fileURL.startAccessingSecurityScopedResource()
    defer {
        if neededAccess {
            fileURL.stopAccessingSecurityScopedResource()
        }
    }
    let tempURL = URL.temporaryDirectory.appendingPathComponent("\(fileURL.lastPathComponent)")
    try? fm.removeItem(at: tempURL)
    if let data = readDataWithWQ(fileURL) {
        if (try? data.write(to: tempURL)) != nil {
            return tempURL
        }
    }
    do {
        try fm.copyItem(at: fileURL, to: tempURL)
        return tempURL
    } catch {
        print("(fm) failed to make temp: \(error.localizedDescription)")
    }
    return nil
}

func generateNavPath(path: String) -> String {
    if !path.contains("/") || path.isEmpty {
        return ""
    }
    
    let file = getFileItem(at: URL(fileURLWithPath: path))
    
    if file.type == .folder || file.type == .symlink {
        return path
    }
    
    if file.type == .file {
        let navPath = URL(fileURLWithPath: path).deletingLastPathComponent().path
        return navPath
    }
    return ""
}

func renameFile(_ url: URL, to newName: String) -> Bool {
    var err: NSString?
    if wq_rename(url.path, newName, &err) {
        return true
    }
    do {
        let data = try Data(contentsOf: url)
        try fm.removeItem(at: url)
        let targetURL = url.deletingLastPathComponent().appendingPathComponent(newName)
        try data.write(to: targetURL)
        return true
    } catch {
        print("(fm) failed to rename file: \(error.localizedDescription)")
    }
    return false
}

func zipFile(_ url: URL) -> Bool {
    do {
        _ = wq_grant(url.deletingLastPathComponent().path)
        let zipDest = url
            .deletingLastPathComponent()
            .appendingPathComponent(url.lastPathComponent + ".zip")
        try FileManager.default.zipItem(at: url, to: zipDest, shouldKeepParent: true)
        return true
    } catch {
        print("(fm) failed to zip file: \(error.localizedDescription)")
    }
    return false
}

func unzipFile(_ url: URL) -> Bool {
    do {
        let unzipDest = url.deletingLastPathComponent()
        _ = wq_grant(unzipDest.path)
        try fm.createDirectory(at: unzipDest, withIntermediateDirectories: true)
        try fm.unzipItem(at: url, to: unzipDest)
        return true
    } catch {
        print("(fm) failed to uncompress file: \(error.localizedDescription)")
    }
    return false
}

func duplicateFile(_ url: URL) -> Bool {
    let targetURL: URL = {
        if url.pathExtension == "" {
            return url
                .deletingLastPathComponent()
                .appendingPathComponent("\(url.deletingPathExtension().lastPathComponent)_copy")
        }
        return url
            .deletingLastPathComponent()
            .appendingPathComponent("\(url.deletingPathExtension().lastPathComponent)_copy.\(url.pathExtension)")
    }()
    if let data = readDataWithWQ(url) {
        var err: NSString?
        if wq_create_file(targetURL.path, data, &err) {
            return true
        }
        if (try? data.write(to: targetURL)) != nil {
            return true
        }
    }
    return false
}

func copyFileToClipboard(_ url: URL) -> Bool {
    do {
        guard let tempURL = makeTemp(url) else {
            throw "failed to make temp!"
        }
        let data = try Data(contentsOf: tempURL)
        let utType = UTType(filenameExtension: tempURL.pathExtension) ?? .data
        
        UIPasteboard.general.setData(data, forPasteboardType: utType.identifier)
        return true
    } catch {
        print("(fm) failed to copy file: \(error.localizedDescription)")
    }
    return false
}

func conformsToPlistViewer(_ url: URL) -> Bool {
    let ext = url.pathExtension.lowercased()
    if ext == "plist" || ext == "strings" || ext == "entitlements" {
        if let data = readDataWithWQ(url, maxBytes: 512 * 1024),
           (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String : Any]) != nil {
            return true
        }
    }
    guard let data = readDataWithWQ(url, maxBytes: 64 * 1024) else { return false }
    if isBinaryPlistData(data) {
        return (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String : Any]) != nil
    }
    return false
}

func conformsToTextViewer(_ url: URL) -> Bool {
    guard let data = readDataWithWQ(url, maxBytes: 128 * 1024) else { return false }
    if isBinaryPlistData(data) {
        return true
    }
    return String(data: data, encoding: .utf8) != nil
}
