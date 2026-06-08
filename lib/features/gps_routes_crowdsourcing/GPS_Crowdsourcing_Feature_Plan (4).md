# GPS Crowdsourcing & Route Contribution Pipeline
## Feature Plan Documentation — NextStation App (Android Phase 1)
 *importatnt!**: there is no backend we send /post to it yet it will be made in future we d our side for recordeing first "The backend does not exist yet — do not implement any actual HTTP upload calls or dio"
 
**Version:** 3.0  
**Platform:** Android (Primary), iOS (Future Phase)  
**Tech Stack Core:** Flutter · Dart · Hive · Dio · flutter_background_service · geolocator · flutter_activity_recognition · flutter_local_notifications · workmanager · path_provider

---

## 1. Vision & Objectives

The community knows Alexandria's streets better than any static dataset. This feature turns every commuter into a silent data contributor — passengers record their real transit journeys in the background, enrich them with fares and transit types, and submit GPX files for backend integration. Over time, this crowdsourced layer fills the gaps in routing data and improves route quality for every user.

**Core Design Principles:**
- **Zero Friction UX** — Start with one tap. Forget about it. Get prompted to submit only when convenient.
- **RAM-Safe & Battery-Friendly** — All live GPS coordinates go directly to Hive. Never in unbounded memory lists. Never to file until trip ends.
- **Offline-First** — Recordings survive airplane mode, GPS interruption, app kills, and device reboots.
- **Passive Intelligence + Active Consent** — The app uses sensors to *detect* and *suggest*, never to *decide*. The user is the only authority on segment boundaries. Sensors inform the backend as metadata; they never modify the GPX structure without user confirmation.

---

## 2. Segmentation Philosophy — Context-Aware Smart Prompts

> This is the most important architectural decision in this feature. Read carefully.

### The Pattern: Detect → Suggest → User Decides

This is the same pattern Google Maps uses for "Are you at this place?" prompts. In software engineering, this is called **Context-Aware Smart Prompts** — the system uses environmental signals to offer timely, relevant suggestions, but the user retains absolute veto power.

```
Sensor detects potential transfer
         ↓
  60-second debounce (is this real or just traffic?)
         ↓ (sustained)
  Save potential_transfer_time to Hive as metadata
  Fire Smart Prompt notification
         ↓
  User says [Yes, I switched]  →  Retroactively close segment at potential_transfer_time
                                   Start new segment from that same timestamp
                                   Show transition sheet (mode + fare for previous segment)
                                   
  User says [No, just traffic] →  Do nothing to segments
  User ignores / dismisses     →  Do nothing to segments
                                   Mark detection as 'ignored' in metadata
```

### Why This Architecture is Correct

**The sensor is useful but not trusted for decisions:**
- Alexandria's urban traffic makes `IN_VEHICLE` vs `WALKING` ambiguous. A microbus in heavy traffic, a speed bump, or a roundabout can all confuse the classifier.
- False auto-splits corrupt the GPX data and create cleanup work in the Review Screen.
- But the *timestamps* of potential transfer events are genuinely valuable metadata for the backend team.

**The user is trusted for decisions:**
- User pressing [Yes, I switched] is a ground-truth signal — 100% accurate.
- User pressing [No] or ignoring is equally valid data — it tells the backend this was a false positive detection at that timestamp.

**The backend gets everything:**
- All detected `potential_transfer_points` (including rejected and ignored ones) are included in the GPX metadata sent to the backend.
- The backend team can use this data to improve the activity recognition model over time.
- Confirmed transfers become proper segment boundaries in the GPX.
- Unconfirmed detections are labeled as `detection_rejected` or `detection_ignored` in metadata.

### What Activity Recognition Controls vs What It Does NOT Control

| Controlled by sensors | NOT controlled by sensors |
|---|---|
| Firing a Smart Prompt notification | Creating or splitting a segment |
| Saving a `potential_transfer_time` timestamp | Modifying the GPX structure |
| Contributing metadata to backend | The user's segment boundary decisions |

### Speed-Based Stationary Detection (separate concern)

Speed from the GPS stream is used **only** for auto-pause detection — not for segmentation and not for Smart Prompts. If the user is stationary for 15+ minutes (speed < 0.8 m/s), recording pauses. This is a completely separate system from the activity recognition pipeline.

---

## 3. Activity Recognition Pipeline (Debounced Smart Prompts)

### 3.1 Detection Flow

```
flutter_activity_recognition stream
         ↓
ActivityType: IN_VEHICLE
         ↓ (transition detected)
ActivityType: WALKING (confidence >= 70%)
         ↓
Start 60-second debounce timer
Save tentative: potential_transfer_time = now (start of WALKING state)
         ↓
  During debounce window:
    - If IN_VEHICLE returns → Cancel timer, clear potential_transfer_time ("just traffic")
    - If WALKING sustained for full 60s → Confirm detection
         ↓ (confirmed)
Save PotentialTransferPoint to Hive:
  { detected_at: ISO8601, confirmed: false, user_response: null }
Fire Smart Prompt local notification
         ↓
Later: IN_VEHICLE resumes (user boarded new transit)
  → Update PotentialTransferPoint: { boarded_at: ISO8601 }
  → This confirms the full walk gap: alighted_at + walked + boarded_at
```

### 3.2 Debounce Algorithm Details

```dart
// Pseudocode — implement in background service
ActivityType? _lastStableActivity;
Timer? _debounceTimer;
DateTime? _potentialTransferStartTime;
static const Duration kDebounceWindow = Duration(seconds: 60);
static const int kMinActivityConfidence = 70; // percent

void onActivityEvent(ActivityEvent event) {
  if (event.confidence < kMinActivityConfidence) return;

  if (event.type == ActivityType.IN_VEHICLE) {
    _lastStableActivity = ActivityType.IN_VEHICLE;

    if (_debounceTimer != null && _debounceTimer!.isActive) {
      // Was walking but got back in vehicle → false positive, cancel
      _debounceTimer!.cancel();
      _debounceTimer = null;
      _potentialTransferStartTime = null;
    } else if (_potentialTransferStartTime != null) {
      // Confirmed walking ended, user is boarding new vehicle
      _onBoardingDetected();
    }
  }

  if (event.type == ActivityType.WALKING) {
    if (_lastStableActivity == ActivityType.IN_VEHICLE &&
        (_debounceTimer == null || !_debounceTimer!.isActive)) {
      // Potential transfer — start debounce
      _potentialTransferStartTime = DateTime.now();
      _debounceTimer = Timer(kDebounceWindow, _onTransferConfirmed);
    }
  }
}

void _onTransferConfirmed() {
  // 60s of sustained WALKING — this looks real
  final transferTime = _potentialTransferStartTime!;
  _savePotentialTransferPoint(transferTime);
  _fireSmartPromptNotification();
}

void _onBoardingDetected() {
  // User is back IN_VEHICLE — update the potential transfer with boarding time
  _updatePotentialTransferWithBoardingTime(DateTime.now());
  _potentialTransferStartTime = null;
}
```

