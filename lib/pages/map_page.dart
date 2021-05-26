import 'dart:math';

import 'package:flutter_switch/flutter_switch.dart';
import 'package:menu_button/menu_button.dart';
import 'package:floating_menu_panel/floating_menu_panel.dart';
import 'package:flutter/material.dart';
import 'package:sensors/sensors.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:ndialog/ndialog.dart';

class MapPage extends StatefulWidget {
  MapPage({Key? key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with AutomaticKeepAliveClientMixin {
  //Location service
  Location location = new Location();
  //Location service enabled
  late bool _serviceEnabled;
  //Permissions check
  late PermissionStatus _permissionGranted;
  //Location data
  late LocationData _locationData;
  //Google map Controller
  late GoogleMapController _googleMapController;
  //Map markers
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  //Fetched locations status
  bool gotData = false;
  //Minimum location distance change
  double minLocationDistance = 5.0;

  //Map Polylines
  Set<Polyline> _polyline = {};
  //Current polyline points
  List<LatLng> currentPoints = [];

  //Google map map types
  List<MapType> mapTypes = [
    MapType.normal,
    MapType.satellite,
    MapType.hybrid,
    MapType.terrain
  ];
  //Initial map type
  int currentMapType = 0;
  //Map type dropdown
  List<String> mapTypeDropdownItems = [
    "Normal",
    "Satellite",
    "Hybrid",
    "Terrain"
  ];
  //Traffic enabled status
  bool trafficEnabled = false;

  /*
    Sensors
  */
  bool initializedSensors = false;
  bool showSensors = false;
  late UserAccelerometerEvent accelerometerEvent;

  @override
  void initState() {
    super.initState();
    initializeLocation();
    initializeSensors();
  }

  initializeSensors() {
    userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      setState(() {
        accelerometerEvent = event;
      });
    });
    setState(() {
      initializedSensors = true;
    });
  }

  buildAccelerometerDataDisplay() {
    return Container(
      margin: EdgeInsets.only(left: MediaQuery.of(context).size.width / 4),
      width: MediaQuery.of(context).size.width / 2,
      child: Column(
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                    title: Text(
                  "Accelerometer sensor : ",
                )),
                ListTile(
                  leading: Icon(Icons.sensors),
                  title: initializedSensors
                      ? Text(
                          "X-Axis : " + accelerometerEvent.x.toStringAsFixed(1),
                        )
                      : Text(""),
                ),
                ListTile(
                  leading: Icon(Icons.sensors),
                  title: initializedSensors
                      ? Text(
                          "Y-Axis : " + accelerometerEvent.y.toStringAsFixed(1),
                        )
                      : Text(""),
                ),
                ListTile(
                  leading: Icon(Icons.sensors),
                  title: initializedSensors
                      ? Text(
                          "Z-Axis : " + accelerometerEvent.z.toStringAsFixed(1),
                        )
                      : Text(""),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _addNewPolyline({int type = 0}) {
    int id = _polyline.length;
    if (type == 0) {
      _polyline.add(Polyline(
        endCap: Cap.roundCap,
        startCap: Cap.roundCap,
        polylineId: PolylineId("${id + 1}"),
        visible: true,
        points: currentPoints,
        color: Colors.blue,
      ));
    }
    if (type == 1) {
      _polyline.add(Polyline(
        endCap: Cap.roundCap,
        startCap: Cap.roundCap,
        polylineId: PolylineId("${id + 1}"),
        visible: true,
        points: currentPoints,
        color: Colors.orange,
      ));
    }
    if (type == 2) {
      _polyline.add(Polyline(
        endCap: Cap.roundCap,
        startCap: Cap.roundCap,
        polylineId: PolylineId("${id + 1}"),
        visible: true,
        points: currentPoints,
        color: Colors.red,
      ));
    }
  }

  LatLng? prevPos = null;
  int currRoadType = 0;
  initializeLocation() async {
    // ignore: deprecated_member_use
    var rng = new Random();
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
    _locationData = await location.getLocation();
    prevPos = LatLng(_locationData.latitude, _locationData.longitude);
    location.changeSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: minLocationDistance,
    );

    location.onLocationChanged.listen((LocationData currentLocation) {
      LatLng currPos = LatLng(
        currentLocation.latitude,
        currentLocation.longitude,
      );

      int x = rng.nextInt(3);

      if (x == 0) {
        if (currRoadType != 0) {
          currentPoints = [];
          currentPoints.add(prevPos!);
          _addNewPolyline(type: 0);
          currRoadType = 0;
        }
        currentPoints.add(currPos);
      }
      if (x == 1) {
        if (currRoadType != 1) {
          currentPoints = [];
          currentPoints.add(prevPos!);
          _addNewPolyline(type: 1);
          currRoadType = 1;
        }
        currentPoints.add(currPos);
      }
      if (x == 2) {
        if (currRoadType != 2) {
          currentPoints = [];
          currentPoints.add(prevPos!);
          _addNewPolyline(type: 2);
          currRoadType = 2;
        }
        currentPoints.add(currPos);
      }
      prevPos = currPos;
      _googleMapController.animateCamera(CameraUpdate.newLatLng(currPos));
      final MarkerId markerId = MarkerId("CurrPos");

      final Marker marker = Marker(
        markerId: markerId,
        position: currPos,
        infoWindow:
            InfoWindow(title: "Current Position", snippet: 'Current position'),
      );

      setState(() {
        markers[markerId] = marker;
      });
    });

    setState(() {
      addInitialPositionMarker();
      gotData = true;
    });
  }

  addInitialPositionMarker() {
    final MarkerId markerId = MarkerId("initialPosition");

    final Marker marker = Marker(
      markerId: markerId,
      position: LatLng(
        _locationData.latitude,
        _locationData.longitude,
      ),
      infoWindow:
          InfoWindow(title: "initialPosition", snippet: 'Initial Position'),
    );

    setState(() {
      markers[markerId] = marker;
    });
  }

  buildMap() {
    return Container(
      child: GoogleMap(
        markers: Set<Marker>.of(markers.values),
        polylines: _polyline,
        mapType: mapTypes[currentMapType],
        trafficEnabled: trafficEnabled,
        initialCameraPosition: CameraPosition(
          target: LatLng(_locationData.latitude, _locationData.longitude),
          zoom: 20,
        ),
        onMapCreated: (GoogleMapController controller) {
          _googleMapController = controller;
        },
      ),
    );
  }

  final Widget normalChildButton = SizedBox(
    width: 93,
    height: 40,
    child: Padding(
      padding: const EdgeInsets.only(left: 16, right: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(child: Text("Map Type", overflow: TextOverflow.ellipsis)),
          const SizedBox(
            width: 12,
            height: 17,
            child: FittedBox(
              fit: BoxFit.fill,
              child: Icon(
                Icons.arrow_drop_down,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  buildMapSettingsPopup() async {
    await NDialog(
      dialogStyle: DialogStyle(titleDivider: true),
      title: Text("Map Settings"),
      content: Container(
        height: MediaQuery.of(context).size.height / 2,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("Map Type"),
                MenuButton(
                  child: normalChildButton,
                  items: mapTypeDropdownItems,
                  itemBuilder: (String value) => Container(
                    height: 40,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                        vertical: 0.0, horizontal: 5),
                    child: Text(value),
                  ),
                  toggledChild: Container(
                    child: normalChildButton,
                  ),
                  onItemSelected: (String value) {
                    setState(() {
                      currentMapType = mapTypeDropdownItems.indexOf(value);
                    });
                  },
                )
              ],
            ),
            Row(
              children: [
                Text("Traffic "),
                FlutterSwitch(
                    value: trafficEnabled,
                    onToggle: (_) {
                      setState(() {
                        trafficEnabled = !trafficEnabled;
                        Navigator.pop(context);
                      });
                    })
              ],
            ),
          ],
        ),
      ),
    ).show(context, transitionType: DialogTransitionType.Bubble);
  }

  buildFloatingBox() {
    return FloatingMenuPanel(
      positionTop: 0.0, // Initial Top Position
      positionLeft: 0.0, // Initial Left Position
      backgroundColor: Color(0xFFEDEDED), // Color of the panel
      contentColor: Colors.black, // Color of the icons
      borderRadius: BorderRadius.circular(8.0), // Border radius of the panel
      dockType: DockType
          .inside, // 'DockType.inside' or 'DockType.outside', weather to dock the panel outside or inside the edge of the screen
      dockOffset:
          5.0, // Offset the dock from the edge depending on the 'dockType' property
      panelAnimDuration: 300, // Duration for panel open and close animation
      panelAnimCurve:
          Curves.easeOut, // Curve for panel open and close animation
      dockAnimDuration:
          100, // Auto dock to the edge of screen - animation duration
      dockAnimCurve: Curves.easeOut, // Auto dock animation curve
      panelOpenOffset:
          20.0, // Offset from the edge of screen when panel is open
      panelIcon: Icons.menu, // Panel open/close icon
      size: 70.0, // Size of single button in the panel
      iconSize: 24.0, // Size of icons
      borderWidth: 1.0, // Width of panel border
      borderColor: Colors.black, // Color of panel border
      onPressed: (index) {
        if (index == 0) buildMapSettingsPopup();
        if (index == 2)
          setState(() {
            showSensors = !showSensors;
          });
      },
      buttons: [
        Icons.map_outlined,
        Icons.camera_alt,
        showSensors ? Icons.sensors_off : Icons.sensors,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          gotData ? buildMap() : Text("Fetching location ! "),
          buildFloatingBox(),
          if (showSensors) buildAccelerometerDataDisplay(),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
