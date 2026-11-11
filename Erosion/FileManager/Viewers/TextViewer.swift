//
//  TextViewer.swift
//  Thái Bình (ErosionWQ)
//
//  Trình xem & chỉnh sửa Văn bản / Mã nguồn tích hợp Tô màu cú pháp (WQSyntax v0.9)
//  Hỗ trợ 17 ngôn ngữ: XML/Plist, JSON, YAML, INI/TOML, CSS, SQL, Markdown, C/Obj-C,
//  Swift, JS/TS, Java/Kotlin, Go, Rust, Python, Shell, Ruby, Lua.
//

import SwiftUI
import UIKit

struct TextViewer: View {
    @EnvironmentObject var mgr: ErosionManager
    @Environment(\.dismiss) var dismiss

    @AppStorage("textViewerSize") var textViewerSize = 12
    @AppStorage("useMonospaced") var useMonospaced = true

    var fileURL: URL

    @State private var file = clearFileItem
    @State private var fileText = ""
    @State private var editText = ""
    @State private var isEditing = false
    @State private var wasBinaryPlist = false
    @State private var syntaxLanguage: String? = nil

    init(_ fileURL: URL) {
        self.fileURL = fileURL
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                if wasBinaryPlist || syntaxLanguage != nil {
                    HStack(spacing: 8) {
                        if wasBinaryPlist {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.left.arrow.right.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Binary Plist → XML (Tự động lưu lại dạng nhị phân)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        if let lang = syntaxLanguage {
                            Text(lang.uppercased())
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.blue.opacity(0.15), in: Capsule())
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.secondarySystemBackground))
                }

                SyntaxTextView(
                    text: isEditing ? $editText : $fileText,
                    isEditable: isEditing,
                    fontSize: CGFloat(max(9, textViewerSize)),
                    monospaced: useMonospaced,
                    language: syntaxLanguage
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(fileURL.lastPathComponent)
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                if !file.writable {
                    HStack {
                        Spacer()
                        Button {
                            Alertinator.shared.alert(title: "Tệp chỉ đọc", body: "Bạn chỉ có quyền xem nội dung tệp này.")
                        } label: {
                            Image(systemName: "lock.fill")
                                .padding(10)
                        }
                        .foregroundStyle(Color.accentColor)
                        .padding(.trailing)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 10) {
                        if isEditing {
                            Button {
                                isEditing = false
                                editText = fileText
                            } label: {
                                ToolbarLabel("Hủy", symbol: "xmark")
                            }
                        }

                        Menu {
                            if file.writable && !isEditing {
                                Button {
                                    isEditing = true
                                } label: {
                                    Label("Chỉnh sửa", systemImage: "pencil")
                                }
                            }

                            Button {
                                Haptic.shared.play(.soft)
                                UIPasteboard.general.string = isEditing ? editText : fileText
                            } label: {
                                Label("Sao chép toàn bộ", systemImage: "doc.on.doc")
                            }

                            Button {
                                if let url = makeTemp(fileURL) {
                                    presentShareSheet(with: url)
                                }
                            } label: {
                                Label("Chia sẻ tệp", systemImage: "square.and.arrow.up")
                            }
                        } label: {
                            Label("Tác vụ", systemImage: "ellipsis.circle")
                                .labelStyle(.iconOnly)
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        Button(role: .adaptiveConfirm) {
                            let res = writeTextIntoFile(fileURL, string: editText)
                            if res {
                                isEditing = false
                                fileText = getFileText(fileURL)
                                editText = fileText
                            }
                        } label: {
                            ToolbarLabel("Lưu", symbol: "checkmark")
                        }
                    } else {
                        Button {
                            dismiss()
                            mgr.refreshFiles.toggle()
                        } label: {
                            ToolbarLabel("Đóng", symbol: "xmark")
                        }
                    }
                }
            }
            .onAppear {
                file = getFileItem(at: fileURL)
                if let rawData = readDataWithWQ(fileURL, maxBytes: 16), isBinaryPlistData(rawData) {
                    wasBinaryPlist = true
                }
                let text = getFileText(fileURL)
                fileText = text
                editText = text
                if wasBinaryPlist {
                    syntaxLanguage = "xml"
                } else {
                    syntaxLanguage = wq_syntax_language(fileURL.lastPathComponent, text)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func writeTextIntoFile(_ url: URL, string: String) -> Bool {
        var dataToWrite = Data(string.utf8)
        if wasBinaryPlist {
            do {
                let plist = try PropertyListSerialization.propertyList(from: dataToWrite, options: [], format: nil)
                dataToWrite = try PropertyListSerialization.data(fromPropertyList: plist, format: .binary, options: 0)
            } catch {
                Alertinator.shared.alert(title: "Mã XML Plist không hợp lệ", body: error.localizedDescription)
                return false
            }
        }
        var wqErr: NSString?
        let ok = wq_write(url.path, dataToWrite, &wqErr)
        if ok {
            Haptic.shared.play(.soft)
            return true
        } else {
            do {
                try dataToWrite.write(to: url)
                return true
            } catch {
                Alertinator.shared.alert(title: "Lưu thất bại", body: (wqErr as String?) ?? error.localizedDescription)
            }
        }
        return false
    }
}

struct SyntaxTextView: UIViewRepresentable {
    @Binding var text: String
    let isEditable: Bool
    let fontSize: CGFloat
    let monospaced: Bool
    let language: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.backgroundColor = .systemBackground
        tv.alwaysBounceVertical = true
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .none
        tv.smartQuotesType = .no
        tv.smartDashesType = .no
        tv.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 20, right: 8)
        tv.isEditable = isEditable
        tv.isSelectable = true
        tv.font = resolvedFont()
        tv.text = text
        context.coordinator.scheduleHighlight(on: tv, text: text, language: language, font: resolvedFont(), delay: 0)
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.parent = self
        if uiView.isEditable != isEditable {
            uiView.isEditable = isEditable
        }
        let font = resolvedFont()
        if uiView.font != font {
            uiView.font = font
            context.coordinator.scheduleHighlight(on: uiView, text: uiView.text, language: language, font: font, delay: 0)
        }
        if uiView.markedTextRange == nil && uiView.text != text {
            let selected = uiView.selectedRange
            uiView.text = text
            if NSMaxRange(selected) <= (uiView.text as NSString).length {
                uiView.selectedRange = selected
            }
            context.coordinator.scheduleHighlight(on: uiView, text: text, language: language, font: font, delay: 0)
        }
    }

    private func resolvedFont() -> UIFont {
        if monospaced {
            return UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        }
        return UIFont.systemFont(ofSize: fontSize)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: SyntaxTextView
        private var generation: UInt = 0

        init(_ parent: SyntaxTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            if textView.markedTextRange == nil {
                parent.text = textView.text
                scheduleHighlight(
                    on: textView,
                    text: textView.text,
                    language: parent.language,
                    font: parent.resolvedFont(),
                    delay: 0.35
                )
            }
        }

        func scheduleHighlight(on textView: UITextView, text: String, language: String?, font: UIFont, delay: TimeInterval) {
            generation &+= 1
            let currentGen = generation
            guard let lang = language, !text.isEmpty, text.utf16.count <= kWQSyntaxMaxLength else {
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak textView] in
                guard let self = self, let tv = textView, self.generation == currentGen else { return }
                if tv.markedTextRange != nil { return }
                let snapshot = tv.text ?? ""
                DispatchQueue.global(qos: .userInitiated).async {
                    guard let highlighted = wq_syntax_highlight(snapshot, lang, font) else { return }
                    DispatchQueue.main.async {
                        guard self.generation == currentGen, tv.markedTextRange == nil, tv.text == snapshot else { return }
                        let storage = tv.textStorage
                        storage.beginEditing()
                        storage.setAttributes([
                            .font: font,
                            .foregroundColor: UIColor.label
                        ], range: NSRange(location: 0, length: storage.length))
                        highlighted.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: highlighted.length)) { val, range, _ in
                            if let color = val as? UIColor, NSMaxRange(range) <= storage.length {
                                storage.addAttribute(.foregroundColor, value: color, range: range)
                            }
                        }
                        storage.endEditing()
                        tv.typingAttributes = [
                            .font: font,
                            .foregroundColor: UIColor.label
                        ]
                    }
                }
            }
        }
    }
}
