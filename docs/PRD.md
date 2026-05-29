# PRD — Iraq Water Level AI Assistant

**Product name (working title):** *Mā* — مياه (Water Level AI Assistant)
**Document version:** 1.0
**Status:** Draft for implementation
**Owner:** Project owner (you)
**Implementation partner:** Claude Code
**Last updated:** 2026-05-29

---

## 1. Executive Summary

Mā is a mobile/desktop chat application for monitoring **water level** across ~100 stations distributed on Iraq's water resources (rivers, dams, lakes, tributaries). Users ask questions in natural Arabic — *"What's the water level at Mosul Dam this week?"* or *"Show me stations with rising levels in the north"* — and the app responds with **Generative UI**: line charts, comparison cards, maps, and alerts rendered live inside the chat.

The app uses **on-device AI** via `flutter_gemma` for fast offline-capable responses, and renders adaptive UI via the `genui` package. In Phase 1 it ships with **local mock data** seeded for ~100 realistic Iraqi stations so the whole product can be built, demoed, and validated before any backend exists. In Phase 2 it swaps the mock data source for a **Laravel backend** without touching the UI or AI logic — thanks to a strict repository abstraction.

---

## 2. Goals and Non-Goals

### 2.1 Goals
1. Let non-technical operators query water level data in plain Arabic and get visual, interactive answers in under 3 seconds.
2. Cover **all** common questions: current level, history, comparison, ranking, trends, anomalies, alerts.
3. Work **fully offline** for the AI layer (Gemma on-device), so field workers in remote areas can still use it.
4. Ship a polished demo with **local mock data** before any backend exists.
5. Make the data source swap (mock → Laravel) a **one-file change** later.

### 2.2 Non-Goals (out of scope for v1)
- Turbidity, water quality, or any non-level sensor data.
- Writing/editing data from the app (read-only in v1).
- User management, roles, permissions (single-user demo in v1).
- Push notifications to external services (alerts shown in-app only in v1).
- Multi-language UI (Arabic only in v1; English strings stored but not exposed).

---

## 3. Target Users

| Persona | Description | Primary need |
|---|---|---|
| **Operations Engineer** | Monitors stations daily, makes operational calls | Fast situational awareness, anomaly detection |
| **Manager / Decision Maker** | Reviews regional trends | Comparison, ranking, exportable summaries |
| **Field Technician** | Visits stations, often offline | Quick station lookup, offline access |

---

## 4. User Stories (priority-ordered)

1. **As an operator**, I want to ask "What is the current level at Mosul Dam?" and get the number plus a 24-hour trend chart.
2. **As a manager**, I want to ask "Show top 5 stations by level today" and get a ranked card list with a map.
3. **As an operator**, I want to ask "Compare Mosul Dam and Haditha Dam this week" and get a dual-line chart.
4. **As an operator**, I want the app to **proactively** flag a station whose level rose unusually fast in the last 6 hours.
5. **As a manager**, I want to ask "Which stations are above their seasonal average?" and get a colored map.
6. **As a field tech**, I want the app to work without internet on previously-loaded data.
7. **As any user**, I want to tap any visual answer and drill deeper — e.g. tap a station card → full history.

---

## 5. Core Features

### F1. Arabic natural-language chat
- Free-text input in Arabic (RTL).
- The AI understands questions about stations, levels, time ranges, comparisons, rankings, anomalies.
- Voice input is **out of scope** for v1 (placeholder mic icon, disabled).

### F2. Generative UI responses
The AI returns not just text but **structured UI blocks** rendered by `genui`. Supported block types:

| Block | When AI uses it | Example trigger |
|---|---|---|
| `StatCard` | Single-value answer | "What's the level at X?" |
| `LineChart` | Time-series of one station | "Show last week at X" |
| `MultiLineChart` | Compare 2–4 stations over time | "Compare X and Y" |
| `RankedList` | Top/bottom N stations | "Top 5 highest today" |
| `StationMap` | Geographic distribution + status | "Show stations on map" |
| `AlertCard` | Anomaly or threshold breach | "Any alerts?" |
| `SummaryText` | Plain text fallback | Greetings, definitions |

