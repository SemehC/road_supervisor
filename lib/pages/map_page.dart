import 'dart:async';

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
  double minLocationDistance = 5.0;

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
      if (locations.length > 1)
        _addPolyline(
          locations[locations.length - 1],
          locations[locations.length - 1],
        );
    });

    setState(() {
      addInitialPositionMarker();
      gotData = true;
    });
  }

  _addPolyline(LocationData pos1, LocationData pos2) {
    List<LatLng> latlng = [];
    latlng.add(LatLng(pos1.latitude, pos1.longitude));
    latlng.add(LatLng(pos2.latitude, pos2.longitude));
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

  @override
  Widget build(BuildContext context) {
    return Container(
      child: gotData ? buildMap() : Text("Fetching location ! "),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
