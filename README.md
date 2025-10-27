# VETech Mobile App

A Flutter mobile app for customers to register, manage profile, book veterinary services, manage pets (including QR tag assignment), and view treatment records.

## Features
- Register and Login (token-based auth)
- Dashboard overview (stats, next booking, recent bookings, pets)
- Bookings: list, filter, create, cancel
- Profile: view, edit, change password, delete account
- Pets: list, add, view details, see treatment history
- Assign pet tag by scanning QR code

## Requirements
- Flutter SDK (3.24+)
- A running API backend as per `API_DOCUMENTATION.md`
- Device/emulator with camera access for QR scanning

## Configure API base URL
The default base URL is `http://127.0.0.1:8000/api/v1` in `lib/core/constants.dart`.

- Android Emulator: use `http://10.0.2.2:8000/api/v1`
- iOS Simulator: `http://127.0.0.1:8000/api/v1`
- Real device: use your PC LAN IP, e.g. `http://192.168.1.10:8000/api/v1`

Update:
- `lib/core/constants.dart` -> `AppConstants.baseUrl`

## Run
1. Install dependencies
   ```powershell
   flutter pub get
   ```
2. Run the app on a device/emulator
   ```powershell
   # Mobile (Android/iOS)
   flutter run
   
   # Web browser
   flutter run -d chrome
   
   # Windows desktop
   flutter run -d windows
   ```

## Platform support
- **Android & iOS**: Full support including camera QR scanning
- **Web**: Full support with manual tag code input (QR scanner not available on web)
- **Windows/Linux/macOS**: Full support with manual tag code input## QR Scanner permissions
- **Android**: `android/app/src/main/AndroidManifest.xml` includes camera permission
- **iOS**: `ios/Runner/Info.plist` includes `NSCameraUsageDescription`
- **Web/Desktop**: Camera QR scanning is not supported; manual tag code input is provided instead

## Folders
- `lib/services`: API client and service layer
- `lib/models`: Data models
- `lib/providers`: State management (Provider)
- `lib/screens`: UI screens

## Notes
- IC numbers are normalized (uppercase, dashes removed) before sending
- Date format: YYYY-MM-DD; Time: HH:MM (24h)
- Token is stored securely via `flutter_secure_storage`

## Troubleshooting
- If requests fail on device, verify the base URL and that your backend is reachable from device
- On Android, ensure you use `10.0.2.2` when hitting a server on your host machine
- If QR scanning shows a black screen on Android emulator, try a physical device
- **Web**: Use `127.0.0.1` or `localhost` for the API base URL. Manual tag input will be used instead of camera scanning
- **CORS**: If running on web and hitting API errors, ensure your Laravel backend allows CORS from your web origin

---

This app follows the API documented in `API_DOCUMENTATION.md`.
