//
//  KeypadManager.swift
//  Erosion
//
//  Created by lunginspector on 8/27/26.
//

import Combine
import Foundation
import UIKit
import ZIPFoundation

// i hate you, apple incorporated.
// with love, lunginspector. august 28th, 2026.
enum KeypadID: String, CaseIterable {
    case one, two, three, four, five, six, seven, eight, nine, star, zero, pound
    
    var fileNames: [String] {
        switch self {
        case .one: return getFileNames(forKey: "-1-")
        case .two: return getFileNames(forKey: "-2-A B C")
        case .three: return getFileNames(forKey: "-3-D E F")
        case .four: return getFileNames(forKey: "-4-G H I")
        case .five: return getFileNames(forKey: "-5-J K L")
        case .six: return getFileNames(forKey: "-6-M N O")
        case .seven: return getFileNames(forKey: "-7-P Q R S")
        case .eight: return getFileNames(forKey: "-8-T U V")
        case .nine: return getFileNames(forKey: "-9-W X Y Z")
        case .star: return getFileNames(forKey: "-*-")
        case .zero: return getFileNames(forKey: "-0-+")
        case .pound: return getFileNames(forKey: "-#-")
        }
    }
    
    private func getFileNames(forKey key: String) -> [String] {
        let files = ["--mask.png", "--white.png", "-hi-mask.png", "-hi-white.png", "--white-bold.png", "--mask-bold.png"]
        return files.map { kp.getFileRegCode() + key + $0 }
    }
    
    func getAccentedFileName() -> String {
        let appearance = UIScreen.main.traitCollection.userInterfaceStyle
        switch appearance {
        case .light: return self.fileNames[0]
        case .dark: return self.fileNames[1]
        default: return self.fileNames[0]
        }
    }
}

enum KPSize: Int, CaseIterable {
    case defSize, small, medium, large, custom
    
    var float: CGFloat {
        switch self {
        case .small: return CGFloat(150)
        case .medium: return CGFloat(205)
        case .large: return CGFloat(225)
        default: return CGFloat(0)
        }
    }
    
    var label: String {
        switch self {
        case .defSize: return "Default"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .custom: return "Custom"
        }
    }
}

enum KPSizeLimits {
    static let min = CGFloat(50)
    static let max = CGFloat(2500)
}

struct KeypadItem: Identifiable, Equatable {
    let id = UUID()
    var kpID: KeypadID
    var imgData = Data()
    var ogImgData = Data()
}

let emptyKeypadArray = [
    KeypadItem(kpID: KeypadID.one), KeypadItem(kpID: KeypadID.two), KeypadItem(kpID: KeypadID.three), KeypadItem(kpID: KeypadID.four), KeypadItem(kpID: KeypadID.five), KeypadItem(kpID: KeypadID.six), KeypadItem(kpID: KeypadID.seven), KeypadItem(kpID: KeypadID.eight), KeypadItem(kpID: KeypadID.nine), KeypadItem(kpID: KeypadID.star), KeypadItem(kpID: KeypadID.zero), KeypadItem(kpID: KeypadID.pound)
]

enum KPMsg {
    static let resetWarn = "You'll lose both what you're currently editing and what you've already set inside of the Phone app."
    static let applyComp = "For changes to take effect, open the Phone app and change the appearance until your custom keys show up. You can also restart your device. Do NOT force kill the Phone app!"
}

let kp = KeypadManager()
final class KeypadManager: ObservableObject {
    static let shared = KeypadManager()
    
    @Published var mpKeypad = [KeypadItem]()
    
    private var mpContainerPath = {
        return UserDefaults.standard.value(forKey: "mpContainerPath") as? String ?? ""
    }
    
    init() {
        if mpKeypad.isEmpty {
            mpKeypad = emptyKeypadArray
        }
    }
    
    func getTelephonyUIDir() -> URL {
        let base = URL(fileURLWithPath: mpContainerPath())
        let caches = base.appendingPathComponent("Library/Caches")
        _ = wq_grant(caches.path)
        for sub in ["TelephonyUI-10", "TelephonyUI-9", "TelephonyUI-8"] {
            let candidate = caches.appendingPathComponent(sub)
            var st = stat()
            if wq_stat(candidate.path, &st) {
                _ = wq_grant(candidate.path)
                return candidate
            }
        }
        return caches.appendingPathComponent("TelephonyUI-10")
    }
    
