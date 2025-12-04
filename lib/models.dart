final class ChargePoint {
  final String id;
  final List<Connector> connectors;

  final double lat;
  final double lon;

  ChargePoint(this.id, this.connectors, this.lat, this.lon);

  static ChargePoint fromJson(Map<String, dynamic> json) => ChargePoint(
    json['ChargePointId'] as String,
    (json['Connectors'] as List<dynamic>)
        .map((json) => Connector.fromJson(json))
        .toList(),
    json['Latitude'] as double,
    json['Longitude'] as double,
  );
}

final class Connector {
  final String id;
  final String status;

  final int maxPower;

  Connector(this.id, this.status, this.maxPower);

  static Connector fromJson(Map<String, dynamic> json) => Connector(
    json['Id'] as String,
    json['StatusForUser'] as String,
    json['MaxPower'] as int,
  );
}

enum PinStatus { unavailable, busy, available }

final class PinConfig {
  final ChargePoint _cp;

  PinConfig(this._cp);

  PinStatus get status => PinStatus.unavailable;
  int get maxPower => _cp.connectors.first.maxPower;

  int get count => _cp.connectors.length;
  List<PinStatus> get connectorStatuses =>
      _cp.connectors.map((_) => PinStatus.unavailable).toList();

  double get lat => _cp.lat;
  double get lon => _cp.lon;
}
