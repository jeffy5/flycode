import 'package:url_launcher/url_launcher.dart';

Future<bool> launchExternalUri(Uri uri) async {
  try {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (opened) {
      return true;
    }
  } catch (_) {
    // Android can report false negatives here depending on package visibility.
  }

  try {
    return await launchUrl(uri);
  } catch (_) {
    return false;
  }
}
