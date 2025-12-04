import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide ImageProvider;
import 'package:yandex_maps_mapkit_lite/image.dart';

import 'models.dart';

final class PinPainterService {
  final Map<PinStatus, ImageProvider> _pinMini = {};

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

  // Common
  void _checkPinColor(PinStatus status, Paint paint) {
    paint.color = _settings.availableColor;
  }

  Future<ui.Image> _createImage(ui.PictureRecorder recorder, Size size) async {
    final image = await recorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    return image;
  }
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
