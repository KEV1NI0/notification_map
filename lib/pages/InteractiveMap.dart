import 'dart:async';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http/http.dart' show get;

class InteractiveMap extends StatefulWidget {
  const InteractiveMap({Key? key}) : super(key: key);

  @override
  State<InteractiveMap> createState() => _InteractiveMapState();
}

class _InteractiveMapState extends State<InteractiveMap> {
  LocationData? _currentLocation;
  late final MapController _mapController;

  bool _permission = false;

  String? _serviceError = '';

  var interActiveFlags = InteractiveFlag.all;

  final Location _locationService = Location();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    initLocationService();
  }

  void initLocationService() async {
    await _locationService.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 1000,
    );

    LocationData? location;
    bool serviceEnabled;
    bool serviceRequestResult;

    try {
      serviceEnabled = await _locationService.serviceEnabled();

      if (serviceEnabled) {
        var permission = await _locationService.requestPermission();
        _permission = permission == PermissionStatus.granted;

        if (_permission) {
          location = await _locationService.getLocation();
          _currentLocation = location;
          _locationService.onLocationChanged
              .listen((LocationData result) async {
            if (mounted) {
              setState(() {
                _currentLocation = result;
                _mapController.move(
                    LatLng(_currentLocation!.latitude!,
                        _currentLocation!.longitude!),
                    _mapController.zoom);
              });
            }
          });
        }
      } else {
        serviceRequestResult = await _locationService.requestService();
        if (serviceRequestResult) {
          initLocationService();
          return;
        }
      }
    } on PlatformException catch (e) {
      debugPrint(e.toString());
      if (e.code == 'PERMISSION_DENIED') {
        _serviceError = e.message;
      } else if (e.code == 'SERVICE_STATUS_ERROR') {
        _serviceError = e.message;
      }
      location = null;
    }
  }
  late LatLng currentLatLng;

  @override
  Widget build(BuildContext context) {


    // Until currentLocation is initially updated, Widget can locate to 0, 0
    // by default or store previous location value to show.
    if (_currentLocation != null) {
      currentLatLng =
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);
    } else {
      currentLatLng = LatLng(0, 0);
    }

    var markers = <Marker>[
      Marker(
        width: 80.0,
        height: 80.0,
        point: currentLatLng,
        builder: (ctx) => const Icon(Icons.location_pin, color: Colors.red,),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: _serviceError!.isEmpty
                  ? Text('This is a map that is showing '
                  '(${currentLatLng.latitude}, ${currentLatLng.longitude}).')
                  : Text(
                  'Error occurred while acquiring location. Error Message : '
                      '$_serviceError'),
            ),
            Flexible(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  maxBounds: LatLngBounds(
                    LatLng(12.398636,-69.177026),
                    LatLng(11.997293,-68.725121),
                  ),
                  zoom: 13,
                  maxZoom: 17,
                  center:
                  LatLng(currentLatLng.latitude, currentLatLng.longitude),
                  interactiveFlags: interActiveFlags,
                ),
                layers: [
                  TileLayerOptions(
                    urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
                    // For example purposes. It is recommended to use
                    // TileProvider with a caching and retry strategy, like
                    // NetworkTileProvider or CachedNetworkTileProvider
                    tileProvider: const NonCachingNetworkTileProvider(),
                  ),
                  MarkerLayerOptions(markers: markers)
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Builder(builder: (BuildContext context) {
        return Stack(
          children: [
            Positioned(
              bottom: 10,
              right: 10,
              child: FloatingActionButton(
                  onPressed: () {
                    if(_currentLocation == null){
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Please try again'),
                      ));
                    } else{
                      print(_currentLocation);
                      print(currentLatLng);
                    }
                    _mapController.move(
                        LatLng(_currentLocation!.latitude!,
                            _currentLocation!.longitude!),
                        _mapController.zoom);
                    setState(() {
                    });
                  },
                  child: const Icon(Icons.my_location)
              ),
            ),
            Positioned(
              bottom: 75,
              right: 10,
              child: FloatingActionButton(
                  onPressed: () {
                    if(_currentLocation == null){
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Please find location first'),
                      ));
                    } else {
                      alertDialog();
                    }
                    setState(() {
                    });
                  },
                  child: const Icon(Icons.add_location_alt)
              ),
            )
          ],
        );
      }),
    );
  }
  Future alertDialog(){

    TextEditingController name = TextEditingController();
    //TextEditingController location = TextEditingController();

    Future<void> insertRecord() async{
      if(name.text==""){
        try{
          String uri = "http://localhost/DBConnect/insert_record.php";
          var res = await http.post(Uri.parse(uri), body: {
            'name': name.text,
          });
          var response=jsonDecode(res.body);
          if(response['success']==""){
            print("record inserted");
          } else {
            print("some issue");
          }
        } catch(e){
          print(e);
        }
      } else{
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Please fill in the Problem Name'),
        ));
      }
    }

    return showDialog(context: context, builder: (context) => AlertDialog(

      title: Column(
        children: [
          TextFormField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Problem Name'),
          ),
          Container(
            width: 300,
            margin: const EdgeInsets.only(top: 10),
            child: MaterialButton(
              child: const Text('Add Marker'),
              onPressed: () { insertRecord(); },
            ),
          )
        ],
      ),
    )
    );
  }
}
