// ignore_for_file: type=lint

import 'package:flycode/l10n/app_localizations.dart';
import 'package:flycode/service/api/api_client.dart';
import 'package:flycode/service/api/models/message.dart';
import 'package:flycode/service/api/models/parts.dart';
import 'package:flycode/service/api/models/provider.dart';
import 'package:flycode/service/api/provider_api.dart';
import 'package:flycode/theme/app_theme.dart';
import 'package:flycode/widgets/message/message_bubble.dart';
import 'package:flycode/widgets/message/message_part.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeProviderApi extends ProviderApi {
  _FakeProviderApi()
    : super(
        ApiClient(baseUrl: 'http://localhost'),
        preferencesLoader: SharedPreferences.getInstance,
      );

  @override
  Future<ProviderListResponse> list({
    String? directory,
    bool forceRefresh = false,
    Duration cacheTtl = const Duration(minutes: 10),
  }) async => ProviderListResponse(
    all: const [],
    defaultProvider: const {},
    connected: const [],
  );
}

const _kTransparentImageDataUrl =
    'data:image/png;base64,'
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO9WlNcAAAAASUVORK5CYII=';

Widget _buildHarness(Widget child) {
  return ProviderScope(
    overrides: [
      providerApiProvider.overrideWith((ref) async => _FakeProviderApi()),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('zh'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topRight,
          child: SizedBox(width: 360, child: child),
        ),
      ),
    ),
  );
}

MessageWithParts _userMessageWithParts(List<Object> parts) {
  return MessageWithParts(
    info: UserMessage(
      id: 'message-1',
      sessionID: 'session-1',
      role: 'user',
      time: MessageTime(created: 1),
      agent: 'build',
      model: MessageModel(providerID: 'openai', modelID: 'gpt-5.4'),
    ),
    parts: parts,
  );
}

FilePart _imagePart(String id) {
  return FilePart(
    id: id,
    sessionID: 'session-1',
    messageID: 'message-1',
    type: 'file',
    mime: 'image/png',
    url: _kTransparentImageDataUrl,
  );
}

TextPart _textPart(String id, String text) {
  return TextPart(
    id: id,
    sessionID: 'session-1',
    messageID: 'message-1',
    type: 'text',
    text: text,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('groups consecutive user images into one horizontal gallery', (
    tester,
  ) async {
    final message = _userMessageWithParts([
      _textPart('text-1', '这些图片是什么东西'),
      _imagePart('image-1'),
      _imagePart('image-2'),
      _imagePart('image-3'),
    ]);

    await tester.pumpWidget(
      _buildHarness(
        MessageBubble(messageWithParts: message, prevIsUser: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(kMessageImageGalleryKey), findsOneWidget);

    final gallery = tester.widget<SingleChildScrollView>(
      find.byKey(kMessageImageGalleryKey),
    );
    expect(gallery.scrollDirection, Axis.horizontal);

    final imageWidgets = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(imageWidgets, hasLength(3));
    for (final image in imageWidgets) {
      expect(image.width, kMessageImageThumbnailSize);
      expect(image.height, kMessageImageThumbnailSize);
    }
  });

  testWidgets('keeps separate galleries when images are split by text', (
    tester,
  ) async {
    final message = _userMessageWithParts([
      _textPart('text-1', '第一段'),
      _imagePart('image-1'),
      _imagePart('image-2'),
      _textPart('text-2', '第二段'),
      _imagePart('image-3'),
    ]);

    await tester.pumpWidget(
      _buildHarness(
        MessageBubble(messageWithParts: message, prevIsUser: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('第一段'), findsOneWidget);
    expect(find.text('第二段'), findsOneWidget);
    expect(find.byKey(kMessageImageGalleryKey), findsNWidgets(2));

    final gallerySize = tester.getSize(
      find.byKey(kMessageImageGalleryKey).first,
    );
    expect(gallerySize.width, (kMessageImageThumbnailSize * 2) + 4);
  });
}
