import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

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
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Bleu nuit
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

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  /// Gestion des permissions et de la géolocalisation
  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage('Veuillez activer le GPS de votre appareil.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showMessage('La permission de localisation est refusée.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage('Permission GPS refusée définitivement. Activez-la dans les paramètres.');
      return;
    }

    // Premier fix GPS
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = pos;
      _isLoading = false;
    });

    // Écoute continue de la position en déplacement
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

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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

          // Bouton flottant pour recentrer sur le GPS
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF06B6D4), // Accent Cyan
              onPressed: _recenterMap,
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
