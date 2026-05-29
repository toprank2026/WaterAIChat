import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/core/design/color_block.dart';
import 'package:ma_water/core/di/providers.dart';
import 'package:ma_water/core/settings/settings_providers.dart';
import 'package:ma_water/ui/shared/animated_gradient.dart';

/// Settings & app-info screen for the "Mā" app.
///
/// Surfaces the active data source (local Mock vs. remote API), an interactive
/// Google Gemini connection card (API key + model, persisted via
/// [settingsControllerProvider]), and basic "about" metadata. The data-source
/// banner is derived from the repository runtime type so no concrete repository
/// is imported here.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// App version label shown in the "حول التطبيق" section.
  static const String _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Derive the data-source label without importing the concrete repository.
    // The DI swap point is `waterStationRepositoryProvider`; in Phase 2 this
    // becomes an API-backed repository, so we branch on the runtime type name.
    final String repoTypeName =
        ref.read(waterStationRepositoryProvider).runtimeType.toString();
    final bool isMock = repoTypeName.contains('Mock');

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('الإعدادات', style: AppTextStyles.titleLg),
        backgroundColor: AppColors.canvas,
        surfaceTintColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.xs,
          AppSpacing.md,
          AppSpacing.xl,
        ),
        children: [
          // Flat ink hairline accent at the top of the settings list.
          const _GradientAccent(),
          const SizedBox(height: AppSpacing.xl),
          _SectionLabel(text: 'مصدر البيانات'),
          const SizedBox(height: AppSpacing.sm),
          _DataSourceBanner(isMock: isMock, repoTypeName: repoTypeName),
          const SizedBox(height: AppSpacing.xl),
          _SectionLabel(text: 'الذكاء الاصطناعي'),
          const SizedBox(height: AppSpacing.sm),
          const _GeminiCard(),
          const SizedBox(height: AppSpacing.xl),
          _SectionLabel(text: 'المظهر'),
          const SizedBox(height: AppSpacing.sm),
          const _ThemeToggleCard(),
          const SizedBox(height: AppSpacing.xl),
          _SectionLabel(text: 'حول التطبيق'),
          const SizedBox(height: AppSpacing.sm),
          const _AboutCard(version: _appVersion),
        ],
      ),
    );
  }
}

/// A thin flat ink hairline used as a quiet editorial rule at the top of the
/// settings list. (Formerly an animated Gemini gradient bar; the kit is now
/// flat, so this resolves to a solid ink line.)
class _GradientAccent extends StatelessWidget {
  const _GradientAccent();

  @override
  Widget build(BuildContext context) {
    return AnimatedGradient(
      colors: const [AppColors.ink],
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: const SizedBox(height: AppSpacing.hair, width: double.infinity),
    );
  }
}

/// A small uppercase mono eyebrow heading used between sections.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.xxs),
      child: Text(text, style: AppTextStyles.eyebrow),
    );
  }
}

/// A flat white card with a 1px hairline border used to group related rows.
/// No shadow — depth comes from the hairline (DESIGN.md → elevation level 1).
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Banner indicating whether the app reads local mock data or a remote API.
///
/// Rendered as a single flat pastel color block whose hue carries the severity
/// (coral for the temporary mock source, mint for a live connection) — the
/// color is the depth device; no shadow.
class _DataSourceBanner extends StatelessWidget {
  const _DataSourceBanner({
    required this.isMock,
    required this.repoTypeName,
  });

  final bool isMock;
  final String repoTypeName;

