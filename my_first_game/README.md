# my_first_game

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## How to work

```bash
flutter run -d chrome 
```

```bash
開発中の起動(ホットリロード付き)
flutter run -d chrome   # ブラウザで確認
flutter run -d macos    # macOSデスクトップアプリとして確認
flutter run              # 接続中の実機/シミュレータを選択

本番ビルド
flutter build apk           # Android APK
flutter build appbundle     # Android App Bundle(Playストア提出用)
flutter build ios           # iOS(要Xcode、実機は署名が必要)
flutter build web           # Web用静的ファイル一式(build/web/)
flutter build macos         # macOSアプリ
```