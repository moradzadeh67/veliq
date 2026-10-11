import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A full-screen selection overlay widget that allows the user to
/// drag mouse/finger to select a rectangular screen region.
class RegionSelectionOverlay extends StatefulWidget {
  final ValueChanged<Rect> onRectSelected;
  final VoidCallback? onCancelled;

  const RegionSelectionOverlay({
    super.key,
    required this.onRectSelected,
    this.onCancelled,
  });

  @override
  State<RegionSelectionOverlay> createState() => _RegionSelectionOverlayState();
}

class _RegionSelectionOverlayState extends State<RegionSelectionOverlay> {
  final FocusNode _focusNode = FocusNode();
  Offset? _startPoint;
  Offset? _currentPoint;

  Rect? get _selectionRect {
    if (_startPoint == null || _currentPoint == null) return null;
    return Rect.fromPoints(_startPoint!, _currentPoint!);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handlePanStart(DragStartDetails details) {
    setState(() {
      _startPoint = details.localPosition;
      _currentPoint = details.localPosition;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentPoint = details.localPosition;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    final rect = _selectionRect;
    if (rect != null && rect.width > 2 && rect.height > 2) {
      widget.onRectSelected(rect);
    } else {
      setState(() {
        _startPoint = null;
        _currentPoint = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          widget.onCancelled?.call();
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _handlePanStart,
        onPanUpdate: _handlePanUpdate,
        onPanEnd: _handlePanEnd,
        child: CustomPaint(
          painter: OverlayPainter(selectionRect: _selectionRect),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Custom painter for rendering the dim background cutout and selection border.
class OverlayPainter extends CustomPainter {
  final Rect? selectionRect;

  OverlayPainter({required this.selectionRect});

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;
    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.35);

    if (selectionRect == null) {
      canvas.drawRect(fullRect, bgPaint);
      return;
    }

    final backgroundPath = Path()..addRect(fullRect);
    final selectionPath = Path()..addRect(selectionRect!);
    final dimPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      selectionPath,
    );

    canvas.drawPath(dimPath, bgPaint);

    final borderPaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(selectionRect!, borderPaint);
  }

  @override
  bool shouldRepaint(covariant OverlayPainter oldDelegate) {
    return oldDelegate.selectionRect != selectionRect;
  }
}
