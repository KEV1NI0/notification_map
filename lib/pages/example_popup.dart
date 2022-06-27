import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MarkerData {
  static const double size = 25;

  MarkerData({
    required this.name,
    required this.latLocation, required String image,
  });

  final String name;
  final LatLng latLocation;
}

class DisplayMarker extends Marker {
  DisplayMarker({required this.marker3})
      : super(
          anchorPos: AnchorPos.align(AnchorAlign.top),
          height: MarkerData.size,
          width: MarkerData.size,
          point: marker3.latLocation,
          builder: (BuildContext ctx) => const Icon(
            Icons.location_pin,
            color: Colors.red,
          ),
        );

  final MarkerData marker3;
}

class MarkerDataPopup extends StatelessWidget {
  const MarkerDataPopup({Key? key, required this.markerDataVar})
      : super(key: key);
  final MarkerData markerDataVar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            //Image.network(monument.imagePath, width: 200),
            Text(markerDataVar.name),
            Text('${markerDataVar.latLocation.latitude}, ${markerDataVar.latLocation.longitude}'),
          ],
        ),
      ),
    );
  }
}
