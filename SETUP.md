# Setup Instructions

## ⚠️ IMPORTANT: Configure API Keys

Before running the app, you need to configure your API keys:

### 1. Environment Variables (.env file)

The `.env` file already exists in the project root. Update it with your keys:

```env
MAPBOX_ACCESS_TOKEN=pk.your_actual_mapbox_token_here
GOOGLE_MAPS_API_KEY=your_google_api_key_here
API_BASE_URL=http://your-backend-url.com/api
```

### 2. Android Configuration

Edit `android/app/src/main/res/values/strings.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">NextStation</string>
    <string name="mapbox_access_token">pk.your_actual_mapbox_token_here</string>
</resources>
```

### 3. iOS Configuration

Edit `ios/Runner/Info.plist` and replace the placeholder:

```xml
<!-- Mapbox Access Token -->
<key>MBXAccessToken</key>
<string>pk.your_actual_mapbox_token_here</string>
```

### 4. Get Your Mapbox Token

1. Sign up at [mapbox.com](https://account.mapbox.com/)
2. Go to **Account → Tokens**
3. Copy your **Default Public Token** (starts with `pk.`)
4. Paste it in the three locations above

### 5. Run the App

```bash
flutter pub get
flutter run
```

---

## 🔐 Security Note

**Never commit your actual API keys to git!**

- The `.env` file is already in `.gitignore`
- However, Android `strings.xml` and iOS `Info.plist` are tracked by git
- Always use placeholders in these files when committing
- Set the real tokens locally after cloning
