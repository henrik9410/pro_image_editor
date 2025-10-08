import 'package:flutter/material.dart';

import '../../widgets/mockup/mockup_widget.dart';
import '/core/models/layers/mockup_models.dart';
import '/core/models/layers/widget_layer.dart';

/// Helper to create a `WidgetLayer` that hosts a `MockupWidget`.
class MockupService {
  static WidgetLayer createMockupLayer({
    required MockupTemplate template,
    Map<String, ImageProvider?> slotImages = const {},
    Offset offset = Offset.zero,
    double scale = 1.0,
  }) {
    return WidgetLayer(
      offset: offset,
      scale: scale,
      widget: RepaintBoundary(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: template.size.width,
            height: template.size.height,
            child: MockupWidget(template: template, slotImages: slotImages),
          ),
        ),
      ),
    );
  }
}