Every block is **tappable** and can produce a follow-up query (genui's interaction model).

### F3. Station catalog
Static list of ~100 Iraqi stations grouped by water body and governorate. Searchable. Each station has an Arabic name, English name, lat/lng, water body, governorate, station number, install date, base/danger thresholds.

### F4. Time-series readings
Each station has hourly water level readings. The mock dataset seeds **365 days × 24 readings = 8,760 readings per station** with realistic patterns (seasonal flow, daily noise, occasional anomalies).

### F5. Anomaly detection
A simple but effective rule + statistical pipeline runs on the readings:
- **Sudden change**: |Δ in 6h| > 3 × historical std-dev → flag.
- **Threshold breach**: level > danger_high or < danger_low → flag.
- **Trend deviation**: 7-day moving average diverges > 15% from same week last year → flag.
Alerts appear both proactively (top of chat on app open) and on-demand (when user asks).

### F6. Offline-first
- All mock data ships bundled.
- Gemma model downloaded once on first launch (~500MB — to be confirmed against model variant chosen).
- Once downloaded, the entire app works offline.

### F7. Future Laravel integration (Phase 2)
- The repository interface (`WaterStationRepository`) has a `MockWaterStationRepository` (Phase 1) and an `ApiWaterStationRepository` (Phase 2) implementation.
- Swapping is a single line in the dependency-injection setup.
- API contract is documented in section 9 so the Laravel team can build to spec in parallel.

---

## 6. Technical Architecture

### 6.1 Stack

| Layer | Technology | Version / Notes |
|---|---|---|
| Framework | Flutter | Stable channel, ≥ 3.24 |
| Language | Dart | ≥ 3.5 |
| On-device AI | `flutter_gemma` | `^0.16.1` |
| Generative UI | `genui` | `^0.9.0` |
| State management | `riverpod` | `^2.5` |
| HTTP (Phase 2) | `dio` | `^5.4` |
| Local storage | `hive` + `path_provider` | for caching last sync |
| Charts (fallback) | `fl_chart` | `^0.68` — used inside genui block builders |
| Map | `flutter_map` + OpenStreetMap | no API key needed |
| i18n | `flutter_localizations` + `intl` | Arabic primary, RTL |
| Fonts | Cairo (UI), Tajawal (body) | Google Fonts |

### 6.2 High-level diagram

```
┌──────────────────────────────────────────────────────────────┐
│                       Presentation                           │
│   ChatScreen ── ComposerBar ── MessagesList ── GenUiHost     │
└────────────────────────────┬─────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────┐
│                      Application                             │
│   ChatController ── ToolDispatcher ── AnomalyService         │
└────────────────────────────┬─────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────┐
│              AI Layer (flutter_gemma)                        │
│   GemmaInferenceService ── PromptBuilder ── ToolParser       │
└────────────────────────────┬─────────────────────────────────┘
                             │
┌────────────────────────────▼─────────────────────────────────┐
│                       Data Layer                             │
│   WaterStationRepository  (interface)                        │
│        ├── MockWaterStationRepository  (Phase 1)             │
│        └── ApiWaterStationRepository   (Phase 2 — Laravel)   │
└──────────────────────────────────────────────────────────────┘
```

### 6.3 Folder structure

```
lib/
├── main.dart
├── app.dart                          # MaterialApp + theming + RTL
├── core/
│   ├── design/                       # design tokens (see §10)
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   ├── app_spacing.dart
│   │   └── app_theme.dart
│   ├── di/
│   │   └── providers.dart            # riverpod providers — SWAP POINT for repo
│   └── utils/
│       └── date_utils.dart
├── data/
│   ├── models/
│   │   ├── station.dart
│   │   ├── reading.dart
│   │   └── alert.dart
│   ├── repositories/
│   │   ├── water_station_repository.dart   # interface
│   │   ├── mock_water_station_repository.dart
│   │   └── api_water_station_repository.dart   # Phase 2
│   └── mock/
│       ├── mock_stations.dart        # ~100 stations seeded
│       └── mock_readings.dart        # generator for hourly readings
├── ai/
│   ├── gemma_service.dart
│   ├── prompt_builder.dart           # system prompt + few-shot examples
│   ├── tool_dispatcher.dart          # routes tool calls → repository
│   ├── tools/
│   │   ├── get_current_level.dart
│   │   ├── get_history.dart
│   │   ├── compare_stations.dart
│   │   ├── rank_stations.dart
│   │   ├── list_alerts.dart
│   │   └── find_station.dart
│   └── anomaly_service.dart
├── ui/
│   ├── chat/
│   │   ├── chat_screen.dart
│   │   ├── composer_bar.dart
│   │   ├── message_bubble.dart
│   │   └── chat_controller.dart
│   ├── genui_blocks/                 # genui → Flutter widget mapping
│   │   ├── stat_card_block.dart
│   │   ├── line_chart_block.dart
│   │   ├── multi_line_chart_block.dart
│   │   ├── ranked_list_block.dart
│   │   ├── station_map_block.dart
│   │   ├── alert_card_block.dart
│   │   └── genui_registry.dart       # registers all blocks with genui
│   └── shared/
│       ├── status_pill.dart
│       └── empty_state.dart
└── l10n/
    └── app_ar.arb
```

### 6.4 The swap point

The single place that decides mock vs API is one Riverpod provider in `core/di/providers.dart`:

```dart
final waterStationRepositoryProvider = Provider<WaterStationRepository>((ref) {
  // Phase 1 — local mock data
  return MockWaterStationRepository();

  // Phase 2 — swap to:
  // return ApiWaterStationRepository(dio: ref.read(dioProvider));
});
```

Nothing else in the app knows or cares which implementation it is.

---

## 7. Data Model

### 7.1 `Station`

```dart
class Station {
  final String id;                  // e.g. "STN-014"
  final int number;                 // human-readable: 14
  final String nameAr;              // "محطة سد الموصل"
  final String nameEn;              // "Mosul Dam Station"
  final String waterBodyAr;         // "نهر دجلة"
  final String waterBodyEn;         // "Tigris River"
  final WaterBodyType bodyType;     // river | dam | lake | tributary
  final String governorateAr;       // "نينوى"
  final String governorateEn;       // "Nineveh"
  final double latitude;
  final double longitude;
  final double baseLevelM;          // normal operating level (meters)
  final double dangerHighM;
  final double dangerLowM;
  final DateTime installedAt;
  final bool isActive;
}

enum WaterBodyType { river, dam, lake, tributary }
```

### 7.2 `WaterLevelReading`

```dart
class WaterLevelReading {
  final String stationId;
  final DateTime timestamp;   // top of the hour, UTC
  final double levelM;        // meters
}
```

### 7.3 `Alert`

```dart
class Alert {
  final String id;
  final String stationId;
  final AlertSeverity severity;     // info | warning | critical
  final AlertKind kind;             // suddenChange | threshold | trendDeviation
  final String messageAr;
  final DateTime detectedAt;
  final double triggerValue;
}
```

---

## 8. Mock Data Strategy (Phase 1)

### 8.1 Coverage
The mock dataset includes **100 stations** distributed across Iraq's main water resources:

| Water body | Stations | Notes |
|---|---:|---|
| Tigris River (دجلة) main stem | 24 | Mosul → Basra |
| Euphrates River (الفرات) main stem | 22 | Husaybah → Qurnah |
| Major dams | 8 | Mosul, Haditha, Dukan, Darbandikhan, Hemrin, Adhaim, Dokan, Bekhme |
| Lakes | 6 | Tharthar, Razazah, Habbaniyah, Sawa, Hamrin reservoir, Dukan reservoir |
| Greater Zab tributary | 8 | |
| Lesser Zab tributary | 7 | |
| Diyala River | 9 | |
| Adhaim River | 5 | |
| Khabur River | 4 | |
| Shatt al-Arab | 7 | |
| **Total** | **100** | |

A small extract is shown below; the full list lives in `lib/data/mock/mock_stations.dart`.

### 8.2 Example seed entries

```dart
const mockStations = <Station>[
  Station(
    id: 'STN-001', number: 1,
    nameAr: 'محطة سد الموصل', nameEn: 'Mosul Dam',
    waterBodyAr: 'نهر دجلة', waterBodyEn: 'Tigris River',
    bodyType: WaterBodyType.dam,
    governorateAr: 'نينوى', governorateEn: 'Nineveh',
    latitude: 36.6307, longitude: 42.8233,
    baseLevelM: 319.0, dangerHighM: 330.0, dangerLowM: 300.0,
    installedAt: DateTime(2023, 1, 15), isActive: true,
  ),
  Station(
    id: 'STN-002', number: 2,
    nameAr: 'محطة جسر الموصل القديم', nameEn: 'Old Mosul Bridge',
    waterBodyAr: 'نهر دجلة', waterBodyEn: 'Tigris River',
    bodyType: WaterBodyType.river,
    governorateAr: 'نينوى', governorateEn: 'Nineveh',
    latitude: 36.3450, longitude: 43.1450,
    baseLevelM: 2.4, dangerHighM: 5.5, dangerLowM: 0.8,
    installedAt: DateTime(2023, 2, 1), isActive: true,
  ),
  Station(
    id: 'STN-018', number: 18,
    nameAr: 'محطة بغداد - الجادرية', nameEn: 'Baghdad — Jadriya',
    waterBodyAr: 'نهر دجلة', waterBodyEn: 'Tigris River',
    bodyType: WaterBodyType.river,
    governorateAr: 'بغداد', governorateEn: 'Baghdad',
    latitude: 33.2780, longitude: 44.3780,
    baseLevelM: 3.2, dangerHighM: 6.5, dangerLowM: 1.5,
    installedAt: DateTime(2023, 3, 12), isActive: true,
  ),
  Station(
    id: 'STN-045', number: 45,
    nameAr: 'محطة سد حديثة', nameEn: 'Haditha Dam',
    waterBodyAr: 'نهر الفرات', waterBodyEn: 'Euphrates River',
    bodyType: WaterBodyType.dam,
    governorateAr: 'الأنبار', governorateEn: 'Anbar',
    latitude: 34.2070, longitude: 42.3580,
    baseLevelM: 147.0, dangerHighM: 154.0, dangerLowM: 135.0,
    installedAt: DateTime(2023, 1, 20), isActive: true,
  ),
  Station(
    id: 'STN-078', number: 78,
    nameAr: 'محطة البصرة - شط العرب', nameEn: 'Basra — Shatt al-Arab',
    waterBodyAr: 'شط العرب', waterBodyEn: 'Shatt al-Arab',
    bodyType: WaterBodyType.river,
    governorateAr: 'البصرة', governorateEn: 'Basra',
    latitude: 30.5085, longitude: 47.7800,
    baseLevelM: 1.8, dangerHighM: 3.5, dangerLowM: 0.5,
    installedAt: DateTime(2023, 4, 5), isActive: true,
  ),
  // ... 95 more
];
```

### 8.3 Reading generator

`mock_readings.dart` generates **deterministic** synthetic readings so demos are reproducible:

```dart
// Seeded by stationId + day, so the same station shows the same history
// regardless of when the demo is run.
List<WaterLevelReading> generateReadings({
  required Station station,
  required DateTime from,
  required DateTime to,
}) {
  final readings = <WaterLevelReading>[];
  final rng = Random(station.id.hashCode);

  for (var t = from; t.isBefore(to); t = t.add(const Duration(hours: 1))) {
    // 1. Seasonal base: sinusoidal over the year
    final dayOfYear = t.difference(DateTime(t.year)).inDays;
    final seasonal = sin(2 * pi * dayOfYear / 365) * (station.dangerHighM - station.baseLevelM) * 0.35;

    // 2. Daily cycle: small sinusoidal over 24h
    final daily = sin(2 * pi * t.hour / 24) * 0.15;

    // 3. Noise
    final noise = (rng.nextDouble() - 0.5) * 0.08;

    // 4. Occasional anomaly (~1% of readings)
    final anomaly = rng.nextDouble() < 0.01 ? (rng.nextDouble() * 1.2) : 0.0;

    final level = station.baseLevelM + seasonal + daily + noise + anomaly;
    readings.add(WaterLevelReading(
      stationId: station.id,
      timestamp: t,
      levelM: double.parse(level.toStringAsFixed(3)),
    ));
  }
  return readings;
}
```

This gives every station ~8,760 readings/year with realistic seasonality, daily noise, and occasional spikes — enough to make all features (history, comparison, ranking, anomalies) work convincingly.

---

## 9. API Contract for Phase 2 (Laravel backend)

The Laravel team can build to this contract in parallel. The Flutter app's `ApiWaterStationRepository` will call exactly these endpoints.

### 9.1 Base
- Base URL: `https://api.<your-domain>.iq/v1`
- Auth: `Authorization: Bearer <token>` (token issuance out of scope for v1)
- All responses JSON, all timestamps ISO 8601 UTC.

### 9.2 Endpoints

#### `GET /stations`
List all stations.

**Response:**
```json
{
  "data": [
    {
      "id": "STN-001",
      "number": 1,
      "name_ar": "محطة سد الموصل",
      "name_en": "Mosul Dam",
      "water_body_ar": "نهر دجلة",
      "water_body_en": "Tigris River",
      "body_type": "dam",
      "governorate_ar": "نينوى",
      "governorate_en": "Nineveh",
      "latitude": 36.6307,
      "longitude": 42.8233,
      "base_level_m": 319.0,
      "danger_high_m": 330.0,
      "danger_low_m": 300.0,
      "installed_at": "2023-01-15T00:00:00Z",
      "is_active": true
    }
  ]
}
```

#### `GET /stations/{id}/readings?from=...&to=...&interval=hour|day`
Time-series readings.

**Response:**
```json
{
  "station_id": "STN-001",
  "interval": "hour",
  "data": [
    { "timestamp": "2026-05-22T00:00:00Z", "level_m": 318.42 },
    { "timestamp": "2026-05-22T01:00:00Z", "level_m": 318.45 }
  ]
}
```

#### `GET /stations/{id}/current`
Latest reading + 24h delta.

```json
{
  "station_id": "STN-001",
  "current": { "timestamp": "2026-05-29T08:00:00Z", "level_m": 319.84 },
  "delta_24h_m": 0.42,
  "status": "normal"
}
```

#### `GET /alerts?active=true`
Open alerts across the fleet.

```json
{
  "data": [
    {
      "id": "ALR-441",
      "station_id": "STN-018",
      "severity": "warning",
      "kind": "sudden_change",
      "message_ar": "ارتفاع متسارع لمستوى الماء — بغداد الجادرية",
      "detected_at": "2026-05-29T06:00:00Z",
      "trigger_value": 4.8
    }
  ]
}
```

#### `GET /stations/rank?by=level&order=desc&limit=5&at=now`
Server-side ranking convenience.

```json
{
  "by": "level",
  "order": "desc",
  "data": [
    { "station_id": "STN-045", "level_m": 153.2, "name_ar": "..." }
  ]
}
```

### 9.3 Error format
```json
{ "error": { "code": "STATION_NOT_FOUND", "message": "..." } }
```

---

## 10. Design System

The app is **light mode only** in v1. All values below are codified in `lib/core/design/`.

### 10.1 Color tokens (`app_colors.dart`)

| Token | Hex | Usage |
|---|---|---|
| `ink` | `#0D2B3E` | Primary text, headings |
| `slate` | `#5A7283` | Secondary text |
| `line` | `#E4EDF2` | Borders, dividers |
| `bg` | `#F6FAFB` | App background |
| `card` | `#FFFFFF` | Card / surface |
| `teal` | `#0D9AA6` | Primary brand |
| `tealDark` | `#077C87` | Pressed state |
| `aqua` | `#19BCD1` | Brand accent / gradient end |
| `mint` | `#E6FBFA` | Soft brand tint |
| `mint2` | `#D5F3F5` | Borders on tinted surfaces |
| `sky` | `#EEF7FB` | Input fields |
| `ok` | `#16A575` | Normal status |
| `okBg` | `#E3F7EF` | Normal status background |
| `warn` | `#E8832F` | Warning status |
| `warnBg` | `#FDEFE1` | Warning status background |
| `danger` | `#E0445F` | Critical status |
| `dangerBg` | `#FCE8EB` | Critical status background |

Primary gradient: `LinearGradient(colors: [teal, aqua])`.

### 10.2 Typography (`app_typography.dart`)

| Style | Font | Size | Weight | Use |
|---|---|---|---|---|
| `displayLg` | Cairo | 32 | 900 | Hero titles |
| `displayMd` | Cairo | 24 | 800 | Section headers |
| `titleLg` | Cairo | 18 | 800 | Card titles |
| `titleMd` | Cairo | 15 | 700 | Subtitles |
| `bodyLg` | Tajawal | 15 | 500 | Chat messages |
| `bodyMd` | Tajawal | 13 | 400 | Body |
| `caption` | Cairo | 11 | 700 | Labels, pills |
| `metric` | Cairo | 22 | 900 | Big numbers in stat cards |

All fonts are loaded via `google_fonts` or bundled.

### 10.3 Spacing scale (`app_spacing.dart`)

```dart
class AppSpacing {
  static const xxs = 4.0;
  static const xs  = 8.0;
  static const sm  = 12.0;
  static const md  = 16.0;
  static const lg  = 24.0;
  static const xl  = 32.0;
  static const xxl = 48.0;
}
```

### 10.4 Radius scale

```dart
class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 22.0;
  static const pill = 999.0;
}
```

### 10.5 Elevation
- **Card resting**: `BoxShadow(blurRadius: 30, offset: (0, 10), color: rgba(13,43,62,0.06))`
- **Card hover/active**: `BoxShadow(blurRadius: 50, offset: (0, 24), color: rgba(13,43,62,0.10))`

### 10.6 Component recipes
- **Chat user bubble**: gradient (teal → aqua), white text, radius `lg lg xs lg`, padding `sm md`.
- **Chat bot bubble**: card surface, ink text, 1px line border, radius `lg lg lg xs`, padding `sm md`.
- **Generative UI card**: white surface, 1px line border, radius `lg`, padding `md`, soft shadow.
- **Status pill**: pill radius, caption typography, tinted background (`okBg` / `warnBg` / `dangerBg`).
- **Input field**: `sky` background, `line` border, pill radius, padding `sm md`.

### 10.7 Iconography
Use `lucide_icons` package. Custom water-drop and dam icons live in `assets/icons/`.

### 10.8 RTL & locale
- App locale forced to `ar_IQ` in v1.
- All widgets respect `Directionality.of(context)`; no `EdgeInsets.only(left:…)` — use `EdgeInsetsDirectional`.

---

## 11. Generative UI Specification

The `genui` package consumes a JSON-like spec from the AI and dispatches to registered Flutter widget builders. The AI's system prompt (in `prompt_builder.dart`) instructs Gemma to emit one of these block types.

### 11.1 Block schemas

```jsonc
// StatCard
{ "type": "stat_card",
  "title": "محطة سد الموصل",
  "value": 319.84, "unit": "م",
  "delta": "+0.42 م خلال 24 ساعة",
  "status": "normal" }

// LineChart
{ "type": "line_chart",
  "title": "مستوى الماء — سد الموصل (آخر 7 أيام)",
  "station_id": "STN-001",
  "points": [{"t": "2026-05-22T00:00:00Z", "v": 318.4}],
  "danger_high": 330.0, "danger_low": 300.0 }

// MultiLineChart
{ "type": "multi_line_chart",
  "title": "مقارنة سد الموصل وسد حديثة",
  "series": [
    {"label": "سد الموصل", "points": []},
    {"label": "سد حديثة", "points": []}
  ] }

// RankedList
{ "type": "ranked_list",
  "title": "أعلى 5 محطات اليوم",
  "items": [
    {"station_id": "STN-001", "name": "سد الموصل", "value": 319.84, "unit": "م"}
  ] }

// StationMap
{ "type": "station_map",
  "title": "حالة المحطات",
  "markers": [
    {"station_id": "STN-001", "lat": 36.6307, "lng": 42.8233, "status": "normal"}
  ] }

// AlertCard
{ "type": "alert_card",
  "severity": "warning",
  "title": "ارتفاع متسارع — بغداد الجادرية",
  "body": "احتمال تجاوز حد التحذير خلال 4 ساعات.",
  "station_id": "STN-018",
  "ai_note": "النمط يطابق موجة موسمية من العام الماضي." }

// SummaryText  (fallback)
{ "type": "summary_text", "text": "..." }
```

### 11.2 Tool calls

Gemma is given a small set of tools it must call to fetch data. The dispatcher (in `ai/tool_dispatcher.dart`) routes each tool call to the repository.

| Tool | Parameters | Returns |
|---|---|---|
| `find_station` | `query: string` | matched stations |
| `get_current_level` | `station_id` | latest reading + delta |
| `get_history` | `station_id, from, to, interval` | readings array |
| `compare_stations` | `station_ids[], from, to` | parallel readings |
| `rank_stations` | `by, order, limit, at` | ranked list |
| `list_alerts` | `active: bool` | alerts array |

The AI's job is: **parse user intent → call tools → assemble a genui block → return**.

### 11.3 Example end-to-end

User: *"كيف مستوى الماء في سد الموصل خلال هذا الأسبوع؟"*

1. Gemma: calls `find_station("سد الموصل")` → `STN-001`.
2. Gemma: calls `get_history(STN-001, now-7d, now, hour)`.
3. Gemma: emits a `line_chart` block with the points + danger lines.
4. Flutter renders `LineChartBlock` widget inline in the chat.

---

## 12. Key Screens (v1)

| # | Screen | Purpose |
|---|---|---|
| 1 | **Splash** | Brand + Gemma model load check |
| 2 | **Onboarding (first run)** | One screen explaining what the app does, downloads model |
| 3 | **Chat (home)** | The product. Composer + scrolling message list + genui blocks |
| 4 | **Station detail** | Opened by tapping a station name; full info + 30-day chart |
| 5 | **Alerts list** | Opened from a pill in the chat header |
| 6 | **Settings** | Model status, theme toggle (Phase 2), data source indicator |

---

## 13. Milestones for Claude Code

The work is broken into **9 milestones**, each independently shippable and demoable. Each has a clear deliverable, acceptance criteria, and an estimated effort in "Claude Code working sessions" (CCS — roughly a few hours of focused agentic coding each).

> **How to drive Claude Code with this PRD:** create a `/docs/PRD.md` in the repo, then in each session say: *"Read `/docs/PRD.md` and implement Milestone N. When done, run all tests and show me the diff."*

### M0 — Project scaffolding (1 CCS)
- Create Flutter project, set up folder structure from §6.3.
- Add all dependencies from §6.1 to `pubspec.yaml`.
- Configure RTL + Arabic locale.
- Add design tokens (§10): colors, typography, spacing, radius, theme.
- Set up Riverpod with `ProviderScope`.
- **Done when:** `flutter run` opens a blank app with brand colors and Arabic typography correctly rendered RTL.

### M1 — Mock data layer (1 CCS)
- Implement `Station`, `WaterLevelReading`, `Alert` models with `freezed` + `json_serializable`.
- Implement `WaterStationRepository` interface.
- Implement `MockWaterStationRepository` with all methods.
- Seed all **100 stations** in `mock_stations.dart` (see §8.1 distribution).
- Implement `generateReadings()` (§8.3) — deterministic, seeded.
- Register the mock repo in `providers.dart` as the active implementation.
- Unit tests: at least one test per repository method.
- **Done when:** `MockWaterStationRepository().getStations()` returns 100 valid stations, `getHistory()` returns hourly readings, all tests green.

### M2 — Chat shell + design system in action (1 CCS)
- Build `ChatScreen`: app bar with brand + live indicator + alerts pill, scrolling message list, composer bar.
- Build `MessageBubble` (user + bot variants) with the design recipes from §10.6.
- Wire a fake "echo" reply so messages send and appear.
- Empty state for first-time users.
- **Done when:** typing a message shows the user bubble, then a bot echo bubble, with correct RTL layout and design tokens.

### M3 — Genui block registry + first 3 blocks (1–2 CCS)
- Set up the `genui` package and the `GenUiRegistry`.
- Implement these block widgets first: `StatCardBlock`, `LineChartBlock`, `SummaryTextBlock`.
- Each block reads its spec (§11.1) and renders with `fl_chart` where needed.
- Hard-code a sample bot reply that emits each block type, to validate rendering.
- **Done when:** sending any message returns a hard-coded reply containing one of the three block types, rendered correctly.

### M4 — Remaining genui blocks (1 CCS)
- `MultiLineChartBlock`, `RankedListBlock`, `StationMapBlock`, `AlertCardBlock`.
- Map uses `flutter_map` + OpenStreetMap, no API key.
- All blocks tappable and emit a follow-up query event.
- **Done when:** all 7 block types render from sample specs; tapping a station marker opens the station detail screen.

### M5 — flutter_gemma integration (2 CCS)
- Add `GemmaInferenceService` wrapping `flutter_gemma`.
- Onboarding screen that downloads the model on first run with progress.
- `PromptBuilder` produces the system prompt + few-shot examples teaching Gemma to:
  - Reply in Arabic.
  - Call one of the 6 tools (§11.2).
  - Emit a single genui block JSON.
- `ToolDispatcher` parses tool calls, routes to the repository, feeds results back to Gemma.
- **Done when:** asking *"شو مستوى الماء في سد الموصل؟"* returns a `stat_card` block with the correct value from mock data.

### M6 — Anomaly detection + alerts (1 CCS)
- Implement `AnomalyService` with the 3 rules from §F5.
- Run it across all stations on app start; cache results.
- "Alerts" pill in app bar shows count; tapping opens alerts list.
- On chat open, if any critical alerts exist, prepend an `alert_card` block.
- **Done when:** at least one mock station has a synthetic anomaly seeded that triggers a visible alert on app launch.

### M7 — Station detail + drill-down (1 CCS)
- `StationDetailScreen` opened from any station reference (chat link, map marker, ranked-list item).
- Header with station meta + status pill.
- 30-day line chart with danger lines.
- "Ask about this station" button → pre-fills the composer.
- **Done when:** every place a station appears in the app is tappable and lands on the detail screen.

### M8 — Polish, empty/error states, performance pass (1 CCS)
- Loading skeletons for chat replies (Gemma can take 1–2 seconds).
- Empty state, network error placeholder (even though we're local, prep for Phase 2).
- Smooth scroll, list virtualization, keep last 50 messages.
- App icon, splash, basic onboarding copy.
- README with run instructions.
- **Done when:** the app is demo-ready: launch, chat, get visual answers, drill in, no jank, no crashes.

### M9 — Phase 2 readiness (deferred until backend exists, ~1 CCS)
- Implement `ApiWaterStationRepository` against the §9 contract using `dio`.
- Add `dioProvider` and switch `waterStationRepositoryProvider` to the API version.
- Add a tiny banner in Settings showing "Connected to: API @ <host>" vs "Mock data".
- Add Hive caching so the last successful sync is available offline.
- **Done when:** flipping one line in `providers.dart` runs the entire app against the live Laravel backend.

---

## 14. Acceptance Criteria for v1 ship

The product is considered v1-ready when **all** of these are true:

1. App runs on Android, iOS, Windows, macOS, Linux from a single Flutter codebase.
2. 100 stations are queryable; ≥10 representative questions (see §4) return correct visual answers.
3. AI response p50 latency < 3s on a mid-range Android device once the model is loaded.
4. All UI is RTL Arabic, design tokens applied consistently.
5. No call site outside `data/` references `MockWaterStationRepository` directly — only the interface.
6. README documents how to switch to API mode in Phase 2.

---

## 15. Risks & mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Gemma model too large for low-end phones | Medium | High | Choose smallest variant (Gemma 2B int4), test on 4GB devices, fall back to text-only mode |
| Arabic tool-calling reliability | Medium | High | Strong few-shot examples in prompt; validation step that retries with corrective hint on parse failure |
| genui v0.9 API churn (pre-1.0) | Medium | Medium | Pin exact version; isolate genui usage behind the block registry to make migration localized |
| Mock data feels fake in demo | Low | Medium | Deterministic seeding + realistic seasonality; salt with curated "interesting" events for demo days |
| Laravel API contract drift | Medium | Medium | Lock §9 with the backend team before they start; version the API (`/v1`) |

---

## 16. Open questions

1. Which exact Gemma variant ships? (2B vs 7B, quantization) — decide after a benchmark on target devices.
2. Should the app store the chat history across launches? — proposed: yes, last 7 days, Hive-backed.
3. Brand identity — does the customer have a logo/wordmark, or is it ours to design?
4. Final list of station thresholds (`danger_high_m`, `danger_low_m`) per real station — needs domain input from the water authority.

---

## 17. Glossary

| Term | Meaning |
|---|---|
| **Genui** | A Dart/Flutter package that turns AI-generated UI specs into real Flutter widgets at runtime |
| **flutter_gemma** | A Flutter package that runs Google's Gemma models on-device |
| **Generative UI** | UI assembled by the AI per response, instead of fixed screens |
| **Tool call** | A structured function the AI invokes to fetch data instead of guessing |
| **Repository** | The data-source abstraction; Phase 1 = local mock, Phase 2 = Laravel API |

---

*End of document.*
