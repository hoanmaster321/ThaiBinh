<div align="center">
  <br>
  <img src="PreviewIcon.png" alt="ErosionWQ Icon" width="130" style="border-radius: 28px;">
  <br>
  <h1>ErosionWQ</h1>
  <p><strong>The Ultimate iOS Customization Toolbox, App Data Manager & Cache Cleaner</strong></p>
  <p>A unified fusion of <a href="https://github.com/jailbreakdotparty/Erosion">Erosion</a> and <a href="https://github.com/kolbicz/WQFiles">WQFiles</a>, powered by the <code>worse_query</code> sandbox escape & <code>fsgetpath</code> inode crawler.</p>

  <p>
    <img alt="iOS Support" src="https://img.shields.io/badge/iOS-16.0%20--%2027.2-007AFF?style=flat-square&logo=apple">
    <img alt="License" src="https://img.shields.io/badge/License-GPL%203.0-green?style=flat-square">
    <img alt="Language" src="https://img.shields.io/badge/Language-Swift%205.10%20%2F%20Obj--C-FA7343?style=flat-square&logo=swift">
    <img alt="Status" src="https://img.shields.io/badge/Status-Production%20Ready-brightgreen?style=flat-square">
  </p>
</div>

---

## 🌟 Overview / Giới thiệu tổng quan

**ErosionWQ** kết hợp sức mạnh tùy biến hệ thống của **Erosion** (jailbreakdotparty) cùng với trình quản lý ứng dụng, dọn dẹp bộ nhớ đệm và duyệt file siêu tốc của **WQFiles** (kolbicz). Ứng dụng hoạt động hoàn toàn trên thiết bị (on-device), **không cần jailbreak** và **không cần kernel exploit**, tận dụng kỹ thuật vượt sandbox `worse_query`.

### 🚀 Key Features / Tính năng nổi bật

1. **Dashboard & Thiết bị (Home)**:
   - Hiển thị tên thương mại thiết bị và build kernel iOS (ví dụ: `iPhone 16 Pro Max · iOS 27.0.1 (24A446)`).
   - Kiểm tra trạng thái App Group (`group.cz.kolbi.wqfiles` / `group.party.jailbreak.erosion`).
   - Respring nhanh qua SpringBoard WebView renderer.
   - Terminal logs trực tiếp (`wq_log` và console output).

2. **Trung tâm Tinh chỉnh (Tweaks - Erosion Engine)**:
   - **MobileGestalt**: Kích hoạt Dynamic Island (hỗ trợ chỉnh Subtype), giới hạn sạc 80% (Charge Limit), Always On Display, bộ nhớ trong (Internal Storage), tắt âm chụp ảnh, spoof model iPhone (thử nghiệm Apple Intelligence).
   - **PosterBoard Wallpapers**: Tùy biến hình nền Nugget-style, đặt lại collections.
   - **Keypad Themer**: Đổi giao diện bàn phím quay số cuộc gọi phong cách Cowabunga.
   - **Supervision & Profiles**: Quản lý trạng thái giám sát thiết bị và cấu hình MDM.
   - **Tự động sao lưu an toàn**: Mọi chỉnh sửa plist hệ thống đều được tự động backup trước khi ghi đè.

3. **Quản lý Dữ liệu Ứng dụng (App Manager - WQFiles Engine)**:
   - Quét siêu tốc tất cả ứng dụng cài đặt nhờ cơ chế duyệt inode `fsgetpath` và cơ sở dữ liệu `LaunchServices` từ container `lsd`.
   - Hiển thị tên app tiếng Việt/bản địa hóa và icon chất lượng cao thay vì mã UUID vô nghĩa.
   - Tính toán dung lượng thực tế (`Documents`, `Library`, `tmp`).
   - **Sao lưu 1 chạm (Back Up)**: Snapshot toàn bộ dữ liệu app vào `AppBackups/<bundleID>/<timestamp>`.
   - **Phục hồi (Restore)**: Khôi phục dữ liệu snapshot trở lại ứng dụng bất kỳ lúc nào.
   - **Chia sẻ file ZIP (AirDrop / Files / Mail)**: Nén backup trực tiếp qua `NSFileCoordinator` và mở Share Sheet.
   - **Xóa sạch dữ liệu (Clear Data)**: Reset ứng dụng về trạng thái mới cài đặt.

4. **Dọn dẹp Bộ nhớ đệm (Cache & Junk Cleaner - WQFiles Engine)**:
   - Quét sạch `Library/Caches` và thư mục `tmp` trên toàn bộ ứng dụng và extension.
   - Quét và dọn dẹp báo cáo lỗi iOS Crash Reports (`/var/mobile/Library/Logs/CrashReporter`).
   - Bộ lọc thông minh: *Select All*, *Large Caches (>50 MB)*, *None*, và tìm kiếm theo tên app.
   - Nút dọn dẹp trực tiếp kèm thanh đo tiến trình và báo cáo số MB/GB giải phóng.

5. **Trình duyệt File chuyên sâu (Advanced File Browser)**:
   - Phím tắt truy cập nhanh: Data Containers (kèm icon app), App Groups, Extension Data, Internal Daemons, System Data, System Groups (MobileGestalt, Profiles), Safety Backups.
   - Nhập đường dẫn bất kỳ (Go to Path).
   - Tốc độ mở container tăng gấp 30 lần (chỉ ~1s thay vì chờ 30 giây như trước).
   - **Trình xem & chỉnh sửa đa năng**:
     - *Plist Viewer & Editor*: Duyệt cây Key-Value, chỉnh sửa giá trị trực tiếp.
     - *Text Editor*: Sửa file văn bản và lưu trực tiếp an toàn.
     - *Hex Viewer*: Soi mã hex từng byte với offset và ASCII representation.
     - *QuickLook*: Xem trước ảnh, âm thanh, video, file nén.
   - Tự động sao lưu file vào `Documents/Backups` trước khi sửa hoặc xóa để khôi phục khi cần.