### 3.3 Confidence Threshold

- Only process activity events with `confidence >= 70%`.
- Events below 70% are ignored entirely.
- This filters out the noise from bumpy roads and slow traffic in Alexandria.

### 3.4 Smart Prompt Notification Design

Fired when a transfer is confirmed (after 60s debounce):

```
┌──────────────────────────────────────────────────┐
│ 🚌 الاسطى بيسأل — تبديل مواصلة؟                │
│                                                  │
│ الاسطى حس إنك نزلت وركبت مواصلة تانية.          │
│ هل غيّرت المواصلة فعلاً؟                         │
│                                                  │
│  [ أيوه، غيّرت ]        [ لأ، زحمة بس ]        │
└──────────────────────────────────────────────────┘
```

**Notification properties:**
- ID: 889 (different from the persistent recording notification ID 888)
- `ongoing: false` — user CAN dismiss it
- Sound: subtle (not alarming)
- Vibration: single short pulse
- Auto-cancel after 5 minutes if not interacted with

**Action responses:**

`[أيوه، غيّرت]`:
1. Retroactively close current segment at `potential_transfer_time` (not at current time).
2. Start new segment from `potential_transfer_time`.
3. Update segment's `endedAt` and the new segment's `startedAt` to `potential_transfer_time`.
4. Update `PotentialTransferPoint.userResponse = 'confirmed'`.
5. If app is foreground → show `SegmentTransitionBottomSheet` for mode + fare input.
6. If app is background → update persistent notification to "Recording — Unspecified Transit."
7. User completes mode selection next time they open app or in Review Screen.

`[لأ، زحمة بس]`:
1. Do absolutely nothing to segments.
2. Update `PotentialTransferPoint.userResponse = 'rejected'`.
3. Keep recording as-is.

**User ignores / dismisses notification:**
1. After 5 minutes, mark `PotentialTransferPoint.userResponse = 'ignored'`.
2. Do nothing to segments.

---

## 4. Data Storage Architecture (Three-Phase Model)

### Why Three Phases?

Writing directly to a `.gpx` file during recording is expensive (disk I/O per GPS ping). Keeping coordinates in RAM lists causes crashes on long trips. The solution is a layered approach:

```
Phase 1 — RECORDING       → Hive (raw GPS stream, buffered + potential transfer points)
Phase 2 — REVIEW / LOCAL  → File System (assembled .gpx) + Hive (metadata)
Phase 3 — UPLOAD / DONE   → Backend (multipart) → GPX deleted, metadata kept in Hive
```

### Phase 1: Active Recording (GPS → Hive)

**Hive Box Name:** `crowdsourcing_box`

**Key Schema:**
```dart
// Active trip header
Key: 'active_trip'
Value: {
  'trip_id': String (UUID),
  'started_at': ISO8601,
  'status': 'recording' | 'paused' | 'gps_lost' | 'stopped',
  'segments': [
    {
      'mode': String?,          // null if unspecified
      'started_at': ISO8601,
      'ended_at': ISO8601?,
    }
  ],
  'current_segment_index': int,
}

// GPS points (buffered flush, append-only)
Key: 'gps_pts_<trip_id>'
Value: List<Map> [
  {
    'lat': double,
    'lon': double,
    'alt': double?,
    'ts': int (epoch ms),
    'seg': int,             // segmentIndex
    'acc': double?,
    'spd': double?,         // m/s — used for stationary detection only
  }
]

// Potential transfer points (from activity recognition)
Key: 'transfers_<trip_id>'
Value: List<Map> [
  {
    'detected_at': ISO8601,           // when WALKING was confirmed (after debounce)
    'boarded_at': ISO8601?,           // when IN_VEHICLE resumed (optional)
    'user_response': String?,         // 'confirmed' | 'rejected' | 'ignored' | null (pending)
    'resulted_in_segment_split': bool,
    'notification_sent_at': ISO8601,
  }
]
```

**GPS Append Strategy (Bounded Buffer):**
- In-memory buffer capped at **50 points maximum**.
- Flush to Hive every 50 points OR every 30 seconds, whichever comes first.
- On flush: append to existing Hive list. On service stop: flush immediately before anything else.

---

### Phase 2: Post-Recording (Hive → .gpx File + Metadata)

**Triggered by:** User taps [Arrived] or auto-stop fires.

**What happens:**
1. Flush remaining buffer to Hive.
2. Pull all GPS points from Hive for `trip_id`.
3. Pull all `PotentialTransferPoints` from Hive for `trip_id`.
4. Run noise filter: exclude points with `accuracy > 30m`.
5. Assemble GPX XML using `compute()` (background isolate).
6. Write `.gpx` to `ApplicationDocumentsDirectory/crowdsourcing/<trip_id>.gpx`.
7. Delete raw GPS points from Hive (`gps_pts_<trip_id>`). Keep transfer points.
8. Update trip metadata: status → `'pending_review'`.
9. Navigate to Review Screen.

**Permanent Metadata in Hive:**
```dart
Key: 'trip_meta_<trip_id>'
Value: {
  'trip_id': String,
  'started_at': ISO8601,
  'ended_at': ISO8601,
  'status': String,
  'gpx_file_path': String?,
  'total_distance_m': double,
  'segments': [
    {
      'index': int,
      'mode': String?,
      'fare_egp': double?,
      'started_at': ISO8601,
      'ended_at': ISO8601,
      'point_count': int,
      'confidence': String,   // 'user_confirmed' | 'unknown'
    }
  ],
  // All detected transfer events — sent to backend regardless of user response
  'potential_transfers': [
    {
      'detected_at': ISO8601,
      'boarded_at': ISO8601?,
      'user_response': String,    // 'confirmed' | 'rejected' | 'ignored'
      'resulted_in_segment_split': bool,
    }
  ],
  'upload_attempt_count': int,
  'last_uploaded_at': ISO8601?,
  'contribution_id': String?,
}
```

