# Development Notes

## Current Implementation Status

### ✅ Completed
- Project scaffolding and structure
- Mapbox integration (Android + iOS)
- Environment configuration (.env)
- Location services
- Map service layer
- Dark theme matching UI mockups
- Home screen with search fields
- Color system (#1B2E35 search inputs)

### 🚧 In Progress
- None

### 📋 TODO
1. Wire up Google Places autocomplete to search fields
2. Implement route preferences bottom sheet
3. Connect to backend routing API
4. Route visualization with color-coded segments
5. Route details screen
6. AI chat interface
7. Onboarding flow
8. Favorites and history

## File System Overview

### Configuration Files
- `.env` - API keys (Mapbox, Google Maps, Backend URL)
- `pubspec.yaml` - Dependencies and app metadata
- `analysis_options.yaml` - Dart linting rules

### Core Layer
**Purpose**: Shared utilities used across all features

- `core/config/env_config.dart` - Loads API keys from .env file
- `core/config/map_config.dart` - Mapbox camera positions, animation settings
- `core/constants/app_colors.dart` - Brand colors, transport mode colors
- `core/constants/app_strings.dart` - Hardcoded strings, endpoints, defaults
- `core/services/location_service.dart` - GPS handling, permissions
- `core/services/map_service.dart` - Mapbox operations (markers, polylines)
- `core/theme/app_theme.dart` - Material theme configuration

### Features Layer
**Purpose**: Feature-specific code (Clean Architecture)

- `features/home/presentation/pages/home_page.dart` - Main map screen

### Platform Configuration
- `android/app/src/main/AndroidManifest.xml` - Permissions
- `android/app/src/main/res/values/strings.xml` - Mapbox token
- `ios/Runner/Info.plist` - iOS permissions + Mapbox token

## Development Commands

```bash
# Get dependencies
flutter pub get

# Run app
flutter run

# Hot reload (while running)
r

# Hot restart (while running)
R

# Analyze code
flutter analyze

# Format code
flutter format .

# Clean build
flutter clean

# Build APK
flutter build apk --release
```

## Known Issues

1. **Color.value deprecation warnings** in `map_service.dart`
   - Mapbox SDK expects int color values
   - Will be fixed in future SDK update

2. **Unused `_mapboxMap` field warning**
   - Will be used when implementing map interactions

## Notes

- Default location: Alexandria City Center (31.2001, 29.9187)
- Map style: Dark theme (mapbox://styles/mapbox/dark-v11)
- Search input background: #1B2E35
- Backend API: Configure in .env file
