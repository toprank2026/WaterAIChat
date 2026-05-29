import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ma_water/core/design/app_colors.dart';
import 'package:ma_water/core/design/app_radius.dart';
import 'package:ma_water/core/design/app_spacing.dart';
import 'package:ma_water/core/design/app_typography.dart';
import 'package:ma_water/core/di/providers.dart';
import 'package:ma_water/ui/alerts/alerts_screen.dart';
import 'package:ma_water/ui/chat/chat_controller.dart';
import 'package:ma_water/ui/chat/chat_models.dart';
import 'package:ma_water/ui/chat/composer_bar.dart';
import 'package:ma_water/ui/chat/message_bubble.dart';
import 'package:ma_water/ui/genui_blocks/genui_registry.dart';
import 'package:ma_water/ui/settings/settings_screen.dart';
import 'package:ma_water/ui/shared/brand_logo.dart';
import 'package:ma_water/ui/shared/empty_state.dart';
import 'package:ma_water/ui/shared/loading_skeleton.dart';
import 'package:ma_water/ui/station_detail/station_detail_screen.dart';

/// The product's home: an Arabic, RTL chat surface.
///
/// Top bar carries the brand mark, a live ("مباشر") indicator, an alerts pill
/// (badge count from [alertsProvider]) and a settings button. The body is a
/// reversed, virtualized message list driven by [chatControllerProvider];
/// assistant blocks render through [GenUiRegistry]. A [ComposerBar] is pinned
/// to the bottom and is populated from [composerPrefillProvider] when another
/// screen requests "ask about this station".
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _composerController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _lastMessageCount = 0;

  @override
  void dispose() {
    _composerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send(String text) {
    ref.read(chatControllerProvider.notifier).send(text);
    _scrollToNewest();
  }

  /// The list is reversed, so "newest" lives at offset 0.0.
  void _scrollToNewest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void _openStation(String stationId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StationDetailScreen(stationId: stationId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ChatState chatState = ref.watch(chatControllerProvider);
    final List<ChatMessage> messages = chatState.messages;

    // Auto-scroll when a new message arrives (sent or received).
    if (messages.length != _lastMessageCount) {
      _lastMessageCount = messages.length;
      _scrollToNewest();
    }

    // Drain any pending composer prefill (set by station detail / blocks).
    ref.listen<String?>(composerPrefillProvider, (previous, next) {
      if (next == null || next.isEmpty) return;
      _composerController.text = next;
      _composerController.selection = TextSelection.fromPosition(
        TextPosition(offset: _composerController.text.length),
      );
      // Clear so the same prefill can be requested again later.
      ref.read(composerPrefillProvider.notifier).state = null;
    });

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList(messages)),
          const Divider(height: 1, thickness: 1, color: AppColors.line),
          ComposerBar(
            controller: _composerController,
            onSend: _send,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.card,
      surfaceTintColor: AppColors.card,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: AppSpacing.md,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          BrandLogo(iconSize: AppSpacing.lg),
          SizedBox(width: AppSpacing.sm),
          _LiveIndicator(),
        ],
      ),
      actions: [
        const _AlertsPill(),
        IconButton(
          tooltip: 'الإعدادات',
          icon: const Icon(Icons.settings_outlined, color: AppColors.slate),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: AppColors.line),
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages) {
    // Only the welcome message present → show the empty state hint.
    if (messages.length <= 1) {
      return const _ChatEmptyState();
    }

    return ListView.separated(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
      itemCount: messages.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        // Reversed: index 0 is the newest message.
        final message = messages[messages.length - 1 - index];
        return _buildRow(message);
      },
    );
  }

  Widget _buildRow(ChatMessage message) {
    if (message.isLoading) {
      return const ChatBubbleSkeleton();
    }

    Widget? blockChild;
    final block = message.block;
    if (block != null) {
      blockChild = GenUiRegistry.build(block, onTapStation: _openStation);
    }

    return MessageBubble(message: message, child: blockChild);
  }
}

/// The small green "live" indicator: a pulsing dot beside the "مباشر" label.
class _LiveIndicator extends StatelessWidget {
  const _LiveIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.okBg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSpacing.xs,
            height: AppSpacing.xs,
            decoration: const BoxDecoration(
              color: AppColors.ok,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            'مباشر',
            style: AppTextStyles.caption.copyWith(color: AppColors.ok),
          ),
        ],
      ),
    );
  }
}

/// Alerts entry point: a bell pill with a count badge sourced from
/// [alertsProvider]. Tapping opens [AlertsScreen].
class _AlertsPill extends ConsumerWidget {
  const _AlertsPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);
    final int count = alertsAsync.maybeWhen(
      data: (alerts) => alerts.length,
      orElse: () => 0,
    );

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSpacing.xxs),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AlertsScreen()),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(AppSpacing.xs),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none,
                color: AppColors.slate,
              ),
              if (count > 0)
                PositionedDirectional(
                  top: -AppSpacing.xxs,
                  end: -AppSpacing.xxs,
                  child: Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.xxs,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: AppSpacing.md,
                      minHeight: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.card, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.card,
                        fontSize: 9,
                      ),
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

/// First-run hint shown when the transcript holds only the welcome message.
class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.water_drop_outlined,
      title: 'اسأل عن مستوى الماء',
      subtitle:
          'اكتب سؤالك بالعربية — مثل: "كم مستوى الماء في سد الموصل هذا الأسبوع؟"',
    );
  }
}
