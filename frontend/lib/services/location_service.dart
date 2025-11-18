import 'package:geolocator/geolocator.dart';

class LocationException implements Exception {
  final String message;
  LocationException(this.message);
}

class LocationService {
  // Gets the current GPS position of the device.
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }
}