  @override
  Widget build(BuildContext context) {
    final Color accent = isMock ? AppColors.warn : AppColors.ok;
    final Color blockColor = isMock ? AppColors.warnBg : AppColors.okBg;
    final IconData icon =
        isMock ? Icons.storage_rounded : Icons.cloud_done_rounded;
    final String eyebrow = isMock ? 'MOCK / LOCAL' : 'LIVE / API';
    final String title =
        isMock ? 'البيانات المحلية (Mock)' : 'API @ <host>';
    final String subtitle = isMock
        ? 'يتم استخدام بيانات تجريبية مخزّنة داخل التطبيق.'
        : 'متصل بخادم البيانات الحيّة عبر الإنترنت.';

    return ColorBlock(
      color: blockColor,
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Solid ink glyph chip — flat, no tint fill.
          Container(
            width: AppSpacing.xl + AppSpacing.xs,
            height: AppSpacing.xl + AppSpacing.xs,
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: AppSpacing.lg, color: AppColors.canvas),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  // Mono eyebrow tinted with the severity foreground.
                  style: AppTextStyles.eyebrow.copyWith(color: accent),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(title, style: AppTextStyles.titleMd),
                const SizedBox(height: AppSpacing.xxs),
                Text(subtitle, style: AppTextStyles.bodyMd),
                const SizedBox(height: AppSpacing.xxs),
                // Keep the runtimeType data-source diagnostic visible.
                Text(
                  repoTypeName,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive card for connecting the app to Google Gemini.
///
/// Bound to [settingsControllerProvider]: lets the user enter/save/clear an
/// obscured API key, optionally override the model, and shows a live connection
/// status line. The key is persisted locally (Hive) on the device only.
class _GeminiCard extends ConsumerStatefulWidget {
  const _GeminiCard();

  @override
  ConsumerState<_GeminiCard> createState() => _GeminiCardState();
}

class _GeminiCardState extends ConsumerState<_GeminiCard> {
  late final TextEditingController _keyController;
  late final TextEditingController _modelController;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsControllerProvider);
    _keyController = TextEditingController(text: settings.geminiApiKey ?? '');
    _modelController = TextEditingController(text: settings.geminiModel);
  }

  @override
  void dispose() {
    _keyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _saveKey() {
    final value = _keyController.text.trim();
    ref.read(settingsControllerProvider.notifier).setGeminiApiKey(value);
    FocusScope.of(context).unfocus();
    _showSnack(value.isEmpty ? 'تم مسح المفتاح' : 'تم حفظ المفتاح');
  }

  void _clearKey() {
    _keyController.clear();
    ref.read(settingsControllerProvider.notifier).setGeminiApiKey(null);
    FocusScope.of(context).unfocus();
    _showSnack('تم مسح المفتاح');
  }

  void _saveModel() {
    final value = _modelController.text.trim();
    if (value.isEmpty) {
      // Fall back to the default model rather than persisting an empty value.
      const fallback = 'gemini-2.0-flash';
      _modelController.text = fallback;
      ref.read(settingsControllerProvider.notifier).setGeminiModel(fallback);
    } else {
      ref.read(settingsControllerProvider.notifier).setGeminiModel(value);
    }
    FocusScope.of(context).unfocus();
    _showSnack('تم حفظ النموذج');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.canvas),
            textAlign: TextAlign.start,
          ),
          backgroundColor: AppColors.ink,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final bool connected = settings.hasGeminiKey;

    return _SettingsCard(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: solid-ink sparkle chip + title + status.
            Row(
              children: [
                Container(
                  width: AppSpacing.xl + AppSpacing.xs,
                  height: AppSpacing.xl + AppSpacing.xs,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: const GradientIcon(
                    icon: Icons.auto_awesome,
                    size: AppSpacing.md + AppSpacing.xxs,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Google Gemini', style: AppTextStyles.titleMd),
                      const SizedBox(height: AppSpacing.xxs),
                      _StatusLine(connected: connected),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, thickness: 1, color: AppColors.hairline),
            const SizedBox(height: AppSpacing.md),

            // API key field.
            Text(
              'مفتاح Gemini API',
              style: AppTextStyles.eyebrow,
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _keyController,
              obscureText: _obscured,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              style: AppTextStyles.bodyLg,
              cursorColor: AppColors.ink,
              decoration: _fieldDecoration(
                hint: 'ألصق مفتاح API هنا',
                suffix: IconButton(
                  tooltip: _obscured ? 'إظهار' : 'إخفاء',
                  onPressed: () => setState(() => _obscured = !_obscured),
                  icon: Icon(
                    _obscured
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    color: AppColors.slate,
                    size: AppSpacing.lg,
                  ),
                ),
              ),
              onSubmitted: (_) => _saveKey(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                // Primary pill: ink fill + white text.
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saveKey,
                    icon: const Icon(Icons.check_rounded, size: AppSpacing.md),
                    label: Text(
                      'حفظ',
                      style: AppTextStyles.titleMd
                          .copyWith(color: AppColors.canvas),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: AppColors.canvas,
                      elevation: 0,
                      padding: const EdgeInsetsDirectional.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Secondary pill: white fill + ink text + hairline border.
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: connected ? _clearKey : null,
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: AppSpacing.md),
                    label: Text(
                      'مسح',
                      style: AppTextStyles.titleMd.copyWith(color: AppColors.ink),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.ink,
                      backgroundColor: AppColors.canvas,
                      side: const BorderSide(color: AppColors.hairline),
                      padding: const EdgeInsetsDirectional.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, thickness: 1, color: AppColors.hairline),
            const SizedBox(height: AppSpacing.md),

            // Optional model override.
            Text(
              'النموذج (اختياري)',
              style: AppTextStyles.eyebrow,
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _modelController,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              style: AppTextStyles.bodyLg,
              cursorColor: AppColors.ink,
              decoration: _fieldDecoration(
                hint: 'gemini-2.0-flash',
                suffix: TextButton(
                  onPressed: _saveModel,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.ink,
                  ),
                  child: Text(
                    'حفظ',
                    style: AppTextStyles.titleMd.copyWith(color: AppColors.ink),
                  ),
                ),
              ),
              onSubmitted: (_) => _saveModel(),
            ),

            const SizedBox(height: AppSpacing.md),
            // Hint: where to get a key + local-only storage. Flat soft surface.
            Container(
              padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.ink,
                    size: AppSpacing.md + AppSpacing.xxs,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'احصل على مفتاح مجاني من Google AI Studio '
                      '(aistudio.google.com). يُحفظ المفتاح محليًا على هذا '
                      'الجهاز فقط ولا يُرسل إلى أي خادم آخر.',
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.slate),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({required String hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.slate),
      isDense: true,
      filled: true,
      fillColor: AppColors.canvas,
      suffixIcon: suffix,
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
      ),
    );
  }
}

/// Connection status line with a Gemini sparkle.
///
/// Shows a solid-ink "connected" state when an API key is configured, otherwise
/// a muted "local engine" state. (The kit is now flat, so the sparkle/text
/// render in solid ink.)
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    if (connected) {
      return Row(
        children: [
          const GradientIcon(icon: Icons.auto_awesome, size: AppSpacing.md),
          const SizedBox(width: AppSpacing.xxs),
          GradientText(
            'متصل بـ Google Gemini',
            style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      );
    }
    return Row(
      children: [
        const Icon(
          Icons.offline_bolt_rounded,
          size: AppSpacing.md,
          color: AppColors.slate,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Flexible(
          child: Text(
            'المحرك المحلي (بدون اتصال)',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.slate),
          ),
        ),
      ],
    );
  }
}

/// Disabled theme toggle — only light mode ships in v1.
class _ThemeToggleCard extends StatelessWidget {
  const _ThemeToggleCard();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      child: ListTile(
        enabled: false,
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: _LeadingIcon(
          icon: Icons.dark_mode_rounded,
          color: AppColors.slate,
        ),
        title: Text(
          'الوضع الداكن (قريباً)',
          style: AppTextStyles.titleMd.copyWith(color: AppColors.slate),
        ),
        subtitle: Padding(
          padding: const EdgeInsetsDirectional.only(top: AppSpacing.xxs),
          child: Text(
            'الإصدار الحالي يدعم الوضع الفاتح فقط.',
            style: AppTextStyles.bodyMd.copyWith(color: AppColors.slate),
          ),
        ),
        trailing: AbsorbPointer(
          child: Opacity(
            opacity: 0.5,
            child: Switch(
              value: false,
              onChanged: (_) {},
              activeThumbColor: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Card with app identity, version, and a short Arabic description.
class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Solid ink identity chip (flat — no gradient).
                Container(
                  width: AppSpacing.xl + AppSpacing.xs,
                  height: AppSpacing.xl + AppSpacing.xs,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: AppColors.canvas,
                    size: AppSpacing.lg,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('مياه', style: AppTextStyles.titleLg),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'الإصدار $version',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.slate,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, thickness: 1, color: AppColors.hairline),
            const SizedBox(height: AppSpacing.md),
            Text(
              'مساعد ذكي لمراقبة مناسيب المياه في العراق، يقدّم تحليلات '
              'وتنبيهات فورية حول المحطات لمساعدتك على اتخاذ القرار في الوقت '
              'المناسب.',
              style: AppTextStyles.bodyLg.copyWith(color: AppColors.slate),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rounded-square container holding a leading list-tile icon, flat soft surface.
class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.xl,
      height: AppSpacing.xl,
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: AppSpacing.md + AppSpacing.xxs, color: color),
    );
  }
}