---

### Phase 3: Upload & Cleanup

**On successful upload:**
- Delete `.gpx` file from File System.
- Set `gpx_file_path` → `null`, `status` → `'uploaded'`, store `contribution_id`.
- Keep all metadata forever.

**On failed upload:**
- Keep `.gpx` file. Set `status` → `'upload_failed'`. Schedule Workmanager retry.

**Storage Summary:**

| Data | Storage | Lifetime |
|---|---|---|
| Live GPS points (buffered) | In-memory (≤ 50 pts) + Hive | Until GPX assembled, then deleted |
| Potential transfer points | Hive | Permanent (sent to backend as metadata) |
| Active trip header | Hive | Until trip ends |
| `.gpx` file | File System | Until successful upload |
| Trip metadata + transfer events | Hive | Forever (contributions history) |

---

## 5. Background Service Architecture

### 5.1 Service Setup

**Package:** `flutter_background_service` (Android Foreground Service)

**AndroidManifest permissions:**
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
```

### 5.2 Two Concurrent Streams in the Background Service

The background service runs **two independent streams simultaneously**:

**Stream 1 — GPS Stream (geolocator):**
```dart
LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)
// Time gate: reject points < 10 seconds after previous
// Noise filter: reject points with accuracy > 50m
// Buffer: max 50 points, flush every 50 pts or 30 seconds
```

**Stream 2 — Activity Recognition Stream (flutter_activity_recognition):**
```dart
// Runs independently of GPS
// Only processes events with confidence >= 70%
// Applies 60-second debounce algorithm
// Does NOT affect GPS stream or segment structure directly
// Only fires Smart Prompt notifications and saves potential_transfer_time
```

These two streams are deliberately kept separate. GPS stream = data collection. Activity stream = suggestion trigger. They only interact when the user confirms a Smart Prompt (at which point the segment boundary is retroactively updated in Hive).

### 5.3 GPS Configuration

```dart
const LocationSettings locationSettings = LocationSettings(
  accuracy: LocationAccuracy.high,
  distanceFilter: 10,
);
const Duration minTimeBetweenPoints = Duration(seconds: 10);
```

**Speed-Based Stationary Detection (auto-pause, separate from activity recognition):**
- If median speed of last 10 points < 0.8 m/s for 15 continuous minutes → auto-pause GPS writing.
- Resume on speed > 1.5 m/s.
- Fires a "still recording?" local notification.
- Does NOT create segments, does NOT interact with activity recognition.

**GPS Lost:**
- No point received for > 60 seconds → enter `GPS_SUSPENDED`.
- Do NOT interpolate. Keep last known position.
- Notification: "GPS اتقفل — التسجيل وقف مؤقتاً."

### 5.4 Persistent Recording Notification (ID: 888)

```
┌──────────────────────────────────────────────────┐
│ 🚌 NextStation — جاري التسجيل                    │
│ 📍 ميكروباص · 2.3 km · 00:14:32                 │
│                                                  │
│  [ غيّرت المواصلة ]       [ وصلت ✓ ]           │
└──────────────────────────────────────────────────┘
```

Updates every 30 seconds. `ongoing: true` — cannot be dismissed.

**[غيّرت المواصلة] action:**
- Foreground: open `SegmentTransitionBottomSheet`.
- Background: close current segment with `mode: null`, start new segment. Notification updates to "Recording — Unspecified Transit." User completes in Review.

**[وصلت ✓] action:**
- Stop GPS stream. Flush buffer. Trigger GPX assembly. Open app to Review Screen.

### 5.5 IPC Methods (service ↔ UI)

```
UI → Service:
  'start_trip'    → { tripId: String, mode: String? }
  'stop_trip'     → {}
  'add_segment'   → { mode: String?, fareEgp: double? }
  'confirm_transfer' → { detectedAt: String, mode: String?, fareEgp: double? }
  'reject_transfer'  → { detectedAt: String }
  'pause_trip'    → {}
  'resume_trip'   → {}

Service → UI:
  'gps_point'           → { lat, lon, segmentIndex, distanceM, elapsedSeconds }
  'potential_transfer'  → { detectedAt: String }   // Smart Prompt fired
  'trip_auto_paused'    → {}
  'gps_lost'            → {}
  'gps_restored'        → {}
  'trip_stopped'        → {}
```

---

## 6. UI/UX Flow (Complete User Journey)

### 6.1 Entry Points

- **Profile → My Contributions → [Start Recording]** (primary)
- **Home Map FAB** (Phase 2)

### 6.2 Mandatory Start Gate

```
┌─────────────────────────────────────────────────┐
│       ما الوسيلة اللي بتركبها دلوقتي؟          │
│                                                 │
│   [🚐 ميكروباص]      [🚌 مينيباص]              │
│   [🛺 تمنية]         [🚎 أتوبيس]               │
│                                                 │
│      ── أو ابدأ التسجيل من غير تحديد ──        │
│         (ممكن تحدد بعدين في المراجعة)           │
└─────────────────────────────────────────────────┘
```

Cannot be dismissed without a choice. `barrierDismissible: false`.

### 6.3 Crowdsourcing Map Mode (Live Recording Screen)

Completely separate from Home map. Different Cubit, different MapWidget instance.

**Map UI Elements:**
- Live polyline, color per segment mode (AppColors mode constants).
- Small colored circle at each segment boundary.
- Top HUD: current mode chip + elapsed time + total distance.
- Bottom action bar: [غيّرت المواصلة] + [وصلت ✓] + [−] minimize.

**Stationary handling:** If last 10 GPS points within 5m radius → stop extending polyline, show pulsing dot.

**On return to app while recording:** Re-draw full polyline from Hive data. Re-subscribe to IPC stream.

### 6.4 Segment Transition BottomSheet

Triggered by [غيّرت المواصلة] button OR after user confirms Smart Prompt:

```
┌─────────────────────────────────────────────────┐
│           بدّلت المواصلة؟                       │
│                                                 │
│  أجرة الرحلة اللي فاتت؟ (اختياري)              │
│  [ 5 ج ] [ 7 ج ] [ 10 ج ] [ __ ج ]            │
│                                                 │
│         بتركب إيه دلوقتي؟                       │
│   [🚐 ميكروباص]      [🚌 مينيباص]              │
│   [🛺 تمنية]         [🚎 أتوبيس]               │
│                                                 │
│                        [ تخطي ← ]              │
└─────────────────────────────────────────────────┘
```

When triggered from Smart Prompt confirmation, shows an additional context line:
`"الاسطى حس إنك غيّرت عند الساعة 10:42 ص"`

### 6.5 Review Screen (Pre-Submission)

- Top 35%: Static map with full trip polyline (all segments color-coded).
- Middle: Scrollable segment cards.
- Bottom: Submit button.

**Per Segment Card:**
```
┌─────────────────────────────────────────────────┐
│ Segment 1  ●───────────────  2.3 km · 00:12    │
│ Transit:  [ 🚐 Microbus   ▼ ]                  │
│ Fare:     [  7  ] EGP                          │
│           [ 5 ][ 7 ][ 10 ][ 15 ]              │
│                    [🗑 Delete segment]          │
└─────────────────────────────────────────────────┘
```

**Submit states:**
- All modes selected → "Submit & Contribute"
- Some modes null → "Submit Anyway (some info missing)" with warning

### 6.6 Post-Submit

```
        ✅  شكراً على مساهمتك!
   الرحلة دي هتساعد الناس تلاقي طريقهم أحسن.
   [ شوف مساهماتي ]     [ ارجع للخريطة ]