    // fun...
    func getFileRegCode() -> String {
        let tpURL = getTelephonyUIDir()
        if let names = wq_list(tpURL.path, nil), let first = names.first {
            let split = first.split(separator: "-")
            if let reg = split.first {
                return String(reg)
            }
        }
        if let tpURLs = try? fm.contentsOfDirectory(at: tpURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
            if let split = tpURLs.first?.lastPathComponent.split(separator: "-") {
                return split.map { String($0) }[0]
            }
        }
        return "other"
    }
    
    func updateKeypadItem(forID id: KeypadID, withData data: Data, ogData: Data? = nil) {
        if let index = mpKeypad.firstIndex(where: { $0.kpID == id }) {
            mpKeypad[index].imgData = data
            if let data = ogData {
                mpKeypad[index].ogImgData = data
            }
        }
    }
    
    func applyKeypadItems() -> Bool {
        let tpDir = getTelephonyUIDir()
        _ = wq_grant(tpDir.path)
        var failed = 0
        for item in mpKeypad {
            guard !item.imgData.isEmpty else { continue }
            let files = item.kpID.fileNames
            for fileName in files {
                let finalURL = tpDir.appendingPathComponent(fileName)
                var err: NSString?
                if wq_write(finalURL.path, item.imgData, &err) || wq_create_file(finalURL.path, item.imgData, &err) {
                    continue
                }
                do {
                    try item.imgData.write(to: finalURL)
                } catch {
                    print("(kp) failed to write image data: \(error.localizedDescription)")
                    failed += 1
                }
            }
        }
        if failed == 0 {
            return true
        }
        return false
    }
    
    func resetKeypadItems() -> Bool {
        let filesURL = getTelephonyUIDir()
        _ = wq_grant(filesURL.path)
        var freed: UInt64 = 0
        if wq_purge_contents(filesURL.path, &freed) {
            clearKeypads()
            return true
        }
        do {
            let files = try fm.contentsOfDirectory(at: filesURL, includingPropertiesForKeys: [])
            for fileURL in files {
                try fm.removeItem(at: fileURL)
            }
            clearKeypads()
            return true
        } catch {
            print("(kp) failed to reset keypad items: \(error.localizedDescription)")
        }
        return false
    }
    
    func clearKeypads() {
        for keypad in mpKeypad {
            if let index = mpKeypad.firstIndex(where: { $0.id == keypad.id }) {
                mpKeypad[index].ogImgData = Data()
                mpKeypad[index].imgData = Data()
            }
        }
    }
    
    func resizeAndRet(withData data: Data, newSize: CGFloat = CGFloat(0), customSize: CGSize? = nil, shallCircle: Bool = false, isDefault: Bool = false) -> Data {
        if let image = UIImage(data: data) {
            var width = isDefault ? image.size.width : customSize?.width ?? newSize
            var height = isDefault ? image.size.height: customSize?.height ?? newSize
            width = min(max(width, KPSizeLimits.min), KPSizeLimits.max)
            height = min(max(height, KPSizeLimits.min), KPSizeLimits.max)
            let resized = image.resized(to: CGSize(width: width, height: height), shouldCircle: shallCircle)
            if let newData = resized.pngData() {
                return newData
            }
        }
        return data
    }
    
    func getCurrentKeypads(size: KPSize = KPSize.defSize, custW: Int = 0, custH: Int = 0, saveOgData: Bool = false) {
        do {
            let filesURL = URL(fileURLWithPath: mpContainerPath()).appendingPathComponent("Library/Caches/TelephonyUI-10")
            for kpId in KeypadID.allCases {
                let fileName = kpId.getAccentedFileName()
                let url = filesURL.appendingPathComponent(fileName)
                let data = try Data(contentsOf: url)
                let imgData = {
                    switch size {
                    case .defSize: return resizeAndRet(withData: data, isDefault: true)
                    case .custom: return resizeAndRet(withData: data, customSize: CGSize(width: custW, height: custH))
                    default: return resizeAndRet(withData: data, newSize: size.float)
                    }
                }()
                if saveOgData {
                    updateKeypadItem(forID: kpId, withData: imgData, ogData: imgData)
                } else {
                    updateKeypadItem(forID: kpId, withData: imgData)
                }
            }
        } catch {
            // keypads could've been reset so nothing to log here, logs are just gonna spit out nonsense
        }
    }
    
