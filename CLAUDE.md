# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project status

This is **Mā** (مياه) — an Arabic-language, RTL water-level monitoring chat app for Iraq, built in Flutter. The codebase is being implemented from a fixed spec at [docs/PRD.md](docs/PRD.md). **Read the PRD first** — it is the source of truth for architecture, data model, design tokens, the Phase 2 API contract, and the milestone breakdown.

Work is organized into **milestones M0–M9** ([PRD §13](docs/PRD.md#13-milestones-for-claude-code)). Each session typically scopes to a single milestone. The milestone's "Done when:" clause is the acceptance criterion — verify it before reporting complete.

When the user says *"implement milestone N"*, the workflow is: open `docs/PRD.md`, jump to §13.N, follow its deliverables, run tests, show diff.

## Commands

Standard Flutter tooling. Flutter ≥ 3.24, Dart ≥ 3.5.

```bash
flutter pub get                                            # install deps
flutter run                                                # default device
flutter run -d windows                                     # specific platform
flutter analyze                                            # static checks
flutter test                                               # all tests
flutter test test/path/to/file_test.dart                   # one file
flutter test --name "returns 100 stations"                 # one test by name
dart run build_runner build --delete-conflicting-outputs   # regenerate freezed / json_serializable
```

After editing any `freezed` model, the `build_runner` command is required before the code will compile.

## Architecture overview

Four layers, top → bottom ([PRD §6.2](docs/PRD.md#62-high-level-diagram)):

1. **Presentation** (`lib/ui/`) — `ChatScreen`, `MessageBubble`, `ComposerBar`, and the **genui block widgets** in `lib/ui/genui_blocks/`. Each block widget renders one block-spec type from [PRD §11.1](docs/PRD.md#111-block-schemas): `StatCard`, `LineChart`, `MultiLineChart`, `RankedList`, `StationMap`, `AlertCard`, `SummaryText`. All blocks are registered with `GenUiRegistry` — the registry is the only place that maps spec → widget.
2. **Application** — `ChatController` (`lib/ui/chat/`) drives one user message through the AI loop.
3. **AI** (`lib/ai/`) — `gemma_service.dart` wraps `flutter_gemma`. `prompt_builder.dart` produces the system prompt + few-shot examples that constrain Gemma to (a) reply in Arabic, (b) call one of six tools in `lib/ai/tools/`, (c) emit a single genui block JSON. `tool_dispatcher.dart` parses tool calls and routes them to the repository. `anomaly_service.dart` runs three rules across all stations.
4. **Data** (`lib/data/`) — `WaterStationRepository` interface with two implementations: `MockWaterStationRepository` (Phase 1) and `ApiWaterStationRepository` (Phase 2, Laravel).

### The swap point — non-negotiable

The single line that switches Phase 1 mock data vs Phase 2 Laravel API lives in `lib/core/di/providers.dart`:

```dart
final waterStationRepositoryProvider = Provider<WaterStationRepository>((ref) {
  return MockWaterStationRepository();                              // Phase 1
  // return ApiWaterStationRepository(dio: ref.read(dioProvider));  // Phase 2
});
```

**No call site outside `lib/data/` may reference `MockWaterStationRepository` or `ApiWaterStationRepository` by concrete type — only the `WaterStationRepository` interface via the Riverpod provider.** This is acceptance criterion #5 ([PRD §14](docs/PRD.md#14-acceptance-criteria-for-v1-ship)). Violating it breaks Phase 2 readiness.

### AI flow (per user message)

User input → `ChatController` → `GemmaInferenceService.infer(prompt)` → Gemma emits **tool-call JSON** → `ToolDispatcher` invokes the tool against `WaterStationRepository` → tool result fed back to Gemma → Gemma emits a **single genui block JSON** → `GenUiRegistry` builds the matching Flutter widget → rendered inline in the chat. Tools: `find_station`, `get_current_level`, `get_history`, `compare_stations`, `rank_stations`, `list_alerts` ([PRD §11.2](docs/PRD.md#112-tool-calls)).

### Mock data

`lib/data/mock/mock_stations.dart` holds the static 100-station list distributed per [PRD §8.1](docs/PRD.md#81-coverage). `lib/data/mock/mock_readings.dart` exposes `generateReadings()` — **deterministic**, seeded by `station.id.hashCode` ([PRD §8.3](docs/PRD.md#83-reading-generator)). Demo reproducibility depends on this; do not introduce wall-clock or unseeded randomness into the generator.

## Project conventions

- **RTL Arabic only.** App locale forced to `ar_IQ`. Use `EdgeInsetsDirectional`, not `EdgeInsets.only(left: …)`. All user-facing copy is Arabic; English fields on models exist but are not exposed in v1.
- **Design tokens live in `lib/core/design/`** (`app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, `app_theme.dart`). Do not hard-code colors, font sizes, or spacing values in widgets — pull from tokens. Full palette and component recipes in [PRD §10](docs/PRD.md#10-design-system).
- **State management: Riverpod** (`^2.5`). Providers live in `lib/core/di/providers.dart`.
- **Models use `freezed` + `json_serializable`.** API JSON keys are `snake_case`; Dart fields are `camelCase` — see the Phase 2 contract in [PRD §9.2](docs/PRD.md#92-endpoints) for the exact wire format that `ApiWaterStationRepository` must produce.
- **`genui` is pre-1.0 (`^0.9.0`).** Keep all genui usage behind `lib/ui/genui_blocks/genui_registry.dart` so a future version bump stays localized.
- **`flutter_gemma` outputs may be unreliable for Arabic tool calls.** `ToolDispatcher` should validate parsed JSON and retry with a corrective hint on parse failure ([PRD §15](docs/PRD.md#15-risks--mitigations) — Arabic tool-calling risk).
