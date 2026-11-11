//
//  MediaPlayerView.swift
//  Thái Bình (ErosionWQ)
//
//  Trình phát Đa phương tiện (Audio & Video) tích hợp từ WQFiles v0.9.
//  Tự động sao chép tệp từ container ngoài vào thư mục tạm trước khi phát bằng AVPlayerViewController.
//

import SwiftUI
import AVKit
import AVFoundation

struct MediaPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    let fileURL: URL

    @State private var localMediaURL: URL? = nil
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil

    private static let mediaExtensions: Set<String> = [
        "mp3", "m4a", "m4b", "aac", "wav", "aif", "aiff", "caf", "flac", "alac",
        "mp4", "m4v", "mov", "3gp", "3g2", "m3u8"
    ]

    static func isMediaFile(_ url: URL) -> Bool {
        return mediaExtensions.contains(url.pathExtension.lowercased())
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 14) {
                        ProgressView()
                            .controlSize(.large)
                        Text("Đang chuẩn bị trình phát đa phương tiện…")
                            .font(.headline)
                        Text(fileURL.lastPathComponent)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .padding()
                } else if let error = errorMessage {
                    VStack(spacing: 14) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.orange)
                        Text("Không thể phát tệp đa phương tiện")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if let url = localMediaURL {
                    AVPlayerControllerRepresentable(mediaURL: url)
                        .ignoresSafeArea(edges: .bottom)
                }
            }
            .navigationTitle(fileURL.lastPathComponent)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if let url = localMediaURL {
                        Button {
                            presentShareSheet(with: url)
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Đóng") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                prepareMedia()
            }
        }
    }

    private func prepareMedia() {
        isLoading = true
        errorMessage = nil
        let sourcePath = fileURL.path
        let fileName = fileURL.lastPathComponent

        DispatchQueue.global(qos: .userInitiated).async {
            let mediaDir = (NSTemporaryDirectory() as NSString).appendingPathComponent("wq-media")
            let fm = FileManager.default
            try? fm.removeItem(atPath: mediaDir)
            try? fm.createDirectory(atPath: mediaDir, withIntermediateDirectories: true)
            let localPath = (mediaDir as NSString).appendingPathComponent(fileName)

            var err: NSString?
            let ok = wq_copy_to_local(sourcePath, localPath, &err)
            wq_log("media: %@ -> %@", sourcePath, ok ? "OK" : (err as String? ?? "failed"))

            DispatchQueue.main.async {
                self.isLoading = false
                if ok {
                    try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                    try? AVAudioSession.sharedInstance().setActive(true)
                    self.localMediaURL = URL(fileURLWithPath: localPath)
                } else {
                    self.errorMessage = (err as String?) ?? "Không thể đọc tệp đa phương tiện này."
                }
            }
        }
    }
}

private struct AVPlayerControllerRepresentable: UIViewControllerRepresentable {
    let mediaURL: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: mediaURL)
        controller.player = player
        controller.allowsPictureInPicturePlayback = true
        player.play()
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}

    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: ()) {
        uiViewController.player?.pause()
        uiViewController.player = nil
    }
}
