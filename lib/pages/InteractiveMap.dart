import 'dart:async';
//import 'dart:html';
import 'package:flutter/services.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
//import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

import 'example_popup.dart';

class InteractiveMap extends StatefulWidget {
  const InteractiveMap({Key? key}) : super(key: key);

  @override
  State<InteractiveMap> createState() => _InteractiveMapState();
}

class _InteractiveMapState extends State<InteractiveMap> {
  LocationData? _currentLocation;
  late final MapController _mapController;
  late CenterOnLocationUpdate _centerOnLocationUpdate;
  late StreamController<double?> _centerCurrentLocationStreamController;

  final PopupController _popupLayerController = PopupController();

  bool _permission = false;

  String? _serviceError = '';

  var interActiveFlags = InteractiveFlag.all & ~InteractiveFlag.rotate;

  final Location _locationService = Location();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    initLocationService();
    _centerOnLocationUpdate = CenterOnLocationUpdate.always;
    _centerCurrentLocationStreamController = StreamController<double?>();
  }

  @override
  void dispose() {
    _centerCurrentLocationStreamController.close();
    super.dispose();
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

  /*bool _load = false;
  late File? imgFile;
  final imgPicker = ImagePicker();

  Widget showImage() {
    if (_load == false) {
      return const Text('no image found');
    } else {
      return const Text('Image Uploaded');
      return Image.file(
        imgFile,
        width: 350,
        height: 350,
      );
    }
  }

  void openCamera() async {
    var imgCamera = await imgPicker.getImage(source: ImageSource.camera);

    setState(() {
      imgFile = File(imgCamera!.path);
      _load = true;
    });
    Navigator.of(context).pop();
  }

  void openGallery() async {
    var imgGallery = await imgPicker.getImage(source: ImageSource.gallery);

    setState(() {
      imgFile = File(imgGallery!.path);
      _load = true;
    });
    Navigator.of(context).pop();
  }

  Future<void> chooseImageDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Choose Source"),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  GestureDetector(
                    child: const Text('Capture Image From Camera'),
                    onTap: () {
                      openCamera();
                    },
                  ),
                  const Padding(padding: EdgeInsets.all(10)),
                  GestureDetector(
                    child: const Text('Select Image From Gallery'),
                    onTap: () {
                      openGallery();
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }*/
  List<LatLng> markerPoints = [
    LatLng(12.140316, -68.858835),
    LatLng(12.194014, -68.981139),
    LatLng(12.156427, -68.865706),
  ];

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

    return Scaffold(
      appBar: AppBar(title: const Text('Add Marker')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
              child: _serviceError!.isEmpty
                  ? Text('Your current location is '
                      '(${currentLatLng.latitude}, ${currentLatLng.longitude}).')
                  : Text(
                      'Error occurred while acquiring location. Error Message : '
                      '$_serviceError'),
            ),
            Flexible(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  onTap: (_, __) => _popupLayerController.hideAllPopups(),
                  onPositionChanged: (MapPosition position, bool hasGesture) {
                    if (hasGesture) {
                      setState(
                        () => _centerOnLocationUpdate =
                            CenterOnLocationUpdate.never,
                      );
                    }
                  },
                  maxBounds: LatLngBounds(
                    LatLng(12.398636, -69.177026),
                    LatLng(11.997293, -68.725121),
                  ),
                  zoom: 13,
                  maxZoom: 17,
                  interactiveFlags: interActiveFlags,
                ),
                children: [
                  TileLayerWidget(
                    options: TileLayerOptions(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: ['a', 'b', 'c'],
                      maxZoom: 19,
                    ),
                  ),
                  LocationMarkerLayerWidget(
                    plugin: LocationMarkerPlugin(
                      centerCurrentLocationStream:
                          _centerCurrentLocationStreamController.stream,
                      centerOnLocationUpdate: _centerOnLocationUpdate,
                    ),
                  ),
                  PopupMarkerLayerWidget(
                      options: PopupMarkerLayerOptions(
                    markers: <Marker>[
                      DisplayMarker(
                          marker3: MarkerData(
                        name: 'Kas Na Kandela',
                        image:
                            "https://media.istockphoto.com/photos/controlled-burn-picture-id172376898?k=20&m=172376898&s=612x612&w=0&h=hK_rOow29oisE-WbTGu7r-W0Xdtkh7Zqtjkv2_gadag=",
                        latLocation: LatLng(12.140316, -68.858835),
                      )),
                    ],
                    popupController: _popupLayerController,
                        popupAnimation: const PopupAnimation.fade(
                            duration: Duration(milliseconds: 500)),
                    popupBuilder: (_, Marker marker) {
                      if (marker is DisplayMarker) {
                        return MarkerDataPopup(markerDataVar: marker.marker3);
                      } else {
                        return const Card(child: Text('No Data Found'));
                      }
                    },
                  ))
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
                    if (_currentLocation == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please try again'),
                      ));
                    } else {
                      setState(() => _centerOnLocationUpdate =
                          CenterOnLocationUpdate.always);
                      _centerCurrentLocationStreamController.add(18);
                    }
                  },
                  child: const Icon(Icons.my_location)),
            ),
            Positioned(
              bottom: 75,
              right: 10,
              child: FloatingActionButton(
                  onPressed: () {
                    if (_currentLocation == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please find location first'),
                      ));
                    } else {
                      addMarkerDialog();
                    }
                    setState(() {});
                  },
                  child: const Icon(Icons.add_location_alt)),
            )
          ],
        );
      }),
    );
  }

  Future addMarkerDialog() {
    String name = '';
    String location = currentLatLng.toString();
    String status = 'open';
    String problemType = 'Select a Problem Type';

    void insertRecord() {
      if (name == '') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please fill in a problem name'),
        ));
      } else if (problemType == 'Select a Problem Type') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a problem type'),
        ));
      } else {
        http.post(Uri.parse("http://localhost/DBConnect/insert_record.php"),
            body: {
              'name': name,
              'location': location,
              'status': status,
              'type': problemType
            });
      }
    }

    return showDialog(
        context: context,
        builder: (context) => StatefulBuilder(builder: (context, setState) {
              return AlertDialog(
                title: Column(
                  children: <Widget>[
                    Container(
                      margin: const EdgeInsets.all(10),
                      child: TextFormField(
                        onChanged: (String value) {
                          setState(() {
                            name = value;
                          });
                        },
                        autofocus: true,
                        onFieldSubmitted: (v) {
                          insertRecord();
                        },
                        decoration:
                            const InputDecoration(labelText: 'Problem Name'),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.all(10),
                      child: DropdownButton<String>(
                        value: problemType,
                        onChanged: (String? newValue) {
                          setState(() {
                            problemType = newValue!;
                          });
                        },
                        items: <String>[
                          'Select a Problem Type',
                          'Social Distancing',
                          'Unauthorized Business Open',
                          'Curfew Violations',
                          'Potholes',
                          'Accessibility issues',
                          'Accidents',
                          'Garbage in the street',
                          'Illegal Dumping',
                          'Dead animal',
                          'Graffiti',
                          'Vandalism',
                          'Stray Animals',
                          'Utility Reports',
                          'Food Safety',
                          'Other',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                    /*Container(
                      margin: const EdgeInsets.all(10),
                      child: _load ? showImage() : const SizedBox(),
                    ),
                    Container(
                      margin: const EdgeInsets.all(10),
                      child: MaterialButton(
                        onPressed: () { chooseImageDialog(context);},
                        child: const Text('Choose an image'),
                      ),
                    ),*/
                    Container(
                      width: 300,
                      margin: const EdgeInsets.only(top: 10),
                      child: MaterialButton(
                        child: const Text('Add Marker'),
                        onPressed: () {
                          insertRecord();
                          Navigator.of(context).pop();
                        },
                      ),
                    )
                  ],
                ),
              );
            }));
  }
}
