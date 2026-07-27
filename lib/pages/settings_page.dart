import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_language.dart';
import '../l10n/l10n.dart';
import '../providers/app_language_provider.dart';
import '../providers/session_completion_notification_provider.dart';
import '../providers/server_config_provider.dart';
import '../theme/app_tokens.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final asyncServerConfig = ref.watch(serverConfigProvider);
    final language = ref.watch(appLanguageProvider);
    final notificationMode = ref.watch(
      sessionCompletionNotificationModeProvider,
    );
    final serverUrl = _serverDisplayText(
      asyncServerConfig.value?.baseUrl ?? 'http://127.0.0.1:4096',
    );
    final tokens = context.tokens;
    final contentBottomPadding = MediaQuery.paddingOf(context).bottom + 16;
    final mutedColor = tokens.mutedForeground;
    final dividerColor = tokens.accent;
    final pagePadding = tokens.pageHorizontalPadding;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          l10n.settingsTitle,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        toolbarHeight: 64,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: dividerColor),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          pagePadding,
          12,
          pagePadding,
          contentBottomPadding,
        ),
        children: [
          _SectionTitle(title: l10n.settingsSectionGeneral),
          _SettingsRow(
            icon: Icons.language,
            title: l10n.settingsLanguage,
            value: language.label(l10n),
            iconColor: mutedColor,
            onTap: () {
              context.push('/settings/language');
            },
          ),
          _SettingsRow(
            icon: Icons.palette_outlined,
            title: l10n.settingsTheme,
            iconColor: mutedColor,
            onTap: () {
              context.push('/settings/theme');
            },
          ),
          _SettingsRow(
            icon: Icons.notifications_outlined,
            title: l10n.settingsSessionCompletionNotification,
            value: notificationMode.label(l10n),
            iconColor: mutedColor,
            onTap: () {
              context.push('/settings/session-completion-notification');
            },
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),
          _SectionTitle(title: l10n.settingsSectionConnectionModel),
          _SettingsRow(
            icon: Icons.dns_outlined,
            title: l10n.settingsServer,
            value: serverUrl,
            iconColor: mutedColor,
            onTap: () {
              final config = asyncServerConfig.value;
              if (config != null) {
                context.push('/settings/server', extra: config);
              } else {
                context.push('/settings/server');
              }
            },
          ),
          _SettingsRow(
            icon: Icons.memory_outlined,
            title: l10n.settingsModel,
            iconColor: mutedColor,
            onTap: () {
              context.push('/settings/model');
            },
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),
          _SectionTitle(title: l10n.settingsSectionMore),
          _SettingsRow(
            icon: Icons.info_outline,
            title: l10n.settingsAbout,
            iconColor: mutedColor,
            onTap: () {
              context.push('/settings/about');
            },
          ),
        ],
      ),
    );
  }

  String _serverDisplayText(String rawUrl) {
    final parsed = Uri.tryParse(rawUrl);
    if (parsed == null || parsed.host.isEmpty) {
      return rawUrl;
    }
    final port = parsed.hasPort ? ':${parsed.port}' : '';
    return '${parsed.host}$port';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: tokens.mutedForeground,
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String title;
  final String? value;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final titleStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
    );
    final valueStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: tokens.mutedForeground,
    );

    return SizedBox(
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(tokens.radiusXs),
          splashColor: tokens.accent,
          highlightColor: tokens.accent,
          hoverColor: tokens.accent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 12),
                Text(title, style: titleStyle),
                if (value != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      value!,
                      style: valueStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                  const SizedBox(width: 8),
                ] else
                  const Spacer(),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: tokens.mutedForeground,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
