<div align="center">
  <br>
  <img src="PreviewIcon.png" alt="ErosionWQ Icon" width="130" style="border-radius: 28px;">
  <br>
  <h1>ErosionWQ (ThaiBinh)</h1>
  <p><strong>The Ultimate iOS Customization Toolbox, Theme Studio, App Data Manager & Cache Cleaner</strong></p>
  <p>Sự kết hợp toàn diện giữa <a href="https://github.com/jailbreakdotparty/Erosion">Erosion</a> và <a href="https://github.com/kolbicz/WQFiles">WQFiles</a>, vận hành trên kỹ thuật vượt sandbox <code>worse_query</code> & bộ quét inode <code>fsgetpath</code>.</p>

  <p>
    <a href="https://github.com/hoanmaster321/ThaiBinh/actions"><img alt="GitHub Actions Build" src="https://github.com/hoanmaster321/ThaiBinh/actions/workflows/build.yml/badge.svg"></a>
    <img alt="iOS Support" src="https://img.shields.io/badge/iOS-17.0%20--%2027.2-007AFF?style=flat-square&logo=apple">
    <img alt="License" src="https://img.shields.io/badge/License-GPL%203.0-green?style=flat-square">
    <img alt="Language" src="https://img.shields.io/badge/Language-Swift%205.10%20%2F%20Obj--C-FA7343?style=flat-square&logo=swift">
    <img alt="Status" src="https://img.shields.io/badge/Status-Production%20Ready-brightgreen?style=flat-square">
  </p>
</div>

---

## 🌟 Tổng quan / Overview

**ErosionWQ (ThaiBinh)** hợp nhất toàn bộ bộ công cụ tinh chỉnh hệ thống của **Erosion** (`jailbreakdotparty`) và trình quản lý dữ liệu ứng dụng, dọn dẹp bộ nhớ đệm, duyệt file siêu tốc của **WQFiles** (`kolbicz`) vào một ứng dụng duy nhất. Ứng dụng hoạt động trực tiếp trên thiết bị (**on-device**), **không cần jailbreak** và **không cần kernel exploit**, sử dụng kỹ thuật `worse_query` (phiên bản kế nhiệm trực tiếp của `bad_query`).

---

## 🔓 Phạm vi quyền truy cập MCM của `worse_query`

Kỹ thuật `worse_query` yêu cầu ứng dụng được ký kèm quyền **App Group** để xin sandbox token từ `containermanagerd`. Toàn bộ các tính năng trong **ErosionWQ** được thiết kế chuẩn xác để đọc/ghi vào **6 nhánh MCM Container** mà `worse_query` hỗ trợ trên iOS 17.0 – 27.2:

1. `/var/containers/Data/System` *(iOS 27)*
2. `/var/containers/Shared/SystemGroup/*` *(iOS 27 — MobileGestalt, ConfigurationProfiles, lsd.iconscache, SpringBoard.sharedsettings, searchpartyd...)*
3. `/var/mobile/Containers/Data/Application/*` *(PosterBoard, MobilePhone, Passbook/Wallet, MobileSafari và toàn bộ ứng dụng cài đặt)*
4. `/var/mobile/Containers/Data/InternalDaemon/*` *(Các tiến trình hệ thống nội bộ)*
5. `/var/mobile/Containers/Data/PluginKitPlugin/*` *(Widgets, WallpaperKit Extensions, ControlKit Extensions)*
6. `/var/mobile/Containers/Shared/AppGroup/*` *(Dữ liệu dùng chung giữa App & Extension)*

---

## 🚀 Các tính năng chính (5 Tabs & Studios)