---

## 📱 Supported Versions / Phiên bản hỗ trợ

- **iOS / iPadOS 17.0 – 27.2** (Hỗ trợ đầy đủ tất cả tính năng bao gồm MobileGestalt).
- **iOS / iPadOS 16.0 – 16.7.x** (Hỗ trợ dọn dẹp cache, duyệt file và một số tweak; tính năng MobileGestalt có thể bị giới hạn do cơ chế sandbox trên iOS 16).

---

## 🛠 Building & Installation / Hướng dẫn Build

### Yêu cầu:
- macOS với Xcode 15 trở lên (hoặc macOS Command Line Tools với `clang`/`swiftc`).
- Có cài đặt `ldid` hoặc chứng chỉ codesign.

### Cách 1: Build bằng script tự động
```bash
git clone https://github.com/hoanmaster321/ErosionWQ.git
cd ErosionWQ
chmod +x build.sh ipabuild.sh

# Build file IPA hoàn chỉnh
./build.sh
```

### Cách 2: Mở bằng Xcode
1. Mở `Erosion.xcodeproj` trong Xcode.
2. Chọn target `Erosion` và thiết bị đích `Any iOS Device (arm64)`.
3. Nhấn **Product** -> **Archive** hoặc chạy script `./ipabuild.sh`.

---

## 📲 Sideloading & App Group Note / Hướng dẫn cài đặt

Kỹ thuật `worse_query` yêu cầu ứng dụng phải giữ quyền **App Group**. Khi sideload bằng các công cụ bên dưới, hãy đảm bảo giữ nguyên entitlement App Group:

- **TrollStore**: Khuyên dùng (nếu thiết bị hỗ trợ). Cài trực tiếp file `.ipa`, toàn quyền truy cập.
- **AltStore / SideStore**: Bật tùy chọn giữ App Groups.
- **Sideloadly**: Bật *App Groups Support* trong cài đặt nâng cao.
- **Feather / Scarlet**: Sideload bình thường bằng chứng chỉ nhà phát triển (Development / Distribution certificate).

---

## 📂 Project Structure / Cấu trúc thư mục

```
ErosionWQ/
├── build.sh                      # Script build tự động dòng lệnh
├── ipabuild.sh                   # Script đóng gói IPA với xcodebuild & ldid
├── PreviewIcon.png               # Icon ứng dụng
├── icons/                        # Bộ biểu tượng app các kích cỡ
├── Erosion.xcodeproj/            # Xcode Project cấu hình iOS 17.0+
└── Erosion/
    ├── bridge.h                  # Header cầu nối Swift <-> C/Obj-C
    ├── ErosionApp.swift          # Điểm khởi chạy app với 5 Tabs
    ├── ContentView.swift         # Tab 1: Dashboard & Live Terminal
    ├── Erosion.entitlements      # Entitlements hỗ trợ các App Group
    ├── Info.plist                # Khai báo quyền, document viewer
    ├── App/
    │   ├── AppsManagerView.swift # Tab 3: Trình quản lý App & Backup
    │   ├── CacheCleanerView.swift# Tab 4: Dọn dẹp cache & crash logs
    │   ├── ButtonStyles.swift    # Giao diện nút bấm
    │   ├── LogView.swift         # Terminal console platter
    │   └── SettingsView.swift    # Cài đặt ứng dụng
    ├── Tweaks/                   # Tab 2: Tinh chỉnh hệ thống
    │   ├── MobileGestalt/        # Dynamic Island, 80% charge, internal storage
    │   ├── PosterBoard/          # Custom wallpapers
    │   ├── Keypads/              # Giao diện bàn phím cuộc gọi
    │   └── Other/                # Supervision & Operations
    ├── FileManager/              # Tab 5: Trình duyệt file
    │   ├── FMRootView.swift      # Màn hình bookmark các container
    │   ├── Browser/              # FileBrowserView, FileRow, FolderRow
    │   ├── Helpers/              # FileHelpers, InfoHelpers
    │   └── Viewers/              # PlistViewer, TextViewer, HexViewer
    └── WQCore/                   # Nhân xử lý WQFiles & Inode engine
        ├── WQAccess.h            # C APIs cho worse_query, fsgetpath, lsd
        ├── WQAccess.m            # Core filesystem driver & backup engine
        └── WQEngine.swift        # Swift service kết nối UI và WQAccess
```

---

## 🛡 License & Credits

Dự án phát hành theo giấy phép **GNU General Public License v3.0 (GPL-3.0)**.

- **[lunginspector](https://github.com/lunginspector)**: Tác giả chính của dự án Erosion.
- **[kolbicz](https://github.com/kolbicz)**: Tác giả của WQFiles (App data manager, cache cleaner, LaunchServices integration).
- **[forcequit (Taj C)](https://github.com/forcequitOS)** & **[0xjohnny](https://github.com/0xjohnnydev)**: Khám phá và xây dựng kỹ thuật sandbox escape `worse_query` / `bad_query`.
- **[murk-sus](https://github.com/murk-sus)**: Kỹ thuật quét inode `fsgetpath` (KAMUI).
- **[Skadz](https://github.com/skadz108)** & **[rooootdev](https://github.com/rooootdev)**: Triển khai exploit và các tiện ích backend Erosion.
- **[neonmodder123](https://github.com/neonmodder123)**: Kỹ thuật respring qua WebView.
