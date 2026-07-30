// Package imports:
import 'package:flutter_test/flutter_test.dart';

// Project imports:
import 'package:pro_image_editor/features/filter_editor/types/filter_matrix.dart';
import 'package:pro_image_editor/features/filter_editor/utils/filter_generator/color_matrix_composer.dart';

void main() {
  test('combineColorMatrices returns identity for an empty list', () {
    expect(combineColorMatrices(const []), kIdentityColorMatrix);
  });

  test(
    'combineColorMatrices returns the matrix unchanged for a single entry',
    () {
      const List<double> matrix = [
        1.0, 0.0, 0.0, 0.0, 10.0, //
        0.0, 1.0, 0.0, 0.0, 20.0, //
        0.0, 0.0, 1.0, 0.0, 30.0, //
        0.0, 0.0, 0.0, 1.0, 0.0, //
      ];

      expect(combineColorMatrices(const [matrix]), matrix);
    },
  );

  test(
    'combineColorMatrices composes matrices in application order '
    '(index 0 applied first)',
    () {
      // Adds 10 to red, applied first.
      const List<double> addRed = [
        1.0, 0.0, 0.0, 0.0, 10.0, //
        0.0, 1.0, 0.0, 0.0, 0.0, //
        0.0, 0.0, 1.0, 0.0, 0.0, //
        0.0, 0.0, 0.0, 1.0, 0.0, //
      ];
      // Doubles every channel, applied second.
      const List<double> doubleAll = [
        2.0, 0.0, 0.0, 0.0, 0.0, //
        0.0, 2.0, 0.0, 0.0, 0.0, //
        0.0, 0.0, 2.0, 0.0, 0.0, //
        0.0, 0.0, 0.0, 2.0, 0.0, //
      ];

      const FilterMatrix input = [addRed, doubleAll];

      final combined = combineColorMatrices(input);

      // A pixel of (0, 0, 0, 1) should become (10, 0, 0, 1) after `addRed`,
      // then (20, 0, 0, 2) after `doubleAll` - i.e. doubleAll(addRed(color)),
      // not addRed(doubleAll(color)) (which would give (10, 0, 0, 2)).
      final r = combined[0] * 0 +
          combined[1] * 0 +
          combined[2] * 0 +
          combined[3] * 1 +
          combined[4];
      expect(r, 20);
    },
  );
}
