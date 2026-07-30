import '../../types/filter_matrix.dart';

/// The 4x5 identity color matrix - leaves every pixel unchanged.
const List<double> kIdentityColorMatrix = [
  1, 0, 0, 0, 0, //
  0, 1, 0, 0, 0, //
  0, 0, 1, 0, 0, //
  0, 0, 0, 1, 0, //
];

/// Combines an ordered [FilterMatrix] (a list of `ColorFilter.matrix`-style
/// 4x5 matrices, as used by `FilterModel.filters`) into a single equivalent
/// 4x5 matrix, applied in the same order [ColorFilterGenerator] would nest
/// them as separate `ColorFiltered` widgets (index 0 applied first/
/// innermost). Returns [kIdentityColorMatrix] for an empty list.
///
/// Unlike nesting one `ColorFiltered` per matrix, this always yields exactly
/// one matrix - so a caller that always wraps its content in exactly one
/// `ColorFiltered` with this result keeps that wrapper's position in the
/// widget tree constant no matter how many component matrices the selected
/// filter has. That matters whenever the wrapped content holds onto state
/// that must survive a filter change (e.g. a playing video, or any other
/// persistent layer content) - a *varying* number of nested `ColorFiltered`
/// ancestors would otherwise change the wrapped content's ancestor chain
/// each time, making Flutter tear it down and rebuild it from scratch.
List<double> combineColorMatrices(FilterMatrix matrices) {
  List<double> result = kIdentityColorMatrix;
  for (final matrix in matrices) {
    result = _composeColorMatrices(outer: matrix, inner: result);
  }
  return result;
}

/// Returns the 4x5 matrix equivalent to applying [inner] then [outer] (i.e.
/// `outer(inner(color))`), both in `ColorFilter.matrix` row-major 4x5 form.
///
/// Each 4x5 matrix implicitly represents a 5x5 affine matrix with a fixed
/// `[0, 0, 0, 0, 1]` last row (so it can act on the augmented color vector
/// `[r, g, b, a, 1]`); composing two of them is a standard matrix multiply of
/// those two 5x5 matrices, which always again has that same fixed last row -
/// so only the top 4 rows ever need to be computed or stored.
List<double> _composeColorMatrices({
  required List<double> outer,
  required List<double> inner,
}) {
  final result = List<double>.filled(20, 0);
  for (var row = 0; row < 4; row++) {
    for (var col = 0; col < 5; col++) {
      double sum = 0;
      for (var k = 0; k < 4; k++) {
        sum += outer[row * 5 + k] * inner[k * 5 + col];
      }
      // `inner`'s implicit 5th row is `[0, 0, 0, 0, 1]`, so it only
      // contributes to the translation column via `outer`'s own offset.
      if (col == 4) sum += outer[row * 5 + 4];
      result[row * 5 + col] = sum;
    }
  }
  return result;
}
