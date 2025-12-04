import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:math' as math;

import 'package:flutter/material.dart' hide ImageProvider;
import 'package:yandex_maps_mapkit_lite/init.dart' as init;
import 'package:yandex_maps_mapkit_lite/mapkit.dart' as ya;
import 'package:yandex_maps_mapkit_lite/mapkit_factory.dart';
import 'package:yandex_maps_mapkit_lite/yandex_map.dart' show YandexMap;

import 'data.dart' as source;
import 'models.dart';
import 'pin_painter_service.dart';

FutureOr<void> main() async => runZonedGuarded(() async {
  WidgetsFlutterBinding.ensureInitialized();

  await init.initMapkit(apiKey: "YOUR_API_KEY");
  runApp(const App());
}, (err, stack) => dev.log('top_level_err', error: err, stackTrace: stack));

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(home: MainScreen());
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<PinConfig> _list = [];

  late ya.ClusterizedPlacemarkCollection _clusterizedCollection;
  // late ya.MapObjectCollection _pinCollection;

  late ya.ClusterListener _clusterListener;

  late PinPainterService _painter;

  @override
  void initState() {
    super.initState();

    final data = jsonDecode(source.data) as List<dynamic>;
    _list.addAll(
      data.map((json) => ChargePoint.fromJson(json)).map((cp) => PinConfig(cp)),
    );

    mapkit.onStart();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        YandexMap(
          onMapCreated: (window) async {
            _painter = PinPainterService();
            _clusterListener = ClusterListenerImpl(_painter);

            // _pinCollection = window.map.mapObjects.addCollection();
            _clusterizedCollection = window.map.mapObjects
                .addClusterizedPlacemarkCollection(_clusterListener);
          },
        ),
        Positioned(
          right: 20,
          bottom: 50,
          child: ElevatedButton(
            onPressed: () async => _createClusters(_painter, _list),
            child: const Text('Add clusters'),
          ),
        ),
      ],
    ),
  );

  @override
  void dispose() {
    mapkit.onStop();
    super.dispose();
  }

  Future<void> _createClusters(
    PinPainterService service,
    List<PinConfig> configs,
  ) async {
    _clusterizedCollection.clear();
    final stopwatch = Stopwatch()..start();

    for (final config in configs) {
      if (stopwatch.elapsedMilliseconds > 8) {
        await Future<void>.delayed(Duration.zero);
        stopwatch.reset();
      }

      await _createClusterAndAddToCollection(service, config);
    }

    _clusterizedCollection.clusterPlacemarks(clusterRadius: 50, minZoom: 10);
  }

  Future<void> _createClusterAndAddToCollection(
    PinPainterService painter,
    PinConfig config,
  ) async {
    final point = ya.Point(latitude: config.lat, longitude: config.lon);
    final provider = await painter.createMiniPin(config);

    _clusterizedCollection.addPlacemarkWithImage(point, provider)
      ..setIconStyle(const ya.IconStyle(anchor: math.Point<double>(0.5, 1)))
      ..userData = config;
  }
}

final class ClusterListenerImpl implements ya.ClusterListener {
  final PinPainterService _pinPainterService;

  ClusterListenerImpl(this._pinPainterService);

  @override
  Future<void> onClusterAdded(ya.Cluster cluster) async {
    final provider = await _pinPainterService.createClusterPin(cluster.size);
    cluster.appearance.setIcon(provider);
  }
}
