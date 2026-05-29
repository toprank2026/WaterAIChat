import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/ui/chat/chat_screen.dart';
import 'package:ma_water/ui/onboarding/onboarding_screen.dart';

/// The launch screen for "Mā".
///
/// Shows a full-bleed [AppColors.primaryGradient] background with a centered
/// white brand lockup and the Arabic tagline, then routes onward after a brief
/// delay.
///
/// In v1 the app always proceeds straight to [ChatScreen] for simplicity, but
/// the [OnboardingScreen] route is kept available (and would be shown on first
/// run once a real "first run" flag is wired up).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Whether this is the user's first launch. When `true` the splash would
  /// route to [OnboardingScreen]; for v1 we always go to [ChatScreen].
  static const bool isFirstRun = false;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1500), _goNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goNext() {
    if (!mounted) return;
    // v1: always go to the chat. The onboarding route remains available for a
    // future first-run flow (see [SplashScreen.isFirstRun]).
    final Widget next = SplashScreen.isFirstRun
        ? const OnboardingScreen()
        : const ChatScreen();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // White brand lockup: drop glyph + "مياه" wordmark.
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.water_drop,
                    size: 56,
                    color: AppColors.card,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'مياه',
                    style: AppTextStyles.displayLg.copyWith(
                      color: AppColors.card,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.xl,
                ),
                child: Text(
                  'مساعد مستوى المياه في العراق',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLg.copyWith(
                    color: AppColors.card,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
