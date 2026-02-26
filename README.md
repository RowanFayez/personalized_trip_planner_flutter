# NextStation 

**NextStation** is a smart multimodal public transit application for Alexandria, Egypt. It provides personalized route planning for both formal (trams, buses) and informal (microbuses, tonaya) transport networks with real-time routing, preference-based optimization, and an AI assistant.
---


---

##  Project Structure "file system"

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
│   ├── presentation/                   # Presentation layer (Clean Architecture)
│   │   ├── features/                   # Feature modules
│   │   │   ├── home/
│   │   │   │   ├── data/
│   │   │   │   │   ├── model/          # Data models
│   │   │   │   │   └── repository/     # Data repositories
│   │   │   │   └── presentation/
│   │   │   │       ├── cubit/          # State management (BLoC/Cubit)
│   │   │   │       ├── view/           # UI screens/pages
│   │   │   │       └── widgets/        # Feature-specific widgets
│   │   │   │
│   │   │   └── auth/                   # Authentication feature
│   │   │       ├── data/
│   │   │       │   ├── model/
│   │   │       │   └── repository/
│   │   │       └── presentation/
│   │   │           ├── cubit/
│   │   │           ├── view/
│   │   │           └── widgets/
│   │   │
│   │   └── widgets/                    # Shared widgets across features
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
└── README.md                          
```

---

##  Architecture

### Core Layer (`lib/core/`)
Contains shared utilities, configurations, and services used across the app:

- **config/**: Application configuration (Mapbox settings, environment variables)
- **constants/**: Immutable values (colors, strings, API endpoints)
- **services/**: Reusable services (location, map operations)
- **theme/**: UI theming (dark mode, color schemes)

### Presentation Layer (`lib/presentation/`)
Organized by feature modules following Clean Architecture principles:

- **features/**: Feature-specific modules (home, auth, etc.)
- **widgets/**: Shared UI components used across features

Each feature module follows this structure:
```
feature/
├── data/
│   ├── model/         # Data models (entities)
│   └── repository/    # Data repositories (API calls, local storage)
└── presentation/
    ├── cubit/         # State management (BLoC/Cubit)
    ├── view/          # UI screens/pages
    └── widgets/       # Feature-specific widgets
```

**Example: `home/` feature**
- `data/model/` - Route model, Stop model
- `data/repository/` - Route repository (fetch routes from API)
- `presentation/cubit/` - Home cubit (state management)
- `presentation/view/` - Home page (main map screen)
- `presentation/widgets/` - Search input widget, route card widget

---


### Installation

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Configure environment variables:**
   
   Create a `.env` file in the project root:
   ```env
   MAPBOX_ACCESS_TOKEN=pk.your_mapbox_token_here
   GOOGLE_MAPS_API_KEY=your_google_api_key_here
   API_BASE_URL=http://your-backend-url.com/api
   ```

3. **Configure Mapbox for Android:**
   
   Already configured in `android/app/src/main/res/values/strings.xml`

4. **Configure Mapbox for iOS:**
   
   Already configured in `ios/Runner/Info.plist`

5. **Run the app:**
   ```bash
   flutter run
   ```





## Mapbox Setup

### 1. Get Access Token
1. Sign up at [mapbox.com](https://account.mapbox.com/)
2. Navigate to **Account → Tokens**
3. Copy your **Default Public Token** (starts with `pk.`)

### 2. Map Style
Currently using: `mapbox://styles/mapbox/dark-v11`

Custom styles can be created in [Mapbox Studio](https://studio.mapbox.com/).


## Build & Deploy

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

