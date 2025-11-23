// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart'; // <-- 1. Import new plugin

class MapsTab extends StatefulWidget {
  const MapsTab({super.key});

  @override
  State<MapsTab> createState() => _MapsTabState();
}

class _MapsTabState extends State<MapsTab> {
  final Completer<GoogleMapController> _mapController = Completer();
  Position? _currentPosition;
  String? _errorMessage;

  // --- 2. NEW STATE VARIABLE ---
  bool _isPermissionPermanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // --- 3. NEW METHOD to open app settings ---
  Future<void> _openAppSettings() async {
    // This will open the app's settings page for the user
    await openAppSettings();
  }

  // --- 4. MODIFIED location logic ---
  Future<void> _getCurrentLocation() async {
    try {
      // 1. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled. Please enable them.';
        });
        return;
      }

      // 2. Use permission_handler to request location
      PermissionStatus status = await Permission.location.request();

      if (status.isGranted) {
        // --- Permission is GRANTED ---
        setState(() {
          _isPermissionPermanentlyDenied = false;
          _errorMessage = null;
        });

        // 3. Get the current location (using geolocator)
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _currentPosition = position;
        });

        // 4. Animate the map camera
        final GoogleMapController controller = await _mapController.future;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15.0,
            ),
          ),
        );
      } else if (status.isDenied) {
        // --- Permission is DENIED ---
        // The user denied it, but not permanently.
        // We can ask again on the next retry.
        setState(() {
          _isPermissionPermanentlyDenied = false;
          _errorMessage = 'Location permission is required to show the map.';
        });
      } else if (status.isPermanentlyDenied) {
        // --- Permission is PERMANENTLY DENIED ---
        // We cannot ask again. We must send them to settings.
        setState(() {
          _isPermissionPermanentlyDenied = true;
          _errorMessage =
              'Location permission is permanently denied. Please enable it in app settings.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get location: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_errorMessage != null) {
      // --- 5. MODIFIED Error Body ---
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                // This is the "smart" button logic
                onPressed: _isPermissionPermanentlyDenied
                    ? _openAppSettings // If permanently denied, open settings
                    : _getCurrentLocation, // Otherwise, try to request again
                child: Text(
                  _isPermissionPermanentlyDenied ? 'Open Settings' : 'Retry',
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_currentPosition == null) {
      // Show loading spinner
      body = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Fetching your location...'),
          ],
        ),
      );
    } else {
      // Show the Google Map
      body = GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          if (!_mapController.isCompleted) {
            _mapController.complete(controller);
          }
        },
        initialCameraPosition: CameraPosition(
          target: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          zoom: 15.0,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      );
    }

    return Scaffold(
      body: body,
      floatingActionButton: _currentPosition != null
          ? FloatingActionButton(
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
