# NextStation 🚌🗺️

**NextStation** is a smart multimodal public transit application for Alexandria, Egypt. It provides personalized route planning for both formal (trams, buses) and informal (microbuses, tonaya) transport networks with real-time routing, preference-based optimization, and an AI assistant.

![Flutter](https://img.shields.io/badge/Flutter-3.8.1-02569B?logo=flutter)
![Mapbox](https://img.shields.io/badge/Mapbox-Maps-000000?logo=mapbox)
![Dart](https://img.shields.io/badge/Dart-3.8.1-0175C2?logo=dart)

---

## 🌟 Features

- **🗺️ Interactive Map**: Mapbox dark-themed map optimized for Alexandria
- **🔍 Smart Search**: Search for routes between two locations or stops
- **🎛️ Custom Preferences**: Set route preferences (fastest, cheapest, simplest)
- **🚶 Walking Time Control**: Adjust maximum acceptable walking distance
- **🎨 Route Visualization**: Color-coded route segments by transport mode
- **💬 AI Assistant (الأسطى)**: Chat-based help for navigation
- **🌍 Multi-Language**: Supports English and Arabic (RTL)
- **📍 Location Services**: Real-time GPS tracking and current location

---

## 📁 Project Structure

```
nextstation/
│
├── lib/
│   ├── core/                           # Core utilities and configurations
│   │   ├── config/
│   │   │   ├── env_config.dart         # Environment variable loader (API keys)
│   │   │   └── map_config.dart         # Mapbox configuration (camera, styles)
│   │   │
│   │   ├── constants/
│   │   │   ├── app_colors.dart         # Color palette (brand colors, transport modes)
│   │   │   └── app_strings.dart        # App-wide constants and default values
│   │   │
│   │   ├── services/
│   │   │   ├── location_service.dart   # GPS location handling and permissions
│   │   │   └── map_service.dart        # Mapbox map operations (markers, routes)
│   │   │
│   │   └── theme/
│   │       └── app_theme.dart          # Dark theme configuration
│   │
│   ├── features/                       # Feature modules (Clean Architecture)
│   │   └── home/
│   │       └── presentation/
│   │           └── pages/
│   │               └── home_page.dart  # Main map screen with search UI
│   │
│   └── main.dart                       # App entry point
│
├── android/                            # Android-specific configuration
│   └── app/src/main/
│       ├── AndroidManifest.xml         # Permissions (location, internet)
│       └── res/values/
│           └── strings.xml             # Mapbox access token
│
├── ios/                                # iOS-specific configuration
│   └── Runner/
│       └── Info.plist                  # Mapbox token + location permissions
│
├── assets/                             # Asset files (images, icons)
│
├── .env                                # Environment variables (API keys) - NOT in git
├── .gitignore                          # Git ignore rules
├── pubspec.yaml                        # Dependencies and project metadata
└── README.md                           # This file
```

---

## 🏗️ Architecture

### Core Layer (`lib/core/`)
Contains shared utilities, configurations, and services used across the app:

- **config/**: Application configuration (Mapbox settings, environment variables)
- **constants/**: Immutable values (colors, strings, API endpoints)
- **services/**: Reusable services (location, map operations)
- **theme/**: UI theming (dark mode, color schemes)

### Features Layer (`lib/features/`)
Organized by feature modules following Clean Architecture principles:

- **home/**: Main map screen with search functionality
- *(Future: route, preferences, chat, onboarding modules)*

Each feature follows:
```
feature/
├── data/          # API calls, models, repositories
├── domain/        # Business logic, use cases
└── presentation/  # UI (pages, widgets, BLoC)
```

---

## 🎨 Design System

### Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| Primary Teal | `#00BCD4` | Brand color, buttons, active states |
| Search Input BG | `#1B2E35` | Search field backgrounds |
| Background Dark | `#0E1D25` | Main app background |
| Accent Red | `#E53935` | Location pins, alerts |

### Transport Mode Colors

| Mode | Color | Hex |
|------|-------|-----|
| 🚶 Walking | Yellow | `#FFC107` |
| 🚊 Tram | Blue | `#2196F3` |
| 🚐 Microbus | Orange | `#FF9800` |
| 🚌 Bus | Green | `#4CAF50` |
| 🚐 Minibus | Purple | `#9C27B0` |
| 🛺 Tonaya | Pink | `#E91E63` |

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: 3.8.1 or higher
- **Dart SDK**: 3.8.1 or higher
- **Android Studio** / **Xcode** (for mobile development)
- **Mapbox Account**: [Sign up at Mapbox](https://account.mapbox.com/)
- **Google Cloud Account**: For Places API (optional)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/RowanFayez/personalized_trip_planner_flutter.git
   cd nextstation
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables:**
   
   Create a `.env` file in the project root:
   ```env
   MAPBOX_ACCESS_TOKEN=pk.your_mapbox_token_here
   GOOGLE_MAPS_API_KEY=your_google_api_key_here
   API_BASE_URL=http://your-backend-url.com/api
   ```

4. **Configure Mapbox for Android:**
   
   Already configured in `android/app/src/main/res/values/strings.xml`

5. **Configure Mapbox for iOS:**
   
   Already configured in `ios/Runner/Info.plist`

6. **Run the app:**
   ```bash
   flutter run
   ```

---

## 📦 Dependencies

### Core Dependencies
- **mapbox_maps_flutter** `^2.3.0` - Interactive map rendering
- **flutter_dotenv** `^5.2.1` - Environment variable management
- **geolocator** `^13.0.2` - Location services and permissions
- **geocoding** `^3.0.0` - Address ↔ coordinates conversion

### State Management
- **flutter_bloc** `^8.1.6` - BLoC pattern for state management
- **equatable** `^2.0.7` - Value equality for BLoC states

### Networking
- **dio** `^5.7.0` - HTTP client for API calls
- **http** `^1.2.2` - Alternative HTTP client

### UI & Navigation
- **go_router** `^14.6.2` - Declarative routing
- **google_places_flutter** `^2.1.1` - Place search autocomplete
- **flutter_svg** `^2.0.16` - SVG rendering

### Local Storage
- **shared_preferences** `^2.3.3` - Key-value persistent storage

---

## 🔧 Configuration Files

### `.env` (Environment Variables)
**⚠️ IMPORTANT**: Never commit this file to git!

Contains sensitive API keys:
```env
MAPBOX_ACCESS_TOKEN=pk.eyJ1...
GOOGLE_MAPS_API_KEY=AIza...
API_BASE_URL=http://localhost:8000/api
```

### `pubspec.yaml`
Defines project dependencies, assets, and metadata.

Key sections:
- **dependencies**: Runtime packages
- **dev_dependencies**: Development tools
- **flutter.assets**: Asset file paths

### Platform Configuration

**Android** (`android/app/src/main/AndroidManifest.xml`):
- Internet permission
- Location permissions (fine & coarse)
- Mapbox token in `strings.xml`

**iOS** (`ios/Runner/Info.plist`):
- Location usage descriptions (required by Apple)
- Mapbox access token
- Background modes (if needed)

---

## 🗺️ Mapbox Setup

### 1. Get Access Token
1. Sign up at [mapbox.com](https://account.mapbox.com/)
2. Navigate to **Account → Tokens**
3. Copy your **Default Public Token** (starts with `pk.`)

### 2. Configure Scopes
Ensure your token has these scopes:
- ✅ `DOWNLOADS:READ`
- ✅ `MAPS:READ`
- ✅ `STYLES:READ`

### 3. Map Style
Currently using: `mapbox://styles/mapbox/dark-v11`

Custom styles can be created in [Mapbox Studio](https://studio.mapbox.com/).

---

## 🔐 Security

### API Key Management
- All API keys stored in `.env` file
- `.env` is git-ignored (never committed)
- Keys loaded at runtime via `EnvConfig`

### Best Practices
✅ Use environment variables for secrets  
✅ Restrict API keys to specific domains/bundles  
✅ Enable rate limiting on backend  
❌ Never hardcode keys in source code  
❌ Never commit `.env` to version control

---

## 🧪 Testing

Run tests:
```bash
flutter test
```

Run with coverage:
```bash
flutter test --coverage
```

Analyze code:
```bash
flutter analyze
```

---

## 🔨 Build & Deploy

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

### iOS (requires macOS)
```bash
flutter build ios --release
```

---

## 🎯 Roadmap

- [x] Mapbox map integration
- [x] Location services
- [x] Search UI
- [ ] Google Places autocomplete
- [ ] Route preferences bottom sheet
- [ ] Backend API integration
- [ ] Multi-segment route visualization
- [ ] Route details screen
- [ ] AI chat assistant (الأسطى)
- [ ] Onboarding tutorial
- [ ] Favorites & recent searches
- [ ] Offline map support
- [ ] Real-time transit updates

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is part of a graduation project at Alexandria University.

---

## 👥 Authors

- **Rowan Fayez** - *Initial work* - [RowanFayez](https://github.com/RowanFayez)
- **Marwan** - *Backend* - [Marwan051](https://github.com/Marwan051)

---

## 🙏 Acknowledgments

- Mapbox for excellent mapping SDK
- Alexandria public transit community
- Open Street Map contributors
- Flutter team for the amazing framework

---

## 📞 Contact

For questions or support, reach out via:
- GitHub Issues: [Report a bug](https://github.com/RowanFayez/personalized_trip_planner_flutter/issues)
- Project Backend: [Routing Server](https://github.com/Marwan051/final_project_routing_server)

---

**Built with ❤️ for Alexandria, Egypt**
