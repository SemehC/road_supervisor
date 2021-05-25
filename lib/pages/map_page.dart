import 'dart:async';

import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:floating_menu_panel/floating_menu_panel.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapPage extends StatefulWidget {
  MapPage({Key? key}) : super(key: key);

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with AutomaticKeepAliveClientMixin {
  Location location = new Location();
  late bool _serviceEnabled;
  late PermissionStatus _permissionGranted;
  late LocationData _locationData;

  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  int _markerIdCounter = 1;
  bool gotData = false;
  double minLocationDistance = 1.0;

  List<LocationData> locations = [];
  final Set<Polyline> _polyline = {};

  @override
  void initState() {
    super.initState();
    initializeLocation();
  }

  initializeLocation() async {
    // ignore: deprecated_member_use

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
    locations.add(_locationData);
    location.changeSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: minLocationDistance,
    );

    location.onLocationChanged.listen((LocationData currentLocation) {
      locations.add(currentLocation);
      if (locations.length > 1) {
        Fluttertoast.showToast(
            msg:
                "Locations : ${locations[locations.length - 1]} ; ${locations[locations.length]}");
        _addPolyline(
          LatLng(locations[locations.length - 1].latitude,
              locations[locations.length - 1].longitude),
          LatLng(locations[locations.length].latitude,
              locations[locations.length].longitude),
        );
      }

      print(currentLocation);
    });

    setState(() {
      addInitialPositionMarker();
      gotData = true;
    });
  }

  _addPolyline(LatLng pos1, LatLng pos2) {
    List<LatLng> latlng = [];
    latlng.add(pos1);
    latlng.add(pos2);
    _polyline.add(Polyline(
      polylineId: PolylineId("Route"),
      visible: true,
      //latlng is List<LatLng>
      points: latlng,
      color: Colors.blue,
    ));
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

  Completer<GoogleMapController> _controller = Completer();

  buildMap() {
    return Container(
      child: GoogleMap(
        markers: Set<Marker>.of(markers.values),
        polylines: _polyline,
        mapType: MapType.hybrid,
        initialCameraPosition: CameraPosition(
          target: LatLng(_locationData.latitude, _locationData.longitude),
          zoom: 20,
        ),
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
    );
  }

  buildFloatingActionButton() {
    return FabCircularMenu(
      children: <Widget>[
        IconButton(
            icon: Icon(Icons.map_outlined),
            onPressed: () {
              print('Home');
            }),
        IconButton(
            icon: Icon(Icons.control_point_duplicate_outlined),
            onPressed: () {
              print('Favorite');
            }),
        IconButton(
            icon: Icon(Icons.camera_alt),
            onPressed: () {
              print('video');
            })
      ],
      alignment: Alignment.centerRight,
      ringWidth: 100,
      ringDiameter: 250,
    );
  }

  bool isFloatingOpen = false;

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
        print("Clicked on item: $index");
      },
      buttons: [
        Icons.map_outlined,
        Icons.camera_alt,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Expanded(
            child: gotData ? buildMap() : Text("Fetching location ! "),
          ),
          buildFloatingBox(),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
