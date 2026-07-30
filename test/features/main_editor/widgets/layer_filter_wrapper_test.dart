// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pro_image_editor/features/filter_editor/types/filter_matrix.dart';
import 'package:pro_image_editor/features/filter_editor/utils/filter_generator/color_matrix_composer.dart';

/// Regression test for the exact pattern
/// `MainEditorInteractiveContent._buildFilteredLayers` uses: layers are
/// always wrapped in exactly one `ColorFiltered`, whose matrix is
/// `combineColorMatrices(filters)` - collapsing however many component
/// matrices the selected filter preset has into one. Before that collapsing,
/// wrapping with a *varying* number of nested `ColorFiltered`s (one per
/// preset matrix, via `ColorFilterGenerator`) would change the ancestor
/// chain directly above the layers every time a filter with a different
/// matrix count was selected, tearing down and rebuilding every layer's
/// content (e.g. a playing video) - the same class of bug fixed earlier for
/// selection changes.
class _CountingContent extends StatefulWidget {
  const _CountingContent({required this.initCount, required this.disposeCount});

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
  Widget build(BuildContext context) => const SizedBox(width: 10, height: 10);
}

void main() {
  testWidgets(
    'wrapping layers in a single combined ColorFiltered survives switching '
    'between filters with different matrix counts',
    (tester) async {
      final initCount = ValueNotifier(0);
      final disposeCount = ValueNotifier(0);
      final layerFilters = ValueNotifier<FilterMatrix>(const []);

      const FilterMatrix oneMatrixFilter = [
        [
          1.0, 0.0, 0.0, 0.0, 0.0, //
          0.0, 1.0, 0.0, 0.0, 0.0, //
          0.0, 0.0, 1.0, 0.0, 0.0, //
          0.0, 0.0, 0.0, 1.0, 0.0, //
        ],
      ];
      const FilterMatrix threeMatrixFilter = [
        [
          1.0, 0.0, 0.0, 0.0, 5.0, //
          0.0, 1.0, 0.0, 0.0, 0.0, //
          0.0, 0.0, 1.0, 0.0, 0.0, //
          0.0, 0.0, 0.0, 1.0, 0.0, //
        ],
        [
          1.1, 0.0, 0.0, 0.0, 0.0, //
          0.0, 1.1, 0.0, 0.0, 0.0, //
          0.0, 0.0, 1.1, 0.0, 0.0, //
          0.0, 0.0, 0.0, 1.0, 0.0, //
        ],
        [
          1.0, 0.0, 0.0, 0.0, 0.0, //
          0.0, 1.0, 0.0, 0.0, 0.0, //
          0.0, 0.0, 1.0, 0.0, 0.0, //
          0.0, 0.0, 0.0, 1.0, -5.0, //
        ],
      ];

      Widget buildFilteredLayers() {
        return ValueListenableBuilder<FilterMatrix>(
          valueListenable: layerFilters,
          builder: (context, filters, child) {
            return ColorFiltered(
              colorFilter: ColorFilter.matrix(combineColorMatrices(filters)),
              child: child,
            );
          },
          child: _CountingContent(
            initCount: initCount,
            disposeCount: disposeCount,
          ),
        );
      }

      await tester.pumpWidget(
        MaterialApp(home: Center(child: buildFilteredLayers())),
      );
      expect(initCount.value, 1);
      expect(disposeCount.value, 0);

      layerFilters.value = oneMatrixFilter;
      await tester.pump();
      expect(
        initCount.value,
        1,
        reason: 'switching to a 1-matrix filter must not reinit layers',
      );
      expect(disposeCount.value, 0);

      layerFilters.value = threeMatrixFilter;
      await tester.pump();
      expect(
        initCount.value,
        1,
        reason: 'switching to a 3-matrix filter must not reinit layers',
      );
      expect(disposeCount.value, 0);

      layerFilters.value = const [];
      await tester.pump();
      expect(
        initCount.value,
        1,
        reason: 'clearing the filter must not reinit layers',
      );
      expect(disposeCount.value, 0);
    },
  );
}
