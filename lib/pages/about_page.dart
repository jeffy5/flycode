import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../theme/app_tokens.dart';
import '../utils/external_link_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const String _appName = 'FlyCode';
  static const String _appVersion = 'v1.0.0';
  static const String _githubUrl = 'https://github.com/jeffy5/flycode';
  static bool _fontLicenseRegistered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final contentBottomPadding = MediaQuery.paddingOf(context).bottom + 20;
    final pagePadding = tokens.pageHorizontalPadding;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aboutTitle),
        centerTitle: false,
        toolbarHeight: 64,
        titleTextStyle: theme.textTheme.titleMedium?.copyWith(
          fontFamily: 'PlusJakartaSans',
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: tokens.accent),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          pagePadding,
          16,
          pagePadding,
          contentBottomPadding,
        ),
        children: [
          _HeroSection(
            appName: _appName,
            description: l10n.aboutHeroDescription,
          ),
          const SizedBox(height: 14),
          _InfoGroupCard(
            children: [
              _InfoRow(title: l10n.aboutCurrentVersion, value: _appVersion),
              _InfoRow(
                title: 'GitHub',
                value: 'jeffy5/flycode',
                onTap: () => _launchExternalUrl(context, _githubUrl),
              ),
              _InfoRow(
                title: l10n.aboutOpenSourceLicenses,
                onTap: () async {
                  await _registerGoogleFontsLicense();
                  if (!context.mounted) {
                    return;
                  }
                  showLicensePage(
                    context: context,
                    applicationName: _appName,
                    applicationVersion: _appVersion,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '© 2026 FlyCode. For moments when coding should stay within reach.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens.mutedForeground,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchExternalUrl(BuildContext context, String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      _showOpenLinkError(context);
      return;
    }

    if (await launchExternalUri(uri)) {
      return;
    }

    if (context.mounted) {
      _showOpenLinkError(context);
    }
  }

  void _showOpenLinkError(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.aboutOpenLinkFailed)));
  }

  Future<void> _registerGoogleFontsLicense() async {
    if (_fontLicenseRegistered) {
      return;
    }

    final licenseText = await rootBundle.loadString('assets/fonts/OFL.txt');
    LicenseRegistry.addLicense(
      () => Stream<LicenseEntry>.value(
        LicenseEntryWithLineBreaks(const <String>[
          'Inter',
          'Plus Jakarta Sans',
        ], licenseText),
      ),
    );
    _fontLicenseRegistered = true;
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.appName, required this.description});

  final String appName;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(tokens.radiusM),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/app_icon/app_logo.jpg',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, error, stackTrace) {
                  return ColoredBox(
                    color: theme.colorScheme.primary,
                    child: Center(
                      child: Text(
                        'FC',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tokens.mutedForeground,
                      fontSize: 14,
                      height: 1.5,
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
}

class _InfoGroupCard extends StatelessWidget {
  const _InfoGroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(tokens.radiusXs),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.title, this.value, this.onTap});

  final String title;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final canTap = onTap != null;

    return SizedBox(
      height: 50,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(tokens.radiusXs),
          hoverColor: Colors.transparent,
          splashColor: tokens.accent.withValues(alpha: 0.35),
          highlightColor: tokens.accent.withValues(alpha: 0.2),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (value != null)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          value!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: tokens.mutedForeground,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (value != null && canTap) const SizedBox(width: 8),
                    if (canTap)
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: tokens.mutedForeground,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
