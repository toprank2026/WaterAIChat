import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:ma_water/core/settings/app_settings.dart';

/// Name of the Hive box that backs [AppSettings].
///
/// The box must already be opened (see `main.dart`) before any provider here
/// is read.
const String settingsBoxName = 'app_settings';

/// Hive key for the persisted Gemini API key.
const String _kGeminiApiKey = 'gemini_api_key';

/// Hive key for the persisted Gemini model identifier.
const String _kGeminiModel = 'gemini_model';

/// Exposes the current [AppSettings] and the [SettingsController] used to
/// mutate them.
final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

/// Reads and writes [AppSettings] against the already-open Hive box
/// [settingsBoxName].
class SettingsController extends Notifier<AppSettings> {
  Box get _box => Hive.box(settingsBoxName);

  /// Optional build-time key (e.g. `--dart-define=GEMINI_API_KEY=...`) used as a
  /// fallback when no key has been saved in-app. A key entered in Settings always
  /// takes precedence.
  static const String _envApiKey = String.fromEnvironment('GEMINI_API_KEY');

  @override
  AppSettings build() {
    final box = _box;
    final String? stored = box.get(_kGeminiApiKey) as String?;
    final String? key = (stored != null && stored.trim().isNotEmpty)
        ? stored
        : (_envApiKey.isNotEmpty ? _envApiKey : null);
    final String model =
        (box.get(_kGeminiModel) as String?) ?? const AppSettings().geminiModel;
    return AppSettings(geminiApiKey: key, geminiModel: model);
  }

  /// Persists [key] (trimmed) as the Gemini API key and updates state.
  ///
  /// Passing `null` or a blank value clears the stored key.
  Future<void> setGeminiApiKey(String? key) async {
    final String? trimmed = key?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      await _box.delete(_kGeminiApiKey);
      state = state.copyWith(clearKey: true);
    } else {
      await _box.put(_kGeminiApiKey, trimmed);
      state = state.copyWith(geminiApiKey: trimmed);
    }
  }

  /// Persists [model] as the selected Gemini model and updates state.
  Future<void> setGeminiModel(String model) async {
    await _box.put(_kGeminiModel, model);
    state = state.copyWith(geminiModel: model);
  }
}
