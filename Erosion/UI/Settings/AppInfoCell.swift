//
//  AppInfoCell.swift
//  ThaiBinh (ErosionWQ)
//

import SwiftUI

struct AppInfoCell: View {
    let build: String
    
    var body: some View {
        HStack(spacing: 14) {
            AppIconCell(image: Image(uiImage: AppInfo.appIcon ?? UIImage()))
            VStack(alignment: .leading, spacing: 2) {
                Text("ThaiBinh (ErosionWQ)")
                    .font(.title3.weight(.semibold))
                Text("Phiên bản \(AppInfo.appVersion) (\(build))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("© 2026 hoanmaster321 · All Rights Reserved")
                    .font(.caption2)
                    .foregroundStyle(.blue)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct AppIconCell: View {
    var image: Image
    
    var body: some View {
        if #available(iOS 26.0, *) {
            image
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .background(PlaceholderAppIconCell())
                .clipShape(.rect(cornerRadius: 18))
                .glassEffect(.regular, in: .rect(cornerRadius: 18))
        } else {
            image
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .background(PlaceholderAppIconCell())
                .clipShape(.rect(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1.5)
                }
        }
    }
}

struct PlaceholderAppIconCell: View {
    var body: some View {
        Image(systemName: "sparkles.rectangle.stack.fill")
            .foregroundStyle(.blue)
            .frame(width: 64, height: 64)
            .background(Color(.systemGray5))
    }
}