    func changeSizeOfKeypads(size: KPSize = KPSize.defSize, custW: Int = 0, custH: Int = 0) {
        for kpItem in mpKeypad {
            let data = kpItem.ogImgData
            let imgData = {
                switch size {
                case .defSize: return resizeAndRet(withData: data, isDefault: true)
                case .custom: return resizeAndRet(withData: data, customSize: CGSize(width: custW, height: custH))
                default: return resizeAndRet(withData: data, newSize: size.float)
                }
            }()
            updateKeypadItem(forID: kpItem.kpID, withData: imgData)
        }
    }
    
    func maskKeysIntoCircle(size: KPSize = KPSize.defSize, custW: Int = 0, custH: Int = 0) {
        for kpItem in mpKeypad {
            let data = kpItem.ogImgData
            let imgData = {
                switch size {
                case .defSize: return resizeAndRet(withData: data, shallCircle: true, isDefault: true)
                case .custom: return resizeAndRet(withData: data, customSize: CGSize(width: custW, height: custH), shallCircle: true)
                default: return resizeAndRet(withData: data, newSize: size.float, shallCircle: true)
                }
            }()
            updateKeypadItem(forID: kpItem.kpID, withData: imgData)
        }
    }
    
    // by far the most annoying piece of swift i've ever had to write. but, it works how it should, so i'm happy.
    // -lunginspector, 9/11/26
    func importTheme(fromURL fileURL: URL) -> Bool {
        do {
            // create a temp dir for extraction
            var filesURL = URL.temporaryDirectory.appendingPathComponent(fileURL.deletingPathExtension().lastPathComponent + "_\(UUID())_EROSIONTMP")
            try fm.createDirectory(at: filesURL, withIntermediateDirectories: true)
            try fm.unzipItem(at: fileURL, to: filesURL)
            let dirURLs = try fm.contentsOfDirectory(at: filesURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            if dirURLs.count < 1 {
                throw "no files found inside of extracted folder!"
            } else if dirURLs.count == 1 {
                filesURL = filesURL.appendingPathComponent(dirURLs[0].lastPathComponent)
            } else {
                if let index = dirURLs.firstIndex(where: { $0.lastPathComponent == "TelephonyUI-8" || $0.lastPathComponent == "TelephonyUI-9" || $0.lastPathComponent == "TelephonyUI-10" }) {
                    filesURL = filesURL.appendingPathComponent(dirURLs[index].lastPathComponent)
                } else {
                    throw "no telephonyui folders found inside of extracted folder!"
                }
            }
            // once extracted check each file for a match with the right image
            var replaceCount = 0
            let fileURLs = try fm.contentsOfDirectory(at: filesURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for fileURL in fileURLs {
                let split = fileURL.lastPathComponent.split(separator: "-").map { String($0) }
                //print(split)
                let fileForAppr = UIScreen.main.traitCollection.userInterfaceStyle == .dark ? "white" : "mask"
                // for appearance - get appearance for key ("white"-dark, "mask"-light) and see if it matches the current appearance too
                let apprName = {
                    if split.indices.contains(3) {
                        let appearance = split[3].split(separator: ".")[0]
                        if appearance == fileForAppr {
                            return split[3]
                        }
                    }
                    if split.indices.contains(2) {
                        let appearance = split[2].split(separator: ".")[0]
                        if appearance == fileForAppr {
                            return split[2]
                        }
                    }
                    return ""
                }()
                //print(apprName)
                if split.indices.contains(1) {
                    // lookup for key
                    let keyNum = split[1]
                    //print("(kp) fileName: \(fileURL.lastPathComponent), keyNum: \(keyNum), appearance: \(appearance), fileForAppr: \(fileForAppr), apprName: \(apprName)")
                    // check if that's the appearance we actually want
                    if let id = KeypadID.allCases.first(where: { $0.fileNames.contains { $0.contains(keyNum) && $0.contains(apprName) }}) {
                        //print("(kp) found image! lookup: \(keyNum), fileName: \(fileURL.lastPathComponent)")
                        let data = try Data(contentsOf: fileURL)
                        updateKeypadItem(forID: id, withData: data, ogData: data)
                        replaceCount += 1
                    }
                }
            }
            if replaceCount < 1 {
                throw "the file was unzipped, but no keys were found?"
            }
            print("(kp) successfully imported theme! fileName: \(fileURL.lastPathComponent), imported keys: \(replaceCount)")
            return true
        } catch {
            print("(kp) failed to import theme: \(error.localizedDescription)")
        }
        return false
    }
    
    // MARK: - Built-in Procedural Keypad Themes
    func applyPresetTheme(_ preset: KeypadPresetTheme) {
        let size = CGSize(width: 225, height: 225)
        for kpID in KeypadID.allCases {
            let img = preset.renderKey(for: kpID, size: size)
            if let data = img.pngData() {
                updateKeypadItem(forID: kpID, withData: data, ogData: data)
            }
        }
    }
}

enum KeypadPresetTheme: String, CaseIterable {
    case neonCyber = "Neon Cyber"
    case matrixHacker = "Matrix Hex"
    case goldLuxury = "Gold Royal"
    case romanNumerals = "Roman Numerals"
    case pastelCandy = "Pastel Glass"
    case ghostMinimal = "Minimal Ring"
    
    var icon: String {
        switch self {
        case .neonCyber: return "bolt.circle.fill"
        case .matrixHacker: return "terminal.fill"
        case .goldLuxury: return "crown.fill"
        case .romanNumerals: return "building.columns.fill"
        case .pastelCandy: return "paintpalette.fill"
        case .ghostMinimal: return "circle.dotted"
        }
    }
    
    func labelForKey(_ id: KeypadID) -> (main: String, sub: String) {
        switch self {
        case .romanNumerals:
            switch id {
            case .one: return ("I", "")
            case .two: return ("II", "ABC")
            case .three: return ("III", "DEF")
            case .four: return ("IV", "GHI")
            case .five: return ("V", "JKL")
            case .six: return ("VI", "MNO")
            case .seven: return ("VII", "PQRS")
            case .eight: return ("VIII", "TUV")
            case .nine: return ("IX", "WXYZ")
            case .star: return ("✱", "")
            case .zero: return ("O", "+")
            case .pound: return ("#", "")
            }
        case .matrixHacker:
            switch id {
            case .one: return ("0x01", "BIN")
            case .two: return ("0x02", "ABC")
            case .three: return ("0x03", "DEF")
            case .four: return ("0x04", "GHI")
            case .five: return ("0x05", "JKL")
            case .six: return ("0x06", "MNO")
            case .seven: return ("0x07", "PQRS")
            case .eight: return ("0x08", "TUV")
            case .nine: return ("0x09", "WXYZ")
            case .star: return ("0x2A", "PTR")
            case .zero: return ("0x00", "NUL")
            case .pound: return ("0x23", "ROOT")
            }
        default:
            switch id {
            case .one: return ("1", "")
            case .two: return ("2", "A B C")
            case .three: return ("3", "D E F")
            case .four: return ("4", "G H I")
            case .five: return ("5", "J K L")
            case .six: return ("6", "M N O")
            case .seven: return ("7", "P Q R S")
            case .eight: return ("8", "T U V")
            case .nine: return ("9", "W X Y Z")
            case .star: return ("∗", "")
            case .zero: return ("0", "+")
            case .pound: return ("#", "")
            }
        }
    }
    
    func renderKey(for id: KeypadID, size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = false
        
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let ctx = context.cgContext
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 8, dy: 8)
            
            let bgColor: UIColor
            let borderColor: UIColor
            let textColor: UIColor
            let borderWidth: CGFloat
            
            switch self {
            case .neonCyber:
                bgColor = UIColor(red: 0.05, green: 0.06, blue: 0.16, alpha: 0.88)
                borderColor = UIColor(red: 0.0, green: 0.95, blue: 1.0, alpha: 0.95)
                textColor = UIColor(red: 0.0, green: 0.98, blue: 1.0, alpha: 1.0)
                borderWidth = 5
            case .matrixHacker:
                bgColor = UIColor(red: 0.02, green: 0.10, blue: 0.04, alpha: 0.90)
                borderColor = UIColor(red: 0.1, green: 0.95, blue: 0.3, alpha: 0.85)
                textColor = UIColor(red: 0.2, green: 1.0, blue: 0.4, alpha: 1.0)
                borderWidth = 4
            case .goldLuxury:
                bgColor = UIColor(red: 0.10, green: 0.09, blue: 0.07, alpha: 0.92)
                borderColor = UIColor(red: 0.95, green: 0.78, blue: 0.32, alpha: 0.95)
                textColor = UIColor(red: 0.98, green: 0.84, blue: 0.42, alpha: 1.0)
                borderWidth = 5
            case .romanNumerals:
                bgColor = UIColor(red: 0.14, green: 0.14, blue: 0.18, alpha: 0.85)
                borderColor = UIColor(white: 0.85, alpha: 0.6)
                textColor = UIColor.white
                borderWidth = 3
            case .pastelCandy:
                bgColor = UIColor(red: 0.95, green: 0.45, blue: 0.75, alpha: 0.32)
                borderColor = UIColor(red: 1.0, green: 0.65, blue: 0.88, alpha: 0.9)
                textColor = UIColor.white
                borderWidth = 4
            case .ghostMinimal:
                bgColor = UIColor.clear
                borderColor = UIColor(white: 1.0, alpha: 0.55)
                textColor = UIColor.white
                borderWidth = 3
            }
            
            ctx.setFillColor(bgColor.cgColor)
            ctx.fillEllipse(in: rect)
            
            ctx.setStrokeColor(borderColor.cgColor)
            ctx.setLineWidth(borderWidth)
            ctx.strokeEllipse(in: rect)
            
            let labels = labelForKey(id)
            let mainFontSize: CGFloat = (self == .matrixHacker) ? 48 : (self == .romanNumerals ? 56 : 78)
            let mainFont: UIFont = (self == .matrixHacker)
                ? UIFont.monospacedSystemFont(ofSize: mainFontSize, weight: .bold)
                : UIFont.systemFont(ofSize: mainFontSize, weight: .semibold)
            
            let pStyle = NSMutableParagraphStyle()
            pStyle.alignment = .center
            
            let mainAttrs: [NSAttributedString.Key: Any] = [
                .font: mainFont,
                .foregroundColor: textColor,
                .paragraphStyle: pStyle
            ]
            let mainSize = (labels.main as NSString).size(withAttributes: mainAttrs)
            let mainY = labels.sub.isEmpty ? (size.height - mainSize.height) / 2.0 : (size.height * 0.44 - mainSize.height / 2.0)
            (labels.main as NSString).draw(in: CGRect(x: 0, y: mainY, width: size.width, height: mainSize.height), withAttributes: mainAttrs)
            
            if !labels.sub.isEmpty {
                let subAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                    .foregroundColor: textColor.withAlphaComponent(0.78),
                    .paragraphStyle: pStyle
                ]
                let subSize = (labels.sub as NSString).size(withAttributes: subAttrs)
                (labels.sub as NSString).draw(in: CGRect(x: 0, y: size.height * 0.68, width: size.width, height: subSize.height), withAttributes: subAttrs)
            }
        }
    }
}

extension UIImage {
    func resized(to size: CGSize, scale: CGFloat = 1.0, shouldCircle: Bool = false) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let ctx = context.cgContext

            if shouldCircle {
                ctx.addEllipse(in: CGRect(origin: .zero, size: size))
                ctx.clip()

                let fillScale = max(size.width / self.size.width, size.height / self.size.height)
                let drawSize = CGSize(width: self.size.width * fillScale, height: self.size.height * fillScale)
                let origin = CGPoint(
                    x: (size.width - drawSize.width) / 2,
                    y: (size.height - drawSize.height) / 2
                )
                draw(in: CGRect(origin: origin, size: drawSize))
            } else {
                draw(in: CGRect(origin: .zero, size: size))
            }
        }
    }
}
