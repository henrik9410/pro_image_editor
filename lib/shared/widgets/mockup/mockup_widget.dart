// Flutter imports:
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '/core/models/layers/mockup_models.dart';

/// Renders a mockup background plus one or more perspective-mapped slot images.
class MockupWidget extends StatelessWidget {
  const MockupWidget({
    super.key,
    required this.template,
    required this.slotImages,
  });

  /// Template describing background and slot quads in template coordinates.
  final MockupTemplate template;

  /// Map slotId -> image widget for replacement. If missing, placeholder used.
  final Map<String, ImageProvider?> slotImages;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: template.size.width,
      height: template.size.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: template.background),
          for (final slot in template.slots)
            Positioned.fill(
              child: _PerspectiveSlot(
                quad: slot.quad,
                imageProvider: slotImages[slot.id],
                placeholder: slot.placeholder,
                canvasSize: template.size,
              ),
            ),
        ],
      ),
    );
  }
}

class _PerspectiveSlot extends StatelessWidget {
  const _PerspectiveSlot({
    required this.quad,
    required this.canvasSize,
    this.imageProvider,
    this.placeholder,
  });

  final List<Offset> quad;
  final Size canvasSize;
  final ImageProvider? imageProvider;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    if (imageProvider == null) {
      return IgnorePointer(child: placeholder ?? const SizedBox.shrink());
    }

    return FutureBuilder<ui.Image>(
      future: _loadImage(imageProvider!, context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        return CustomPaint(
          painter: _QuadImagePainter(snapshot.data!, quad, canvasSize),
        );
      },
    );
  }

  Future<ui.Image> _loadImage(ImageProvider provider, BuildContext context) async {
    final config = createLocalImageConfiguration(context);
    final completer = Completer<ImageInfo>();
    final stream = provider.resolve(config);
    late final ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      completer.complete(info);
      stream.removeListener(listener);
    });
    stream.addListener(listener);
    final info = await completer.future;
    return info.image;
  }
}

class _QuadImagePainter extends CustomPainter {
  _QuadImagePainter(this.image, this.quad, this.canvasSize);

  final ui.Image image;
  final List<Offset> quad; // clockwise
  final Size canvasSize;

  @override
  void paint(Canvas canvas, Size size) {
    // Normalize to current widget size
    final sx = size.width / canvasSize.width;
    final sy = size.height / canvasSize.height;
    final dst = [for (final p in quad) Offset(p.dx * sx, p.dy * sy)];

    // Triangulate quad (two triangles)
    final vertices = ui.Vertices(
      ui.VertexMode.triangles,
      <Offset>[dst[0], dst[1], dst[2], dst[0], dst[2], dst[3]],
      textureCoordinates: <Offset>[
        const Offset(0, 0),
        Offset(image.width.toDouble(), 0),
        Offset(image.width.toDouble(), image.height.toDouble()),
        const Offset(0, 0),
        Offset(image.width.toDouble(), image.height.toDouble()),
        Offset(0, image.height.toDouble()),
      ],
    );

    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..shader = ImageShader(
        image,
        TileMode.clamp,
        TileMode.clamp,
        Matrix4.identity().storage,
      );

    canvas.drawVertices(vertices, BlendMode.srcOver, paint);
  }

  @override
  bool shouldRepaint(covariant _QuadImagePainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.quad != quad;
  }
}


