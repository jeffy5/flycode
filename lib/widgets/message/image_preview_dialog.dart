import 'package:flutter/material.dart';

Future<void> showImagePreviewDialog({
  required BuildContext context,
  required List<ImageProvider<Object>> images,
  required int initialIndex,
}) {
  if (images.isEmpty) return Future.value();

  final safeInitialIndex = initialIndex.clamp(0, images.length - 1);
  return showDialog<void>(
    context: context,
    builder: (_) =>
        ImagePreviewDialog(images: images, initialIndex: safeInitialIndex),
  );
}

class ImagePreviewDialog extends StatefulWidget {
  final List<ImageProvider<Object>> images;
  final int initialIndex;

  const ImagePreviewDialog({
    super.key,
    required this.images,
    required this.initialIndex,
  }) : assert(images.length > 0),
       assert(initialIndex >= 0 && initialIndex < images.length);

  @override
  State<ImagePreviewDialog> createState() => _ImagePreviewDialogState();
}

class _ImagePreviewDialogState extends State<ImagePreviewDialog> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.scrim,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) => Center(
              child: InteractiveViewer(
                child: Image(
                  image: widget.images[index],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.broken_image_outlined,
                    color: theme.colorScheme.onPrimary,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: IgnorePointer(
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.scrim.withValues(alpha: 0.64),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.images.length}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 16,
            right: 16,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.close,
                color: theme.colorScheme.onPrimary,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
