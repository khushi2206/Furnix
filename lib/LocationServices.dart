import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationServices extends StatefulWidget {
  const LocationServices({super.key});

  @override
  State<LocationServices> createState() => _LocationServicesState();
}

class _LocationServicesState extends State<LocationServices> {
  String locationStatus = 'Unknown';

  // Method to check location permission and get the current position
  Future<void> getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      // If permission is denied, request it
      permission = await Geolocator.requestPermission();

      // If permission is still denied after requesting, display a message
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          locationStatus = 'Location permission denied';
        });
        return;
      }
    }

    // If permission is granted, get the current position
    Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);

    // Update the status to show the location
    setState(() {
      locationStatus = 'Latitude: ${currentPosition.latitude}, Longitude: ${currentPosition.longitude}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Geolocator"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: getCurrentLocation,
              child: const Text("Grab Location"),
            ),
            const SizedBox(height: 20),
            Text(
              locationStatus,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

