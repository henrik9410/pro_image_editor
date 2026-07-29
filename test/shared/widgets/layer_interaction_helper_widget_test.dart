// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pro_image_editor/plugins/defer_pointer/defer_pointer.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_image_editor/shared/widgets/layer/interaction_helper/layer_interaction_helper_widget.dart';

/// Regression test for the layer-content-reinitializes-on-selection bug:
/// `LayerInteractionHelperWidget.build()` returns structurally different
/// ancestor widgets around its `child` depending on selection state (no
/// wrapper / `DeferPointer` / `TooltipVisibility` > `DeferPointer` > `Stack`),
/// which used to make Flutter tear down and recreate `child`'s entire
/// subtree - and therefore any stateful content inside it, e.g. a video
/// player controller or persistent HTML content - every time a layer was
/// selected, deselected, or another layer was selected instead.
class _CountingContent extends StatefulWidget {
  const _CountingContent({
    required this.initCount,
    required this.disposeCount,
  });

  final ValueNotifier<int> initCount;
  final ValueNotifier<int> disposeCount;

  @override
  State<_CountingContent> createState() => _CountingContentState();
}

class _CountingContentState extends State<_CountingContent> {
  @override
  void initState() {
    super.initState();
    widget.initCount.value++;
  }

  @override
  void dispose() {
    widget.disposeCount.value++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox(width: 40, height: 40);
}

void main() {
  testWidgets(
    'LayerInteractionHelperWidget preserves child State across selection '
    'changes',
    (tester) async {
      final initCount = ValueNotifier(0);
      final disposeCount = ValueNotifier(0);
      final layer = TextLayer(text: 'x', id: 'layer-under-test');

      Widget buildHarness({
        required bool selected,
        required String selectedLayerId,
      }) {
        return MaterialApp(
          home: DeferredPointerHandler(
            id: 'fixed-defer-id',
            selectedLayerId: selectedLayerId,
            child: Center(
              child: LayerInteractionHelperWidget(
                layerData: layer,
                configs: const ProImageEditorConfigs(),
                isInteractive: true,
                selected: selected,
                child: _CountingContent(
                  initCount: initCount,
                  disposeCount: disposeCount,
                ),
              ),
            ),
          ),
        );
      }

      // Nothing selected.
      await tester.pumpWidget(
        buildHarness(selected: false, selectedLayerId: ''),
      );
      expect(initCount.value, 1);
      expect(disposeCount.value, 0);

      // This layer becomes selected.
      await tester.pumpWidget(
        buildHarness(selected: true, selectedLayerId: layer.id),
      );
      expect(initCount.value, 1, reason: 'selecting must not reinit content');
      expect(disposeCount.value, 0);

      // Deselected via tapping outside -> nothing selected again.
      await tester.pumpWidget(
        buildHarness(selected: false, selectedLayerId: ''),
      );
      expect(
        initCount.value,
        1,
        reason: 'deselecting must not reinit content',
      );
      expect(disposeCount.value, 0);

      // A different layer becomes selected (this layer is now a bystander).
      await tester.pumpWidget(
        buildHarness(selected: false, selectedLayerId: 'other-layer-id'),
      );
      expect(
        initCount.value,
        1,
        reason:
            'another layer becoming selected must not reinit this bystander',
      );
      expect(disposeCount.value, 0);

      // This layer is reselected directly, without passing through "none".
      await tester.pumpWidget(
        buildHarness(selected: true, selectedLayerId: layer.id),
      );
      expect(
        initCount.value,
        1,
        reason: 'reselecting directly must not reinit content',
      );
      expect(disposeCount.value, 0);

      expect(find.byType(LayerInteractionHelperWidget), findsOneWidget);
    },
  );
}