### 1. 🏠 Dashboard & Chẩn đoán Thiết bị (Home)
- Hiển thị tên thương mại thiết bị, mã máy và bản dựng kernel iOS (ví dụ: `iPhone 16 Pro Max (iPhone17,2) · iOS 27.0.1 (24A446)`).
- Kiểm tra trạng thái **App Group** đang hoạt động (`wq_app_group`).
- Thống kê trực tiếp dung lượng bộ nhớ máy (Đang dùng / Còn trống) và tổng dung lượng các bản sao lưu an toàn.
- **Respring 1 chạm** qua SpringBoard WebView renderer.
- **Live Console Logs**: Truyền tải trực tiếp toàn bộ log hệ thống và log thao tác `wq_log` (`[wq] ...`) theo thời gian thực.

### 2. 🎨 Trung tâm Tinh chỉnh & Theme Studio (Tweaks)
- **Theme & Visual Mods Studio (`ThemeStudioView`)**:
  - **Wallet / Passbook Card Skins**: Tự động quét container `com.apple.Passbook` và cho phép thay ảnh nền thẻ `.pkpass` (`cardBackgroundCombined@2x.png`, `background@2x.png`, `strip@2x.png`) bằng bất kỳ ảnh nào từ Thư viện ảnh (tự động backup ảnh gốc).
  - **PosterBoard Wallpaper Descriptors**: Liệt kê các bộ cung cấp hình nền trong `PRBPosterExtensionDataStore` (`CollectionsPoster`, `MercuryPoster`, `PhotosPosterProvider`, `WeatherPoster`, `EmojiPoster`...) để chỉnh sửa sâu.
  - **Safari & SystemGroup Icon Cache**: Chỉnh sửa nhanh `com.apple.mobilesafari.plist` và quản lý/xóa bộ nhớ đệm icon `systemgroup.com.apple.lsd.iconscache`.
- **Dialer Keypad Studio (`KeypadView`)**:
  - Tùy biến bàn phím quay số trong container `com.apple.mobilephone` (`TelephonyUI-10` / `TelephonyUI-9` / `TelephonyUI-8`).
  - **6 Bộ Theme Bàn phím tạo sẵn 1 chạm (Built-in Themes)**: *Neon Cyber*, *Matrix Hex (`0x01`..`0x09`)*, *Gold Royal*, *Roman Numerals (`I`..`IX`)*, *Pastel Glass*, *Minimal Ring*, hoặc tự chọn ảnh / nhập gói theme `.zip`.
- **Custom Wallpapers (`PosterBoardView`)**:
  - Nhập và áp dụng các gói hình nền động `.tendies` vào `com.apple.PosterBoard`.
- **SpringBoard, PosterBoard & SystemGroup Studio (`SpringBoardTweaksView`)**:
  - Tùy chỉnh chữ dưới đáy màn hình khóa (**Lock Screen Footnote**) và thông tin thiết bị (**Asset Tag**) trong `SharedDeviceConfiguration.plist`.
  - Tắt âm chụp ảnh Camera (`RegionalBehaviorShutterClick` = `0`) cho máy Nhật/Hàn.
  - **1-Tap Back Up & Restore Lock Screen Posters**: Sao lưu và khôi phục toàn bộ cấu hình màn hình khóa của `com.apple.PosterBoard`.
  - **Purge & Rebuild Icon Cache**: Xóa sạch cache trong `systemgroup.com.apple.lsd.iconscache` để làm mới biểu tượng ứng dụng.
- **MobileGestalt Hardware Flags (`GestaltView`)**:
  - Bật **Dynamic Island** (kèm chỉnh Subtype), **Always On Display (AOD)**, **Giới hạn sạc 80% (Charge Limit)**, **Boot Chime**, **Stage Manager & iPadOS UI**, **Action Button UI**, **Camera Control UI**, **Tap to Wake**, **Spoof Model (Apple Intelligence)**.
- **Custom File Overwrite & Presets (`OperationsView`)**:
  - Tích hợp danh sách Preset các đường dẫn `SystemGroup` quan trọng để ghi đè/xuất file nhanh chóng kèm cơ chế tự động sao lưu.