```

---

## 7. GPX File Format Specification

```xml
<?xml version="1.0" encoding="UTF-8"?>
<gpx version="1.1" creator="NextStation-Android"
     xmlns="http://www.topografix.com/GPX/1/1"
     xmlns:ns="http://nextstation.app/gpx/extensions/v1">

  <metadata>
    <name>NextStation Contribution</name>
    <time>2025-01-15T10:30:00Z</time>
    <extensions>
      <ns:trip_id>uuid</ns:trip_id>
      <ns:app_version>1.2.0</ns:app_version>
      <ns:device_os>android</ns:device_os>

      <!-- All detected potential transfers, regardless of user response -->
      <ns:potential_transfers>
        <ns:transfer>
          <ns:detected_at>2025-01-15T10:44:00Z</ns:detected_at>
          <ns:boarded_at>2025-01-15T10:46:30Z</ns:boarded_at>
          <ns:user_response>confirmed</ns:user_response>
          <ns:resulted_in_segment_split>true</ns:resulted_in_segment_split>
        </ns:transfer>
        <ns:transfer>
          <ns:detected_at>2025-01-15T11:02:00Z</ns:detected_at>
          <ns:boarded_at>2025-01-15T11:02:45Z</ns:boarded_at>
          <ns:user_response>rejected</ns:user_response>
          <ns:resulted_in_segment_split>false</ns:resulted_in_segment_split>
        </ns:transfer>
      </ns:potential_transfers>
    </extensions>
  </metadata>

  <!-- One <trk> per user-confirmed segment -->
  <trk>
    <name>Segment 1</name>
    <extensions>
      <ns:segment_index>0</ns:segment_index>
      <ns:transit_mode>microbus</ns:transit_mode>
      <ns:fare_egp>7.0</ns:fare_egp>
      <!-- user_confirmed = user explicitly selected mode -->
      <!-- unknown = user skipped mode selection -->
      <ns:confidence>user_confirmed</ns:confidence>
    </extensions>
    <trkseg>
      <trkpt lat="31.2156" lon="29.9232">
        <ele>12.5</ele>
        <time>2025-01-15T10:30:05Z</time>
        <extensions><ns:accuracy>4.2</ns:accuracy></extensions>
      </trkpt>
    </trkseg>
  </trk>

</gpx>
```

**GPX Assembly Rules:**
- One `<trk>` per user-confirmed segment only. Activity recognition detections that were rejected/ignored do NOT appear as `<trk>` elements.
- All `potential_transfer` events (confirmed, rejected, ignored) appear in `<metadata>` extensions.
- Points with accuracy > 30m excluded.
- GPX assembly runs in `compute()` isolate — never on UI thread.

---

## 8. Edge Cases & Error Handling

| Scenario | Detection | Response |
|---|---|---|
| **User forgot to stop (stationary 15+ min)** | GPS speed < 0.8 m/s for 15 min | Auto-pause + notification "لسه بتسجل؟ وصلت؟" with [Stop] and [Continue] |
| **Smart Prompt not answered within 5 min** | Timer on notification send time | Mark `user_response: 'ignored'`, do nothing to segments |
| **Multiple Smart Prompts firing rapidly** | Debounce cooldown: 3 min minimum between prompts | Reject new detection events for 3 min after a prompt fires |
| **App crash / phone reboot mid-trip** | On next launch, scan Hive for `status: 'recording'` | Auto-terminate → flush buffer → assemble GPX → redirect to Review |
| **GPS disabled mid-trip** | Geolocator stream timeout > 60s | Enter GPS_SUSPENDED, do NOT interpolate, notify user |
| **Activity recognition disabled or unavailable** | try/catch on stream init | Gracefully disable Smart Prompts, continue recording GPS only |
| **No internet on submit** | Dio connection error | Status → `'pending_upload'`, Workmanager retry scheduled |
| **Very short trip (< 5 GPS points)** | Point count check before GPX assembly | Warning: "الرحلة قصيرة جداً — هل تريد إرسالها؟" |
| **Segment with 0 GPS points** | Point count per segment < 2 | Auto-remove in Review, show snackbar |
| **User responds [Yes] to Smart Prompt while app is background** | Notification action handler in service | Service retroactively splits segment in Hive, updates persistent notification |

---

## 9. Backend API Contract (Proposed)

> Backend on Railway (same tech as existing). No endpoint exists yet. This contract drives frontend implementation.

### Upload New Contribution

```
POST /api/v1/crowdsourcing/contributions
Content-Type: multipart/form-data

Parts:
  - gpx_file: <binary .gpx>
  - metadata: <JSON string>

Metadata JSON:
{
  "trip_id": "uuid",
  "started_at": "ISO8601",
  "ended_at": "ISO8601",
  "total_distance_m": 4700,
  "segments": [
    {
      "index": 0,
      "transit_mode": "microbus",
      "fare_egp": 7.0,
      "confidence": "user_confirmed",
      "duration_seconds": 720,
      "distance_m": 3100,
      "point_count": 68
    }
  ],
  "potential_transfers": [
    {
      "detected_at": "ISO8601",
      "boarded_at": "ISO8601",
      "user_response": "confirmed",
      "resulted_in_segment_split": true
    },
    {
      "detected_at": "ISO8601",
      "boarded_at": "ISO8601",
      "user_response": "rejected",
      "resulted_in_segment_split": false
    }
  ],
  "app_version": "1.2.0",
  "is_amendment": false
}

