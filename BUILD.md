# Hướng dẫn Build APK VPNStore

## 1. Cài Flutter
- Tải: https://docs.flutter.dev/get-started/install/windows
- Giải nén vào C:\flutter
- Thêm C:\flutter\bin vào PATH

## 2. Cài Android Studio + SDK
- Tải: https://developer.android.com/studio
- Cài Android SDK (API 21+)
- Cài Android NDK (dùng cho flutter_v2ray)

## 3. Build APK

```bash
cd C:\Users\Administrator\Downloads\vpnstore_app

# Lấy dependencies
flutter pub get

# Build APK release
flutter build apk --release

# APK xuất ra tại:
# build\app\outputs\flutter-apk\app-release.apk
```

## 4. Ký APK (tuỳ chọn, để publish)

```bash
keytool -genkey -v -keystore vpnstore.keystore -alias vpnstore -keyalg RSA -keysize 2048 -validity 10000
flutter build apk --release --obfuscate --split-debug-info=debug/
```

## Cấu trúc app

- Login → đăng nhập bằng email/password vpnstore.pro.vn
- Home → trạng thái VPN, thông tin gói, dữ liệu đã dùng
- Server List → danh sách node, ping test, chọn server
- Settings → tối ưu TCP (MTU, UDP, DNS, TLS)

## Bảo mật sub link

- App không chứa sub URL trong code
- Đăng nhập bằng user/pass → nhận auth token
- Token lưu mã hoá (obfuscated) trong SharedPreferences
- Nodes fetch qua HTTPS với Authorization header → GFW không quét được