### 3. 📦 Quản lý Dữ liệu Ứng dụng (App Manager)
- Quét siêu tốc toàn bộ ứng dụng trong `/var/mobile/Containers/Data/Application` bằng `fsgetpath` và giải mã tên + biểu tượng thực tế từ cơ sở dữ liệu `LaunchServices` (`lsd`).
- **Multi-Snapshot Backup Manager**: Tạo nhiều bản sao lưu theo mốc thời gian (`Documents/AppBackups/<bundleID>/<timestamp>`), xem dung lượng từng bản, chọn khôi phục bất kỳ mốc thời gian nào hoặc xóa bản cũ.
- **Import & Share Backup (`.zip`)**: Xuất bản sao lưu ra file `.zip` qua AirDrop/Files hoặc **Nhập file `.zip` sao lưu từ ngoài vào** để khôi phục dữ liệu giữa các thiết bị.
- **1-Tap Edit App Preferences (`.plist`)**: Mở thẳng file `<Container>/Library/Preferences/<bundleID>.plist` (`UserDefaults`) vào trình sửa Plist chỉ với 1 chạm.
- **Clear App Data**: Đặt lại ứng dụng về trạng thái mới cài đặt (có tùy chọn tự động sao lưu trước khi xóa).

### 4. 🧹 Dọn dẹp Bộ nhớ đệm (Cache Cleaner)
- Quét sạch `Library/Caches` và `tmp` trên cả 4 nhánh MCM (`Application`, `PluginKitPlugin`, `InternalDaemon`, `AppGroup`) cùng với `lsd.iconscache` và `osanalyticsdiagnostics` trong `SystemGroup`.
- Bộ lọc chọn nhanh: *Select All*, *Large (>50 MB)*, *None*, kèm thanh tìm kiếm và báo cáo chính xác dung lượng giải phóng.

### 5. 📁 Trình duyệt File chuyên sâu (File Browser)
- Bookmark truy cập nhanh tất cả các nhánh MCM Container, kèm hiển thị icon & tên ứng dụng trực tiếp trên từng thư mục UUID.
- Tự động dò tìm các container hệ thống trong `/var/containers/Shared/SystemGroup` trên iOS 27.0.1+ (`wq_known_system_groups`).
- **Bộ công cụ xem & sửa file mạnh mẽ**:
  - **Plist Viewer & Raw XML Editor**: Sửa dạng cây Key-Value hoặc chuyển sang sửa mã XML trực tiếp (tự động giải mã Binary Plist `bplist00` sang XML và đóng gói lại đúng định dạng gốc khi lưu).
  - **Text Editor & Hex Viewer**: Xem/sửa văn bản và soi mã Hex từng byte.
  - **Đổi tênFile/Thư mục nâng cao (`wq_rename`)**: Hỗ trợ đổi tên trực tiếp hoặc tự động fallback copy+unlink an toàn trong môi trường sandbox.
  - **1-Tap File Restore**: Tự động sao lưu mọi file bị ghi đè/xóa vào `Documents/Backups`, kèm nút **"Restore to Original Path"** ngay trong menu nhấn giữ để hoàn tác về đúng vị trí gốc.

---

## 🛠 Hướng dẫn Build & Cài đặt

### Tự động qua GitHub Actions (Khuyên dùng)
Mỗi lần push code lên nhánh `main`, workflow [`.github/workflows/build.yml`](.github/workflows/build.yml) sẽ tự động biên dịch bằng Xcode trên `macos-latest`, ký giả bằng `ldid` kèm `Erosion.entitlements` và xuất bản file **`ErosionWQ.ipa`** trong mục **Actions -> Artifacts**.

### Build thủ công trên macOS
```bash
git clone https://github.com/hoanmaster321/ThaiBinh.git
cd ThaiBinh
chmod +x build.sh ipabuild.sh

# Build ra gói ứng dụng và đóng gói IPA
./ipabuild.sh
```