Response 201: { "contribution_id": "server-uuid", "status": "under_review" }
```

### Amend Contribution (no GPX re-upload)

```
PATCH /api/v1/crowdsourcing/contributions/<contribution_id>
Body: { "segments": [...], "is_amendment": true }
Response 200: { "status": "amended" }
```

---

## 10. Contributions Profile Page

### List Item Design

```
┌──────────────────────────────────────────────────┐
│ 📍 15 يناير 2025 — 10:30 ص                     │
│ 🚐 Microbus  →  🛺 Tomnaya                       │
│ 4.7 km  ·  2 segments  ·  14 EGP total          │
│                                 [Uploaded ✓]    │
└──────────────────────────────────────────────────┘
```

### Status Badges

| Status | Badge | Color |
|---|---|---|
| `uploaded` | ✓ Uploaded | `AppColors.success` |
| `pending_upload` | ↑ Waiting for network | `AppColors.warning` |
| `upload_failed` | ⚠ Retry Upload | `AppColors.error` |
| `pending_review` | → Ready to Submit | `AppColors.primaryTeal` |

### Edit Capability
- `pending_review` → full edit + re-submit.
- `uploaded` → metadata-only edit (fare/mode) → PATCH request, no GPX re-upload.

---

## 11. Privacy — Location Fuzzing (Phase 2)

GPS points in the **first and last 3 minutes** of every trip are rounded to 3 decimal places (~100m precision) during GPX assembly. Raw Hive data stays untouched. A `<ns:fuzzing_applied>true</ns:fuzzing_applied>` flag is added to GPX metadata. User sees a one-time tooltip explaining this.

---

## 12. Flutter Package Dependencies

```yaml
dependencies:
  flutter_background_service: ^5.x.x    # Foreground Service
  geolocator: ^12.x.x                   # GPS stream
  flutter_activity_recognition: ^2.x.x  # Smart Prompt detection (not segmentation)
  flutter_local_notifications: ^17.x.x  # Persistent + Smart Prompt notifications
  workmanager: ^0.5.x                   # Offline retry
  connectivity_plus: ^6.x.x            # Network state for retry trigger
  hive_flutter: ^1.x.x                 # already in project
  path_provider: ^2.x.x
  dio: ^5.x.x                          # already in project
  uuid: ^4.x.x
```

---

## 13. File & Folder Structure

```
lib/
└── features/
    └── crowdsourcing/
        ├── data/
        │   ├── models/
        │   │   ├── trip_metadata_model.dart
        │   │   ├── gps_point_model.dart
        │   │   ├── segment_model.dart
        │   │   └── potential_transfer_model.dart     ← NEW
        │   ├── repositories/
        │   │   └── contribution_repository_impl.dart
        │   ├── services/
        │   │   ├── gps_recording_service.dart
        │   │   ├── activity_detection_service.dart   ← NEW (debounce logic)
        │   │   ├── smart_prompt_service.dart         ← NEW (notification firing + response)
        │   │   ├── gpx_builder_service.dart
        │   │   ├── trip_local_data_source.dart
        │   │   └── contribution_api_service.dart
        │   └── background/
        │       └── recording_background_handler.dart
        ├── domain/
        │   ├── entities/
        │   │   ├── trip.dart
        │   │   ├── trip_segment.dart
        │   │   ├── gps_point.dart
        │   │   └── potential_transfer.dart           ← NEW
        │   ├── repositories/
        │   │   └── contribution_repository.dart
        │   └── usecases/
        │       ├── start_trip_usecase.dart
        │       ├── stop_trip_usecase.dart
        │       ├── add_segment_usecase.dart
        │       ├── confirm_transfer_usecase.dart      ← NEW
        │       └── submit_contribution_usecase.dart
        └── presentation/
            ├── cubit/
            │   ├── recording_cubit.dart
            │   ├── recording_state.dart
            │   ├── review_cubit.dart
            │   └── review_state.dart
            ├── views/
            │   ├── crowdsourcing_map_page.dart
            │   ├── review_page.dart
            │   └── contributions_page.dart
            └── widgets/
                ├── segment_card.dart
                ├── mode_selector_sheet.dart
                ├── transition_sheet.dart
                ├── live_route_painter.dart
                └── contribution_list_item.dart
```

---

## 14. Implementation Phases

### Phase 1 — Core Recording (MVP)
- [ ] Hive box: GPS points + trip metadata + potential transfer model
- [ ] Android Foreground Service + persistent notification
- [ ] GPS stream → bounded buffer → Hive flush
- [ ] Mandatory start gate BottomSheet
- [ ] Manual segment transitions ([غيّرت المواصلة])
- [ ] Activity recognition stream + 60s debounce algorithm
- [ ] Smart Prompt notification (ID: 889) with [أيوه] / [لأ] actions
- [ ] Retroactive segment split on Smart Prompt confirmation
- [ ] GPX builder in compute() isolate (includes potential_transfers in metadata)
- [ ] Review Screen with segment cards
- [ ] Multipart upload + Workmanager retry
- [ ] Crash/reboot recovery

### Phase 2 — Polish
- [ ] Speed-based auto-pause refinement
- [ ] GPS lost handling
- [ ] Segment merge in Review Screen
- [ ] Post-upload metadata amendment (PATCH)
- [ ] Location fuzzing (privacy)
- [ ] Home Map FAB entry point

### Phase 3 — Future
- [ ] iOS support
- [ ] Admin feedback in Contributions page
- [ ] Use rejected/ignored transfer metadata to improve detection thresholds

---

---

# AI Implementation Prompt

> Use this prompt verbatim when delegating implementation to an AI coding assistant.

---

```
You are a senior Flutter engineer implementing the GPS Crowdsourcing Recording feature
for NextStation, a transit navigation app for Alexandria, Egypt.
Target platform: Android only (initial phase). Flutter + Dart.

## Existing Project Context

