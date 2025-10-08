// Flutter imports:
import 'package:flutter/material.dart';

/// A single replaceable area inside a mockup (e.g., a screen or frame opening).
/// The area is defined by a convex quad in clockwise order.
class MockupSlot {
  MockupSlot({
    required this.id,
    required this.quad,
    this.placeholder,
  });

  final String id;
  final List<Offset> quad; // length = 4, clockwise
  final Widget? placeholder; // shown until user sets content

  Map<String, dynamic> toMap() => {
        'id': id,
        'quad': [
          for (final p in quad) {'x': p.dx, 'y': p.dy}
        ],
      };
}

/// Template describing a mockup image with one or more slots.
class MockupTemplate {
  MockupTemplate({
    required this.size,
    required this.background,
    required this.slots,
  });

  final Size size; // pixel size of the composed widget
  final Widget background; // frame/laptop/etc.
  final List<MockupSlot> slots;
}


