import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/core/di/providers.dart';

/// Read-only settings & app-info screen for the "Mā" app.
///
/// Surfaces the active data source (local Mock vs. remote API), the AI
/// inference engine in use, and basic "about" metadata. Everything here is
/// informational — no settings are mutated and no new providers are declared.
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
        backgroundColor: AppColors.card,
        surfaceTintColor: AppColors.card,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.all(AppSpacing.md),
        children: [
          _SectionLabel(text: 'مصدر البيانات'),
          const SizedBox(height: AppSpacing.xs),
          _DataSourceBanner(isMock: isMock, repoTypeName: repoTypeName),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel(text: 'نموذج الذكاء الاصطناعي'),
          const SizedBox(height: AppSpacing.xs),
          const _AiModelCard(),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel(text: 'المظهر'),
          const SizedBox(height: AppSpacing.xs),
          const _ThemeToggleCard(),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel(text: 'حول التطبيق'),
          const SizedBox(height: AppSpacing.xs),
          const _AboutCard(version: _appVersion),
        ],
      ),
    );
  }
}

/// A small uppercase-style section heading used between cards.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: AppColors.slate),
      ),
    );
  }
}

/// A rounded card surface used to group related rows.
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// Banner indicating whether the app reads local mock data or a remote API.
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
    final Color accentBg = isMock ? AppColors.warnBg : AppColors.okBg;
    final IconData icon =
        isMock ? Icons.storage_rounded : Icons.cloud_done_rounded;
    final String title =
        isMock ? 'البيانات المحلية (Mock)' : 'API @ <host>';
    final String subtitle = isMock
        ? 'يتم استخدام بيانات تجريبية مخزّنة داخل التطبيق.'
        : 'متصل بخادم البيانات الحيّة عبر الإنترنت.';

    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accentBg,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: AppSpacing.xl,
            height: AppSpacing.xl,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, size: AppSpacing.lg, color: accent),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMd.copyWith(color: accent),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.slate),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card describing the active inference engine and the planned Gemma upgrade.
class _AiModelCard extends StatelessWidget {
  const _AiModelCard();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xxs,
            ),
            leading: _LeadingIcon(
              icon: Icons.psychology_rounded,
              color: AppColors.teal,
            ),
            title: Text(
              'المحرك: استدلالي محلي (Heuristic)',
              style: AppTextStyles.titleMd,
            ),
            subtitle: Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.xxs),
              child: Text(
                'يعمل التحليل بالكامل على الجهاز دون اتصال بالنماذج السحابية.',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.slate),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.line),
          ListTile(
            contentPadding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xxs,
            ),
            leading: _LeadingIcon(
              icon: Icons.auto_awesome_rounded,
              color: AppColors.slate,
            ),
            title: Text(
              'نموذج Gemma',
              style: AppTextStyles.titleMd.copyWith(color: AppColors.slate),
            ),
            subtitle: Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSpacing.xxs),
              child: Text(
                'يمكن تفعيل نموذج Gemma لاحقًا لتحسين دقة الإجابات.',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.slate),
              ),
            ),
            trailing: const _SoonBadge(),
          ),
        ],
      ),
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
          vertical: AppSpacing.xxs,
        ),
        leading: _LeadingIcon(
          icon: Icons.dark_mode_rounded,
          color: AppColors.slate,
        ),
        title: Text(
          'الوضع الداكن',
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
              activeThumbColor: AppColors.teal,
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
                Container(
                  width: AppSpacing.xl + AppSpacing.xs,
                  height: AppSpacing.xl + AppSpacing.xs,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: AppColors.card,
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
                        style: AppTextStyles.bodyMd
                            .copyWith(color: AppColors.slate),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.line),
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

/// Rounded square container holding a leading list-tile icon.
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
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, size: AppSpacing.md + AppSpacing.xxs, color: color),
    );
  }
}

/// A small "(قريباً)" pill marking not-yet-available features.
class _SoonBadge extends StatelessWidget {
  const _SoonBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.sky,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'قريباً',
        style: AppTextStyles.caption.copyWith(color: AppColors.teal),
      ),
    );
  }
}