The app already has:
- Mapbox maps (mapbox_maps_flutter SDK) — same MapWidget pattern as existing HomeMap
- Hive via HiveService.openBox<dynamic>(boxName) — see hive_service.dart
- Dio HTTP client with Supabase Bearer auth — use sl<Dio>()
- BLoC/Cubit (flutter_bloc) — all state in Cubits
- flutter_screenutil for sizing — .w .h .r .sp
- AppColors constants — no hardcoded hex
- Existing FareChip widget: crowdsourcing/presentation/widgets/fare_chip.dart
- Existing FareFeedbackValidator: crowdsourcing/domain/fare_feedback_validator.dart
- GoRouter navigation — see app_router.dart
- safeApiCall() for all API calls — see api_result.dart
- GetIt (sl) for DI — register everything new in ServiceLocator.init()
- CoreHiveBoxes for box name constants — add 'crowdsourcing_box' there

## Feature Overview

Users record multi-segment transit journeys while commuting. The system:
1. Runs as Android Foreground Service with persistent notification (ID: 888)
2. Writes GPS points to Hive via a bounded buffer (max 50 pts, flush every 50 or 30s)
3. Runs Activity Recognition in parallel to detect potential transfer moments
4. Fires a Smart Prompt notification (ID: 889) when a likely transfer is detected
5. User decides: [Yes, I switched] → retroactive segment split | [No, just traffic] → nothing changes
6. Assembles a GPX 1.1 file only after trip ends, using compute() isolate
7. Includes ALL detected potential_transfer events in GPX metadata regardless of user response
8. User reviews + annotates segments in Review Screen before submitting
9. Uploads via Multipart POST to backend, with Workmanager offline retry

## CRITICAL DESIGN RULES — never violate:

RULE 1: Activity recognition NEVER automatically creates, splits, or modifies segments.
        It ONLY fires a Smart Prompt notification and saves a potential_transfer_time.
        Segment structure changes ONLY when the user explicitly confirms [أيوه، غيّرت].

RULE 2: Retroactive split — when user confirms a Smart Prompt, the segment boundary
        is placed at potential_transfer_time (when WALKING started after debounce),
        NOT at the current time when the user tapped the notification.

RULE 3: All potential_transfer detections (confirmed, rejected, ignored) must be
        saved to Hive and included in the GPX metadata sent to backend. This data
        is valuable for the backend team to improve detection quality over time.

RULE 4: The 60-second debounce is mandatory. If IN_VEHICLE resumes within 60 seconds
        of WALKING starting, cancel the detection entirely — it was traffic, not a transfer.

RULE 5: Speed data from GPS is used ONLY for stationary auto-pause detection.
        It has NO relationship to the activity recognition pipeline.

RULE 6: Never store GPS coordinates in unbounded Dart List variables.
        Never write to File System during active recording.
        Never interpolate GPS points when signal is lost.
        Never block UI thread with GPX assembly — use compute().

---

## TASK 1: Hive Data Layer

Add 'crowdsourcing_box' to CoreHiveBoxes.

Create models WITHOUT code generation (manual toMap/fromMap):

GpsPointModel:
  lat (double), lon (double), altitude (double?), timestampMs (int epoch ms),
  segmentIndex (int), accuracyM (double?), speedMs (double?)

TripSegmentModel:
  index (int), mode (String? — 'microbus'|'tomnaya'|'minibus'|'bus'|null),
  fareEgp (double?), startedAt (String ISO8601), endedAt (String? ISO8601),
  confidence ('user_confirmed' if mode selected | 'unknown' if null),
  pointCount (int)

PotentialTransferModel:
  detectedAt (String ISO8601),      // when WALKING confirmed (post-debounce)
  boardedAt (String? ISO8601),      // when IN_VEHICLE resumed
  userResponse (String? — 'confirmed' | 'rejected' | 'ignored' | null for pending),
  notificationSentAt (String ISO8601),
  resultedInSegmentSplit (bool)

TripMetadataModel:
  tripId (String UUID), status (String), startedAt, endedAt (String?),
  segments (List<TripSegmentModel>),
  potentialTransfers (List<PotentialTransferModel>),
  gpxFilePath (String?), totalDistanceM (double?),
  uploadAttemptCount (int), contributionId (String?), lastUploadedAt (String?)

Status String constants:
  'recording' | 'paused' | 'gps_lost' | 'pending_review' |
  'pending_upload' | 'uploaded' | 'upload_failed'

TripLocalDataSource methods:
  Future<void> saveActiveTrip(TripMetadataModel trip)
  Future<TripMetadataModel?> getActiveTrip()
  Future<void> clearActiveTrip()
  Future<void> appendGpsPointsBatch(String tripId, List<GpsPointModel> points)
  Future<List<GpsPointModel>> getGpsPoints(String tripId)
  Future<void> deleteGpsPoints(String tripId)
  Future<void> addPotentialTransfer(String tripId, PotentialTransferModel transfer)
  Future<void> updateTransferResponse(String tripId, String detectedAt, String response, bool resulted)
  Future<void> retroactiveSplitSegment(String tripId, String splitAtIso8601)
    // This is the key method: updates current segment's endedAt to splitAtIso8601,
    // creates a new segment starting at splitAtIso8601 with mode: null,
    // increments current_segment_index in active trip header
  Future<void> saveTripMetadata(TripMetadataModel meta)
  Future<List<TripMetadataModel>> getAllCompletedTripMetadata()
  Future<void> updateTripStatus(String tripId, String status)
  Future<void> updateTripAfterUpload(String tripId, String contributionId)

Hive key scheme:
  'active_trip' → active trip header
  'gps_pts_<tripId>' → GPS points list
  'transfers_<tripId>' → potential transfers list
  'trip_meta_<tripId>' → completed trip metadata
  'trip_meta_keys' → List<String> of all tripIds (index for getAllCompletedTripMetadata)

---

## TASK 2: Background Service

Create recording_background_handler.dart using flutter_background_service.

The service runs TWO INDEPENDENT STREAMS:

=== GPS Stream ===
  geolocator LocationSettings: accuracy=high, distanceFilter=10
  Time gate: reject points < 10s after previous
  Noise filter: reject points with accuracyM > 50
  Bounded buffer: List<GpsPointModel> _buffer, max 50 items
  Flush buffer to Hive when: buffer.length >= 50 OR 30s elapsed since last flush
  On stop_trip: flush immediately before anything else
  Speed tracking: keep rolling window of last 10 speed values for stationary detection

  Stationary Detection (auto-pause, GPS stream only — NOT activity recognition):
    If median speed of last 10 points < 0.8 m/s sustained for 900s (15 min)
    → emit 'trip_auto_paused' IPC event
    → fire local notification ID 890: "لسه بتسجل؟ وصلت؟" with [Stop] action
    Resume automatically if speed > 1.5 m/s

  GPS Lost:
    If no geolocator event for > 60s → emit 'gps_lost', update persistent notification
    Do NOT write interpolated points
    On restore → emit 'gps_restored', resume

