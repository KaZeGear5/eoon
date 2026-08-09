import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'services/routing_service.dart';
import 'models/alert.dart';
import 'widgets/alert_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const EoonApp());
}

class EoonApp extends StatelessWidget {
  const EoonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EooN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapLibreMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  RouteInfo? _currentRoute;
  final List<RoadAlert> _alerts = [];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage('Veuillez activer le GPS sur votre appareil.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showMessage('La permission de localisation a été refusée.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage('Permission GPS bloquée dans les réglages.');
      return;
    }

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = pos;
      _isLoading = false;
    });

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position newPos) {
      setState(() {
        _currentPosition = newPos;
      });
    });
  }

  Future<void> _drawRouteTo(LatLng destination) async {
    if (_currentPosition == null || _mapController == null) return;

    LatLng start = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    RouteInfo? route = await RoutingService.getRoute(start, destination);

    if (route != null) {
      setState(() {
        _currentRoute = route;
      });

      await _mapController!.clearLines();
      await _mapController!.addLine(
        LineOptions(
          geometry: route.points,
          lineColor: "#06B6D4",
          lineWidth: 6.0,
          lineOpacity: 0.9,
        ),
      );
    }
  }

  /// Ajouter une alerte sur la carte à la position actuelle du conducteur
  void _reportAlert(AlertType type) async {
    if (_currentPosition == null || _mapController == null) return;

    LatLng currentLatLng = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    RoadAlert newAlert = RoadAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      position: currentLatLng,
      timestamp: DateTime.now(),
    );

    setState(() {
      _alerts.add(newAlert);
    });

    // Ajoute un cercle de signalement sur la carte
    await _mapController!.addCircle(
      CircleOptions(
        geometry: currentLatLng,
        circleColor: _getAlertColorHex(type),
        circleRadius: 10.0,
        circleOpacity: 0.8,
        circleStrokeWidth: 2,
        circleStrokeColor: "#FFFFFF",
      ),
    );

    _showMessage('Alerte "${newAlert.title}" signalée à la communauté !');
  }

  String _getAlertColorHex(AlertType type) {
    switch (type) {
      case AlertType.police:
        return "#3B82F6";
      case AlertType.accident:
        return "#EF4444";
      case AlertType.hazard:
        return "#F59E0B";
      case AlertType.traffic:
        return "#8B5CF6";
    }
  }

  void _openReportMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AlertReportSheet(
        onAlertSelected: _reportAlert,
      ),
    );
  }

  void _recenterMap() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          16.0,
        ),
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF06B6D4)),
                )
              : MapLibreMap(
                  onMapCreated: (controller) => _mapController = controller,
                  onMapClick: (point, latLng) => _drawRouteTo(latLng),
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition?.latitude ?? 48.8566,
                      _currentPosition?.longitude ?? 2.3522,
                    ),
                    zoom: 16.0,
                  ),
                  styleString: "https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json",
                  myLocationEnabled: true,
                  myLocationTrackingMode: MyLocationTrackingMode.Tracking,
                ),

          // Panneau récapitulatif d'itinéraire
          if (_currentRoute != null)
            Positioned(
              bottom: 110,
              left: 20,
              right: 20,
              child: Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(_currentRoute!.durationSeconds / 60).round()} min',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF06B6D4),
                            ),
                          ),
                          Text(
                            '${(_currentRoute!.distanceMeters / 1000).toStringAsFixed(1)} km',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF06B6D4),
                        ),
                        onPressed: () => _showMessage('Guidage activé !'),
                        child: const Text('Démarrer', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bouton "Signaler" style Waze (Orange/Jaune d'alerte)
          Positioned(
            bottom: 30,
            left: 20,
            child: FloatingActionButton.extended(
              heroTag: 'report_btn',
              backgroundColor: const Color(0xFFF59E0B),
              onPressed: _openReportMenu,
              icon: const Icon(Icons.warning_amber_rounded, color: Colors.white),
              label: const Text('Signaler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),

          // Bouton pour recentrer GPS
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'recenter_btn',
              backgroundColor: const Color(0xFF06B6D4),
              onPressed: _recenterMap,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