### Lưu ý khi Sideload
Hãy đảm bảo công cụ sideload của bạn (**SideStore**, **AltStore**, **Sideloadly**, **Feather**, **TrollStore** hoặc chứng chỉ Apple Developer) **giữ nguyên quyền App Group (`com.apple.security.application-groups`)** để `worse_query` có thể kích hoạt.

---

## 📂 Cấu trúc Mã nguồn

```
ThaiBinh/
├── .github/workflows/build.yml   # CI/CD tự động build IPA trên GitHub Actions
├── build.sh / ipabuild.sh        # Script build dòng lệnh & đóng gói IPA
├── Erosion.xcodeproj/            # Xcode Project (Deployment Target: iOS 17.0+)
└── Erosion/
    ├── bridge.h                  # Cầu nối Objective-C / C sang Swift
    ├── ErosionApp.swift          # Giao diện chính 5 Tabs
    ├── ContentView.swift         # Tab 1: Home Dashboard, Storage & Live Console
    ├── Erosion.entitlements      # Khai báo quyền App Group
    ├── App/
    │   ├── AppsManagerView.swift # Tab 3: App Manager, Multi-Snapshot, ZIP Import & Prefs Editor
    │   ├── CacheCleanerView.swift# Tab 4: MCM Cache & Diagnostics Cleaner
    │   ├── LogView.swift         # Màn hình Terminal thời gian thực
    │   └── SettingsView.swift    # Cài đặt chung
    ├── Tweaks/                   # Tab 2: Trung tâm Tinh chỉnh & Theme
    │   ├── TweaksView.swift      # Menu điều hướng Tweaks
    │   ├── ThemeStudio/          # Mod Skin thẻ Wallet, PosterBoard Descriptors, Safari & Icon Cache
    │   ├── SpringBoard/          # Lock Screen Footnote/AssetTag, Shutter Mute, Poster Backup
    │   ├── Keypads/              # Dialer Keypad Themer + 6 Built-in Procedural Themes
    │   ├── MobileGestalt/        # Dynamic Island, AOD, Charge Limit, Stage Manager, Spoofing
    │   ├── PosterBoard/          # Trình cài đặt hình nền .tendies
    │   └── Other/                # Supervision, LockScreen Config & Preset File Operations
    ├── FileManager/              # Tab 5: Trình duyệt File MCM
    │   ├── FMRootView.swift      # Bookmark các nhánh MCM Container & Safety Backups
    │   ├── Browser/              # FileBrowserView, FileRow (1-Tap Restore), FolderRow
    │   ├── Helpers/              # FileHelpers & FileItemHelpers tích hợp sâu WQAccess
    │   └── Viewers/              # PlistViewer (Tree + XML), TextViewer (Binary Plist), HexViewer
    └── WQCore/                   # Nhân xử lý WQFiles & worse_query
        ├── WQAccess.h            # Header C/Obj-C APIs
        ├── WQAccess.m            # Engine worse_query, fsgetpath, lsd parser, auto-backup & rename
        └── WQEngine.swift        # ObservableObject quản lý trạng thái toàn cục
```

---

## 🛡 Bản quyền & Ghi nhận (Credits)

Phát hành theo giấy phép **GNU General Public License v3.0 (GPL-3.0)**.
- **[jailbreakdotparty / lunginspector](https://github.com/jailbreakdotparty/Erosion)**: Dự án gốc Erosion.
- **[kolbicz](https://github.com/kolbicz/WQFiles)**: Dự án gốc WQFiles.
- **[forcequit (Taj C)](https://github.com/forcequitOS/worse_query)** & **[0xjohnny](https://github.com/0xjohnnydev)**: Kỹ thuật vượt sandbox `worse_query` / `bad_query`.
- **[murk-sus](https://github.com/murk-sus)**: Kỹ thuật quét inode `fsgetpath` (KAMUI).
