import 'dart:convert';

import 'package:flycode/widgets/message/image_preview_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _kTransparentImageData =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO9WlNcAAAAASUVORK5CYII=';

List<ImageProvider<Object>> _images(int count) => List.generate(
  count,
  (_) => MemoryImage(base64Decode(_kTransparentImageData)),
  growable: false,
);

Widget _buildHarness({required List<ImageProvider<Object>> images}) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showImagePreviewDialog(
            context: context,
            images: images,
            initialIndex: 1,
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('opens at the requested image and swipes horizontally', (
    tester,
  ) async {
    await tester.pumpWidget(_buildHarness(images: _images(3)));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(ImagePreviewDialog), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.controller?.initialPage, 1);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text('3 / 3'), findsOneWidget);
  });

  testWidgets('keeps single-image zoom and close behavior', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showImagePreviewDialog(
                context: context,
                images: _images(1),
                initialIndex: 0,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('1 / 1'), findsNothing);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(ImagePreviewDialog), findsNothing);
  });

  testWidgets('pans a zoomed image without changing pages', (tester) async {
    await tester.pumpWidget(_buildHarness(images: _images(3)));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final viewer = find.byType(InteractiveViewer);
    final center = tester.getCenter(viewer);
    final firstPointer = await tester.startGesture(
      center - const Offset(20, 0),
      pointer: 1,
    );
    final secondPointer = await tester.startGesture(
      center + const Offset(20, 0),
      pointer: 2,
    );
    await firstPointer.moveTo(center - const Offset(100, 0));
    await secondPointer.moveTo(center + const Offset(100, 0));
    await tester.pump();
    await firstPointer.up();
    await secondPointer.up();
    await tester.pumpAndSettle();

    await tester.dragFrom(center, const Offset(-200, 0));
    await tester.pumpAndSettle();

    expect(find.text('2 / 3'), findsOneWidget);
  });
}
