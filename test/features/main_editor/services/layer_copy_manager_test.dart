// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pro_image_editor/core/models/layers/layer.dart';
import 'package:pro_image_editor/features/main_editor/services/layer_copy_manager.dart';
import 'package:pro_image_editor/features/paint_editor/enums/paint_editor_enum.dart';
import 'package:pro_image_editor/features/paint_editor/models/painted_model.dart';

/// Regression test: `MainEditorLayers` keys every layer's widget with
/// `Layer.key` (a `GlobalKey`), and every committed edit (add/remove/update
/// layer, drag/rotate/scale finishing, undo/redo, reordering) copies the
/// *entire* active layer list via `LayerCopyManager.copyLayerList` - even for
/// layers that didn't themselves change. Before the fix, every `Layer`
/// subclass constructor defaulted `key` to a fresh `GlobalKey()`, so any one
/// of those commits silently gave *every* layer's widget a new identity and
/// tore down and rebuilt it from scratch - invisible for stateless content
/// (text/emoji/paint) but destructive for stateful `WidgetLayer` content
/// (video players, persistent HTML, ...).
void main() {
  final manager = LayerCopyManager();

  test('copyLayer preserves the original key for a TextLayer', () {
    final layer = TextLayer(text: 'hello');
    final copy = manager.copyLayer(layer);
    expect(copy.key, same(layer.key));
  });

  test('copyLayer preserves the original key for an EmojiLayer', () {
    final layer = EmojiLayer(emoji: '😀');
    final copy = manager.copyLayer(layer);
    expect(copy.key, same(layer.key));
  });

  test('copyLayer preserves the original key for a WidgetLayer', () {
    final layer = WidgetLayer(widget: const SizedBox());
    final copy = manager.copyLayer(layer);
    expect(copy.key, same(layer.key));
  });

  test('copyLayer preserves the original key for a PaintLayer', () {
    final layer = PaintLayer(
      item: PaintedModel(
        mode: PaintMode.freeStyle,
        offsets: const [],
        color: Colors.black,
        strokeWidth: 1,
        opacity: 1,
      ),
      rawSize: const Size(10, 10),
      opacity: 1,
    );
    final copy = manager.copyLayer(layer);
    expect(copy.key, same(layer.key));
  });

  test(
    'copyLayerList preserves every layer\'s key, including untouched ones',
    () {
      final layers = [
        TextLayer(text: 'a'),
        WidgetLayer(widget: const SizedBox()),
        EmojiLayer(emoji: '🙂'),
      ];
      final copies = manager.copyLayerList(layers);

      for (var i = 0; i < layers.length; i++) {
        expect(
          copies[i].key,
          same(layers[i].key),
          reason: 'layer at index $i lost its widget identity on copy',
        );
      }
    },
  );
}
