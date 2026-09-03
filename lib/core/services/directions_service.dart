import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class DirectionsService {
  static Future<List<LatLng>?> getRoute({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
  }) async {
    if (!ApiConstants.hasGoogleMapsKey) return null;

    final String baseUrl = 'https://maps.googleapis.com/maps/api/directions/json';
    
    String waypointsStr = '';
    if (waypoints != null && waypoints.isNotEmpty) {
      waypointsStr = '&waypoints=optimize:true|';
      waypointsStr += waypoints.map((p) => '${p.latitude},${p.longitude}').join('|');
    }

    final String url = '$baseUrl?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '$waypointsStr'
        '&key=${ApiConstants.googleMapsApiKey}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
          final String points = data['routes'][0]['overview_polyline']['points'];
          return _decodePolyline(points);
        }
      }
    } catch (e) {
      // Return null on failure
    }
    
    return null;
  }

  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }
}
