import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'services/routing_service.dart';

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
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Style Sombre
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

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  /// Gestion des permissions et suivi GPS
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
      _showMessage('Permission GPS bloquée. Activez-la dans les réglages du téléphone.');
      return;
    }

    // Premier relevé GPS
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = pos;
      _isLoading = false;
    });

    // Écoute de la position en temps réel pendant le déplacement
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

  /// Calcul et tracé d'un itinéraire au clic sur la carte
  Future<void> _drawRouteTo(LatLng destination) async {
    if (_currentPosition == null || _mapController == null) return;

    LatLng start = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    RouteInfo? route = await RoutingService.getRoute(start, destination);

    if (route != null) {
      setState(() {
        _currentRoute = route;
      });

      // Nettoie la carte avant d'afficher la nouvelle ligne
      await _mapController!.clearLines();

      // Dessine la ligne d'itinéraire en Cyan Néon (Signature EooN)
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
                  onMapClick: (point, latLng) {
                    // Clic sur la carte = Définir comme destination
                    _drawRouteTo(latLng);
                  },
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
              bottom: 100,
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
                        onPressed: () {
                          _showMessage('Lancement du guidage vocal...');
                        },
                        child: const Text('Démarrer', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bouton pour recentrer sur sa position
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
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
