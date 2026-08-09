import 'package:maplibre_gl/maplibre_gl.dart';

enum AlertType {
  police,
  accident,
  hazard,
  traffic,
}

class RoadAlert {
  final String id;
  final AlertType type;
  final LatLng position;
  final DateTime timestamp;

  RoadAlert({
    required this.id,
    required this.type,
    required this.position,
    required this.timestamp,
  });

  String get title {
    switch (type) {
      case AlertType.police:
        return 'Contrôle / Police';
      case AlertType.accident:
        return 'Accident';
      case AlertType.hazard:
        return 'Danger / Obstacle';
      case AlertType.traffic:
        return 'Ralentissement';
    }
  }

  String get iconAsset {
    switch (type) {
      case AlertType.police:
        return '👮';
      case AlertType.accident:
        return '💥';
      case AlertType.hazard:
        return '⚠️';
      case AlertType.traffic:
        return '🚗';
    }
  }
}
