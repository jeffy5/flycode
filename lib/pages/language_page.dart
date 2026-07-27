import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_language.dart';
import '../l10n/l10n.dart';
import '../providers/app_language_provider.dart';
import '../theme/app_tokens.dart';

class LanguagePage extends ConsumerWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selected = ref.watch(appLanguageProvider);
    final pagePadding = context.tokens.pageHorizontalPadding;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.languageTitle)),
      body: RadioGroup<AppLanguage>(
        groupValue: selected,
        onChanged: (value) {
          if (value == null) return;
          ref.read(appLanguageProvider.notifier).setLanguage(value);
        },
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: pagePadding),
          children: [
            const SizedBox(height: 8),
            for (final language in AppLanguage.values)
              RadioListTile<AppLanguage>(
                value: language,
                title: Text(language.label(l10n)),
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
    );
  }
}
