import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Minimal canvas implementation for campus demo.
///
/// Notes:
/// - This file intentionally focuses on drawing + export PNG bytes.
/// - Eraser is implemented as transparent stroke (simple) for demo purposes.
class StrokePoint {
  final Offset position;
  final DateTime time;

  const StrokePoint({
    required this.position,
    required this.time,
  });
}

class Stroke {
  final List<StrokePoint> points;
  final Color color;
  final double strokeWidth;

  const Stroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

/// Canvas widget that draws freehand strokes.
///
/// To export PNG, use [exportPngBytes] through the state via GlobalKey.
class DoodinkCanvas extends StatefulWidget {
  final Color brushColor;
  final double brushSize;
  final bool isEraser;
  final VoidCallback? onStrokesChanged;

  const DoodinkCanvas({
    super.key,
    required this.brushColor,
    required this.brushSize,
    required this.isEraser,
    this.onStrokesChanged,
  });

  @override
  State<DoodinkCanvas> createState() => _DoodinkCanvasState();
}

class _DoodinkCanvasState extends State<DoodinkCanvas> {
  final GlobalKey _repaintKey = GlobalKey();

  final List<Stroke> _strokes = [];
  Stroke? _current;

  Future<ui.Image> _renderToImage({double pixelRatio = 3.0}) async {
    final boundary = _repaintKey.currentContext?.findRenderObject();
    // RenderRepaintBoundary type is internal; we only rely on the available method.
    // ignore: avoid_dynamic_calls
    final dynamic b = boundary;
    if (b == null) {
      throw StateError('Canvas boundary not ready');
    }

    // ignore: avoid_dynamic_calls
    final image = await b.toImage(pixelRatio: pixelRatio) as ui.Image;
    return image;

  }

  /// Export the current canvas as PNG bytes.
  Future<Uint8List> exportPngBytes({double pixelRatio = 3.0}) async {
    final image = await _renderToImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData?.buffer.asUint8List();
    if (bytes == null) {
      throw StateError('Failed to export png bytes');
    }
    return bytes;
  }

  void clear() {
    setState(() {
      _strokes.clear();
      _current = null;
    });
    widget.onStrokesChanged?.call();
  }

  void _startStroke(Offset pos) {
    final color = widget.isEraser ? Colors.transparent : widget.brushColor;
    final strokeWidth = widget.isEraser ? widget.brushSize * 1.2 : widget.brushSize;

    _current = Stroke(
      points: [StrokePoint(position: pos, time: DateTime.now())],
      color: color,
      strokeWidth: strokeWidth,
    );

    setState(() {});
  }

  void _appendPoint(Offset pos) {
    if (_current == null) return;

    _current = Stroke(
      points: [
        ..._current!.points,
        StrokePoint(position: pos, time: DateTime.now()),
      ],
      color: _current!.color,
      strokeWidth: _current!.strokeWidth,
    );

    setState(() {});
  }

  void _endStroke() {
    if (_current == null) return;

    setState(() {
      _strokes.add(_current!);
      _current = null;
    });

    widget.onStrokesChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _repaintKey,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (d) => _startStroke(d.localPosition),
        onPanUpdate: (d) => _appendPoint(d.localPosition),
        onPanEnd: (_) => _endStroke(),
        child: CustomPaint(
          painter: _DoodinkCanvasPainter(
            strokes: _strokes,
            current: _current,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _DoodinkCanvasPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? current;

  _DoodinkCanvasPainter({required this.strokes, required this.current});

  @override
  void paint(Canvas canvas, Size size) {
    final all = [...strokes];
    if (current != null) all.add(current!);

    for (final stroke in all) {
      if (stroke.points.length < 2) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true;

      final path = Path();
      path.moveTo(
        stroke.points.first.position.dx,
        stroke.points.first.position.dy,
      );

      for (final p in stroke.points.skip(1)) {
        path.lineTo(p.position.dx, p.position.dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DoodinkCanvasPainter oldDelegate) {
    return oldDelegate.strokes.length != strokes.length || oldDelegate.current != current;
  }
}

