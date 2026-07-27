import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/github.dart';

/// Returns the appropriate highlight.js theme based on system brightness.
///
/// - Light mode: githubTheme (GitHub's light theme)
/// - Dark mode: atomOneDarkTheme (Atom One Dark, closest to GitHub dark style)
///
/// The 'root' background color is set to transparent to allow the parent
/// Container to control the background color.
///
/// Note: flutter_highlight 0.7.0 doesn't include github_dark theme.
/// atomOneDarkTheme provides a similar modern dark syntax highlighting.
Map<String, TextStyle> buildHighlightTheme(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final baseTheme = isDark ? atomOneDarkTheme : githubTheme;

  // Copy the theme and set root background to transparent
  // so the parent Container's background color is visible
  return {
    ...baseTheme,
    'root': baseTheme['root']!.copyWith(backgroundColor: Colors.transparent),
  };
}
