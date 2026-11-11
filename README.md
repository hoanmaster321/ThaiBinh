<div align="center">
  <br>
  <img src="PreviewIcon.png" alt="ErosionWQ Icon" width="130" style="border-radius: 28px;">
  <br>
  <h1>Thái Bình (ErosionWQ)</h1>
  <p><strong>Bộ Công Cụ Tinh Chỉnh iOS, Xưởng Theme, Quản Lý Dữ Liệu Ứng Dụng, Dọn Rác & Trung Tâm Giải Trí Mini Games</strong></p>
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

## 🚀 Các tính năng chính (6 Tabs & Studios)

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

### 3. 📦 Quản lý Dữ liệu Ứng dụng (App Manager — WQFiles v0.9)
- **Liệt kê Container siêu tốc từ LaunchServices DB (`WQLaunchServices`)**: Hỗ trợ 8 cấu trúc bản ghi `CSStore2` trên **iOS 26.x (`26`, `26.5`, `26.5b`), 27.0, 27.2 (`27.2`, `27.2b`, `27.2c`, `27.2d`)**, tự động từ chối cơ sở dữ liệu nếu layout chỉ ánh xạ được dưới 50% container (`#37`), dò ngược từ inode mới nhất (`wq_scan_for_ls_store`) để tìm cơ sở dữ liệu `com.apple.LaunchServices-*.csstore` chỉ trong vài giây mà không cần quét toàn bộ ổ đĩa, đồng thời tự động ánh xạ Bundle ID cho container trên iOS 27.2 và tải trực tiếp icon PNG từ gói `.app` trên iOS 26.
- **Bộ lọc Hiển thị Ứng dụng (`#28`) & Thanh chỉ mục chữ cái A–Z**: Lọc nhanh theo *Tất cả ứng dụng*, *Ứng dụng Apple*, *Ứng dụng bên thứ 3*, hoặc *Đã có Sao lưu*; khi sắp xếp theo tên ứng dụng, hiển thị thanh nhảy nhanh A–Z bên cạnh phải.
- **Menu nhấn giữ Ứng dụng (`#27`) & Khôi phục từ AppBackups**: Nhấn giữ ứng dụng bất kỳ để **Sao chép Bundle ID**, **Sao chép Đường dẫn Container**, **Mở thư mục Dữ liệu**, hoặc nhấn giữ trực tiếp thư mục trong `AppBackups` để **Khôi phục bản Sao lưu**.
- **Multi-Snapshot Backup Manager**: Tạo nhiều bản sao lưu theo mốc thời gian (`Documents/AppBackups/<bundleID>/<timestamp>`), xem dung lượng từng bản, chọn khôi phục bất kỳ mốc thời gian nào hoặc xóa bản cũ.
- **Import & Share Backup (`.zip`)**: Xuất bản sao lưu ra file `.zip` qua AirDrop/Files hoặc **Nhập file `.zip` sao lưu từ ngoài vào** để khôi phục dữ liệu giữa các thiết bị.
- **1-Tap Edit App Preferences (`.plist`)**: Mở thẳng file `<Container>/Library/Preferences/<bundleID>.plist` (`UserDefaults`) vào trình sửa Plist chỉ với 1 chạm.
- **Clear App Data**: Đặt lại ứng dụng về trạng thái mới cài đặt (có tùy chọn tự động sao lưu trước khi xóa).

### 4. 🧹 Dọn dẹp Bộ nhớ đệm (Cache Cleaner)
- Quét sạch `Library/Caches` và `tmp` trên cả 4 nhánh MCM (`Application`, `PluginKitPlugin`, `InternalDaemon`, `AppGroup`) cùng với `lsd.iconscache` và `osanalyticsdiagnostics` trong `SystemGroup` (tự động gỡ cờ khóa `UF_IMMUTABLE | UF_APPEND` khi gặp `EPERM` - `#8`).
- Bộ lọc chọn nhanh: *Chọn tất cả*, *Lớn (>50 MB)*, *Bỏ chọn*, kèm thanh tìm kiếm và báo cáo chính xác dung lượng giải phóng.

### 5. 📁 Trình duyệt File chuyên sâu, Tô màu Cú pháp, Media Player & SQLite (File Browser — WQFiles v0.9)
- **Chọn nhiều mục (`Select`), Di chuyển liên ứng dụng (`Move Here`) & Nén/Giải nén ZIP (`WQArchive`)**:
  - Nhấn **Chọn** ở góc phải trên để chọn nhiều tệp/thư mục cùng lúc và thực hiện **Di chuyển (`Move`)**, **Nén ZIP (`Compress`)** hoặc **Xóa (`Delete`)** (`#9`).
  - **Di chuyển dữ liệu xuyên ứng dụng (`wq_move`)**: Chọn tệp/thư mục, mở bất kỳ thư mục nào của ứng dụng khác và nhấn **Di chuyển vào đây (`Move Here`)** (an toàn tuyệt đối, không bao giờ ghi đè tệp đã tồn tại).
  - **Nén & Giải nén ZIP an toàn (`WQArchive`)**: Nén trực tiếp qua `WQAccess` và giải nén tệp `.zip` (hỗ trợ cả ZIP64, kiểm tra CRC32, chặn đường dẫn thoát thư mục và bỏ qua symlink).
  - **Nhập nhiều tệp cùng lúc hoặc Nhập cả thư mục (`#23`)**: Tự động đánh số thứ tự (`"Tên 2"`) nếu trùng tên thay vì ghi đè.
