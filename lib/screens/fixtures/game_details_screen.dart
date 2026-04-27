import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class GameDetailsScreen extends StatefulWidget {
  final String homeTeam;
  final String awayTeam;
  final String score;
  final String venue;
  final double lat;
  final double lng;

  const GameDetailsScreen({
    super.key,
    required this.homeTeam,
    required this.awayTeam,
    required this.score,
    required this.venue,
    required this.lat,
    required this.lng,
  });

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  static const neonGreen = Color(0xFF00FF85);
  static const bgBlack = Color(0xFF0A0A0A);
  static const cardGrey = Color(0xFF141414);

  late GoogleMapController mapController;
  String _distanceText = "Calculating distance...";

  @override
  void initState() {
    super.initState();
    _calculateDistance();
  }

  Future<void> _calculateDistance() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _distanceText = "Location services disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _distanceText = "Location permissions denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _distanceText = "Location permissions permanently denied.");
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        widget.lat,
        widget.lng,
      );

      final distanceInKm = (distanceInMeters / 1000).toStringAsFixed(1);
      if (mounted) {
        setState(() {
          _distanceText = "$distanceInKm km away";
        });
      }
    } catch (e) {
      if (mounted) setState(() => _distanceText = "Unable to get location.");
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    // The position of the stadium
    final LatLng stadiumPos = LatLng(widget.lat, widget.lng);

    return Scaffold(
      backgroundColor: bgBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: neonGreen, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "MATCH PREVIEW",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. MATCH HEADER 
          _buildHeader(),

          // 2. THE LIVE MAP SECTION
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardGrey,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: stadiumPos,
                    zoom: 15.0, 
                  ),
                  // THE PIN (Marker)
                  markers: {
                    Marker(
                      markerId: const MarkerId("stadium_pin"),
                      position: stadiumPos,
                      infoWindow: InfoWindow(
                        title: widget.venue,
                        snippet: "Sunday League Matchday",
                      ),
                    ),
                  },
                  // UI Settings to keep it clean
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  myLocationButtonEnabled: false,
                ),
              ),
            ),
          ),

          // 3. DISTANCE TEXT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, color: neonGreen, size: 16),
                const SizedBox(width: 8),
                Text(
                  _distanceText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),

          // 4. NAVIGATION BUTTON
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: ElevatedButton.icon(
              onPressed: () => _openNativeMaps(),
              icon: const Icon(Icons.directions, color: Colors.black),
              label: const Text(
                "OPEN IN GOOGLE MAPS",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: neonGreen,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // Handoff location to the native Google Maps App
  Future<void> _openNativeMaps() async {
    // FIXED: Corrected quotes and added actual coordinates
    final String url =
        'https://www.google.com/maps/search/?api=1&query=${widget.lat},${widget.lng}';

    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Helpful for debugging on your MacBook simulator
      debugPrint("Could not launch maps for coordinates: ${widget.lat}, ${widget.lng}");
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _teamDetail(widget.homeTeam),
          Text(
            widget.score,
            style: const TextStyle(color: neonGreen, fontSize: 36, fontWeight: FontWeight.w900),
          ),
          _teamDetail(widget.awayTeam),
        ],
      ),
    );
  }

  Widget _teamDetail(String name) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 30,
          backgroundColor: cardGrey,
          child: Icon(Icons.shield, color: neonGreen),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
