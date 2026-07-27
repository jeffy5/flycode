import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../theme/app_tokens.dart';
import '../../utils/external_link_launcher.dart';

typedef MessageMarkdownLinkLauncher = Future<void> Function(Uri uri);

const Key messageMarkdownCodeBlockKey = ValueKey('message-markdown-code-block');

@visibleForTesting
MessageMarkdownLinkLauncher debugMessageMarkdownLinkLauncher =
    _launchMarkdownLink;

Future<void> openMessageMarkdownLink(String? href) async {
  if (href == null || href.trim().isEmpty) {
    return;
  }

  final uri = Uri.tryParse(href.trim());
  if (uri == null) {
    return;
  }

  await debugMessageMarkdownLinkLauncher(uri);
}

Future<void> _launchMarkdownLink(Uri uri) async {
  await launchExternalUri(uri);
}

MarkdownStyleSheet buildMessageMarkdownStyleSheet(BuildContext context) {
  final theme = Theme.of(context);
  final tokens = context.tokens;
  final textTheme = theme.textTheme;
  final onSurface = theme.colorScheme.onSurface;
  final primary = theme.colorScheme.primary;
  final isDark = theme.brightness == Brightness.dark;
  final blockquoteBackground = isDark
      ? theme.colorScheme.primary.withValues(alpha: 0.14)
      : tokens.info.withValues(alpha: 0.72);
  final tableHeaderBackground = isDark
      ? tokens.border.withValues(alpha: 0.72)
      : tokens.card;
  final tableCellBackground = theme.colorScheme.surface;
  final tableBorderColor = tokens.border.withValues(
    alpha: isDark ? 0.95 : 0.85,
  );

  TextStyle headingStyle(double size) {
    return textTheme.titleLarge!.copyWith(
      fontFamily: 'PlusJakartaSans',
      fontSize: size,
      height: 1.25,
      fontWeight: FontWeight.w700,
      color: onSurface,
    );
  }

  final bodyStyle = textTheme.bodyMedium!.copyWith(
    fontSize: 15,
    height: 1.6,
    color: onSurface,
  );

  return MarkdownStyleSheet(
    p: bodyStyle,
    pPadding: EdgeInsets.zero,
    blockSpacing: 14,
    a: bodyStyle.copyWith(color: primary, fontWeight: FontWeight.w600),
    strong: bodyStyle.copyWith(color: onSurface, fontWeight: FontWeight.w700),
    em: bodyStyle.copyWith(color: onSurface, fontStyle: FontStyle.italic),
    del: bodyStyle.copyWith(
      color: tokens.mutedForeground,
      decoration: TextDecoration.lineThrough,
    ),
    code: bodyStyle.copyWith(
      color: isDark
          ? theme.colorScheme.primary.withValues(alpha: 0.95)
          : primary,
      fontFamily: 'monospace',
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.35,
    ),
    h1: headingStyle(22),
    h2: headingStyle(19),
    h3: headingStyle(17),
    h4: headingStyle(15),
    h5: headingStyle(15),
    h6: headingStyle(15),
    h1Padding: const EdgeInsets.only(top: 4, bottom: 2),
    h2Padding: const EdgeInsets.only(top: 2, bottom: 2),
    h3Padding: const EdgeInsets.only(top: 2, bottom: 2),
    h4Padding: EdgeInsets.zero,
    h5Padding: EdgeInsets.zero,
    h6Padding: EdgeInsets.zero,
    listIndent: 22,
    listBullet: bodyStyle.copyWith(fontSize: 14, height: 1.55),
    listBulletPadding: const EdgeInsets.only(right: 8),
    blockquote: bodyStyle.copyWith(
      color: onSurface.withValues(alpha: 0.9),
      fontStyle: FontStyle.italic,
    ),
    blockquotePadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    blockquoteDecoration: BoxDecoration(
      color: blockquoteBackground,
      borderRadius: BorderRadius.circular(8),
      border: Border(left: BorderSide(color: primary, width: 3)),
    ),
    tableHead: bodyStyle.copyWith(
      fontSize: 13,
      height: 1.35,
      fontWeight: FontWeight.w700,
      color: onSurface,
    ),
    tableBody: bodyStyle.copyWith(fontSize: 13, height: 1.45),
    tableHeadAlign: TextAlign.left,
    tablePadding: const EdgeInsets.only(top: 4, bottom: 8),
    tableBorder: TableBorder.all(
      color: tableBorderColor,
      width: 1,
      borderRadius: BorderRadius.circular(12),
    ),
    tableCellsPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    tableCellsDecoration: BoxDecoration(color: tableCellBackground),
    tableHeadCellsPadding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 10,
    ),
    tableHeadCellsDecoration: BoxDecoration(color: tableHeaderBackground),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(
        top: BorderSide(
          color: tokens.border.withValues(alpha: isDark ? 0.95 : 0.85),
          width: 1,
        ),
      ),
    ),
    codeblockDecoration: const BoxDecoration(),
  );
}

class MessageCodeBlockThemeData {
  const MessageCodeBlockThemeData({
    required this.backgroundColor,
    required this.headerColor,
    required this.borderColor,
    required this.codeColor,
    required this.languageColor,
    required this.iconColor,
    required this.successColor,
    required this.commentColor,
  });

  final Color backgroundColor;
  final Color headerColor;
  final Color borderColor;
  final Color codeColor;
  final Color languageColor;
  final Color iconColor;
  final Color successColor;
  final Color commentColor;
}

MessageCodeBlockThemeData buildMessageCodeBlockTheme(BuildContext context) {
  final theme = Theme.of(context);
  final tokens = context.tokens;
  final isDark = theme.brightness == Brightness.dark;

  return MessageCodeBlockThemeData(
    backgroundColor: isDark ? tokens.accent : tokens.card,
    headerColor: isDark ? tokens.accent.withValues(alpha: 0.92) : tokens.card,
    borderColor: tokens.border.withValues(alpha: isDark ? 0.95 : 0.8),
    codeColor: theme.colorScheme.onSurface,
    languageColor: tokens.mutedForeground,
    iconColor: tokens.mutedForeground,
    successColor: tokens.successForeground,
    commentColor: tokens.mutedForeground.withValues(alpha: isDark ? 0.95 : 0.9),
  );
}
