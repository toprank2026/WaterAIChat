import 'package:flutter/foundation.dart';

/// Immutable user/app settings persisted in the Hive box `app_settings`.
///
/// Holds the Gemini API key and the selected Gemini model. The key is optional
/// (the app can run without one until the user provides it); the model has a
/// sensible default.
@immutable
class AppSettings {
  const AppSettings({
    this.geminiApiKey,
    this.geminiModel = 'gemini-2.5-flash-lite',
  });

  /// The user-provided Gemini API key, or `null`/empty when not configured.
  final String? geminiApiKey;

  /// The selected Gemini model identifier.
  final String geminiModel;

  /// `true` when a non-blank Gemini API key has been configured.
  bool get hasGeminiKey => (geminiApiKey?.trim().isNotEmpty ?? false);

  /// Returns a copy with the given fields replaced.
  ///
  /// Pass [clearKey] `true` to explicitly unset [geminiApiKey] (this takes
  /// precedence over [geminiApiKey]).
  AppSettings copyWith({
    String? geminiApiKey,
    bool clearKey = false,
    String? geminiModel,
  }) {
    return AppSettings(
      geminiApiKey: clearKey ? null : (geminiApiKey ?? this.geminiApiKey),
      geminiModel: geminiModel ?? this.geminiModel,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          runtimeType == other.runtimeType &&
          geminiApiKey == other.geminiApiKey &&
          geminiModel == other.geminiModel;

  @override
  int get hashCode => Object.hash(geminiApiKey, geminiModel);

  @override
  String toString() =>
      'AppSettings(hasGeminiKey: $hasGeminiKey, geminiModel: $geminiModel)';
}
