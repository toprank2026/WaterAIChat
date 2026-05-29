# Mā — مياه

**Iraq Water-Level AI Assistant.** A cross-platform Flutter chat app for monitoring water level across ~100 stations on Iraq's rivers, dams, and lakes. Users ask questions in natural Arabic and get **Generative UI** answers — line charts, comparison cards, maps, and alerts rendered live inside the chat.

The full product spec is in [`docs/PRD.md`](docs/PRD.md); architecture notes are in [`CLAUDE.md`](CLAUDE.md).

- **On-device AI:** `flutter_gemma` (offline-capable inference).
- **State:** Riverpod.
- **UI:** RTL Arabic, light mode, design tokens in `lib/core/design/`.
- **Data:** Phase 1 ships bundled mock data for 100 stations. Phase 2 swaps to a Laravel backend via one line — see below.

## Running

```bash
flutter pub get                                            # install dependencies
dart run build_runner build --delete-conflicting-outputs   # generate freezed / json_serializable code
flutter run                                                # launch on the default device
```

To target a specific platform:

```bash
flutter run -d windows        # or: -d chrome, -d macos, -d linux, or an Android/iOS device id
```

Useful checks:

```bash
flutter analyze   # static analysis
flutter test      # unit + widget tests
```

> **Note:** `build_runner` is required whenever a `freezed` / `json_serializable` model changes, otherwise the generated `*.g.dart` / `*.freezed.dart` parts will be missing and the code will not compile.

## Switching to API mode (Phase 2)

The entire app talks to data only through the `WaterStationRepository` interface, resolved by a single Riverpod provider. Flipping from bundled mock data to the live Laravel API is a **one-line change** in [`lib/core/di/providers.dart`](lib/core/di/providers.dart):

```dart
final waterStationRepositoryProvider = Provider<WaterStationRepository>((ref) {
  return MockWaterStationRepository();                              // Phase 1 — bundled mock data
  // return ApiWaterStationRepository(dio: ref.read(dioProvider));  // Phase 2 — Laravel API
});
```

Comment out the `MockWaterStationRepository()` line and uncomment the `ApiWaterStationRepository(...)` line. Nothing else in the app references a concrete repository implementation (acceptance criterion #5, PRD §14), so no UI or AI code changes are needed. The API contract `ApiWaterStationRepository` is built against is documented in [PRD §9](docs/PRD.md#9-api-contract-for-phase-2-laravel-backend).