=== Activity Recognition Stream ===
  Initialize flutter_activity_recognition stream
  If stream unavailable (permission denied, device unsupported) → disable silently,
    log debug message, continue with GPS stream only

  State machine per TASK 2 section 3.2 debounce algorithm:
    _lastStableActivity: ActivityType?
    _debounceTimer: Timer?  (60 seconds)
    _potentialTransferStartTime: DateTime?
    _pendingBoardingTime: DateTime?

  Only process events where confidence >= 70

  On WALKING sustained 60s:
    Call TripLocalDataSource.addPotentialTransfer() with detectedAt = _potentialTransferStartTime
    Fire Smart Prompt notification ID 889
    Emit 'potential_transfer' IPC event with { detectedAt: ISO8601 }

  On IN_VEHICLE resumes (after a confirmed WALKING phase):
    Update _pendingBoardingTime = DateTime.now()
    Call TripLocalDataSource to update boardedAt on latest pending transfer

  Prompt cooldown: after a Smart Prompt fires, ignore new WALKING detections
    for 180 seconds (3 min) to prevent prompt spam

=== Persistent Notification (ID: 888) ===
  ongoing: true
  Actions: [{id: 'transfer', label: 'غيّرت المواصلة'}, {id: 'arrived', label: 'وصلت ✓'}]
  Update every 30 seconds: "جاري التسجيل — {modeName} · {distanceKm} km · {elapsed}"

  'arrived' action → invoke 'stop_trip'
  'transfer' action (background) → invoke 'add_segment' with mode=null,
    update notification to "جاري التسجيل — وسيلة غير محددة · ..."

=== Smart Prompt Notification (ID: 889) ===
  ongoing: false (dismissible)
  Auto-cancel after 5 minutes
  Actions: [{id: 'confirm_transfer', label: 'أيوه، غيّرت'},
            {id: 'reject_transfer', label: 'لأ، زحمة بس'}]

  'confirm_transfer' action handler:
    1. Call TripLocalDataSource.retroactiveSplitSegment(tripId, potentialTransferStartTime)
    2. Call TripLocalDataSource.updateTransferResponse(tripId, detectedAt, 'confirmed', true)
    3. Emit 'segment_split_confirmed' IPC event
    4. Update persistent notification to "جاري التسجيل — وسيلة غير محددة · ..."

  'reject_transfer' action handler:
    1. Call TripLocalDataSource.updateTransferResponse(tripId, detectedAt, 'rejected', false)
    2. Emit 'transfer_rejected' IPC event
    3. No changes to segments

  On auto-cancel after 5 min:
    Call TripLocalDataSource.updateTransferResponse(tripId, detectedAt, 'ignored', false)

=== IPC Methods (UI → Service) ===
  'start_trip'    → { tripId, mode? }
  'stop_trip'     → {}
  'add_segment'   → { mode?, fareEgp? }
  'pause_trip'    → {}
  'resume_trip'   → {}

=== IPC Events (Service → UI) ===
  'gps_point'               → { lat, lon, segmentIndex, distanceM, elapsedSeconds }
  'potential_transfer'      → { detectedAt: String }
  'segment_split_confirmed' → {}
  'transfer_rejected'       → {}
  'trip_auto_paused'        → {}
  'gps_lost'                → {}
  'gps_restored'            → {}
  'trip_stopped'            → {}

=== Crash Recovery (on service init) ===
  getActiveTrip() → if status='recording' → resume GPS stream + activity stream for that tripId
  Check for any pending transfers (userResponse=null) older than 5 min → mark as 'ignored'

---

## TASK 3: GPX Builder Service

GpxBuilderService.buildGpxFile() runs via compute().

Input: { tripMeta: TripMetadataModel, rawPoints: List<GpsPointModel> }
All input must be serializable to plain Map (no platform channels in isolate).

Noise filters:
  Exclude points: accuracyM > 30
  Exclude points: speedMs == 0 AND accuracyM > 15

GPX structure:
  xmlns:ns="http://nextstation.app/gpx/extensions/v1"

  <metadata> extensions:
    ns:trip_id, ns:app_version, ns:device_os
    ns:potential_transfers → list of all PotentialTransferModel entries
      Each has: detected_at, boarded_at, user_response, resulted_in_segment_split

  One <trk> per TripSegmentModel (group rawPoints by segmentIndex):
    <extensions>: segment_index, transit_mode (or "unknown"), fare_egp, confidence
    <trkseg><trkpt>: lat, lon, <ele>, <time UTC ISO8601>
    <trkpt extensions>: ns:accuracy

Output: write to ApplicationDocumentsDirectory/crowdsourcing/<tripId>.gpx
After write: call TripLocalDataSource.deleteGpsPoints(tripId) — in the calling context, not isolate

---

## TASK 4: Recording Cubit

States:
  RecordingInitial
  RecordingOrphanFound { tripMeta }
  RecordingInProgress {
    tripId, currentMode, currentModeDisplay,
    elapsedSeconds, distanceM, segmentCount,
    isPaused, isGpsLost,
    recentPoints (List<GpsPointModel> for live map — bounded to last 500 for display)
  }
  RecordingSmartPromptFired { detectedAt }  ← show visual indicator on map
  RecordingGeneratingGpx
  RecordingComplete { tripMeta }
  RecordingError { message }

Methods:
  Future<void> init()                           ← check for orphan + subscribe to IPC stream
  Future<void> startRecording(String? initialMode)
  Future<void> stopRecording()
  Future<void> addSegmentTransition({String? mode, double? fareEgp})
  void _onServiceEvent(Map<String, dynamic> event)   ← handles all IPC events

On 'segment_split_confirmed' IPC event:
  Update currentMode to null, currentModeDisplay to "Unspecified"
  Refresh segmentCount from Hive
  Emit updated RecordingInProgress state

On 'potential_transfer' IPC event:
  Emit RecordingSmartPromptFired state briefly (for UI to show a visual cue on map)
  Then return to RecordingInProgress

---

## TASK 5: Live Recording Map Page (CrowdsourcingMapPage)

Route: '/crowdsourcing/record'

Uses BlocProvider<RecordingCubit>. Calls cubit.init() in initState.

