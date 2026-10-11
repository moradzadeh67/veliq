import 'package:flutter/foundation.dart';

/// A rectangular region of the desktop in **global screen points**.
///
/// The origin is the top-left corner of the primary display, with `y` growing
/// downwards. This is the coordinate space used by the native selection
/// overlay and by the capture bridge, so a region can be passed straight from
/// one to the other without conversion.
@immutable
class ScreenRegion {
  final double x;
  final double y;
  final double width;
  final double height;

  const ScreenRegion({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Whether the region is large enough to be a meaningful selection.
  ///
  /// Guards against accidental single clicks, which would otherwise trigger a
  /// capture of a 0x0 region.
  bool get isUsable => width >= 2 && height >= 2;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenRegion &&
          other.x == x &&
          other.y == y &&
          other.width == width &&
          other.height == height;

  @override
  int get hashCode => Object.hash(x, y, width, height);

  @override
  String toString() =>
      'ScreenRegion(x: $x, y: $y, width: $width, height: $height)';
}
