# 🔍 Network Scanner App

A powerful and intuitive Flutter-based LAN scanner that detects and categorizes devices connected to your local network. It highlights potential IoT or smart devices using customizable keyword filtering.

---

## 🚀 Features

- 🔎 Scans all pingable devices on the local Wi-Fi network.
- 🧠 Classifies devices based on hostname patterns (e.g., Android, Windows, macOS, Routers).
- 🎯 Keyword matching to detect devices like `camera`, `iot`, `smart`, etc.
- 📑 Displays hostnames, IP addresses, OS types, and visual device icons.
- 🧰 Filter toggle to view only matched devices.
- 🧾 Easy customization of keywords via a YAML config file.

---

## 📦 Dependencies

Ensure the following dependencies are added in your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  network_tools: ^2.0.0
  network_info_plus: ^4.0.0
  yaml: ^3.1.1
````

---

## 🛠️ Setup & Installation

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/network_scanner_flutter.git
cd network_scanner_flutter
```

### 2. Install packages

```bash
flutter pub get
```

### 3. Add keyword configuration

Create the file:

```yaml
# assets/keywords.yaml
keywords:
  - camera
  - iot
  - sensor
  - smart
  - test
```

Then in your `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/keywords.yaml
```

### 4. Run the app

```bash
flutter run
```

---

## 🧠 Keyword Matching Logic

* Hostnames are scanned for presence of configured keywords.
* Devices with matching hostnames are:

  * Visually highlighted.
  * Labeled with the matched keyword.
  * Filterable using the **Filter Keywords** toggle.

---

## 📂 Project Structure

```
lib/
├── main.dart         # Main app logic
assets/
└── keywords.yaml     # List of keywords used to match device hostnames
```

---

## 🔐 Required Android Permissions

Ensure the following permissions are added in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
```

---

## ⚠️ Notes

* Works best on real devices connected to Wi-Fi.
* Hostname resolution depends on the router's capability.
* Keyword matching is **case-insensitive** and configurable.

---

## 📃 License

This project is licensed under the [MIT License](LICENSE).

---
