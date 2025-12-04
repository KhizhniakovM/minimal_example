import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide ImageProvider;
import 'package:yandex_maps_mapkit_lite/image.dart';

import 'models.dart';

final class PinPainterService {
  static const _startAngle = -90;
  static const _angleBetweenPaths = 5;
  static const _fullCircleDegrees = 360;

  final Map<PinStatus, ImageProvider> _pinMini = {};
  final Map<PinStatus, ui.Image> _pinBlank = {};
  final Map<int, ui.Image> _power = {};

  ui.Image? _clusterBlank;

  final textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );

  final PinPainterSettings _settings = PinPainterSettings(
    Colors.green,
    TextStyle(),
    TextStyle(),
    TextStyle(),
    'kw',
    400,
    2,
  );

  PinPainterService();

  Future<ImageProvider> createPin(PinConfig config) async {
    final status = config.status;
    final blank = _pinBlank[status] ?? await _createPinBlank(status);
    final text = _power[config.maxPower] ?? await _createText(config);
    final connectors = await _createConnectors(config, blank, text);

    final data = await connectors.toByteData(format: ui.ImageByteFormat.png);
    final image = Image.memory(
      data!.buffer.asUint8List(),
      width: 20,
      height: _settings.size,
    );
    return ImageProvider.fromImageProvider(image.image);
  }

  Future<ImageProvider> createMiniPin(PinConfig config) async =>
      _pinMini[config.status] ?? await _createMini(config);

  Future<ImageProvider> createClusterPin(int count) async {
    final blank = _clusterBlank ??= await _createClusterBlank(count);
    final cluster = await _createClusterText(blank, count);

    final data = await cluster.toByteData(format: ui.ImageByteFormat.png);
    final result = Image.memory(
      data!.buffer.asUint8List(),
      width: _settings.clusterSize,
      height: _settings.clusterSize,
    );
    return ImageProvider.fromImageProvider(result.image);
  }

  Future<ui.Image> _createClusterBlank(int count) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final center = Offset(_settings.clusterSize / 2, _settings.clusterSize / 2);
    final radius = _settings.clusterSize / 2;

    final paint = Paint()..color = Colors.white;

    _paintMiniWhiteCircle(canvas, paint, center, radius);
    _paintMiniCenterCircleForCluster(
      canvas,
      paint,
      center,
      _settings.clusterSize,
    );

    final image = await _createImage(
      recorder,
      Size(_settings.clusterSize, _settings.clusterSize),
    );
    return image;
  }

  Future<ui.Image> _createClusterText(ui.Image blank, int count) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = Colors.white;

    canvas.drawImage(blank, Offset.zero, paint);
    _paintClusterText(canvas, count);

    final image = await _createImage(
      recorder,
      Size(_settings.clusterSize, _settings.clusterSize),
    );
    return image;
  }

  Future<ImageProvider> _createMini(PinConfig config) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final center = Offset(_settings.miniSize / 2, _settings.miniSize / 2);
    final radius = _settings.miniSize / 2;

    final paint = Paint()..color = Colors.white;

    _paintMiniWhiteCircle(canvas, paint, center, radius);
    _paintMiniCenterCircle(canvas, paint, center, config, _settings.miniSize);

    final image = await _createImage(
      recorder,
      Size(_settings.miniSize, _settings.miniSize),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final result = Image.memory(
      data!.buffer.asUint8List(),
      width: _settings.miniSize,
      height: _settings.miniSize,
    );
    final provider = ImageProvider.fromImageProvider(result.image);
    _pinMini[config.status] = provider;
    return provider;
  }

  void _paintMiniWhiteCircle(
    Canvas canvas,
    Paint paint,
    Offset center,
    double radius,
  ) {
    paint.color = Colors.white;
    canvas.drawCircle(center, radius, paint);
  }

  void _paintMiniCenterCircle(
    Canvas canvas,
    Paint paint,
    Offset center,
    PinConfig config,
    double size,
  ) {
    _checkPinColor(config.status, paint);
    canvas.drawCircle(center, size * 0.35, paint);
  }

  void _paintMiniCenterCircleForCluster(
    Canvas canvas,
    Paint paint,
    Offset center,
    double size,
  ) {
    paint.color = _settings.availableColor;
    canvas.drawCircle(center, size * 0.45, paint);
  }

  Future<ui.Image> _createPinBlank(PinStatus status) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final center = Offset(_settings.size / 2, (_settings.size / 2) * 0.8);
    final radius = (_settings.size / 2) * 0.75;

    final paint = Paint()..color = Colors.white;

    _paintMainShadow(center, radius, canvas);
    _paintMainTriangle(_settings.size, canvas, paint);
    _paintSmallTriangle(paint, _settings.size, canvas, status);
    _paintMainWhiteCircle(canvas, paint, center, radius);
    _paintCenterCircle(paint, radius, canvas, center, status);

    final image = await _createImage(
      recorder,
      Size(_settings.size, _settings.size),
    );
    _pinBlank[status] = image;
    return image;
  }

  Future<ui.Image> _createConnectors(
    PinConfig config,
    ui.Image blank,
    ui.Image text,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = Colors.white;

    final center = Offset(_settings.size / 2, (_settings.size / 2) * 0.8);
    final radius = (_settings.size / 2) * 0.75;

    final pathsCount = config.count;

    canvas
      ..drawImage(blank, Offset.zero, paint)
      ..drawImage(text, Offset.zero, paint);

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.125;

    final circlePathRadius = radius * 0.875;

    if (pathsCount == 1) {
      _checkPinColor(config.status, paint);
      canvas.drawCircle(center, circlePathRadius, paint);

      final image = await _createImage(
        recorder,
        Size(_settings.size, _settings.size),
      );
      return image;
    }

    final betweenAngle = _angleBetweenPaths.degreesToRadians();
    final pathLength = (_fullCircleDegrees / pathsCount) - _angleBetweenPaths;
    final sweepAngle = pathLength.degreesToRadians();
    final arcRect = Rect.fromCircle(center: center, radius: circlePathRadius);
    double startAngle = _startAngle.degreesToRadians() + (betweenAngle / 2);

    for (final _ in config.connectorStatuses) {
      _checkConnectorColor(paint);
      canvas.drawArc(arcRect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle + betweenAngle;
    }

    final image = await _createImage(
      recorder,
      Size(_settings.size, _settings.size),
    );
    return image;
  }

  Future<ui.Image> _createText(PinConfig config) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final center = Offset(_settings.size / 2, (_settings.size / 2) * 0.8);
    double scale = _settings.pixelRatio;
    final powerText = TextSpan(
      text: config.maxPower.toString(),
      style: _settings.powerTextStyle,
    );
    final kwText = TextSpan(style: _settings.muTextStyle, text: _settings.kw);

    if (_settings.shortestSide > 600) {
      scale = _settings.pixelRatio * 2;
    }

    textPainter
      ..text = powerText
      ..textScaler = TextScaler.linear(scale)
      ..layout(minWidth: _settings.size)
      ..paint(canvas, Offset(0, center.dy - (14 * scale)))
      ..text = kwText
      ..layout(minWidth: _settings.size)
      ..paint(canvas, Offset(0, center.dy + 8));

    final image = await _createImage(
      recorder,
      Size(_settings.size, _settings.size),
    );
    _power[config.maxPower] = image;
    return image;
  }

  void _paintClusterText(Canvas canvas, int count) {
    final center = Offset(_settings.clusterSize / 2, _settings.clusterSize / 2);
    double scale = _settings.pixelRatio;
    final powerText = TextSpan(
      text: count.toString(),
      style: _settings.clusterTextStyle,
    );

    if (_settings.shortestSide > 600) {
      scale = _settings.pixelRatio * 2;
    }

    textPainter
      ..text = powerText
      ..textScaler = TextScaler.linear(scale)
      ..layout(minWidth: _settings.clusterSize)
      ..paint(canvas, Offset(0, center.dy / 1.9));
  }

  void _paintMainShadow(Offset center, double radius, Canvas canvas) {
    final path =
        Path()..addOval(Rect.fromCircle(center: center, radius: radius + 5));

    canvas.drawShadow(path, Colors.black38, 5, true);
  }

  void _paintMainTriangle(double size, Canvas canvas, Paint paint) {
    final triangle =
        Path()
          ..moveTo(size * 0.2, size * 0.6)
          ..lineTo(size * 0.475, size * 0.875)
          ..arcToPoint(
            Offset(size * 0.525, size * 0.875),
            radius: Radius.circular(size * 0.04),
            clockwise: false,
          )
          ..lineTo(size * 0.8, size * 0.6)
          ..close();

    canvas.drawPath(triangle, paint);
  }

  void _paintSmallTriangle(
    Paint paint,
    double size,
    Canvas canvas,
    PinStatus status,
  ) {
    _checkPinColor(status, paint);

    final smallTriangle =
        Path()
          ..moveTo(size * 0.225, size * 0.575)
          ..lineTo(size * 0.49, size * 0.85)
          ..arcToPoint(
            Offset(size * 0.51, size * 0.85),
            radius: Radius.circular(size * 0.02),
            clockwise: false,
          )
          ..lineTo(size * 0.775, size * 0.575)
          ..close();

    canvas.drawPath(smallTriangle, paint);
  }

  void _paintMainWhiteCircle(
    Canvas canvas,
    Paint paint,
    Offset center,
    double radius,
  ) {
    paint.color = Colors.white;
    canvas.drawCircle(center, radius, paint);
  }

  void _paintCenterCircle(
    Paint paint,
    double radius,
    Canvas canvas,
    Offset center,
    PinStatus status,
  ) {
    _checkPinColor(status, paint);
    final centerCircleRadius = radius * 0.75;
    canvas.drawCircle(center, centerCircleRadius, paint);
  }

  // Common
  void _checkPinColor(PinStatus status, Paint paint) {
    paint.color = _settings.availableColor;
  }

  void _checkConnectorColor(Paint paint) {
    paint.color = Colors.red;
  }

  Future<ui.Image> _createImage(ui.PictureRecorder recorder, Size size) async {
    final image = await recorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    return image;
  }
}

extension DegreesToRadians on num {
  double degreesToRadians() => this * (math.pi / 180);
}

final class PinPainterSettings {
  final Color availableColor;

  final TextStyle clusterTextStyle;

  final TextStyle powerTextStyle;

  final TextStyle muTextStyle;

  final String kw;

  final double shortestSide;

  final double pixelRatio;

  PinPainterSettings(
    this.availableColor,
    this.clusterTextStyle,
    this.powerTextStyle,
    this.muTextStyle,
    this.kw,
    this.shortestSide,
    this.pixelRatio,
  );

  double get size => (shortestSide * pixelRatio) / 6;
  double get userSize => size / 1.5;
  double get miniSize => size / 4;

  double get hubSize => size;

  double get clusterSize => size / 2;

  double get imageSize => pixelRatio * 44;
}
