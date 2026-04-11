import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  final marker = CircleMarker(
    point:  LatLng(0, 0),
    radius: 100,
    useRadiusInMeter: true,
  );
  print(marker.useRadiusInMeter);
}