- **Hiển thị Bundle ID dưới tên ứng dụng (`#27`) & Đếm số lượng mục con (`#35`)**:
  - Danh sách container hiển thị trực tiếp Bundle ID dưới tên ứng dụng thay vì mã UUID của thư mục.
  - Tùy chọn **Hiển thị số lượng mục trong thư mục (`Show Item Counts`)** tải số mục con ở chế độ nền và hiển thị trực tiếp.
- **Tùy chọn Cho phép Xóa dữ liệu (`Allow Deleting` - `#32`)**: Khi tắt, khóa toàn bộ thao tác xóa tệp, vuốt trái để xóa (`#36`), xóa dữ liệu ứng dụng và dọn rác.
- **Bộ công cụ xem & sửa file mạnh mẽ**:
  - **Tô màu Cú pháp 17 ngôn ngữ (`WQSyntax` - `#34`)**: Tô màu mã nguồn và dữ liệu trực tiếp khi xem và khi đang chỉnh sửa đối với XML/Plist, JSON, YAML, INI/TOML, CSS, SQL, Markdown, C/Objective-C, Swift, JavaScript/TypeScript, Java/Kotlin, Go, Rust, Python, Shell, Ruby, Lua (tự nhận diện dòng `#!` hoặc nội dung XML/JSON).
  - **Trình phát Đa phương tiện (`MediaPlayerView` - `#25`, `#29`)**: Phát trực tiếp các tệp âm thanh & video (`mp3`, `m4a`, `wav`, `flac`, `mp4`, `mov`…) bằng trình phát hệ thống (hỗ trợ Picture-in-Picture).
  - **Trình xem Cơ sở dữ liệu SQLite (Chỉ đọc, Truy vấn SQL & Xuất CSV - `SQLiteViewer`)**: Tự động nhận diện tệp `.sqlite`, `.db`, `.sqlite3` (hoặc header `SQLite format 3`), mở bản sao tạm thời kèm tệp `-wal` ở chế độ `PRAGMA query_only = ON`, duyệt danh sách bảng & view kèm số dòng, phân trang dữ liệu, xem chi tiết từng dòng, chạy truy vấn `SELECT` / `PRAGMA` / `EXPLAIN` và **Xuất kết quả ra tệp `.csv`**.
  - **Plist Viewer & Raw XML Editor**: Sửa dạng cây Key-Value hoặc chuyển sang sửa mã XML trực tiếp (tự động giải mã Binary Plist `bplist00` sang XML và đóng gói lại đúng định dạng gốc khi lưu).
  - **Text Editor & Hex Viewer**: Xem/sửa văn bản và soi mã Hex từng byte.
  - **Vuốt sang trái để Xóa / Đổi tên (`Swipe Actions` - `#36`) & Sắp xếp nâng cao**: Hỗ trợ vuốt sang trái trên dòng tệp/thư mục để xóa (kèm sao lưu tự động bằng APFS Clone `fclonefileat`) hoặc đổi tên; hỗ trợ tùy chọn **"Thư mục lên đầu"** và sắp xếp theo **Ngày tạo**.
  - **1-Tap File Restore**: Tự động sao lưu mọi file bị ghi đè/xóa vào `Documents/Backups`, kèm nút **"Khôi phục về đường dẫn gốc"** ngay trong menu nhấn giữ.

### 6. 🎮 Trung tâm Giải trí Thái Bình (Mini Games — `MiniGamesView`)
- Tích hợp sẵn **5 tựa game mini cổ điển** hoạt động mượt mà không cần mạng, kèm phản hồi xúc giác (`Haptic`) và tự động lưu kỷ lục điểm số (`@AppStorage`):
  1. **2048 Thái Bình (`Game2048View`)**: Bàn cờ 4×4 hỗ trợ thao tác vuốt hoặc phím điều hướng, hoàn tác nước đi (`Undo`) và lưu kỷ lục.
  2. **Rắn Săn Mồi (`SnakeGameView`)**: Lưới 15×15 với 3 mức tốc độ (*Chậm*, *Chuẩn*, *Siêu tốc*), hỗ trợ vuốt + phím D-Pad và tạm dừng.
  3. **Dò Mìn Cổ Điển (`MinesweeperGameView`)**: Bãi mìn 9×9 (10 quả mìn), đảm bảo an toàn ở lượt chạm đầu tiên, tự động mở lan vùng trống và chuyển đổi nhanh giữa chế độ **⛏️ Mở ô** / **🚩 Cắm cờ** (hoặc nhấn giữ để cắm cờ).
  4. **Cờ Caro 3×3 & 5×5 (`TicTacToeGameView`)**: Hỗ trợ bàn cờ 3×3 cổ điển hoặc 5×5 mở rộng (4 quân liên tiếp thắng), chế độ **Đấu với Máy (AI thông minh)** hoặc **2 Người chơi cùng máy**.
  5. **Lật Hình Trí Nhớ (`MemoryMatchGameView`)**: Ghép 8 cặp biểu tượng trên bàn 4×4 với bộ đếm lượt lật và kỷ lục ít lượt nhất.

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
