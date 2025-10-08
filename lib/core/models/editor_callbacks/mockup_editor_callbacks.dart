import 'package:flutter/widgets.dart';

import 'standalone_editor_callbacks.dart';

/// Callbacks dedicated to mockup editing/replacement flows.
class MockupEditorCallbacks extends StandaloneEditorCallbacks {
  const MockupEditorCallbacks({
    this.onTapSlot,
    this.onReplaceSlot,
    super.onUpdateUI,
    super.onUndo,
    super.onRedo,
    super.onDone,
    super.onCloseEditor,
    super.onInit,
    super.onAfterViewInit,
  });

  /// Called when the user taps on a mockup slot area.
  final void Function(String slotId)? onTapSlot;

  /// Called after a slot image was replaced programmatically.
  /// Implementations can persist state or update UI.
  final void Function(String slotId, ImageProvider provider)? onReplaceSlot;
}


