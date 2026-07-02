# D-Trade Capital 📈

<p align="center">
  <img src="assets/images/logo.jpeg" alt="D-Trade Capital Logo" width="120"/>
</p>

<p align="center">
  <b>Institutional-Grade Trading Terminal — Built with Flutter</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.5%2B-02569B?logo=flutter&logoColor=white"/>
  <img src="https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase&logoColor=white"/>
  <img src="https://img.shields.io/badge/Version-1.0.0-gold"/>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey"/>
  <img src="https://img.shields.io/badge/License-MIT-blue"/>
</p>

---

## 📌 About D-Trade Capital

**D-Trade Capital** is a professional-grade, mobile-first trading terminal designed for serious traders and investors. Built with Flutter and powered by Supabase, it combines real-time market data, AI-driven signals, and a sleek dark-themed UI to deliver an institutional-quality trading experience — right in your pocket.

Whether you're a crypto trader, stock investor, or forex analyst, D-Trade Capital brings together everything you need: live charts, curated signals, paper trading simulation, portfolio tracking, and a full account management suite — all in one app.

> **"Trade smarter. Not harder."**

---

## ✨ Key Features

### 📊 Live Trading Interface
- Real-time tickers: **BTC/USD, ETH/USD, XAU/USD, SPX, NASDAQ, Forex pairs**
- Interactive **candlestick charts** with live price updates
- **BUY / SELL execution** with configurable Lot size, Stop Loss & Take Profit
- WebSocket-powered live price feeds

### 🤖 AI Market Intelligence
- **AI-driven alerts** for high-probability trade setups
- **Signals Hub** — curated signals across CRYPTO, STOCKS & FOREX
- **Intelligence View** — sentiment analysis and market deep-dives

### 🧪 Paper Trading Simulator
- Risk-free practice with **virtual funds and real market prices**
- Full trade history with **P&L tracking**
- Account balance management and progression tracking

### 💳 Account & Payments
- Google Sign-In and Email/Password authentication via Supabase
- **UPI, Crypto, and Card payment** flows for subscriptions
- Secure profile management with avatar upload

### 📓 Trading Journal
- Log your trades with notes and performance analysis
- Calendar-based trade history view
- Track habits and discipline over time

---

## 🛠️ Technology Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter (SDK ^3.5.0) |
| **State Management** | Flutter Riverpod ^2.4.0 |
| **Backend / Auth / DB** | Supabase Flutter ^2.0.0 |
| **Routing** | Go Router ^12.0.0 |
| **Charts** | fl_chart, candlesticks |
| **Networking** | Dio ^5.0.0 |
| **Real-time** | Socket.IO Client ^2.0.3 |
| **Storage** | Flutter Secure Storage ^9.0.0 |
| **Fonts** | Google Fonts ^8.1.0 |
| **Auth** | Google Sign-In ^6.2.1 |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK >= 3.5.0
- Android Studio / VS Code with Flutter & Dart extensions
- Supabase project configured
- `.env` file (see below)

### Installation

**1. Clone the repository**
```bash
git clone https://github.com/dtradecapital/D-terminal-app.git
cd D-terminal-app
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Configure environment**

Create `assets/env` file in the project root:
```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

**4. Run the app**
```bash
flutter run
```

---

## 📦 Play Store Deployment Guide

Follow these steps to deploy D-Trade Capital as a production app on the Google Play Store.

### Step 1 — Register on Google Play Console

1. Go to [play.google.com/console](https://play.google.com/console)
2. Sign in and pay the **one-time $25 developer registration fee**
3. Complete account setup (name, email, address)

### Step 2 — Prepare the App

Update `android/app/build.gradle`:
```gradle
defaultConfig {
    applicationId "com.dtradecapital.app"   // permanent — cannot change after publish
    minSdkVersion 21
    targetSdkVersion 34
    versionCode 1        // increment on every upload
    versionName "1.0.0"
}
```

Update `pubspec.yaml`:
```yaml
version: 1.0.0+1   # name+code
```

### Step 3 — Generate a Signing Keystore

```powershell
keytool -genkey -v -keystore dtrade-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias dtrade
```

> ⚠️ **Never commit** `.jks` or `key.properties` to GitHub. Add them to `.gitignore`.

Create `android/key.properties`:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=dtrade
storeFile=dtrade-release-key.jks
```

Update `android/app/build.gradle` to use signing config:
```gradle
def keystoreProperties = new Properties()
keystoreProperties.load(new FileInputStream(rootProject.file('key.properties')))

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

### Step 4 — Build the Release Bundle

```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### Step 5 — Create App on Play Console

1. Click **"Create app"** on Play Console
2. Fill: App name → `D-Trade Capital`, Language → English, Type → App
3. Agree to policies → Click **"Create app"**

### Step 6 — Fill Store Listing

Navigate to **Grow → Store presence → Main store listing**:

| Field | Value |
|---|---|
| App name | D-Trade Capital |
| Short description | Professional stock & crypto trading terminal (≤ 80 chars) |
| Full description | Up to 4000 chars describing all features |
| App icon | 512×512 PNG (no transparency) |
| Feature graphic | 1024×500 PNG or JPG |
| Screenshots | Min 2 phone screenshots |

### Step 7 — Complete Required Policies

- **Content Rating**: Go to `Policy → App content → Content rating` → Select **Finance** category → Submit questionnaire
- **Data Safety**: Declare data collected (email, financial info, device ID) and your Privacy Policy URL
- **App Access**: Provide demo credentials for reviewers if login is required
- **Target Audience**: Set 18+ (financial / trading app)

### Step 8 — Upload & Release

1. Go to **Release → Production → Create new release**
2. Upload `app-release.aab`
3. Add release notes:
   ```
   Version 1.0.0 — Initial Release
   • Live market data and candlestick charts
   • AI-powered trading signals
   • Paper trading simulator
   • Trading journal
   • Secure account management
   ```
4. Click **"Review release"** → resolve any warnings
5. Click **"Start rollout to Production"** (recommend 20% staged rollout first)

### Step 9 — After Publishing

| Action | Tool |
|---|---|
| Monitor crashes | Android Vitals in Play Console |
| Track installs | Statistics dashboard |
| Respond to reviews | Reviews section |
| Push updates | Increment `versionCode`, build new AAB, upload |

---

## 📁 Project Structure

```
dtrade/
├── lib/
│   ├── core/              # Providers, themes, constants
│   ├── screens/           # All screen views
│   │   ├── trading_view.dart
│   │   ├── account_view.dart
│   │   ├── auth_gate.dart
│   │   └── ...
│   ├── services/          # API and data services
│   │   └── chart_service.dart
│   └── widgets/           # Reusable UI components
│       ├── live_candle_chart.dart
│       └── trading_journal.dart
├── assets/
│   ├── images/            # App images and logo
│   └── env                # Environment configuration
├── android/               # Android-specific config
└── pubspec.yaml
```

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m 'Add your feature'`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

---

## 📜 License

Distributed under the **MIT License**.

---

<p align="center">
  Developed with ❤️ by <b>D-Trade Capital Team</b><br/>
  <a href="https://github.com/dtradecapital/D-terminal-app">GitHub</a> · Version 1.0.0
</p>