Map: MapWidget, same config as HomeMap (same styleUri, textureView: true, disable ornaments)

Live polyline: draw from RecordingInProgress.recentPoints via MapService or direct source/layer
Color per segmentIndex using AppColors mode colors (microbusColor, minibusColor, etc.)

On RecordingSmartPromptFired: briefly pulse the current position marker in a different color
  (visual cue that the app detected something — 2 second animation, then returns to normal)

On RecordingComplete: navigate to ReviewPage with tripMeta

On stationary detection (last 10 points within 5m radius):
  Show pulsing CircleLayer at current position instead of extending polyline

Top HUD: mode chip + timer + distance (SafeArea positioned at top)
Bottom action bar: [غيّرت المواصلة] → SegmentTransitionSheet | [وصلت ✓] | [−] minimize

SegmentTransitionSheet:
  When triggered from user's direct [غيّرت المواصلة] tap:
    Standard header: "بدّلت المواصلة؟"

  When triggered after user confirms Smart Prompt ([أيوه، غيّرت]):
    Shows context: "الاسطى حس إنك غيّرت عند الساعة {time}"
    Same fare + mode inputs

Reuses FareChip widget for fare presets.
Returns ({String? mode, double? fare}).

---

## TASK 6: Review Page (ReviewPage)

Receives TripMetadataModel as GoRouter extra.

ReviewCubit state: { segments: List<TripSegmentModel>, isSubmitting, error }

Layout:
  Top 35%: static Mapbox map, full trip polyline color-coded by segment
  Remaining: SingleChildScrollView → segment cards → submit button

On page load:
  Remove segments with pointCount < 2 automatically, show snackbar

SegmentCard:
  Colored left border (mode color)
  Mode selector button (opens mode picker)
  FareFeedbackInput + FareChip presets (reuse existing)
  Delete button with confirmation

Submit flow:
  All modes set → "Submit & Contribute"
  Any mode null → "Submit Anyway" with warning (not blocked)
  On success: delete GPX file, update Hive, navigate to success screen
  On failure: show retry, keep GPX

---

## TASK 7: Contributions Page (ContributionsPage)

Load from TripLocalDataSource.getAllCompletedTripMetadata(), sort by startedAt desc.

ContributionListItem:
  Date + time
  Segment mode icons row (mode emoji → mode emoji → ?)
  Distance + segment count + total fare
  Status badge per AppColors

Actions by status:
  pending_review → [Submit →] → ReviewPage
  upload_failed  → [Retry ↑] → trigger re-upload
  uploaded       → [Edit 🖊] → ReviewPage (edit-only mode)
  pending_upload → spinner, no action

Empty state: "مفيش مساهمات لحد دلوقتي" + [ابدأ تسجيل رحلة] CTA

---

## TASK 8: Offline Upload + Workmanager

ContributionApiService.uploadContribution(meta, gpxFile):
  Dio multipart: gpx_file as MultipartFile + metadata JSON string
  Include potential_transfers array in metadata JSON
  Timeout: connectTimeout 30s, receiveTimeout 120s
  On success: return contribution_id

SubmitContributionUseCase:
  On success: updateTripAfterUpload() + delete GPX file
  On failure: updateTripStatus('upload_failed')
  Register Workmanager one-time retry task

Workmanager task (tag: 'contribution_upload_retry'):
  NetworkType.connected constraint
  Scan Hive for status='upload_failed' or 'pending_upload'
  Retry each. Max 5 attempts then stop (keep as upload_failed for manual retry).

connectivity_plus: on restore → trigger immediate retry for pending trips.

---

## TASK 9: Android Permissions

Permission sequence:
  1. ACCESS_FINE_LOCATION → standard request
  2. ACTIVITY_RECOGNITION → standard request (Android 10+)
  3. ACCESS_BACKGROUND_LOCATION → show rationale dialog first:
     "NextStation محتاج يوصل للموقع وهو في الخلفية عشان يكمل تسجيل رحلتك."
     [السماح] | [مش دلوقتي]
  4. POST_NOTIFICATIONS (Android 13+)

If ACTIVITY_RECOGNITION denied → disable Smart Prompts silently, GPS recording continues normally.
If ACCESS_BACKGROUND_LOCATION permanently denied → show settings redirect.

---

## CODING STANDARDS:

- Sizing: flutter_screenutil (.w .h .r .sp)
- Colors: AppColors only
- State: Cubit + BlocBuilder (no setState for logic)
- HTTP: sl<Dio>() with existing interceptors
- Hive: HiveService.openBox<dynamic>(CoreHiveBoxes.crowdsourcingBox)
- Navigation: GoRouter
- Error handling: safeApiCall()
- Arabic text: Directionality(textDirection: TextDirection.rtl, ...)
- DI: ServiceLocator.init() GetIt registration

## HARD CONSTRAINTS — enforce throughout:

1. flutter_activity_recognition NEVER modifies segments directly
2. Retroactive split is placed at potential_transfer_time, not at user response time
3. All potential_transfer detections (any user_response) must reach the backend
4. 60-second debounce is non-negotiable
5. Bounded buffer max 50 GPS points — no unbounded lists
6. compute() for GPX assembly — never on UI thread
7. No File System writes during active recording
8. No GPS point interpolation on signal loss
9. Notification ID 888 = persistent (ongoing), ID 889 = Smart Prompt (dismissible)

Implement TASK 1 first, then proceed in order. After each task, summarize what was built.
```

---

## Appendix: Key Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Activity recognition role | Passive detection → Smart Prompt only | Sensors suggest, user decides — no false auto-splits |
| Debounce window | 60 seconds | Filters out traffic stops and roundabouts; validated for urban Egypt conditions |
| Retroactive segment boundary | At `potential_transfer_time` (WALKING start) | GPX accuracy: the actual transfer happened then, not when user tapped notification |
| Transfer metadata to backend | ALL events (confirmed + rejected + ignored) | Backend uses rejection data to tune detection thresholds over time |
| GPX segment structure | User-confirmed only | Segments reflect user truth; detections live in metadata, not in track structure |
| Speed data role | Stationary auto-pause only | Separate concern from activity recognition; prevents 15-min zombie recordings |
| Smart Prompt cooldown | 3 minutes between prompts | Prevents notification spam in stop-and-go traffic |
| Activity recognition unavailable | Graceful fallback to GPS-only | Permission denied or unsupported device shouldn't block core recording |
